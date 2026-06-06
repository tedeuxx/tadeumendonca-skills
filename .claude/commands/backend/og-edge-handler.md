Implement or update the Lambda@Edge handler in <project>-api/src/functions/og-edge/.

Context: $ARGUMENTS

The edge does a **3-way classification** at CloudFront Viewer Request — humans get the SPA, bots get server-built HTML. It covers **two bot functionalities**: OG previews for social scrapers, and dynamic rendering for SEO crawlers.

## Lambda@Edge constraints (mandatory)
- NO VPC / NO Hono / NO audit / NO DocumentDB — runs at the CloudFront PoP.
- NO `process.env` at runtime — hardcode the API base per build (or read a CloudFront custom header).
- Handler signature: `CloudFrontRequestEvent` (not APIGatewayProxyEventV2).
- Keep the bundle tiny; only `fetch` to the API.

## Classification: `src/functions/og-edge/index.ts`

```typescript
import { CloudFrontRequestHandler } from 'aws-lambda';

const SOCIAL_UA  = /facebookexternalhit|twitterbot|linkedinbot|whatsapp|telegrambot|slackbot|discordbot|pinterest/i;
const CRAWLER_UA = /googlebot|bingbot|duckduckbot|yandex|baiduspider|applebot/i;
const API_BASE = 'https://api.<apex-domain>';   // no env vars at edge

export const handler: CloudFrontRequestHandler = async (event) => {
  const req = event.Records[0].cf.request;
  const ua  = req.headers['user-agent']?.[0]?.value ?? '';
  const { type, slug } = parsePath(req.uri);   // '/' → {type:'profile'}; '/articles/x' → {type,slug}

  // 1) Social scrapers (no JS) → minimal <head> with OG/Twitter tags
  if (SOCIAL_UA.test(ua)) {
    const meta = await fetch(`${API_BASE}/og-meta/${type}/${slug}`).then(r => r.json());
    return html(buildOgHead(meta));
  }
  // 2) Search crawlers → full indexable HTML (head + body content)
  if (CRAWLER_UA.test(ua)) {
    const page = await fetch(`${API_BASE}/prerender/${type}/${slug}`).then(r => r.text());
    return html(page);
  }
  // 3) Humans → passthrough to S3 (React SPA, CSR)
  return req;
};

const html = (body: string) => ({
  status: '200', statusDescription: 'OK',
  headers: {
    'content-type':  [{ value: 'text/html; charset=utf-8' }],
    'cache-control': [{ value: 'public, max-age=300' }],
  },
  body,
});
```

## The two functionalities

| | Social (web scraping) | SEO (search crawlers) |
|---|---|---|
| UA | facebook/linkedin/whatsapp/x… | googlebot/bingbot/… |
| Calls | `GET /og-meta/{type}/{slug}` | `GET /prerender/{type}/{slug}` |
| Returns | `<head>` only: OG/Twitter tags | full HTML: head + **content body** + JSON-LD |
| Goal | rich share card | indexable page (no SSR) |

Both come from the API (DocumentDB) — see `/backend/prerender`. The React app and the human path are unchanged (CSR). Not cloaking: crawler and user resolve to the same content.

## Deploy notes
- us-east-1 (Lambda@Edge); `publish-version` after `update-function-code`; qualified ARN → SSM `/{env}/api/lambda-edge-og-qualified-arn`.
- esbuild target `node22`, platform `node`, bundle `true`.
- Attached at CloudFront Viewer Request — see `/infrastructure/cloudfront`.
