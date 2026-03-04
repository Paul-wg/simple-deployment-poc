#!/bin/bash
# Generate dynamic index.html with current timestamp

ENV_NAME=${1:-Paul-wg}
BUILD_TIME=$(TZ='Australia/Melbourne' date '+%Y-%m-%d %H:%M:%S %Z')

cat > index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>CI/CD POC Deployment</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        h1 { font-size: 3em; margin: 20px 0; }
        h2 { font-size: 2em; margin: 20px 0; }
        p { font-size: 1.2em; }
        .workflow {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            margin: 30px auto;
            max-width: 600px;
            text-align: left;
        }
        .workflow h3 { margin-top: 0; text-align: center; }
        .workflow ol { line-height: 1.8; }
    </style>
</head>
<body>
    <h1> Simple Deployment POC to verify CI/CD</h1>
    <h2>I am ${ENV_NAME} at ${BUILD_TIME}!</h2>
    <p>Environment: ${ENV_NAME}</p>
    <p>Build Time: ${BUILD_TIME}</p>
    
    <div class="workflow">
        <h3>📋 Deployment Workflow</h3>
        <ol>
            <li>Terraform builds AWS infrastructure</li>
            <li>Git commit/push code to GitHub</li>
            <li>GitHub Actions triggered automatically</li>
            <li>Configure AWS credentials (OIDC)</li>
            <li>Login to AWS ECR</li>
            <li>Build Docker image</li>
            <li>Push image to ECR</li>
            <li>Auto-fetch target EC2 instance ID</li>
            <li>Deploy Docker container to EC2 via SSM</li>
            <li>Auto-fetch Elastic IP allocation</li>
            <li>Associate EIP with EC2 instance</li>
            <li>Verify deployment success</li>
        </ol>
    </div>
</body>
</html>
EOF

echo "Generated index.html for ${ENV_NAME} at ${BUILD_TIME}"
