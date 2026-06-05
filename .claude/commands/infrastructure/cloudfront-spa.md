Implement or review the CloudFront SPA distribution (frontend.tf) in tadeumendonca-iac.

Context: $ARGUMENTS

Composes WAF(CLOUDFRONT) + CloudFront + S3(OAC) + Route53, public modules called directly.

## WAF CLOUDFRONT (us-east-1 alias required)

```hcl
module "waf_cloudfront" {
  source    = "aws-ia/waf/aws"
  version   = "~> 1.0"
  providers = { aws = aws.us_east_1 }
  name      = "tadeumendonca-cloudfront-${var.environment}"
  scope     = "CLOUDFRONT"
  managed_rule_groups = [{ name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS", priority = 1 }]
}
```

## CloudFront (terraform-aws-modules/cloudfront/aws ~> 3.0)

```hcl
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.0"
  aliases            = [var.domain_name]
  http_version       = "http2and3"
  price_class        = "PriceClass_100"
  web_acl_id         = module.waf_cloudfront.web_acl_arn
  viewer_certificate = {
    acm_certificate_arn      = data.aws_acm_certificate.main.arn   # us-east-1, looked up by domain
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  create_origin_access_control = true
  origin = {
    s3 = { domain_name = module.frontend_bucket.s3_bucket_bucket_regional_domain_name
           origin_access_control = "s3_oac" }
  }
  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized
    lambda_function_association = {
      viewer-request = { lambda_arn = module.fn_og_edge.lambda_function_qualified_arn, include_body = false }
    }
  }
  custom_error_response = [   # SPA routing: serve index.html on 403/404
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
    { error_code = 404, response_code = 200, response_page_path = "/index.html" }
  ]
}
```

## Route53 A-alias → CloudFront (in frontend.tf)
`aws_route53_record` type `A`, alias target = the CloudFront distribution domain, `zone_id = data.aws_route53_zone.main.zone_id`.

## Conventions
- **Lambda@Edge (og-edge)** attached at Viewer Request via `lambda_function_qualified_arn` — bot UA detection for OG tags, no SSR. See `/backend/og-edge-handler`.
- Add an **`/og/*` cache behavior** routed to the `og-images` bucket so OG PNGs are served from the same distribution (no subdomain).
- **Cache header split is set by the fed deploy** (immutable hashed assets vs `no-cache` index.html), not here — see `/workflow/deploy-fed`.
- ACM cert resolved via `data.aws_acm_certificate.main.arn` (us-east-1) — never an ARN in tfvars.
- SSM: `/{env}/frontend/cloudfront-distribution-id = module.cloudfront.cloudfront_distribution_id`.
