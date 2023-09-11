#initilization for AWS provider
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.16.1"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}


# 1. Create vpc

resource "aws_vpc" "prod-vpc-1" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "prod-vpc-1"
  }
}


# 2. Create Internet Gateway

resource "aws_internet_gateway" "prod-internet-gw-1" {
  vpc_id = aws_vpc.prod-vpc-1.id

  tags = {
    Name = "prod-internet-gw-1"
  }
}


# 3. Create Custom Route Table

resource "aws_route_table" "prod-route-table-1" {
  vpc_id = aws_vpc.prod-vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-internet-gw-1.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.prod-internet-gw-1.id
  }

  tags = {
    Name = "prod-route-table-1"
  }
}


# 4. Create a Subnet 

resource "aws_subnet" "public-subnet-1" {
  vpc_id     = aws_vpc.prod-vpc-1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet-1"
  }
}


# 5. Associate subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.prod-route-table-1.id
}


# 6. Create Security Groups to allow port 22,80,443

resource "aws_security_group" "allow-web-1" {
  name        = "allow_web_traffic"
  description = "allow_tcp_traffic"
  vpc_id      = aws_vpc.prod-vpc-1.id

  tags = {
    Name = "allow-web-1"
  }

  # Avoids conflict with not being able to edit or delete security groups
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ssh" {
  security_group_id = aws_security_group.allow-web-1.id

  cidr_ipv4 = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_http" {
  security_group_id = aws_security_group.allow-web-1.id

  cidr_ipv4 = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_https" {
  security_group_id = aws_security_group.allow-web-1.id

  cidr_ipv4 = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "egress_all" {
  security_group_id = aws_security_group.allow-web-1.id

  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}


# 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.public-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web-1.id]
}


# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "web-eip-1" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.prod-internet-gw-1]
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "web-server-1" {
  ami               = "ami-01c647eace872fc02"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "web-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo Real knowledge is to know the extent of one's ignorance. > /var/www/html/index.html'
                EOF

  tags = {
    Name = "web-server-1"
  }
}