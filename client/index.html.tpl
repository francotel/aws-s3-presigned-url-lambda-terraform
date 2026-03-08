<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>S3 Secure Upload</title>
    <script src="https://cdn.jsdelivr.net/npm/spark-md5@3.0.2/spark-md5.min.js"></script>
    <style>
        :root{
        --primary:#6542DD;
        --secondary:#AF9FFF;
        --bg:#0b0b12;
        --glass:rgba(255,255,255,.05);
        --border:rgba(255,255,255,.08);
        --text:#ffffff;
        --muted:#9ca3af;
        }
        
        *{
        box-sizing:border-box;
        font-family:system-ui,-apple-system,'Segoe UI',Roboto,sans-serif;
        }
        
        body{
        margin:0;
        min-height:100vh;
        display:flex;
        align-items:center;
        justify-content:center;
        background:
        radial-gradient(circle at 20% 20%, #6542DD33, transparent 40%),
        radial-gradient(circle at 80% 80%, #AF9FFF33, transparent 40%),
        var(--bg);
        color:white;
        }
        
        .container{
        width:640px;
        background:var(--glass);
        border:1px solid var(--border);
        border-radius:16px;
        backdrop-filter:blur(20px);
        -webkit-backdrop-filter:blur(20px);
        padding:2rem;
        box-shadow:
        0 10px 40px rgba(0,0,0,.6),
        inset 0 0 1px rgba(255,255,255,.1);
        }
        
        /* HEADER */
        .header{
        text-align:center;
        margin-bottom:2rem;
        }
        
        .logo{
        height:50px;
        margin-bottom:10px;
        }
        
        .header h1{
        margin:0;
        font-size:1.6rem;
        font-weight:600;
        }
        
        .header p{
        margin-top:6px;
        font-size:.9rem;
        color:var(--muted);
        }
        
        /* UPLOAD AREA */
        .upload-area{
        border:2px dashed var(--border);
        border-radius:14px;
        padding:2.5rem;
        text-align:center;
        cursor:pointer;
        transition:.25s;
        background:rgba(255,255,255,.02);
        }
        
        .upload-area:hover{
        border-color:var(--primary);
        background:rgba(255,255,255,.04);
        }
        
        .upload-area.dragover{
        border-color:var(--secondary);
        background:rgba(101,66,221,.12);
        }
        
        .upload-icon{
        font-size:38px;
        margin-bottom:10px;
        }
        
        /* BUTTONS */
        .button-container {
            display: flex;
            gap: 1rem;
            justify-content: center;
            margin-top: 1rem;
        }
        
        button{
        background:linear-gradient(135deg,var(--primary),var(--secondary));
        border:none;
        color:white;
        padding:.7rem 1.5rem;
        border-radius:8px;
        font-weight:600;
        cursor:pointer;
        transition:.2s;
        border: 1px solid rgba(255,255,255,0.1);
        }
        
        button:hover{
        transform:translateY(-1px);
        box-shadow:0 6px 18px rgba(101,66,221,.4);
        }
        
        button:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }
        
        /* PREVIEW */
        .preview{
        margin-top:1.5rem;
        display:none;
        justify-content:center;
        align-items:center;
        text-align:center;
        }
        
        .preview img,
        .preview video{
        display:block;
        margin:auto;
        max-width:100%;
        max-height:260px;
        border-radius:10px;
        border:1px solid var(--border);
        object-fit:contain;
        }
        
        /* FILE INFO */
        .file-info{
        margin-top:1rem;
        padding:1rem;
        background:rgba(255,255,255,.03);
        border-radius:10px;
        display:none;
        border-left: 4px solid var(--primary);
        }
        
        .file-details{
        display:grid;
        grid-template-columns:auto 1fr;
        gap:.5rem 1rem;
        margin-top:.5rem;
        font-size:.9rem;
        }
        
        .file-details strong{
        color:var(--muted);
        }
        
        /* PROGRESS */
        progress{
        width:100%;
        margin-top:1rem;
        height:10px;
        display:none;
        border-radius:10px;
        overflow:hidden;
        }
        
        progress::-webkit-progress-bar{
        background:#1c1c26;
        }
        
        progress::-webkit-progress-value{
        background:linear-gradient(90deg,var(--primary),var(--secondary));
        }
        
        /* STATUS */
        .status{
        margin-top:1rem;
        padding:.8rem;
        border-radius:8px;
        font-size:.9rem;
        display:none;
        font-weight:500;
        }
        
        .success{
        background:#0f2e1f;
        color:#4ade80;
        border-left: 4px solid #4ade80;
        }
        
        .error{
        background:#2b1515;
        color:#f87171;
        border-left: 4px solid #f87171;
        }
        
        .loading{
        background:#2a2410;
        color:#facc15;
        border-left: 4px solid #facc15;
        }
        
        footer{
        margin-top:1.5rem;
        text-align:center;
        font-size:.75rem;
        color:#6b7280;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <img src="logo-client.png" class="logo" alt="Logo">
            <h1>Secure File Upload</h1>
            <p>Upload files directly to Amazon S3 using presigned URLs</p>
        </div>

        <!-- API Gateway URL injected by Terraform -->
        <form id="uploadForm" action="${api_gateway_url}">
            <div class="upload-area" id="dropZone">
                <div class="upload-icon">☁️</div>
                <p><strong>Drag & drop</strong> your file</p>
                <p style="color:#9ca3af;font-size:.85rem;">or choose from device</p>
                <input type="file" id="fileInput" hidden>
                <button type="button" id="selectFileBtn">Select File</button>
            </div>

            <div class="preview" id="preview">
                <img id="previewImage" alt="Preview">
                <video id="previewVideo" controls></video>
            </div>

            <div class="file-info" id="fileInfo">
                <strong>📄 File Information</strong>
                <div class="file-details">
                    <strong>Name:</strong> <span id="fileName"></span>
                    <strong>Size:</strong> <span id="fileSize"></span>
                    <strong>Type:</strong> <span id="fileType"></span>
                    <strong>Network:</strong> <span id="networkType"></span>
                </div>
            </div>

            <progress id="progressBar" value="0" max="100"></progress>
            <div class="status" id="status"></div>

            <div class="button-container">
                <button type="button" id="uploadBtn" disabled>🚀 Upload to S3</button>
            </div>
        </form>

        <footer>
            Powered by Amazon S3 Presigned URLs
        </footer>
    </div>

    <script>
        // DOM element references
        const DOM = {
            form: document.getElementById('uploadForm'),
            fileInput: document.getElementById('fileInput'),
            selectFileBtn: document.getElementById('selectFileBtn'),
            uploadBtn: document.getElementById('uploadBtn'),
            dropZone: document.getElementById('dropZone'),
            preview: document.getElementById('preview'),
            previewImage: document.getElementById('previewImage'),
            previewVideo: document.getElementById('previewVideo'),
            fileInfo: document.getElementById('fileInfo'),
            fileName: document.getElementById('fileName'),
            fileSize: document.getElementById('fileSize'),
            fileType: document.getElementById('fileType'),
            networkType: document.getElementById('networkType'),
            progressBar: document.getElementById('progressBar'),
            status: document.getElementById('status')
        };
        
        // State
        let selectedFile = null;
        let fileNetwork = 'unknown';
        let fileBase64MD5 = null;
        
        // ==================== EVENT LISTENERS ====================
        
        // Select file button
        DOM.selectFileBtn.addEventListener('click', () => {
            DOM.fileInput.click();
        });
        
        // Upload button
        DOM.uploadBtn.addEventListener('click', async () => {
            if (selectedFile && fileBase64MD5) {
                await processUpload(selectedFile, fileNetwork, fileBase64MD5);
            } else {
                updateStatus('error', '❌ Please select a file first');
            }
        });
        
        // File input change
        DOM.fileInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                selectedFile = file;
                handleFileSelection(file);
            }
        });
        
        // Drag & drop prevention
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            DOM.dropZone.addEventListener(eventName, preventDefaults);
        });
        
        function preventDefaults(e) {
            e.preventDefault();
            e.stopPropagation();
        }
        
        // Drag & drop visual feedback
        ['dragenter', 'dragover'].forEach(eventName => {
            DOM.dropZone.addEventListener(eventName, () => {
                DOM.dropZone.classList.add('dragover');
            });
        });
        
        ['dragleave', 'drop'].forEach(eventName => {
            DOM.dropZone.addEventListener(eventName, () => {
                DOM.dropZone.classList.remove('dragover');
            });
        });
        
        // Drop event
        DOM.dropZone.addEventListener('drop', (e) => {
            const file = e.dataTransfer.files[0];
            if (file) {
                DOM.fileInput.files = e.dataTransfer.files;
                selectedFile = file;
                handleFileSelection(file);
            }
        });
        
        // ==================== CORE FUNCTIONS ====================
        
        /**
         * Handles file selection and prepares for upload
         * @param {File} file - Selected file object
         */
        async function handleFileSelection(file) {
            if (!file) return;
        
            // Show preview
            showPreview(file);
        
            // Display file information
            DOM.fileInfo.style.display = 'block';
            DOM.fileName.textContent = file.name;
            DOM.fileSize.textContent = formatBytes(file.size);
            DOM.fileType.textContent = file.type || 'application/octet-stream';
            
            // Detect network type
            fileNetwork = detectNetwork();
            DOM.networkType.textContent = fileNetwork;
        
            // Calculate MD5 hash
            updateStatus('loading', '🔄 Calculating MD5 hash...');
            DOM.progressBar.style.display = 'block';
            DOM.progressBar.value = 30;
            
            try {
                fileBase64MD5 = await calculateMD5Base64(file);
                console.debug('MD5 calculated:', fileBase64MD5);
                
                DOM.progressBar.value = 60;
                updateStatus('success', '✅ File ready for upload');
                
                // Enable upload button
                DOM.uploadBtn.disabled = false;
            } catch (error) {
                console.error('MD5 calculation error:', error);
                updateStatus('error', '❌ Failed to calculate MD5');
                DOM.uploadBtn.disabled = true;
            }
        }
        
        /**
         * Shows preview for images and videos
         * @param {File} file - File to preview
         */
        function showPreview(file) {
            DOM.preview.style.display = 'flex';
            DOM.previewImage.style.display = 'none';
            DOM.previewVideo.style.display = 'none';
        
            const url = URL.createObjectURL(file);
        
            if (file.type.startsWith('image/')) {
                DOM.previewImage.src = url;
                DOM.previewImage.style.display = 'block';
            } else if (file.type.startsWith('video/')) {
                DOM.previewVideo.src = url;
                DOM.previewVideo.style.display = 'block';
            }
        }
        
        /**
         * Formats bytes to human readable format
         * @param {number} bytes - File size in bytes
         * @returns {string} Formatted size
         */
        function formatBytes(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }
        
        /**
         * Detects network type using Network Information API
         * @returns {string} Network type
         */
        function detectNetwork() {
            if ('connection' in navigator) {
                const conn = navigator.connection || 
                            navigator.mozConnection || 
                            navigator.webkitConnection;
                return conn.effectiveType || conn.type || 'unknown';
            }
            return 'unknown';
        }
        
        /**
         * Calculates MD5 hash and returns Base64 encoded string
         * @param {File} file - File to hash
         * @returns {Promise<string>} Base64 encoded MD5
         */
        async function calculateMD5Base64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = (e) => {
                    try {
                        const spark = new SparkMD5.ArrayBuffer();
                        spark.append(e.target.result);
                        const md5Binary = spark.end(true);
                        resolve(btoa(md5Binary));
                    } catch (error) {
                        reject(error);
                    }
                };
                reader.onerror = reject;
                reader.readAsArrayBuffer(file);
            });
        }
        
        /**
         * Main upload process
         * @param {File} file - File to upload
         * @param {string} network - Network type
         * @param {string} base64MD5 - Base64 MD5 hash
         */
        async function processUpload(file, network, base64MD5) {
            updateStatus('loading', '🔑 Requesting presigned URL...');
            DOM.progressBar.value = 30;
            DOM.uploadBtn.disabled = true;
        
            try {
                // Get presigned URL from API
                const presignedUrl = await getPresignedUrl(file, base64MD5, network);
                
                if (!presignedUrl) {
                    throw new Error('Failed to obtain presigned URL');
                }
        
                // Upload directly to S3
                updateStatus('loading', '📤 Uploading to S3...');
                DOM.progressBar.value = 60;
                
                await uploadToS3(presignedUrl, file, base64MD5);
                
                DOM.progressBar.value = 100;
                updateStatus('success', '✅ File uploaded successfully!');
                
            } catch (error) {
                console.error('Upload error:', error);
                updateStatus('error', `❌ Error: $${error.message}`);
                DOM.progressBar.value = 0;
                DOM.uploadBtn.disabled = false;
            }
        }
        
        /**
         * Requests presigned URL from API Gateway
         * @param {File} file - File to upload
         * @param {string} base64MD5 - Base64 MD5 hash
         * @param {string} network - Network type
         * @returns {Promise<string>} Presigned URL
         */
        async function getPresignedUrl(file, base64MD5, network) {
            const response = await fetch(DOM.form.action, {
                method: 'POST',
                headers: { 
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    filename: file.name,
                    filesize: file.size,
                    filetype: file.type || 'application/octet-stream',
                    filemd5: base64MD5,
                    clientnetwork: network
                })
            });
        
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.error || `HTTP $${response.status}: $${response.statusText}`);
            }
        
            const data = await response.json();
            return data.presignedUrl;
        }
        
        /**
         * Uploads file directly to S3 using presigned URL
         * @param {string} presignedUrl - Presigned URL
         * @param {File} file - File to upload
         * @param {string} base64MD5 - Base64 MD5 hash for validation
         */
        async function uploadToS3(presignedUrl, file, base64MD5) {
            const response = await fetch(presignedUrl, {
                method: 'PUT',
                headers: {
                    'Content-MD5': base64MD5,
                    'Content-Type': file.type || 'application/octet-stream'
                },
                body: file
            });
        
            if (!response.ok) {
                throw new Error(`S3 upload failed: $${response.statusText}`);
            }
        
            return response;
        }
        
        /**
         * Updates status message
         * @param {string} type - Status type (success, error, loading)
         * @param {string} message - Status message
         */
        function updateStatus(type, message) {
            DOM.status.style.display = 'block';
            DOM.status.className = `status $${type}`;
            DOM.status.textContent = message;
        }
    </script>

</body>

</html>