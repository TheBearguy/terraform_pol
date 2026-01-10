resource "aws_s3_bucket" "my_hashi_hashi_bucket4110" {
    bucket = "hashi-rama-state-bucket"
    # region = "eu-north-1"
    # region is a default parameter. Its a provider level parameters, must be defined in provider.tf
    tags = {
        Name = "hashi-rama-state-bucket", 
        Environment = "Dev"
    }
}