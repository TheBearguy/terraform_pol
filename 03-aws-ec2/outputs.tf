output "ec2_public_ip" {
    # value = aws_instance.my_instance.public_ip # this works if you have just one instance 
    # value = aws_instance.my_instance[*].public_ip 
    # my_instance[*] = for all instances
    # The * thing doesnt work with "for_each" meta argument
    value = [
        for instance in aws_instance.my_instance : instance.public_ip
        # iterating the instances and getting their public ip
    ]

}

output "ec2_public_dns" {
    # value = aws_instance.my_instance.public_dns
    # value = aws_instance.my_instance[*].public_dns
    value = [
        for instance in aws_instance.my_instance : instance.public_dns
    ]
}

output "ec2_private_ip" {
    # value = aws_instance.my_instance.private_ip
    # value = aws_instance.my_instance[*].private_ip
    value = [
        for instance in aws_instance.my_instance : instance.private_ip
    ]
}