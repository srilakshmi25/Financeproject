provider "aws" {
region     = "ap-south-1"
}

resource "aws_vpc" "nataraj" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public01" {
  vpc_id     = aws_vpc.nataraj.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public01"
  }
}


resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.nataraj.id

  tags = {
    Name = "gw1"
  }
}

resource "aws_route_table" "rt01" {
  vpc_id = aws_vpc.nataraj.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw1.id

  }
  tags = {
    Name = "rt01"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public01.id
  route_table_id = aws_route_table.rt01.id
}

resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.nataraj.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "HTTP traffic"
    from_port        = 00
    to_port          = 65000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg1"
  }
}

resource "aws_network_interface" "new-ip" {
  subnet_id   = aws_subnet.public01.id
  private_ips = ["10.0.1.10"]
}

resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.new-ip
  associate_with_private_ip = "10.0.1.10"
}

resource "aws_instance" "prod-server" {
  ami           = "ami-0c2af51e265bd5e0e"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.public01.id
  vpc_security_group_ids = [aws_security_group.sg1.id]
  key_name = "project-key"
 
 network_interface {
        device_index            = 0
        network_interface_id    = aws_network_interface.new-ip
    }
 tags = {
  Name = "prod-server"
 }
}
