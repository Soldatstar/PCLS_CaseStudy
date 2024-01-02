
### GENERAL ###

# Create aws vpc
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

# Create a vpc endpoint for S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.myvpc.id
  service_name = "com.amazonaws.eu-north-1.s3"
  route_table_ids = [aws_route_table.route.id]
}

# Create aws internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id
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

### SUBNETS ###

# Subnet for servers in first availability zone
resource "aws_subnet" "server-subnet1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
}

# Subnet for servers in second availability zone
resource "aws_subnet" "server-subnet2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-north-1b"
}

### ROUTETABLES & ASSOCIATION ###

# Create aws ipv4 default route
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Subnet linking to route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.server-subnet1.id
  route_table_id = aws_route_table.route.id
}

# Subnet linking to database
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "postgresubgroup"
  subnet_ids = [aws_subnet.server-subnet1.id,aws_subnet.server-subnet2.id]

  tags = {
    Name = "PostgreSQL subnet group"
  }
}

# Subnet linking to redis
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.server-subnet1.id]

  depends_on = [aws_subnet.server-subnet1]
}
