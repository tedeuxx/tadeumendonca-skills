Implement cursor-based pagination with React Query in tadeumendonca-fed.

Resource: $ARGUMENTS (e.g., "posts", "articles")

## useInfiniteQuery pattern

```typescript
import { useInfiniteQuery } from '@tanstack/react-query';
import { api } from '../services/api';

export function usePosts() {
  return useInfiniteQuery({
    queryKey: ['posts'],
    queryFn: ({ pageParam }) => api.get(`/posts?limit=20${pageParam ? `&cursor=${pageParam}` : ''}`),
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (lastPage) => lastPage.next_cursor ?? undefined,
  });
}
```

## Infinite scroll trigger

```typescript
const { data, fetchNextPage, hasNextPage, isFetchingNextPage } = usePosts();

// Use IntersectionObserver or Cloudscape's onLoadItems for scroll trigger
const items = data?.pages.flatMap(p => p.items) ?? [];
```

## API response shape (snake_case, cursor-based)

```typescript
interface PageResponse<T> {
  items: T[];
  next_cursor?: string;   // absent on last page
}
```

## Conventions
- Cursor is opaque — never parse or display it
- `limit` default: 20 for posts, 10 for articles
- Tag filter (articles): `?tag={tag}&cursor=...&limit=10`
- Response fields are snake_case — matches DB and API convention (no transformation)

## Rationale — cursor, not offset
Pagination uses an opaque cursor over the indexed sort key (`_id`/`created_at`), not `skip`/offset. On DocumentDB a range query on an indexed field (`find({_id:{$lt:cursor}}).sort({_id:-1}).limit(n)`) stays index-efficient, while `.skip(n)` scans and discards. Cursors also survive re-ordering (e.g. sort by engagement) where offset pagination breaks.
