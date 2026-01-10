terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.27.0"
    }
  }

  backend "s3" {
    bucket = "hashi-rama-state-bucket"
    key = "terraform.tfstate"
    region = "eu-north-1"
    dynamodb_table = "hashi-rama-state-table"
  }
}