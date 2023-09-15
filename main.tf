#initilization for AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
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
  cidr_block = "10.0.0.0/16"

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
  vpc_id            = aws_vpc.prod-vpc-1.id
  cidr_block        = "10.0.1.0/24"
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
  ingress {
    description = "ssh"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    description = "http"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  ingress {
    description = "https"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow-web-1"
  }

  # Avoids conflict with not being able to edit or delete security groups
  lifecycle {
    create_before_destroy = true
  }
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
  depends_on                = [aws_internet_gateway.prod-internet-gw-1, aws_instance.web-server-1]
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "web-server-1" {
  ami               = "ami-053b0d53c279acc90"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  key_name          = "web-key"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              echo "Real knowledge is to know the extent of one's ignorance." | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server-1"
  }
}


# 10. Create Network ACL, just in case.
resource "aws_network_acl" "web-nacl-1" {
  vpc_id = aws_vpc.prod-vpc-1.id

  # Ingress rules for allowing ssh 22, http 80, https 443.
  ingress {
    protocol   = "tcp"
    rule_no    = 50
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 150
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # Egress rule for allowing all outgoing traffic
  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "web-nacl-1"
  }
}


# 11. Associate NACL with subnet 
resource "aws_network_acl_association" "b" {
  network_acl_id = aws_network_acl.web-nacl-1.id
  subnet_id      = aws_subnet.public-subnet-1.id
}


# Prints DNS for future use and to prove web server successful launch.
output "DNS" {
  value = aws_instance.web-server-1.public_dns
}
