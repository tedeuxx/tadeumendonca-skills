Deploy tadeumendonca-api to AWS.

Environment: $ARGUMENTS (staging | production)

## Steps in deploy.yml

**1. Build (esbuild)**
```bash
node esbuild.config.mjs
# Outputs: dist/{fn}/index.js (bundled, minified, platform=node, target=node22)
```

**2. Deploy VPC Lambda functions (5×)**
```bash
for fn in profile posts articles og-image notifications; do
  FN_NAME=$(aws ssm get-parameter --name /$ENV_NAME/api/lambda-function-name-$fn --query 'Parameter.Value' --output text)
  cd dist/$fn && zip -r ../../${fn}.zip . && cd ../..
  aws s3 cp ${fn}.zip s3://$S3_BUCKET/${fn}/latest.zip
  aws lambda update-function-code --function-name $FN_NAME --s3-bucket $S3_BUCKET --s3-key ${fn}/latest.zip
done
```

**3. Deploy Lambda@Edge (og-edge, us-east-1)**
```bash
aws lambda update-function-code --function-name $EDGE_FN_NAME --s3-bucket $S3_BUCKET --s3-key og-edge/latest.zip
aws lambda publish-version --function-name $EDGE_FN_NAME
# Qualified ARN in SSM is updated by api repo after publish (or managed by IaC on next apply)
```

**4. Reimport API contract**
```bash
API_ID=$(aws ssm get-parameter --name /$ENV_NAME/api/gateway-id --query 'Parameter.Value' --output text)
export COGNITO_ISSUER="https://cognito-idp.${AWS_REGION}.amazonaws.com/${USER_POOL_ID}"
export COGNITO_CLIENT_ID=$CLIENT_ID
# Export INVOKE_ARN_{fn} for each function
envsubst < openapi/openapi.yaml > openapi/openapi.resolved.json
aws apigatewayv2 reimport-api --api-id "$API_ID" --body file://openapi/openapi.resolved.json
```

## Coverage gate

CI blocks deploy if test coverage < 85%. Check `vitest.config.ts` coverage threshold.

## OIDC role

Assumed via `AWS_ROLE_ARN` from SSM `/{env}/iam/github-actions-api-role-arn` (set by IaC).
