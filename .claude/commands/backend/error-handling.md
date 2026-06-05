Implement or review HTTP error handling in tadeumendonca-api.

Context: $ARGUMENTS

## Mandatory rule

**Throw typed errors — NEVER `return { statusCode: 4xx }` directly.** A middy error handler maps thrown errors to the HTTP response. This keeps handlers focused on the happy path and guarantees a consistent error shape + audit capture.

## Error classes: `src/shared/errors.ts`

```typescript
export class AppError extends Error {
  constructor(public statusCode: number, public code: string, message: string) {
    super(message);
    this.name = this.constructor.name;
  }
}
export class NotFoundError extends AppError {
  constructor(message = 'Resource not found') { super(404, 'not_found', message); }
}
export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') { super(401, 'unauthorized', message); }
}
// ValidationError → 400, ForbiddenError → 403 follow the same pattern.
```

## Error middleware (runs after audit captures the response)

```typescript
export const errorHandler: middy.MiddlewareObj = {
  onError: async (request) => {
    const e = request.error as AppError;
    const statusCode = e instanceof AppError ? e.statusCode : 500;
    request.response = {
      statusCode,
      headers: { 'Content-Type': 'application/json' },
      // snake_case body, consistent across the API
      body: JSON.stringify({
        error: e instanceof AppError ? e.code : 'internal_error',
        message: statusCode === 500 ? 'Internal server error' : e.message,
      }),
    };
  },
};
```

## Usage in handlers

```typescript
const profile = await profiles.findOne({ _id: id });
if (!profile) throw new NotFoundError('Profile not found');

const groups = event.requestContext.authorizer?.jwt?.claims?.['cognito:groups'] ?? [];
if (!groups.includes('admin')) throw new UnauthorizedError();
```

## Conventions
- Error response body is **snake_case**: `{ error: string, message: string }` — same as every other response (no mapping layer). See `/backend/lambda-handler`.
- `500` never leaks internal messages to the client (logged via powertools instead).
- The error handler is wired in the shared middy stack so every VPC Lambda inherits it; `fn-og-edge` (Lambda@Edge) has no middy and handles errors inline.
