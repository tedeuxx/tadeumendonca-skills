Implement or review notifications (email via SES) in <project>-api.

Context: $ARGUMENTS

The `notifications` module of the BFF — emails registered subscribers (e.g. on a new post) and manages subscriptions. SES is provisioned in `/infrastructure/ses`.

## Send via SES (SDK v3)
```typescript
import { SESv2Client, SendEmailCommand } from '@aws-sdk/client-sesv2';
const ses = new SESv2Client({});                              // module-level singleton

export async function sendEmail(to: string, subject: string, html: string) {
  await ses.send(new SendEmailCommand({
    FromEmailAddress: process.env.SES_FROM_ADDRESS,           // no-reply@<apex-domain> (IaC)
    Destination: { ToAddresses: [to] },
    Content: { Simple: { Subject: { Data: subject }, Body: { Html: { Data: html } } } },
  }));
}
```
- Lambda role needs `ses:SendEmail` (`/infrastructure/ses`); reaches SES via NAT.
- Templates: simple HTML strings now; move to SES **templates** / `SendBulkEmail` when volume/variety grows.

## Subscriptions (collection `subscribers`)
```jsonc
{ "_id": "ObjectId", "cognito_sub": "…", "email": "…", "status": "active | unsubscribed", "created_at": "ISODate" }
```
- `POST /subscriptions` → upsert an `active` subscriber (the user's `sub`/`email` from the validated claims).
- `DELETE /subscriptions` (or a one-click unsubscribe link/token) → `status = "unsubscribed"`.
- Indexes `{ cognito_sub: 1 }` unique, `{ status: 1 }` (`/backend/document-db`).

## Sync vs async (never block the request)
A publish that notifies **N** subscribers must **not** run inline — fan-out is slow and fails partially.
- **Now (monolith):** **publish** a `post_published` domain event to an **SNS** topic and return immediately; an SNS-subscribed Lambda fans out the emails, with a **DLQ** on the subscription for failed deliveries. Cheapest/simplest fan-out — `/infrastructure/sns`.
- **Idempotency:** dedupe by `(post_id, subscriber_id)` so retries don't double-send.
- Fan-out reads `subscribers` where `status = "active"` and batches.

## Conventions
- snake_case payloads; from-address + region from env (`/backend/environment-config`).
- **SES sandbox:** new accounts only send to verified addresses — production access is a one-time manual request (`/infrastructure/ses`).
- Audit the action (`subscribers_create`, etc. — `/backend/audit-middleware`); identity from claims (`/backend/action-types`).

## Pros & cons
**Pros**
- SNS async fan-out decouples producers from consumers; SES delivers email.
- Subscriptions + DLQ handle retries/failures.
**Cons**
- SES sandbox + deliverability concerns.
- Delivery is eventual; failures land in the DLQ, not inline.
