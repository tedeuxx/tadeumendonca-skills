Use Amazon SNS in <project> infrastructure (async domain events).

Context: $ARGUMENTS

SNS is the **simplest, lowest-cost** pub/sub for async fan-out — domain events like `post_published` that trigger notifications (`/backend/notifications`). Chosen over EventBridge for cost/simplicity (no content routing / replay needed at this scale).

## Configuration
```hcl
resource "aws_sns_topic" "events" {
  name              = "<project>-events-${var.environment}"
  display_name      = "<project> events"
  fifo_topic        = false                           # standard topic — cheapest; no strict ordering need
  kms_master_key_id = "alias/aws/sns"                 # SSE at rest, MANDATORY (/infrastructure/kms)
}

# DLQ — MANDATORY on every SNS→Lambda subscription (no event silently lost)
resource "aws_sqs_queue" "events_dlq" {
  name                      = "<project>-events-dlq-${var.environment}"
  message_retention_seconds = 1209600                 # 14 days
  kms_master_key_id         = "alias/aws/sqs"         # SSE at rest
}

resource "aws_sns_topic_subscription" "notifications" {
  topic_arn      = aws_sns_topic.events.arn
  protocol       = "lambda"
  endpoint       = module.bff.lambda_function_arn     # the notifications consumer
  filter_policy  = jsonencode({ type = ["post_published"] })                        # only what this consumer wants
  redrive_policy = jsonencode({ deadLetterTargetArn = aws_sqs_queue.events_dlq.arn })  # failures → DLQ
}

resource "aws_lambda_permission" "sns" {
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  function_name = module.bff.lambda_function_name
  source_arn    = aws_sns_topic.events.arn
}
# SSM: /{env}/events/topic-arn = aws_sns_topic.events.arn ; the BFF role gets sns:Publish (/infrastructure/iam)
```
**Choices that matter:** standard topic (`fifo_topic=false`); **KMS SSE on the topic AND the DLQ** (mandatory); **`redrive_policy` → SQS DLQ is mandatory** on every subscription; `filter_policy` so a consumer only gets the event types it wants.

## DLQ pattern (mandatory)
- Every SNS→Lambda subscription carries a `redrive_policy` to an **SQS DLQ**. SNS retries Lambda deliveries automatically; once retries are exhausted the message lands in the DLQ (14-day retention) instead of being lost — the DLQ is **never** the primary path.
- Alarm on the DLQ depth (`ApproximateNumberOfMessagesVisible` > 0 → notify the owner via this topic). Reprocess by redriving from the DLQ.
- The DLQ is KMS-encrypted at rest (`aws/sqs`).

## Conventions
- Message = a small JSON domain event (`{ "type": "post_published", "post_id": "…" }`, snake_case).
- Producer (BFF module) publishes; consumers subscribe (`/backend/notifications`). TLS in transit by default (`/infrastructure/kms`).
- Scale-up path: if content routing / replay / many event types appear, revisit EventBridge.
## Pros & cons
**Pros**
- Cheapest, simplest pub/sub; KMS SSE on topic + DLQ.
- Mandatory SQS DLQ — no event is silently lost.
**Cons**
- No replay / event store (vs EventBridge).
- Routing limited to filter policies; standard topic = no strict ordering.
