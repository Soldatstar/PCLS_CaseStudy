terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region     = "eu-north-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# Create aws vpc
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
    enable_dns_support = true
}

# Create aws internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id
}

# Create aws ipv4 default route
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Subnet for servers
resource "aws_subnet" "server-subnet1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
}
resource "aws_subnet" "server-subnet2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-north-1b"
}

# Subnet linking to route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.server-subnet1.id
  route_table_id = aws_route_table.route.id
}
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "postgresubgroup"
  subnet_ids = [aws_subnet.server-subnet1.id,aws_subnet.server-subnet2.id]

  tags = {
    Name = "PostgreSQL subnet group"
  }
}

# Security group for port 22,80,443
resource "aws_security_group" "allow-web" {
  name        = "allow-web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "8080 from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "8443 from VPC"
    from_port        = 8443
    to_port          = 8443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
# Create a VPC endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.myvpc.id
  service_name = "com.amazonaws.eu-north-1.s3"
  route_table_ids = [aws_route_table.route.id]
}

# Create network interface using subnet-server and security groups
resource "aws_network_interface" "server-nic" {
  subnet_id       = aws_subnet.server-subnet1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow-web.id]
}

# Create public ip adress using aws elastic ip
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}
#create shared S3 bucket
resource "aws_s3_bucket" "s3bucket" {
  bucket = "nextcloud-aio-bucket-pcls"
  tags = {
    Name        = "NC Shared Bucket"
  }
}
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.small"
  username             = "nextcloud"
  password             = "nextcloud"
  skip_final_snapshot  = true
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.allow-web.id]
  db_subnet_group_name = aws_db_subnet_group.postgres_subnet_group.name
  depends_on = [aws_internet_gateway.gw]

}
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "redis-replication-group"
  description = "Redis replication group"
  node_type                     = "cache.t3.small"
  engine                        = "redis"
  engine_version                = "5.0.5"
  parameter_group_name          = "default.redis5.0"
  port                          = 6379
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.name
  auth_token                     = var.redis_auth
  transit_encryption_enabled    = true
  depends_on                    = [aws_internet_gateway.gw]
}
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.server-subnet1.id]

  depends_on = [aws_subnet.server-subnet1]
}

# Create first EC2 instance
resource "aws_instance" "server" {
  ami           = "ami-0014ce3e52359afbd"
  instance_type = "t3.micro"
  availability_zone = "eu-north-1a"
  key_name = "pcls-sshkey"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.server-nic.id
  }

  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt install docker.io -y
  sudo docker run -d -p 8080:80 \
    -e POSTGRES_HOST=${aws_db_instance.postgres.address} \
    -e POSTGRES_DB=${aws_db_instance.postgres.identifier} \
    -e POSTGRES_USER=${aws_db_instance.postgres.username} \
    -e POSTGRES_PASSWORD=${aws_db_instance.postgres.password} \
    -e REDIS_HOST=${aws_elasticache_replication_group.redis.primary_endpoint_address} \
    -e REDIS_HOST_PASSWORD=${var.redis_auth}\
    -e OBJECTSTORE_S3_HOST=s3.eu-north-1.amazonaws.com \
    -e OBJECTSTORE_S3_BUCKET=${aws_s3_bucket.s3bucket.bucket} \
    -e OBJECTSTORE_S3_KEY=${var.access_key}\
    -e OBJECTSTORE_S3_SECRET=${var.secret_key} \
    -e OBJECTSTORE_S3_REGION=eu-north-1 \
    nextcloud
  EOF
}




