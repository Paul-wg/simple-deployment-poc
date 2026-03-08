# Simple Deployment POC

A proof-of-concept CI/CD pipeline demonstrating automated Docker deployment to AWS EC2 using GitHub Actions, ECR, and SSM.

## Overview

This project showcases a complete automated deployment workflow:
- Push code to GitHub → Triggers GitHub Actions
- Builds Docker image with dynamic content
- Pushes to AWS ECR
- Deploys to EC2 via SSM (no SSH keys)
- Associates Elastic IP
- Verifies deployment

## Architecture

### AWS Infrastructure (Terraform)
- **EC2**: t3.micro, Amazon Linux 2023, 30GB GP3, Docker + PostgreSQL 16 client
- **S3**: Shared bucket for initialization scripts (protected from deletion)
- **Elastic IP**: Static public IP for EC2
- **VPC**: 3 private subnets for RDS Aurora
- **RDS Aurora**: PostgreSQL 16.4, db.t4g.medium, cluster name `nebulas-aurora-cluster`
- **Secrets Manager**: Aurora master password (username: `postgres`, database: `nebuladb`)
- **IAM Roles**: EC2 role with S3, ECR, SSM, and Secrets Manager permissions
- **Security Groups**: 
  - EC2: HTTP (80) from anywhere
  - RDS: PostgreSQL (5432) from within VPC only
- **SSM**: Session Manager for secure access (no SSH)

### GitHub Actions Workflow
- **Trigger**: Push to `wg`, `steven`, or `main` branches
- **Authentication**: OIDC (no access keys) via `GitHubActionsDeployRole`
- **Region**: ap-southeast-4 (Melbourne)
- **ECR Repository**: `simple-poc-wg` (branch-specific)

## Project Structure

```
simple-deployment-poc/
├── .github/workflows/
│   └── deploy.yml           # GitHub Actions CI/CD pipeline
├── scripts/
│   ├── generate-html.sh     # Generates dynamic HTML (not used in Docker build)
│   └── deploy-to-ec2.sh     # Manual deployment script
├── doc/
│   ├── POC_SIMPLE_DEPLOYMENT.md  # Detailed architecture documentation
│   └── GITHUB_AWS_AUTH.md        # OIDC vs access keys comparison
├── Dockerfile               # nginx:alpine with dynamic HTML
├── nginx.conf               # Nginx configuration
└── README.md                # This file
```

## Deployment Workflow

### Step-by-Step Process

1. **Checkout code** from GitHub
2. **Set environment variables** based on branch (wg/steven/main)
3. **Configure AWS credentials** using OIDC
4. **Login to ECR**
5. **Build Docker image** with:
   - `ENV_NAME`: Branch name (wg/steven/prod)
   - `BUILD_TIME`: Melbourne timezone timestamp
6. **Push to ECR** with tags:
   - `:latest`
   - `:${github.sha}` (commit hash)
7. **Auto-fetch EC2 instance ID** by tag `name=Nebulas-host`
8. **Deploy to EC2 via SSM**:
   - Stop old container
   - Remove old container
   - Pull new image from ECR
   - Start new container on port 80
   - Clean up old images
9. **Auto-fetch EIP allocation ID** by tag `Name=ai-steven-dev-eip`
10. **Associate EIP** with EC2 instance
11. **Verify deployment** by checking HTTP response

## Key Features

### Security
- ✅ **No SSH keys** - All access via SSM Session Manager
- ✅ **OIDC authentication** - No AWS access keys in GitHub secrets
- ✅ **Secrets Manager** - Database passwords stored securely
- ✅ **Private subnets** - RDS isolated from internet
- ✅ **IAM least privilege** - Role-based access control

### Automation
- ✅ **Auto-discovery** - Finds EC2 and EIP by tags (no hardcoded IDs)
- ✅ **Zero-downtime** - Stops old container before starting new
- ✅ **Self-healing** - Docker restart policy `unless-stopped`
- ✅ **Image cleanup** - Removes unused Docker images

### Developer Experience
- ✅ **Branch-based environments** - wg/steven/main → separate deployments
- ✅ **Dynamic content** - Shows environment name and build timestamp
- ✅ **Melbourne timezone** - All timestamps in AEDT/AEST
- ✅ **Visual feedback** - Deployment workflow displayed on webpage

## Prerequisites

### AWS Setup
1. **VPC**: Default VPC in ap-southeast-4
2. **OIDC Provider**: GitHub OIDC provider configured
3. **IAM Role**: `GitHubActionsDeployRole` with:
   - AmazonEC2ContainerRegistryPowerUser
   - AmazonEC2FullAccess
   - AmazonSSMFullAccess
4. **ECR Repository**: `simple-poc-wg` (or branch-specific name)
5. **Terraform**: Infrastructure deployed via `aws-infra/` module

