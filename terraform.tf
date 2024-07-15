# Initialize Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "proj-vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway
resource "aws_internet_gateway" "proj-ig" {
  vpc_id = aws_vpc.proj-vpc.id
  tags = {
    Name = "gateway1"
  }
}

# Set up the route table
resource "aws_route_table" "proj-rt" {
  vpc_id = aws_vpc.proj-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.proj-ig.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.proj-ig.id
  }
  tags = {
    Name = "rt1"
  }
}

# Set up the subnet
resource "aws_subnet" "proj-subnet" {
  vpc_id            = aws_vpc.proj-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1d"
  tags = {
    Name = "subnet1"
  }
}

# Associate the subnet with the route table
resource "aws_route_table_association" "proj-rt-sub-assoc" {
  subnet_id      = aws_subnet.proj-subnet.id
  route_table_id = aws_route_table.proj-rt.id
}

# Create a security group
resource "aws_security_group" "proj-sg" {
  name        = "proj-sg"
  description = "Enable web traffic for the project"
  vpc_id      = aws_vpc.proj-vpc.id
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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow port 80 inbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "proj-sg1"
  }
}

# Create a new network interface
resource "aws_network_interface" "proj-ni" {
  subnet_id       = aws_subnet.proj-subnet.id
  security_groups = [aws_security_group.proj-sg.id]
}

# Attach the elastic IP to the network interface
resource "aws_eip" "proj-eip" {
  vpc = true
  network_interface         = aws_network_interface.proj-ni.id
  associate_with_private_ip = "10.0.0.10"
}

# Create an Ubuntu EC2 instance
resource "aws_instance" "Prod-Server" {
  ami           = "ami-0a0e5d9c7acc336f1"
  instance_type = "t2.medium"
  availability_zone = "us-east-1d"
  key_name               = "banking"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.proj-ni.id
  }
  user_data = <<EOF
#!/bin/bash
sudo apt-get update -y
sudo apt install docker.io -y
sudo systemctl enable docker
sudo docker run -itd -p 8085:8081 swathi683/banking-app1:1.1
sudo docker start $(docker ps -aq)
EOF
  tags = {
    Name = "Prod-server"
  }
}
output "network_interface_id" {
  value = aws_network_interface.proj-ni.id
}

output "ip_address" {
  value = aws_eip.proj-eip.public_ip
}

