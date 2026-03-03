<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>S3 Presigned URL Upload</title>
    <!-- SparkMD5 for MD5 hash calculation -->
    <script src="https://cdn.jsdelivr.net/npm/spark-md5@3.0.2/spark-md5.min.js"></script>
    <style>
        * { box-sizing: border-box; font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif; }
        body { max-width: 600px; margin: 2rem auto; padding: 0 1rem; background: #fafafa; }
        h1 { color: #232f3e; border-bottom: 2px solid #ff9900; padding-bottom: 0.5rem; }
        .upload-area { 
            border: 2px dashed #ccc; 
            padding: 2rem; 
            text-align: center; 
            border-radius: 8px;
            background: white;
            transition: all 0.3s ease;
            cursor: pointer;
        }
        .upload-area.dragover { 
            border-color: #ff9900; 
            background: #fff8e7; 
        }
        .file-info { 
            margin-top: 1rem; 
            padding: 1rem; 
            background: #f0f0f0; 
            border-radius: 4px; 
            display: none; 
            border-left: 4px solid #ff9900;
        }
        .progress { 
            width: 100%; 
            height: 20px; 
            margin: 1rem 0; 
            display: none;
            border-radius: 10px;
        }
        .progress::-webkit-progress-value {
            background: #ff9900;
            border-radius: 10px;
        }
        .progress::-webkit-progress-bar {
            background: #e0e0e0;
            border-radius: 10px;
        }
        .status { 
            padding: 1rem; 
            border-radius: 4px; 
            margin-top: 1rem; 
            display: none;
            font-weight: 500;
        }
        .success { 
            background: #d4edda; 
            color: #155724; 
            border-left: 4px solid #28a745;
        }
        .error { 
            background: #f8d7da; 
            color: #721c24; 
            border-left: 4px solid #dc3545;
        }
        .loading { 
            background: #fff3cd; 
            color: #856404; 
            border-left: 4px solid #ffc107;
        }
        button { 
            background: #ff9900; 
            color: #232f3e; 
            border: none; 
            padding: 0.75rem 1.5rem; 
            border-radius: 4px; 
            cursor: pointer; 
            font-weight: 600;
            transition: background 0.3s ease;
        }
        button:hover { 
            background: #ffb84d; 
        }
        button:disabled { 
            opacity: 0.5; 
            cursor: not-allowed; 
        }
        .file-details {
            display: grid;
            grid-template-columns: auto 1fr;
            gap: 0.5rem 1rem;
            margin-top: 0.5rem;
        }
        .file-details strong {
            color: #232f3e;
        }
    </style>
</head>
<body>
    <h1>📤 Upload File to Amazon S3</h1>
    <p>Select a file to generate a presigned URL and upload directly to S3</p>
    
    <!-- API Gateway URL will be injected by Terraform -->
    <form id="uploadForm" action="${api_gateway_url}">
        <div class="upload-area" id="dropZone">
            <p>📁 Drag & drop a file here or click to select</p>
            <input type="file" id="fileInput" hidden>
            <button type="button" id="selectFileBtn">Select File</button>
        </div>
        
        <div class="file-info" id="fileInfo">
            <strong>📄 File Information:</strong>
            <div class="file-details">
                <strong>Name:</strong> <span id="fileName"></span>
                <strong>Size:</strong> <span id="fileSize"></span>
                <strong>Type:</strong> <span id="fileType"></span>
                <strong>Network:</strong> <span id="networkType"></span>
            </div>
        </div>

        <progress class="progress" id="progressBar" value="0" max="100"></progress>
        
        <div class="status" id="status"></div>
    </form>

    <script>
        // DOM element references
        const DOM = {
            form: document.getElementById('uploadForm'),
            fileInput: document.getElementById('fileInput'),
            selectFileBtn: document.getElementById('selectFileBtn'),
            dropZone: document.getElementById('dropZone'),
            fileInfo: document.getElementById('fileInfo'),
            fileName: document.getElementById('fileName'),
            fileSize: document.getElementById('fileSize'),
            fileType: document.getElementById('fileType'),
            networkType: document.getElementById('networkType'),
            progressBar: document.getElementById('progressBar'),
            status: document.getElementById('status')
        };

        // ==================== EVENT LISTENERS ====================

        // File selection button
        DOM.selectFileBtn.addEventListener('click', () => {
            DOM.fileInput.click();
        });

        // File input change
        DOM.fileInput.addEventListener('change', (e) => {
            handleFileSelection(e.target.files[0]);
        });

        // Drag & drop event prevention
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
            DOM.fileInput.files = e.dataTransfer.files;
            handleFileSelection(file);
        });

        // ==================== CORE FUNCTIONS ====================

        /**
         * Handles file selection and initiates upload process
         * @param {File} file - Selected file object
         */
        async function handleFileSelection(file) {
            if (!file) return;

            // Display file information
            DOM.fileInfo.style.display = 'block';
            DOM.fileName.textContent = file.name;
            DOM.fileSize.textContent = formatBytes(file.size);
            DOM.fileType.textContent = file.type || 'application/octet-stream';
            
            // Detect network type
            const network = detectNetwork();
            DOM.networkType.textContent = network;

            // Start upload process
            await processUpload(file, network);
        }

        /**
         * Formats bytes to human readable format
         * @param {number} bytes - File size in bytes
         * @returns {string} Formatted size (e.g., "1.5 MB")
         */
        function formatBytes(bytes) {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }

        /**
         * Detects network type using Network Information API
         * @returns {string} Network type (wifi, 4g, 3g, etc.) or 'unknown'
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
         * Calculates MD5 hash of a file and returns Base64 encoded string
         * @param {File} file - File to hash
         * @returns {Promise<string>} Base64 encoded MD5 hash
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
         * Main upload process: MD5 calculation -> Get presigned URL -> Upload to S3
         * @param {File} file - File to upload
         * @param {string} network - Detected network type
         */
        async function processUpload(file, network) {
            updateStatus('loading', '🔄 Starting upload process...');
            DOM.progressBar.style.display = 'block';
            DOM.progressBar.value = 0;

            try {
                // Step 1: Calculate MD5
                updateStatus('loading', '📊 Calculating MD5 hash...');
                DOM.progressBar.value = 20;
                const base64MD5 = await calculateMD5Base64(file);
                console.debug('MD5 calculated:', base64MD5);

                // Step 2: Get presigned URL from API
                updateStatus('loading', '🔑 Requesting presigned URL...');
                DOM.progressBar.value = 40;
                const presignedUrl = await getPresignedUrl(file, base64MD5, network);
                
                if (!presignedUrl) {
                    throw new Error('Failed to obtain presigned URL');
                }

                // Step 3: Upload directly to S3
                updateStatus('loading', '📤 Uploading to S3...');
                DOM.progressBar.value = 60;
                await uploadToS3(presignedUrl, file, base64MD5);
                
                DOM.progressBar.value = 100;
                updateStatus('success', '✅ File uploaded successfully!');
                
            } catch (error) {
                console.error('Upload error:', error);
                updateStatus('error', `❌ Error: $${error.message}`);
                DOM.progressBar.value = 0;
            }
        }

        /**
         * Requests a presigned URL from the backend API
         * @param {File} file - File to upload
         * @param {string} base64MD5 - Base64 encoded MD5 hash
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
         * @param {string} presignedUrl - Presigned URL for upload
         * @param {File} file - File to upload
         * @param {string} base64MD5 - Base64 encoded MD5 hash for validation
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
         * Updates status message and styling
         * @param {string} type - Status type (success, error, loading)
         * @param {string} message - Status message to display
         */
        function updateStatus(type, message) {
            DOM.status.style.display = 'block';
            DOM.status.className = `status $${type}`;
            DOM.status.textContent = message;
        }
    </script>
</body>
</html>