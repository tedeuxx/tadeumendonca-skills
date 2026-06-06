Deploy tadeumendonca-api (the BFF) to AWS.

Environment: $ARGUMENTS (staging | production)

The api is **one BFF Lambda** (+ the separate og-edge Lambda@Edge). Deploy = update the BFF code + reimport the generated contract.

## Steps in deploy.yml

**1. Build (esbuild)**
```bash
node esbuild.config.mjs            # → dist/index.js  (one BFF bundle: minified, target node22, arm64)
node esbuild.config.mjs --edge     # → dist/og-edge/index.js (Lambda@Edge bundle)
```

**2. Deploy the BFF Lambda (single)**
```bash
BFF_NAME=$(aws ssm get-parameter --name /$ENV_NAME/api/bff-function-name --query 'Parameter.Value' --output text)
( cd dist && zip -r ../bff.zip . )
aws s3 cp bff.zip s3://$S3_BUCKET/bff/latest.zip
aws lambda update-function-code --function-name "$BFF_NAME" --s3-bucket "$S3_BUCKET" --s3-key bff/latest.zip
```

**3. Deploy Lambda@Edge (og-edge, us-east-1)**
```bash
aws lambda update-function-code --function-name "$EDGE_FN_NAME" --s3-bucket "$S3_BUCKET" --s3-key og-edge/latest.zip
aws lambda publish-version --function-name "$EDGE_FN_NAME"
# qualified ARN → SSM (or managed by IaC on next apply)
```

**4. Reimport the API contract (generated from code)**
```bash
API_ID=$(aws ssm get-parameter --name /$ENV_NAME/api/gateway-id --query 'Parameter.Value' --output text)
npx tsx scripts/gen-openapi.ts                       # emit openapi.gen.json from the Hono app (/backend/openapi)
export COGNITO_ISSUER="https://cognito-idp.${AWS_REGION}.amazonaws.com/${USER_POOL_ID}" COGNITO_CLIENT_ID=$CLIENT_ID
export INVOKE_ARN_bff=$(aws lambda get-function --function-name "$BFF_NAME" --query 'Configuration.FunctionArn' --output text)
envsubst < openapi/openapi.aws.tftpl.json > openapi/openapi.resolved.json   # overlay: single integration + authorizer
aws apigatewayv2 reimport-api --api-id "$API_ID" --body file://openapi/openapi.resolved.json
```

## Gates
CI blocks deploy on the quality/test/security gates (`/workflow/testing-coverage`, `/workflow/sonarcloud`).

## OIDC role
Assumed via `AWS_ROLE_ARN` from SSM `/{env}/iam/github-actions-api-role-arn` (set by IaC) — `/workflow/github-actions`.
