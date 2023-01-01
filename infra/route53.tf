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
    "v=spf1 include:spf.messagingengine.com ?all",                         # Fastmail
    "google-site-verification=8gF9yPO5sAgTnTT8AF8Q0lCut2jI9JXP8pVFMRF1M4k" # Goolge search console
  ]
}

# Fastmail.com

resource "aws_route53_record" "fastmail_mx" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "gjhr.me"
  type    = "MX"
  ttl     = 3600
  records = [
    "10 in1-smtp.messagingengine.com",
    "20 in2-smtp.messagingengine.com"
  ]
}

resource "aws_route53_record" "fastmail_dkim_1" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "fm1._domainkey.gjhr.me"
  type    = "CNAME"
  ttl     = 3600
  records = ["fm1.gjhr.me.dkim.fmhosted.com"]
}

resource "aws_route53_record" "fastmail_dkim_2" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "fm2._domainkey.gjhr.me"
  type    = "CNAME"
  ttl     = 3600
  records = ["fm2.gjhr.me.dkim.fmhosted.com"]
}

resource "aws_route53_record" "fastmail_dkim_3" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "fm3._domainkey.gjhr.me"
  type    = "CNAME"
  ttl     = 3600
  records = ["fm3.gjhr.me.dkim.fmhosted.com"]
}

# Temporary migration records

resource "aws_route53_record" "temp_trackhammer" {
  zone_id = aws_route53_zone.gjhr_me.zone_id
  name    = "trackhammer.gjhr.me"
  type    = "CNAME"
  ttl     = 60
  records = ["dgush7i5ti2nm.cloudfront.net."]
}
