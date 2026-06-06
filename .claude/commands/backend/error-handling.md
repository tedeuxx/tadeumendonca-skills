Implement or review HTTP error handling in tadeumendonca-api.

Context: $ARGUMENTS

Conceptual skill — the error model and response shape. The framework-specific central handler (how thrown errors map to responses) is wired in `/backend/hono`.

## Mandatory rule
**Throw typed errors — never return an inline 4xx.** A single central handler maps thrown errors to the HTTP response; handlers stay on the happy path.

## Error classes: src/shared/errors/http-errors.ts
```typescript
export class AppError extends Error {
  constructor(public statusCode: number, public code: string, message: string) {
    super(message); this.name = this.constructor.name;
  }
}
export class NotFoundError extends AppError { constructor(m = 'Resource not found') { super(404, 'not_found', m); } }
export class UnauthorizedError extends AppError { constructor(m = 'Unauthorized') { super(401, 'unauthorized', m); } }
// ValidationError → 400, ForbiddenError → 403 follow the same pattern.
```

## Response shape (every error)
snake_case body, consistent across the API; status = the error's `statusCode`:
```jsonc
{ "error": "not_found", "message": "Post not found" }
```
The central handler maps `AppError` → its `statusCode` + `{ error: code, message }`; anything else → `500` `internal_error` with a generic message (real cause logged, never leaked).

## Usage in handlers
```typescript
const post = await repository.get(slug);
if (!post) throw new NotFoundError('Post not found');
if (!groups.includes('admin')) throw new UnauthorizedError();
```

## Conventions
- Error body is snake_case `{ error, message }` — same shape across the API.
- `500` never leaks internals (logged via Powertools — `/backend/logging`).
- Schema-validation failures map to a `400` `ValidationError` so they share the shape.
- The central handler that catches thrown errors and writes the response is wired in `/backend/hono`.
