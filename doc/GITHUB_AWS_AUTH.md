# GitHub Actions AWS Authentication Options

## Option 1: AWS Access Keys (Current - Simple but Less Secure)

### GitHub Secrets Required:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Workflow Configuration:
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ap-southeast-4
```

---

## Option 2: AWS OIDC (Recommended - More Secure)

### Benefits:
- ✅ No long-lived credentials
- ✅ Automatic credential rotation
- ✅ Better security posture
- ✅ Follows AWS best practices

### Setup Steps:

#### 1. Create OIDC Provider in AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region ap-southeast-4 \
  --profile ai-steven
```

#### 2. Create IAM Role for GitHub Actions

Create file: `github-actions-trust-policy.json`
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::119778517641:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:Paul-wg/simple-deployment-poc:*"
        }
      }
    }
  ]
}
```

Create the role:
```bash
aws iam create-role \
  --role-name GitHubActionsDeployRole \
  --assume-role-policy-document file://github-actions-trust-policy.json \
  --region ap-southeast-4 \
  --profile ai-steven
```

#### 3. Attach Permissions to Role

```bash
# ECR permissions
aws iam attach-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser \
  --profile ai-steven

# EC2 permissions
aws iam attach-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess \
  --profile ai-steven

# SSM permissions
aws iam attach-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMFullAccess \
  --profile ai-steven
```

#### 4. Update GitHub Workflow

Replace the credentials step in `.github/workflows/deploy.yml`:

```yaml
# Step 3: Configure AWS credentials (OIDC)
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::119778517641:role/GitHubActionsDeployRole
    role-session-name: GitHubActions-${{ github.run_id }}
    aws-region: ap-southeast-4
```

#### 5. Add Permissions to Workflow

Add this at the top of the `jobs` section:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write   # Required for OIDC
      contents: read    # Required for checkout
```

### Complete OIDC Workflow Example:

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
      id-token: write
      contents: read
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set environment variables
        run: |
          # ... same as before ...
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::119778517641:role/GitHubActionsDeployRole
          role-session-name: GitHubActions-${{ github.run_id }}
          aws-region: ${{ env.AWS_REGION }}
      
      # ... rest of the steps remain the same ...
```

---

## Comparison

| Feature | Access Keys | OIDC |
|---------|-------------|------|
| Setup Complexity | Simple | Moderate |
| Security | Good | Excellent |
| Credential Rotation | Manual | Automatic |
| Credential Storage | GitHub Secrets | None needed |
| AWS Best Practice | ⚠️ Acceptable | ✅ Recommended |
| Audit Trail | Good | Excellent |

---

## Recommendation

**For POC**: Use Access Keys (simpler, faster setup)
**For Production**: Use OIDC (more secure, no credential management)

---

## Quick Start Commands

### Option 1: Access Keys (Current)
```bash
# 1. Create IAM user with programmatic access
# 2. Add secrets to GitHub
# 3. Done!
```

### Option 2: OIDC (Recommended)
```bash
# 1. Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2. Create role with trust policy
# 3. Attach permissions
# 4. Update workflow
# 5. No secrets needed!
```
