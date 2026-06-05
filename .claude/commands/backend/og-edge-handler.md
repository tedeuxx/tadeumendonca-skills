Implement or update the Lambda@Edge handler in tadeumendonca-api/src/functions/og-edge/.

Context: $ARGUMENTS

## Lambda@Edge constraints (mandatory)
- NO VPC — Lambda@Edge runs at CloudFront PoP, cannot be in a VPC
- NO middy — middy uses Node.js features incompatible with Lambda@Edge strict runtime
- NO audit middleware — no DocumentDB access
- NO process.env at runtime — environment variables are NOT available in Lambda@Edge viewer-request
- Handler signature: `CloudFrontRequestEvent` (not APIGatewayProxyEventV2)

## Pattern: `src/functions/og-edge/index.ts`

```typescript
import { CloudFrontRequestHandler } from 'aws-lambda';

const BOT_UA_REGEX = /facebookexternalhit|twitterbot|linkedinbot|whatsapp|telegrambot|slackbot|discordbot/i;
const API_BASE = 'https://api.tadeumendonca.io';  // hardcoded — no env vars in Lambda@Edge

export const handler: CloudFrontRequestHandler = async (event) => {
  const request = event.Records[0].cf.request;
  const ua = request.headers['user-agent']?.[0]?.value ?? '';

  if (!BOT_UA_REGEX.test(ua)) {
    return request; // human — passthrough to S3 (SPA)
  }

  // Bot: parse path → call /og-meta → return OG HTML
  const [, type, slug] = request.uri.match(/\/(posts|articles)\/([^/]+)/) ?? [];
  if (!type || !slug) return request;

  const meta = await fetch(`${API_BASE}/og-meta/${type}/${slug}`).then(r => r.json());

  return {
    status: '200',
    statusDescription: 'OK',
    headers: { 'content-type': [{ value: 'text/html; charset=utf-8' }] },
    body: buildOgHtml(meta),
  };
};

function buildOgHtml(meta: { title: string; description: string; imageUrl: string; url: string }) {
  return `<!DOCTYPE html><html><head>
    <meta property="og:title" content="${meta.title}" />
    <meta property="og:description" content="${meta.description}" />
    <meta property="og:image" content="${meta.imageUrl}" />
    <meta property="og:url" content="${meta.url}" />
    <script>window.location.href = "${meta.url}"</script>
  </head></html>`;
}
```

## Deploy notes
- Must be deployed to us-east-1 (Lambda@Edge requirement)
- Must use `publish-version` after `update-function-code` — CloudFront needs a qualified ARN
- Qualified ARN stored in SSM `/{env}/api/lambda-edge-og-qualified-arn`
- esbuild target: `node22`, platform: `node`, bundle: `true`
