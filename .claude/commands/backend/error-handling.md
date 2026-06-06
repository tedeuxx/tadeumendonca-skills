Implement or review HTTP error handling in tadeumendonca-api (Hono).

Context: $ARGUMENTS

## Mandatory rule

**Throw typed errors — never return an inline 4xx.** Hono's `app.onError` maps thrown errors to the response; handlers stay on the happy path.

## Error classes: src/shared/errors/http-errors.ts

```typescript
export class AppError extends Error {
  constructor(public statusCode: number, public code: string, message: string) {
    super(message); this.name = this.constructor.name;
  }
}
export class NotFoundError extends AppError {
  constructor(m = 'Resource not found') { super(404, 'not_found', m); }
}
export class UnauthorizedError extends AppError {
  constructor(m = 'Unauthorized') { super(401, 'unauthorized', m); }
}
// ValidationError → 400, ForbiddenError → 403 follow the same pattern.
```

## Central handler: src/shared/middleware/error.ts

```typescript
import { ErrorHandler } from 'hono';
import { logger } from './logger';

export const errorHandler: ErrorHandler = (err, c) => {
  const statusCode = err instanceof AppError ? err.statusCode : 500;
  logger.error('request failed', { error: err.message, statusCode });
  return c.json(
    {
      error: err instanceof AppError ? err.code : 'internal_error',
      message: statusCode === 500 ? 'Internal server error' : err.message,
    },
    statusCode,
  );
};
// wired once per app: app.onError(errorHandler)
```

## Usage in handlers

```typescript
const post = await repository.get(slug);
if (!post) throw new NotFoundError('Post not found');
if (!groups.includes('admin')) throw new UnauthorizedError();
```

## Conventions
- Error body is snake_case `{ error, message }` — same shape across the API.
- `500` never leaks internals to the client (logged via Powertools instead).
- `@hono/zod-openapi` validation failures map to a `400` `ValidationError` (default hook) so they share the shape.
- `app.onError` is wired once per Hono app — see `/backend/framework`.
