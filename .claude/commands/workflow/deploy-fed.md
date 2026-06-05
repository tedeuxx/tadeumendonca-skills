Deploy tadeumendonca-fed to AWS.

Environment: $ARGUMENTS (staging | production)

## Steps in deploy.yml

**1. Fetch config from SSM**
```bash
S3_BUCKET=$(aws ssm get-parameter --name /$ENV_NAME/frontend/s3-bucket-name --query 'Parameter.Value' --output text)
CF_DIST_ID=$(aws ssm get-parameter --name /$ENV_NAME/frontend/cloudfront-distribution-id --query 'Parameter.Value' --output text)
API_URL=$(aws ssm get-parameter --name /$ENV_NAME/api/gateway-url --query 'Parameter.Value' --output text)
# + cognito-client-id, cognito-hosted-ui-url
```

**2. Build (Vite — env vars injected at build time)**
```bash
npm ci && npm run build
# VITE_API_BASE_URL=$API_URL VITE_COGNITO_CLIENT_ID=$CLIENT_ID etc.
```

**3. S3 sync (split cache headers)**
```bash
# Hashed assets: immutable (1 year) — filename contains content hash (e.g. index-BKaF91.js)
aws s3 sync dist/ s3://$S3_BUCKET/ --delete --exclude "index.html" \
  --cache-control "public,max-age=31536000,immutable"

# index.html: no-cache — SPA entry, always must be fresh to reference updated asset hashes
aws s3 cp dist/index.html s3://$S3_BUCKET/index.html \
  --cache-control "no-cache,no-store,must-revalidate"
```

**4. CloudFront invalidation**
```bash
aws cloudfront create-invalidation --distribution-id $CF_DIST_ID --paths "/*"
```

## Coverage gate + E2E

CI blocks deploy if unit test coverage < 85% OR Playwright E2E tests fail.

## OIDC role

Assumed via `AWS_ROLE_ARN` from SSM `/{env}/iam/github-actions-fed-role-arn` (set by IaC).
