resource "aws_route53_zone" "gjhr_me" {
  name = "gjhr.me"
}

# TXT

resource "aws_route53_record" "txt" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "gjhr.me"
  type    = "TXT"
  ttl     = 3600
  records = [
    "v=spf1 include:outlook.com -all",                                     # Outlook
    "google-site-verification=8gF9yPO5sAgTnTT8AF8Q0lCut2jI9JXP8pVFMRF1M4k" # Goolge search console
  ]
}

# Outlook.com

resource "aws_route53_record" "outlook_mx" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "gjhr.me"
  type    = "MX"
  ttl     = 3600
  records = ["0 141223073.pamx1.hotmail.com."]
}

resource "aws_route53_record" "outlook_autodiscover_cname" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "autodiscover.gjhr.me"
  type    = "CNAME"
  ttl     = 3600
  records = ["autodiscover.outlook.com."]
}

# Temporary migration records

resource "aws_route53_record" "temp_trackhammer" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "trackhammer.gjhr.me"
  type    = "CNAME"
  ttl     = 60
  records = ["dgush7i5ti2nm.cloudfront.net."]
}
