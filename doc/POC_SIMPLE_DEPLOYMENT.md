# Simple POC - Automated Deployment Architecture

**Version:** 1.0 POC  
**Date:** March 2026  
**Status:** Proof of Concept  
**Purpose:** Simple CI/CD Flow Demonstration

---

## 1. POC Overview

### 1.1 Goal

Demonstrate a **simple automated deployment flow** from local development to AWS EC2 using GitHub Actions, Docker, and basic web server.

### 1.2 Scope

- ✅ Simple nginx web server with custom page
- ✅ 3 branches → 3 environments
- ✅ Automated build and deploy on git push
- ✅ Docker containerization
- ✅ Static IP association
- ✅ Automated verification test

### 1.3 Out of Scope (Keep it Simple!)

- ❌ Load balancers
- ❌ Auto-scaling
- ❌ Complex infrastructure
- ❌ Database setup
- ❌ SSL certificates
- ❌ Domain names

---

## 2. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    LOCAL DEVELOPMENT                            │
│                                                                 │
│  Developer Laptop (VS Code)                                     │
│  ├── Edit code                                                  │
│  ├── git commit                                                 │
│  └── git push                                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Push to Branch
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GITHUB REPOSITORY                            │
│                                                                 │
│  Repository: simple-deployment-poc                              │
│  ├── Branch: wg      → WG Environment                           │
│  ├── Branch: steven  → Steven Environment                       │
│  └── Branch: main    → Production Environment                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Trigger GitHub Actions
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              GITHUB ACTIONS (CI/CD Pipeline)                    │
│                                                                 │
│  Step 1: Detect Branch (wg/steven/main)                         │
│  Step 2: Build Docker Image                                     │
│         └── nginx + custom index.html                           │
│  Step 3: Push to Amazon ECR                                     │
│  Step 4: Deploy via SSM Session Manager                         │
│  Step 5: Pull & Run Docker Container                            │
│  Step 6: Associate Static IP (Elastic IP)                       │
│  Step 7: Verify with curl test                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Deploy to AWS
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS CLOUD (ap-southeast-4)                        │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  WG Environment (wg branch)                              │   │
│  │  ┌────────────┐         ┌────────────┐                  │   │
│  │  │ Elastic IP │────────▶│   EC2      │                  │   │
│  │  │ 3.x.x.1    │         │ t3.micro   │                  │   │
│  │  └────────────┘         │ Docker     │                  │   │
│  │                         │ nginx:80   │                  │   │
│  │                         └────────────┘                  │   │
│  │  ECR: simple-poc-wg:latest                               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Steven Environment (steven branch)                      │   │
│  │  ┌────────────┐         ┌────────────┐                  │   │
│  │  │ Elastic IP │────────▶│   EC2      │                  │   │
│  │  │ 3.x.x.2    │         │ t3.micro   │                  │   │
│  │  └────────────┘         │ Docker     │                  │   │
│  │                         │ nginx:80   │                  │   │
│  │                         └────────────┘                  │   │
│  │  ECR: simple-poc-steven:latest                           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Production Environment (main branch)                    │   │
│  │  ┌────────────┐         ┌────────────┐                  │   │
│  │  │ Elastic IP │────────▶│   EC2      │                  │   │
│  │  │ 3.x.x.3    │         │ t3.micro   │                  │   │
│  │  └────────────┘         │ Docker     │                  │   │
│  │                         │ nginx:80   │                  │   │
│  │                         └────────────┘                  │   │
│  │  ECR: simple-poc-prod:latest                             │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Deployment Flow

### 3.1 Step-by-Step Process

