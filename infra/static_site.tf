module "static_site" {
  source = "git::https://github.com/george-richardson/terraform_s3_cloudfront_static_site.git?ref=2.0.1"

  providers = {
    aws.useast1 = aws.useast1
  }

  name           = "gjhr.me"
  bucket_name    = "gjhr.me-origin"
  hosted_zone_id = aws_route53_zone.gjhr_me.zone_id
}

