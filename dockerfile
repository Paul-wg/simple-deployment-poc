# Use lightweight nginx image
FROM nginx:alpine

# Set environment variable for branch name
ARG ENV_NAME=unknown
ARG BUILD_TIME=unknown

# Create custom index.html with deployment workflow
RUN echo "<!DOCTYPE html>" > /usr/share/nginx/html/index.html && \
    echo "<html><head><title>POC Deployment</title>" >> /usr/share/nginx/html/index.html && \
    echo "<style>" >> /usr/share/nginx/html/index.html && \
    echo "body { font-family: Arial; text-align: center; padding: 50px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }" >> /usr/share/nginx/html/index.html && \
    echo "h1 { font-size: 3em; margin: 20px 0; }" >> /usr/share/nginx/html/index.html && \
    echo "h2 { font-size: 2em; margin: 20px 0; }" >> /usr/share/nginx/html/index.html && \
    echo "p { font-size: 1.2em; }" >> /usr/share/nginx/html/index.html && \
    echo ".workflow { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; margin: 30px auto; max-width: 600px; text-align: left; }" >> /usr/share/nginx/html/index.html && \
    echo ".workflow h3 { margin-top: 0; text-align: center; }" >> /usr/share/nginx/html/index.html && \
    echo ".workflow ol { line-height: 1.8; }" >> /usr/share/nginx/html/index.html && \
    echo "</style></head><body>" >> /usr/share/nginx/html/index.html && \
    echo "<h1>Simple Deployment POC - Happy Friday!</h1>" >> /usr/share/nginx/html/index.html && \
    echo "<h2>I am ${ENV_NAME} at ${BUILD_TIME}!</h2>" >> /usr/share/nginx/html/index.html && \
    echo "<h2>Long weekend ahead - Time to relax!</h2>" >> /usr/share/nginx/html/index.html && \
    echo "<p>Environment: ${ENV_NAME}</p>" >> /usr/share/nginx/html/index.html && \
    echo "<p>Build Time: ${BUILD_TIME}</p>" >> /usr/share/nginx/html/index.html && \
    echo "<div class='workflow'><h3>Deployment Workflow</h3><ol>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Terraform builds AWS infrastructure</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Git commit/push code to GitHub</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>GitHub Actions triggered automatically</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Configure AWS credentials (OIDC)</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Login to AWS ECR</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Build Docker image</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Push image to ECR</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Auto-fetch target EC2 instance ID</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Deploy Docker container to EC2 via SSM</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Auto-fetch Elastic IP allocation</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Associate EIP with EC2 instance</li>" >> /usr/share/nginx/html/index.html && \
    echo "<li>Verify deployment success</li>" >> /usr/share/nginx/html/index.html && \
    echo "</ol></div></body></html>" >> /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