```
┌─────────────────────────────────────────────────────────────────┐
│ STEP 1: Developer Makes Changes                                │
├─────────────────────────────────────────────────────────────────┤
│ Location: Local Laptop (VS Code)                                │
│ Action:                                                         │
│   1. Edit code in project                                       │
│   2. git add .                                                  │
│   3. git commit -m "Update feature"                             │
│   4. git push origin wg                                         │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 2: GitHub Actions Triggered                                │
├─────────────────────────────────────────────────────────────────┤
│ Trigger: Push to branch (wg/steven/main)                        │
│ Action:                                                         │
│   1. Checkout code                                              │
│   2. Detect branch name                                         │
│   3. Set environment variables                                  │
│      - ENV_NAME = wg                                            │
│      - EC2_HOST = 3.x.x.1                                       │
│      - ECR_REPO = simple-poc-wg                                 │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 3: Build Docker Image                                      │
├─────────────────────────────────────────────────────────────────┤
│ Base Image: nginx:alpine (lightweight)                          │
│ Action:                                                         │
│   1. Create Dockerfile                                          │
│   2. Generate index.html with:                                  │
│      "I am WG at 2025-01-15 10:30:45!"                          │
│   3. docker build -t simple-poc-wg:latest .                     │
│   4. Tag image with timestamp                                   │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 4: Push to Amazon ECR                                      │
├─────────────────────────────────────────────────────────────────┤
│ Registry: AWS ECR (ap-southeast-4)                                   │
│ Action:                                                         │
│   1. aws ecr get-login-password                                 │
│   2. docker login to ECR                                        │
│   3. docker tag simple-poc-wg:latest \                          │
│      123456789.dkr.ecr.ap-southeast-4.amazonaws.com/simple-poc-wg    │
│   4. docker push to ECR                                         │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 5: Deploy to EC2                                           │
├─────────────────────────────────────────────────────────────────┤
│ Target: Pre-provisioned EC2 (t3.micro)                          │
│ Action:                                                         │
│   1. Connect via SSM Session Manager (no SSH keys!)             │
│   2. Stop old container: docker stop simple-poc || true         │
│   3. Remove old container: docker rm simple-poc || true         │
│   4. Pull new image from ECR                                    │
│   5. Run new container:                                         │
│      docker run -d --name simple-poc \                          │
│        -p 80:80 \                                               │
│        --restart unless-stopped \                               │
│        123456789.dkr.ecr.ap-southeast-4.amazonaws.com/simple-poc-wg  │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 6: Associate Elastic IP                                    │
├─────────────────────────────────────────────────────────────────┤
│ Purpose: Ensure static IP remains associated                    │
│ Action:                                                         │
│   1. Get EC2 instance ID                                        │
│   2. aws ec2 associate-address \                                │
│      --instance-id i-xxxxx \                                    │
│      --allocation-id eipalloc-xxxxx                             │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ STEP 7: Verify Deployment                                       │
├─────────────────────────────────────────────────────────────────┤
│ Test: HTTP GET request                                          │
│ Action:                                                         │
│   1. Wait 10 seconds for container startup                      │
│   2. curl http://3.x.x.1/                                       │
│   3. Check response contains:                                   │
│      "I am WG at 2025-01-15 10:30:45!"                          │
│   4. Exit code 0 = SUCCESS ✅                                   │
│   5. Exit code 1 = FAILURE ❌                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Branch to Environment Mapping

| Branch Name | Environment | EC2 Instance | Elastic IP | ECR Repository | Auto-Deploy |
|-------------|-------------|--------------|------------|----------------|-------------|
| **wg** | WG Dev | i-wg-xxxxx | 3.x.x.1 | simple-poc-wg | ✅ On push |
| **steven** | Steven Dev | i-steven-xxxxx | 3.x.x.2 | simple-poc-steven | ✅ On push |
| **main** | Production | i-prod-xxxxx | 3.x.x.3 | simple-poc-prod | ✅ On push |

---

## 5. Project Structure

```
simple-deployment-poc/
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions workflow
├── Dockerfile                      # Docker build instructions
├── nginx.conf                      # Nginx configuration (optional)
├── scripts/
│   ├── generate-html.sh            # Generate dynamic index.html
│   └── deploy-to-ec2.sh            # Deployment script
└── README.md                       # Project documentation
```

---

## 6. Key Files

### 6.1 Dockerfile

```dockerfile
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
```

### 6.2 GitHub Actions Workflow (.github/workflows/deploy.yml)

```yaml
name: Simple POC Deployment