### Local Tools
- AWS CLI v2
- Terraform >= 1.0
- Docker (for local testing)
- Session Manager plugin (for SSM access)

## Usage

### Deploy Infrastructure

```bash
cd /path/to/aws-infra

# First time: Import existing S3 bucket
./apply.sh

# Daily workflow
./apply.sh -auto-approve
```

### Deploy Application

**Automatic (via GitHub Actions):**
```bash
cd simple-deployment-poc
git add .
git commit -m "Update application"
git push origin wg  # Triggers deployment
```

**Manual (via SSM):**
```bash
cd simple-deployment-poc/scripts
./deploy-to-ec2.sh
```

### Connect to EC2

```bash
cd /path/to/aws-infra/scripts
./connect-ai-host.sh
```

Or directly:
```bash
INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:name,Values=Nebulas-host" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text \
  --region ap-southeast-4 \
  --profile ai-steven)

aws ssm start-session --target $INSTANCE_ID --region ap-southeast-4 --profile ai-steven
```

### Access Database

**Get password:**
```bash
PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ai-steven-dev-aurora-master-password \
  --query SecretString \
  --output text \
  --region ap-southeast-4 \
  --profile ai-steven | jq -r .password)
```

**Connect from EC2:**
```bash
psql -h <aurora-endpoint> -U postgres -d nebuladb
```

### Destroy Infrastructure

```bash
cd /path/to/aws-infra

# Safe destroy (preserves S3 bucket)
./destroy.sh

# Or use the script in scripts/ folder
./scripts/safe-destroy.sh
```

## Configuration

### Terraform Variables (`aws-infra/terraform.tfvars`)

```hcl
aws_region            = "ap-southeast-4"
aws_profile           = "ai-steven"
vpc_id                = "vpc-00d99c392e8a488eb"
subnet_id             = "subnet-02a6c924b93797e96"
environment           = "dev"
project_name          = "ai-steven"
instance_type         = "t3.micro"
root_volume_size      = 30
s3_bucket_name        = "ai-foundry-artifacts-apse4"
aurora_engine_version = "16.4"
aurora_instance_class = "db.t4g.medium"
allocate_eip          = true
```

### GitHub Actions Environment Variables

Set in `.github/workflows/deploy.yml`:
- `AWS_REGION`: ap-southeast-4
- `ECR_REGISTRY`: 119778517641.dkr.ecr.ap-southeast-4.amazonaws.com
- Branch-specific: `ENV_NAME`, `EC2_HOST`, `EIP_ALLOC`, `INSTANCE_ID`

## Troubleshooting

### GitHub Actions Fails

**Check logs:**
```
https://github.com/Paul-wg/simple-deployment-poc/actions
```

**Common issues:**
- OIDC role trust policy incorrect
- ECR repository doesn't exist
- EC2 instance not running
- SSM agent not active

### Container Not Starting

**Check Docker logs on EC2:**
```bash
docker ps -a
docker logs simple-poc
```

### Database Connection Issues

**Verify security group:**
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ai-steven-dev-db-sg" \
  --region ap-southeast-4 \
  --profile ai-steven
```

**Test from EC2:**
```bash
telnet <aurora-endpoint> 5432
```

## Important Notes

### S3 Bucket Protection
- S3 bucket `ai-foundry-artifacts-apse4` is **protected from deletion**
- Shared across all environments
- `destroy.sh` removes it from Terraform state but preserves in AWS
- Manual deletion required if truly needed

### EC2 Instance Tags
- **Name**: `nebulas-ai` (display name)
- **name**: `Nebulas-host` (used by scripts for discovery)
- Keep both tags for proper functionality

### EIP Association
- EIP is associated **after** container deployment
- Brief downtime during association (~5 seconds)
- EIP persists across EC2 recreations

### Docker Image Tags
- `:latest` - Always points to most recent build
- `:${commit-sha}` - Specific commit version
- Old images cleaned up automatically

## Reusing This POC

To adapt this for another application:

1. **Copy project structure**
2. **Update Dockerfile** with your application
3. **Modify terraform.tfvars** for your environment
4. **Update deploy.yml**:
   - Change ECR repository name
   - Update branch names
   - Adjust container name and port
5. **Configure OIDC** for your GitHub repository
6. **Create ECR repository** in your AWS account
7. **Deploy infrastructure** with Terraform
8. **Push code** to trigger deployment

## Resources

- **AWS Account**: 119778517641
- **Region**: ap-southeast-4 (Melbourne)
- **GitHub Repo**: https://github.com/Paul-wg/simple-deployment-poc
- **Terraform Modules**: `aws-infra/modules/`
- **Documentation**: `doc/` folder

## License

Internal POC - Not for public distribution
