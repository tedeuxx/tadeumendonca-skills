Use Amazon SNS in tadeumendonca infrastructure (async domain events).

Context: $ARGUMENTS

SNS is the **simplest, lowest-cost** pub/sub for async fan-out — used for domain events like `post_published` that trigger notifications (`/backend/notifications`). Chosen over EventBridge for cost + simplicity (no content routing / replay needed at this scale).

## Topic + Lambda subscription (Terraform)
```hcl
resource "aws_sns_topic" "events" {
  name              = "tadeumendonca-events-${var.environment}"
  kms_master_key_id = "alias/aws/sns"            # SSE at rest (/infrastructure/encryption)
}
resource "aws_sns_topic_subscription" "notifications" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "lambda"
  endpoint  = module.bff.lambda_function_arn     # the notifications consumer (or a dedicated fn)
}
resource "aws_lambda_permission" "sns" {
  action = "lambda:InvokeFunction"; principal = "sns.amazonaws.com"
  function_name = module.bff.lambda_function_name; source_arn = aws_sns_topic.events.arn
}
# topic ARN → SSM: /{env}/events/topic-arn ; BFF role gets sns:Publish
```

## Reliability
- Attach a **DLQ** (a small SQS) to the Lambda subscription (`redrive_policy` / `on_failure`) so failed notifications aren't lost — **without** making SQS the primary path.
- SNS retries Lambda deliveries automatically.

## Conventions
- Message = a small JSON domain event (`{ "type": "post_published", "post_id": "…" }`, snake_case); use **subscription filter policies** on `type` if several event types share the topic.
- SSE at rest (`/infrastructure/encryption`); tagged (`/infrastructure/tagging`).
- Producer (BFF module) publishes; consumers subscribe — `/backend/notifications`.
- Scale-up path: if content routing / replay / many event types appear, revisit EventBridge.
