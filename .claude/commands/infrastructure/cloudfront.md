Use CloudFront in tadeumendonca infrastructure.

Context: $ARGUMENTS

Module: `terraform-aws-modules/cloudfront/aws ~> 3.0`.

## Standard config
```hcl
http_version       = "http2and3"
price_class        = "PriceClass_100"
web_acl_id         = module.waf_cloudfront.web_acl_arn          # CLOUDFRONT WAF (us-east-1)
viewer_certificate = { acm_certificate_arn = data.aws_acm_certificate.main.arn,
                       ssl_support_method = "sni-only", minimum_protocol_version = "TLSv1.2_2021" }
create_origin_access_control = true                            # OAC — S3 stays private
default_cache_behavior = { viewer_protocol_policy = "redirect-to-https", compress = true,
                           cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" }   # managed CachingOptimized
```

## Conventions
- **OAC, not OAI** — origin S3 buckets stay private; reach them via `s3_bucket_bucket_regional_domain_name`.
- TLS ≥ `TLSv1.2_2021`, HTTPS redirect, compression on (`/infrastructure/encryption`).
- Edge logic: **Lambda@Edge** (Viewer Request) for bot/SEO (`/backend/og-edge-handler`); CloudFront Functions for trivial header/redirect logic only.
- CLOUDFRONT-scope WAF requires the us-east-1 provider alias (`/infrastructure/waf`); cert via `/infrastructure/acm`.
- SPA-specific delivery (index.html fallback, `/og/*` behavior, cache-header split) → `/infrastructure/cloudfront-spa`, `/workflow/deploy-fed`.
