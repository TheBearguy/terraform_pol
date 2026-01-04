variable "ec2_instance_type" {
    default = "t3.micro"
    type = string
}

variable "ec2_default_root_storage_size" {
    default = 8
    type = number
}

variable "ec2_ami_id" {
    default = "ami-0fa91bc90632c73c9"
    type = string
}

variable "env" {
    default = "prod"
    type = string
}