on:
  push:
    branches:
      - wg
      - steven
      - main

env:
  AWS_REGION: ap-southeast-4
  ECR_REGISTRY: 119778517641.dkr.ecr.ap-southeast-4.amazonaws.com

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # Required for OIDC
      contents: read    # Required for checkout
    
    steps:
      # Step 1: Checkout code
      - name: Checkout code
        uses: actions/checkout@v3
      
      # Step 2: Determine environment based on branch
      - name: Set environment variables
        run: |
          BRANCH_NAME=${GITHUB_REF##*/}
          echo "BRANCH_NAME=$BRANCH_NAME" >> $GITHUB_ENV
          
          case $BRANCH_NAME in
            wg)
              echo "ENV_NAME=wg" >> $GITHUB_ENV
              echo "EC2_HOST=3.x.x.1" >> $GITHUB_ENV
              echo "EIP_ALLOC=eipalloc-wg-xxxxx" >> $GITHUB_ENV
              echo "INSTANCE_ID=i-wg-xxxxx" >> $GITHUB_ENV
              ;;
            steven)
              echo "ENV_NAME=steven" >> $GITHUB_ENV
              echo "EC2_HOST=3.x.x.2" >> $GITHUB_ENV
              echo "EIP_ALLOC=eipalloc-steven-xxxxx" >> $GITHUB_ENV
              echo "INSTANCE_ID=i-steven-xxxxx" >> $GITHUB_ENV
              ;;
            main)
              echo "ENV_NAME=prod" >> $GITHUB_ENV
              echo "EC2_HOST=3.x.x.3" >> $GITHUB_ENV
              echo "EIP_ALLOC=eipalloc-prod-xxxxx" >> $GITHUB_ENV
              echo "INSTANCE_ID=i-prod-xxxxx" >> $GITHUB_ENV
              ;;
          esac
          
          echo "BUILD_TIME=$(date '+%Y-%m-%d %H:%M:%S')" >> $GITHUB_ENV
          echo "ECR_REPO=simple-poc-${ENV_NAME}" >> $GITHUB_ENV
      
      # Step 3: Configure AWS credentials (OIDC)
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::119778517641:role/GitHubActionsDeployRole
          role-session-name: GitHubActions-${{ github.run_id }}
          aws-region: ${{ env.AWS_REGION }}
      
      # Step 4: Login to Amazon ECR
      - name: Login to Amazon ECR
        run: |
          aws ecr get-login-password --region ${{ env.AWS_REGION }} | \
          docker login --username AWS --password-stdin ${{ env.ECR_REGISTRY }}
      
      # Step 5: Build Docker image
      - name: Build Docker image
        run: |
          docker build \
            --build-arg ENV_NAME=${{ env.ENV_NAME }} \
            --build-arg BUILD_TIME="${{ env.BUILD_TIME }}" \
            -t ${{ env.ECR_REPO }}:latest \
            -t ${{ env.ECR_REPO }}:${{ github.sha }} \
            .
      
      # Step 6: Tag and push to ECR
      - name: Push to ECR
        run: |
          docker tag ${{ env.ECR_REPO }}:latest \
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPO }}:latest
          
          docker tag ${{ env.ECR_REPO }}:latest \
            ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPO }}:${{ github.sha }}
          
          docker push ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPO }}:latest
          docker push ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPO }}:${{ github.sha }}
      
      # Step 7: Deploy to EC2 via SSM
      - name: Deploy to EC2 via SSM
        run: |
          aws ssm send-command \
            --instance-ids ${{ env.INSTANCE_ID }} \
            --document-name "AWS-RunShellScript" \
            --parameters 'commands=[
              "aws ecr get-login-password --region ${{ env.AWS_REGION }} | docker login --username AWS --password-stdin ${{ env.ECR_REGISTRY }}",
              "docker stop simple-poc || true",
              "docker rm simple-poc || true",
              "docker pull ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPO }}:latest",
              "docker run -d --name simple-poc -p 80:80 --restart unless-stopped ${{ env.ECR_REGISTRY }}/${{ env.ECR_REPO }}:latest",
              "docker image prune -f"
            ]' \
            --region ${{ env.AWS_REGION }}
      
      # Step 8: Associate Elastic IP
      - name: Associate Elastic IP
        run: |
          aws ec2 associate-address \
            --instance-id ${{ env.INSTANCE_ID }} \
            --allocation-id ${{ env.EIP_ALLOC }} \
            --region ${{ env.AWS_REGION }}
      
      # Step 9: Verify deployment
      - name: Verify deployment
        run: |
          echo "Waiting 10 seconds for container to start..."
          sleep 10
          
          echo "Testing HTTP endpoint..."
          RESPONSE=$(curl -s http://${{ env.EC2_HOST }}/)
          
          if echo "$RESPONSE" | grep -q "${{ env.ENV_NAME }}"; then
            echo "✅ Deployment successful!"
            echo "Response: $RESPONSE"
          else
            echo "❌ Deployment failed!"
            echo "Response: $RESPONSE"
            exit 1
          fi
```

---

## 7. AWS Infrastructure Setup

### 7.1 Pre-requisites (Manual Setup - One Time)

**1. Create ECR Repositories:**
```bash
aws ecr create-repository --repository-name simple-poc-wg --region ap-southeast-4      --profile ai-steven
aws ecr create-repository --repository-name simple-poc-steven --region ap-southeast-4  --profile ai-steven
aws ecr create-repository --repository-name simple-poc-prod --region ap-southeast-4    --profile ai-steven
```

**2. Allocate Elastic IPs:**
```bash
aws ec2 allocate-address --domain vpc --region ap-southeast-4  # For WG
aws ec2 allocate-address --domain vpc --region ap-southeast-4  # For Steven
aws ec2 allocate-address --domain vpc --region ap-southeast-4  # For Prod
```

**3. Create IAM Role for EC2 (SSM + ECR Access):**
```bash
# Create trust policy for EC2
cat > ec2-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

# Create IAM role
aws iam create-role \
  --role-name simple-poc-ec2-role \
  --assume-role-policy-document file://ec2-trust-policy.json

# Attach SSM policy
aws iam attach-role-policy \
  --role-name simple-poc-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Attach ECR read policy
aws iam attach-role-policy \
  --role-name simple-poc-ec2-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Create instance profile
aws iam create-instance-profile \
  --instance-profile-name simple-poc-ec2-profile

aws iam add-role-to-instance-profile \
  --instance-profile-name simple-poc-ec2-profile \
  --role-name simple-poc-ec2-role
```

**4. Launch EC2 Instances:**
```bash
# Launch 3 x t3.micro instances with Amazon Linux 2023
# Attach the IAM instance profile created above
# Install Docker and SSM agent on each:
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# SSM agent is pre-installed on Amazon Linux 2023
# Verify it's running:
sudo systemctl status amazon-ssm-agent
```

**5. Create Security Group:**
```bash
# Allow HTTP (80) only - NO SSH needed!
aws ec2 create-security-group \
  --group-name simple-poc-sg \
  --description "Simple POC Security Group" \
  --region ap-southeast-4

aws ec2 authorize-security-group-ingress \
  --group-name simple-poc-sg \
  --protocol tcp --port 80 --cidr 0.0.0.0/0 \
  --region ap-southeast-4
```

### 7.2 GitHub Authentication Configuration

**Option 1: OIDC (Recommended - No Secrets Needed)**

Setup OIDC provider and IAM role (see `doc/GITHUB_AWS_AUTH.md` for details):

```bash
# 1. Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2. Create IAM role: GitHubActionsDeployRole
# 3. Attach permissions: ECR, EC2, SSM
```

**Option 2: Access Keys (Alternative)**

Add these secrets to GitHub repository settings:

| Secret Name | Description |
|-------------|-------------|
| AWS_ACCESS_KEY_ID | AWS IAM access key |
| AWS_SECRET_ACCESS_KEY | AWS IAM secret key |

**Note:** OIDC is more secure and recommended for production.

---

## 8. Testing the POC

### 8.1 Test Scenario 1: WG Branch

```bash
# On local laptop
git checkout wg
echo "Test change" >> test.txt
git add test.txt
git commit -m "Test WG deployment"
git push origin wg

# Expected result:
# 1. GitHub Actions triggered
# 2. Docker image built with "I am wg at 2025-01-15 10:30:45!"
# 3. Deployed to EC2 at 3.x.x.1
# 4. curl http://3.x.x.1/ shows the page
```

### 8.2 Test Scenario 2: Steven Branch

```bash
# On local laptop
git checkout steven
echo "Steven's feature" >> feature.txt
git add feature.txt
git commit -m "Test Steven deployment"
git push origin steven

# Expected result:
# 1. Deployed to different EC2 at 3.x.x.2
# 2. curl http://3.x.x.2/ shows "I am steven at ..."
```

### 8.3 Test Scenario 3: Production

```bash
# On local laptop
git checkout main
git merge wg
git push origin main

# Expected result:
# 1. Deployed to production EC2 at 3.x.x.3
# 2. curl http://3.x.x.3/ shows "I am prod at ..."
```

---

## 9. Success Criteria

### 9.1 POC is Successful When:

- ✅ Push to `wg` branch automatically deploys to WG environment
- ✅ Push to `steven` branch automatically deploys to Steven environment
- ✅ Push to `main` branch automatically deploys to Production
- ✅ Each environment shows correct message with timestamp
- ✅ Elastic IP remains associated after deployment
- ✅ curl test passes in GitHub Actions
- ✅ Old container is replaced with new one
- ✅ No manual intervention required

### 9.2 Verification Commands

```bash
# Check WG environment
curl http://3.x.x.1/

# Check Steven environment
curl http://3.x.x.2/

# Check Production environment
curl http://3.x.x.3/

# Each should return:
# "I am {ENV_NAME} at {TIMESTAMP}!"
```

---

## 10. Cost Estimation (POC)

| Resource | Quantity | Cost/Month | Total |
|----------|----------|------------|-------|
| EC2 t3.micro | 3 | $7.50 | $22.50 |
| Elastic IP (associated) | 3 | $0 | $0 |
| ECR Storage (1GB) | 3 repos | $0.10 | $0.30 |
| Data Transfer (minimal) | - | $0.09/GB | ~$1 |
| **Total** | | | **~$24/month** |

**Note:** This is for POC only. Production would need more resources.

---

## 11. Next Steps After POC

Once POC is successful, consider:

1. ✅ Add SSL/TLS certificates
2. ✅ Add load balancer for production
3. ✅ Implement auto-scaling
4. ✅ Add monitoring and alerting
5. ✅ Implement proper secrets management
6. ✅ Add automated testing
7. ✅ Implement rollback mechanism
8. ✅ Add health checks

---

## 12. Troubleshooting

### 12.1 Common Issues

**Issue 1: Docker container not starting**
```bash
# Connect via SSM and check logs
aws ssm start-session --target i-xxxxx
docker logs simple-poc
docker ps -a
```

**Issue 2: Cannot pull from ECR**
```bash
# Check ECR login
aws ecr get-login-password --region ap-southeast-4
# Check IAM permissions
```

**Issue 3: Elastic IP not associated**
```bash
# Check instance ID and allocation ID
aws ec2 describe-addresses --region ap-southeast-4
aws ec2 describe-instances --region ap-southeast-4
```

**Issue 4: curl test fails**
```bash
# Check security group allows port 80
# Check nginx is running: docker ps
# Check from EC2: curl localhost
```

---

## 13. Summary

This POC demonstrates:

1. ✅ **Simple automated deployment** from GitHub to AWS
2. ✅ **Branch-based environments** (wg, steven, main)
3. ✅ **Docker containerization** with nginx
4. ✅ **ECR for image storage**
5. ✅ **Automated verification** with curl test
6. ✅ **Static IP management** with Elastic IP
7. ✅ **Secure deployment via SSM** (no SSH keys!)

**Total Time:** ~2 hours to set up, < 5 minutes per deployment

**Complexity:** Low (perfect for POC!)

---

**End of Document**
