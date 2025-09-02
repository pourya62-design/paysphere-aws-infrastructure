#############################################
# Provider Configuration
#############################################
provider "aws" {
  region = "us-east-1" # منطقه انتخابی
}

#############################################
# VPC and Networking
#############################################
resource "aws_vpc" "paysphere_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "paysphere-vpc"
  }
}

resource "aws_subnet" "paysphere_subnet" {
  vpc_id                  = aws_vpc.paysphere_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "paysphere-public-subnet"
  }
}

resource "aws_internet_gateway" "paysphere_igw" {
  vpc_id = aws_vpc.paysphere_vpc.id
  tags = {
    Name = "paysphere-internet-gateway"
  }
}

resource "aws_route_table" "paysphere_route_table" {
  vpc_id = aws_vpc.paysphere_vpc.id
  tags = {
    Name = "paysphere-route-table"
  }
}

resource "aws_route" "paysphere_internet_access" {
  route_table_id         = aws_route_table.paysphere_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.paysphere_igw.id
}

resource "aws_route_table_association" "paysphere_subnet_association" {
  subnet_id      = aws_subnet.paysphere_subnet.id
  route_table_id = aws_route_table.paysphere_route_table.id
}

#############################################
# Security Group
#############################################
resource "aws_security_group" "paysphere_sg" {
  name        = "paysphere-sec-group"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.paysphere_vpc.id

  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP Access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "paysphere-security-group"
  }
}

#############################################
# EC2 Instance
#############################################
resource "aws_instance" "paysphere_instance" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 (US-East-1)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.paysphere_subnet.id
  vpc_security_group_ids = [aws_security_group.paysphere_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "paysphere-ec2"
  }
}

#############################################
# S3 Bucket
#############################################
resource "aws_s3_bucket" "paysphere_bucket" {
  bucket = "paysphere-bucket-${random_id.bucket_id.hex}"
  acl    = "private"

  tags = {
    Name = "paysphere-storage-bucket"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}
