# Key Pair (login)
resource aws_key_pair my_infra_app_key {
    key_name = "${var.env}-infra-app-ec2-key"
    public_key = file("terra-ec2-key.pub")
    tags = {
      Environment = var.env
    }
}

# VPC and security group
resource aws_default_vpc default {

}

resource aws_security_group my_infra_app_security_group {
    name = "${var.env}-infra-app-sg"
    description = "This will add a TF generated security group for my infra app"
    vpc_id = aws_default_vpc.default.id

    # inbound rules
    ingress {
        from_port = 22 # ssh
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH open"
    }

    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Application"
    }

    egress {
        from_port = 8000
        to_port = 8000
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "all outbound access opoen"
    }

    tags = {
        Name = "${var.env}-infra-app-sg"
    }
}

resource "aws_instance" infra_app_instance {
    count = var.instance_count
    depends_on = [ aws_security_group.my_infra_app_security_group, aws_key_pair.my_infra_app_key ]
    key_name = aws_key_pair.my_infra_app_key.key_name
    security_groups = [aws_security_group.my_infra_app_security_group.name]
    instance_type = var.instance_type 
    ami = var.ec2_ami_id 
    root_block_device {
        volume_size = var.env == "prod" ? 15 : 10
        volume_type = "gp3"
    }
    tags = {
        Name = "${var.env}-infra-app-ec2-instance" 
    }
}