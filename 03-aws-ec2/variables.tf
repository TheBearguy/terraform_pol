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

variable "instance_configs" {
  description = "Map of instance configurations"
  type = map(object({
    ami_id        = string
    instance_type = string
  }))
  default = {
    "web" = {
      ami_id        = "ami-0abcdef1234567890" # Example AMI ID, update as needed
      instance_type = "t2.micro"
    },
    "app" = {
      ami_id        = "ami-0fedcba9876543210" # Example AMI ID, update as needed
      instance_type = "t2.micro"
    }
  }
}