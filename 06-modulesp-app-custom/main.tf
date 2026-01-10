module "dev-infra" {
    source = "./infra_app"
    env = "dev"
    bucket_name = "infra-app-bucket"
    instance_count = 1
    instance_type = "t3.micro"
    ec2_ami_id = "ami-0683ee28af6610487" # amazon linux
    hash_key = "studentID"
}

module "prod-infra" {
    source = "./infra_app"
    env = "prod"
    bucket_name = "infra-app-bucket"
    instance_count = 2
    instance_type = "t3.micro"
    ec2_ami_id = "ami-0683ee28af6610487" # amazon linux
    hash_key = "studentID"
}

module "stg-infra" {
    source = "./infra_app"
    env = "stg"
    bucket_name = "infra-app-bucket"
    instance_count = 2
    instance_type = "t3.micro"
    ec2_ami_id = "ami-0683ee28af6610487" # amazon linux
    hash_key = "studentID"
}