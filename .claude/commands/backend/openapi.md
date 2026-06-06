Generate the OpenAPI contract from the backend code (Hono + zod-openapi).

Context: $ARGUMENTS

## The spec is generated, never hand-written

Routes are declared with **`@hono/zod-openapi`** (`OpenAPIHono` + `createRoute`) where the **zod schemas are both runtime validation and the OpenAPI definition** — single source of truth. `openapi.json` is emitted from the code; the API GW contract is that generated spec + a thin AWS overlay.

## Declare routes with createRoute
```typescript
import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';

const PostSchema = z.object({ id: z.string(), title: z.string(), body_markdown: z.string() }); // snake_case

const listPosts = createRoute({
  method: 'get', path: '/posts',
  request: { query: z.object({ cursor: z.string().optional() }) },
  responses: { 200: { content: { 'application/json': { schema: z.array(PostSchema) } }, description: 'List posts' } },
});

export const app = new OpenAPIHono<{ Bindings: LambdaBindings }>();
app.openapi(listPosts, (c) => c.json(/* repository result */));
```

## Emit the document
```typescript
app.doc('/openapi.json', { openapi: '3.1.0', info: { title: 'tadeumendonca-api', version } });

// scripts/gen-openapi.ts — run in CI before deploy
import { writeFileSync } from 'node:fs';
import { app } from '../src/app';
writeFileSync('openapi/openapi.gen.json', JSON.stringify(app.getOpenAPI31Document({
  openapi: '3.1.0', info: { title: 'tadeumendonca-api', version: process.env.VERSION! },
}), null, 2));
```
Optional: serve **Swagger UI** via `@hono/swagger-ui` at `/docs` (non-prod only).

## API GW reimport (deploy)
The generated spec has paths + schemas + the security scheme reference. A build step overlays the AWS-specific parts and resolves env values, then reimports:
- `x-amazon-apigateway-integration` per route → the function's Lambda invoke ARN (`AWS_PROXY`).
- Cognito JWT authorizer (`securitySchemes` + `x-amazon-apigateway-authorizer`): issuer = pool URL, audience = client id — from SSM, injected via `envsubst`.
- `aws apigatewayv2 reimport-api --api-id $(ssm …/api/gateway-id) --body file://openapi/openapi.aws.json`.

## Conventions
- Schemas are the single source of truth — **never hand-edit a generated `openapi.*.json`**.
- snake_case fields (matches the API). Keep the AWS overlay (integration + authorizer) as a small template, not inside the generated file.
- Replaces the old hand-written `openapi.yaml`. See `/backend/framework`, `/infrastructure/api-gw-contract`, `/workflow/deploy-api`.
