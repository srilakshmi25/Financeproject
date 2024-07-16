
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
  region = "ap-south-1"
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
  availability_zone = "ap-south-1a"
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

# Create a key pair
resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins"
  public_key = file("~/.ssh/jenkins.pem")
}

# Create a new network interface
resource "aws_network_interface" "proj-ni" {
  subnet_id       = aws_subnet.proj-subnet.id
  security_groups = [aws_security_group.proj-sg.id]
  private_ips     = ["10.0.1.10"]
}

# Attach the elastic IP to the network interface
resource "aws_eip" "proj-eip" {
  vpc = true
  network_interface = aws_network_interface.proj-ni.id
  depends_on        = [aws_network_interface.proj-ni]
}
# Create a TLS private key for Jenkins
resource "tls_private_key" "jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an AWS key pair for Jenkins
resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins"
  public_key = tls_private_key.jenkins.public_key_openssh
}

# Create an Ubuntu EC2 instance
resource "aws_instance" "Prod-Server" {
  ami               = "ami-0c2af51e265bd5e0e"
  instance_type     = "t2.medium"
  availability_zone = "ap-south-1a"
  key_name          = aws_key_pair.jenkins.key_name

  network_interface {
    device_index          = 0
    network_interface_id  = aws_network_interface.proj-ni.id
  }
}

  user_data = <<EOF
#!/bin/bash
sudo apt-get update -y
EOF
}
