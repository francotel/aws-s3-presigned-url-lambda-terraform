# ============================================
# 🚀 Terraform + DevSecOps Makefile
# ============================================

.EXPORT_ALL_VARIABLES:

# -------- Global variables --------
AWS_PROFILE ?= scc-aws
ENV ?= dev

TFVARS := $(ENV).tfvars
TFPLAN := tfplan
TFPLAN_JSON := tfplan.json

PROJECT_NAME := aws-s3-presigned-url
SEC_DIR := security

TERRAFORM := terraform

# -------- Help --------
.PHONY: help
help:
	@echo "📘 Available commands"
	@echo ""
	@echo "🌱 Infrastructure"
	@echo "  make tf-init        Initialize Terraform"
	@echo "  make tf-plan        Terraform plan (ENV=$(ENV))"
	@echo "  make tf-apply       Apply Terraform"
	@echo "  make tf-destroy     Destroy infrastructure"
	@echo ""
	@echo "🔐 Security / DevSecOps"
	@echo "  make sec-iac        Scan Terraform PLAN with Checkov"
	@echo "  make sec-fs         Scan repository with Trivy"
	@echo "  make sec-all        Run all security scans"
	@echo ""
	@echo "💰 FinOps"
	@echo "  make infracost      Cost breakdown"
	@echo "  make infracost-html Cost report (HTML)"
	@echo ""
	@echo "🧹 Utilities"
	@echo "  make clean          Cleanup local files"

# -------- Validation --------
.PHONY: check-env
check-env:
	@if [ ! -f "$(TFVARS)" ]; then \
		echo "❌ Missing tfvars file: $(TFVARS)"; \
		exit 1; \
	fi

# -------- Clean --------
.PHONY: clean
clean:
	@echo "🧹 Cleaning workspace..."
	rm -rf .terraform .terraform.lock.hcl \
		$(TFPLAN) $(TFPLAN_JSON)

# -------- Terraform --------
.PHONY: tf-init
tf-init:
	@echo "🌱 Terraform init (ENV=$(ENV))"
	$(TERRAFORM) init -reconfigure -upgrade
	$(TERRAFORM) validate

.PHONY: tf-plan
tf-plan: check-env tf-init
	@echo "🧪 Terraform plan (ENV=$(ENV))"
	$(TERRAFORM) fmt --recursive
	$(TERRAFORM) plan -var-file=$(TFVARS) -out=$(TFPLAN)

.PHONY: tf-plan-json
tf-plan-json: tf-plan
	@echo "📄 Exporting Terraform plan to JSON"
	$(TERRAFORM) show -json $(TFPLAN) > $(TFPLAN_JSON)

.PHONY: tf-apply
tf-apply:
	@echo "🚀 Terraform apply"
	$(TERRAFORM) apply -auto-approve -input=false $(TFPLAN)

.PHONY: tf-destroy
tf-destroy: check-env
	@echo "💣 Terraform destroy (ENV=$(ENV))"
	$(TERRAFORM) destroy -var-file=$(TFVARS) -auto-approve

# -------- Security: Checkov (Terraform PLAN) --------
.PHONY: sec-iac
sec-iac: tf-plan-json
	@echo "🔐 Running Checkov scan on Terraform PLAN"
	checkov \
		--framework terraform_plan \
		--config-file $(SEC_DIR)/checkov.yaml \
		-f $(TFPLAN_JSON)

# -------- Security: Trivy (Filesystem / Node.js) --------
.PHONY: sec-fs
sec-fs:
	@echo "🛡️ Running Trivy filesystem scan"
	trivy fs ./src \
		--config $(SEC_DIR)/trivy.yaml

# -------- Security: All --------
.PHONY: sec-all
sec-all: sec-iac sec-fs
	@echo "✅ All DevSecOps security scans completed"

# -------- FinOps --------
.PHONY: infracost
infracost: tf-plan
	@echo "💰 Infracost breakdown"
	infracost breakdown --path $(TFPLAN)

.PHONY: infracost-html
infracost-html: tf-plan
	@echo "📊 Infracost HTML report"
	infracost breakdown --path . --format html > cost-report.html
	open cost-report.html