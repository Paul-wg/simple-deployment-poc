# Use lightweight nginx image
FROM nginx:alpine

# Set environment variable for branch name
ARG ENV_NAME=unknown
ARG BUILD_TIME=unknown

# Create custom index.html
RUN echo "<!DOCTYPE html>" > /usr/share/nginx/html/index.html && \
    echo "<html><head><title>POC Deployment</title></head>" >> /usr/share/nginx/html/index.html && \
    echo "<body style='font-family: Arial; text-align: center; padding: 50px;'>" >> /usr/share/nginx/html/index.html && \
    echo "<h1>🚀 Simple Deployment POC</h1>" >> /usr/share/nginx/html/index.html && \
    echo "<h2>I am ${ENV_NAME} at ${BUILD_TIME}!</h2>" >> /usr/share/nginx/html/index.html && \
    echo "<p>Environment: ${ENV_NAME}</p>" >> /usr/share/nginx/html/index.html && \
    echo "<p>Build Time: ${BUILD_TIME}</p>" >> /usr/share/nginx/html/index.html && \
    echo "</body></html>" >> /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
