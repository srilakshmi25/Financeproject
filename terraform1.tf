# Configure the AWS provider
provider "aws" {
  region = "ap-south-1"
}
# Creating a VPC
resource "aws_vpc" "project-vpc" {
 cidr_block = "10.0.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "project-ig" {
 vpc_id = aws_vpc.project-vpc.id
 tags = {
 Name = "project-gateway1"
 }
}

# Setting up the route table
resource "aws_route_table" "project-rt" {
 vpc_id = aws_vpc.project-vpc.id
 route {
 # pointing to the internet
 cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.project-ig.id
 }
 route {
 ipv6_cidr_block = "::/0"
 gateway_id = aws_internet_gateway.project-ig.id
 }
 tags = {
 Name = "project-routetable"
 }
}

# Setting up the subnet
resource "aws_subnet" "project-subnet" {
 vpc_id = aws_vpc.project-vpc.id
 cidr_block = "10.0.1.0/24"
 availability_zone = "ap-south-1a"
 tags = {
 Name = "project-subnet1"
 }
}

# Associating the subnet with the route table
resource "aws_route_table_association" "project-rt-sub-assoc" {
subnet_id = aws_subnet.project-subnet.id
route_table_id = aws_route_table.project-rt.id
}

# Creating a Security Group
resource "aws_security_group" "project-sg" {
 name = "project-sg"
 description = "Enable web traffic for the project"
 vpc_id = aws_vpc.project-vpc.id
 ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
 description = "HTTPS traffic"
 from_port = 443
 to_port = 443
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "HTTP traffic"
 from_port = 0
 to_port = 65000
 protocol = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
 }
 ingress {
 description = "Allow port 80 inbound"
 from_port   = 80
 to_port     = 80
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
 from_port = 0
 to_port = 0
 protocol = "-1"
 cidr_blocks = ["0.0.0.0/0"]
 ipv6_cidr_blocks = ["::/0"]
 }
 tags = {
 Name = "project-sg"
 }
}

# Creating a new network interface
resource "aws_network_interface" "project-ni" {
 subnet_id = aws_subnet.project-subnet.id
 private_ips = ["10.0.1.10"]
 security_groups = [aws_security_group.project-sg.id]
}

# Attaching an elastic IP to the network interface
resource "aws_eip" "project-eip" {
 vpc = true
 network_interface = aws_network_interface.project-ni.id
 associate_with_private_ip = "10.0.1.10"
}


# Creating an ubuntu EC2 instance
resource "aws_instance" "Test-Server" {
 ami = "ami-0c2af51e265bd5e0e"
 instance_type = "t2.micro"
 availability_zone = "ap-south-1b"
 key_name = "jenkins"
 network_interface {
 device_index = 0
 network_interface_id = aws_network_interface.project-ni.id
 }
 user_data  = <<-EOF
 #!/bin/bash
     sudo apt-get update -y
 EOF
 tags = {
 Name = "Test-Server"
 }
}
