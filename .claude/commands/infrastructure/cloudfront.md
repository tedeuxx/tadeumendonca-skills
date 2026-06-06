Use CloudFront in <project> infrastructure (incl. the SPA distribution).

Context: $ARGUMENTS

Module: `terraform-aws-modules/cloudfront/aws ~> 3.0`. Composes WAF(CLOUDFRONT) + CloudFront + S3(OAC) + Route53, public modules called directly (`frontend.tf`).

## WAF CLOUDFRONT (us-east-1 alias required)
```hcl
module "waf_cloudfront" {
  source    = "aws-ia/waf/aws"
  version   = "~> 1.0"
  providers = { aws = aws.us_east_1 }
  name      = "<project>-cloudfront-${var.environment}"
  scope     = "CLOUDFRONT"
  managed_rule_groups = [{ name = "AWSManagedRulesCommonRuleSet", vendor_name = "AWS", priority = 1 }]
}
```

## CloudFront distribution (full config)
```hcl
module "cloudfront" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "~> 3.0"

  aliases      = [var.domain_name]
  http_version = "http2and3"
  price_class  = "PriceClass_100"                 # NA + EU edges only (cheapest); cf PriceClass_All
  web_acl_id   = module.waf_cloudfront.web_acl_arn # CLOUDFRONT WAF (us-east-1)

  viewer_certificate = {
    acm_certificate_arn      = data.aws_acm_certificate.main.arn   # us-east-1, looked up by domain (/infrastructure/acm)
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"      # TLS in-transit floor (/infrastructure/kms)
  }

  create_origin_access_control = true              # OAC — S3 stays private (not OAI)
  origin = {
    s3 = { domain_name = module.frontend_bucket.s3_bucket_bucket_regional_domain_name
           origin_access_control = "s3_oac" }
    og = { domain_name = module.og_images_bucket.s3_bucket_bucket_regional_domain_name
           origin_access_control = "s3_oac" }       # /og/* origin
  }

  default_cache_behavior = {
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # managed CachingOptimized
    lambda_function_association = {
      viewer-request = { lambda_arn = module.fn_og_edge.lambda_function_qualified_arn, include_body = false }
    }
  }
  ordered_cache_behavior = [                        # OG PNGs from the same distribution (no subdomain)
    { path_pattern = "/og/*", target_origin_id = "og", viewer_protocol_policy = "redirect-to-https",
      allowed_methods = ["GET","HEAD"], compress = true,
      cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" }
  ]

  custom_error_response = [                         # SPA routing: serve index.html on 403/404
    { error_code = 403, response_code = 200, response_page_path = "/index.html" },
    { error_code = 404, response_code = 200, response_page_path = "/index.html" }
  ]
}
```

## Route53 A-alias → CloudFront
`aws_route53_record` type `A`, alias target = `module.cloudfront.cloudfront_distribution_domain_name`, `zone_id = "Z2FDTNDATAQYW2"` (CloudFront constant). See `/infrastructure/route53`.

## Conventions
- **OAC, not OAI** — origin S3 buckets stay private; reach them via `s3_bucket_bucket_regional_domain_name` (`/infrastructure/s3`).
- TLS ≥ `TLSv1.2_2021`, HTTPS redirect, compression on; encryption stance `/infrastructure/kms`.
- **Lambda@Edge (og-edge)** at Viewer Request via `lambda_function_qualified_arn` — bot UA detection for OG/SEO, no SSR (`/backend/og-edge-handler`). CloudFront Functions only for trivial header/redirect logic.
- **`/og/*` behavior** routes to the `og-images` bucket so OG PNGs serve from the same distribution.
- **Cache-header split** (immutable hashed assets vs `no-cache` index.html) is set by the **fed deploy**, not here (`/workflow/github-actions`).
- CLOUDFRONT-scope WAF requires the us-east-1 alias (`/infrastructure/waf`); cert via `/infrastructure/acm`; distribution id to SSM `/{env}/frontend/cloudfront-distribution-id` (`/infrastructure/ssm`).
## Pros & cons
**Pros**
- Global TLS edge with OAC — origin S3 stays private.
- Lambda@Edge enables SEO/social crawling without SSR.
- One distribution serves the SPA + `/og/*`.
**Cons**
- Lambda@Edge constraints: no VPC, us-east-1 only, slow propagation.
- Cache invalidation/propagation latency.
- PriceClass_100 = fewer edge locations (cost vs reach).
