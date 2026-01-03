# Key-pair (login)

resource aws_key_pair my_key {
    key_name = "terra-ec2-key"
    public_key = file("terra-ec2-key.pub")
}

# VPC and Security group

resource aws_default_vpc default {
    
}

resource aws_security_group my_security_group {
    name = "automate-sg"
    description = "This will add a TF generated Security group"
    vpc_id = aws_default_vpc.default.id # interpolation 
    
    # inbound rules - 
    ingress {
        from_port = 22 # ssh
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH open"
    }
    
    ingress {
        from_port = 80 # http
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "http open"
    }

    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Application"
    }

    # outbound rules - 
    egress {
        from_port = 0
        to_port = 0
        # 0 port means nothing.
        # from_port, to_port can be removed as well. it'll work without it
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "all outbound access opoen"
    }


    tags = {
        Name = "automate-sg"
    }
}

# EC2 instance
resource "aws_instance" "my_instance" {
    key_name = aws_key_pair.my_key.key_name
    security_groups = [aws_security_group.my_security_group.name]
    instance_type = "t3.micro"
    ami = "ami-0fa91bc90632c73c9" # ubuntu
    root_block_device {
        volume_size = 8
        volume_type = "gp3"
    }
    tags = {
        Name = "my-hashi-ec2-instance"
        
    }
}