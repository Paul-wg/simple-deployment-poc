#!/bin/bash
# Generate dynamic index.html with current timestamp

ENV_NAME=${1:-Paul-wg}
BUILD_TIME=$(date '+%Y-%m-%d %H:%M:%S')

cat > index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>POC Deployment</title>
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
    </style>
</head>
<body>
    <h1>🚀 Simple Deployment POC</h1>
    <h2>I am ${ENV_NAME} at ${BUILD_TIME}!</h2>
    <p>Environment: ${ENV_NAME}</p>
    <p>Build Time: ${BUILD_TIME}</p>
</body>
</html>
EOF

echo "Generated index.html for ${ENV_NAME} at ${BUILD_TIME}"
