resource aws_s3_bucket my-infra-app-bucket99 {
    bucket = "${var.env}-${var.bucket_name}"
    region = "eu-north-1"
    tags = {
      Name = "${var.env}-${var.bucket_name}"
      Environment = var.env
    }
}