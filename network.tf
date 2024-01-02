
### GENERAL ###

# create aws vpc
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

# create a vpc endpoint for s3
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.myvpc.id
  service_name = "com.amazonaws.eu-north-1.s3"
  route_table_ids = [aws_route_table.priv-route.id]
}

# create aws internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id
}

# create public ip adress for nat gateway
resource "aws_eip" "elastic-ip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.gw]
}

# nat gateway for private subnets
resource "aws_nat_gateway" "nat-priv-subnet" {
  allocation_id = aws_eip.elastic-ip.id
  subnet_id     = aws_subnet.pub-sub-1.id
  depends_on = [aws_internet_gateway.gw]
}

### SUBNETS ###

# creating 1st public subnet
resource "aws_subnet" "pub-sub-1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1a"
}

# creating 2nd public subnet
resource "aws_subnet" "pub-sub-2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-north-1b"
}

# creating private subnet
resource "aws_subnet" "priv-sub" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "eu-north-1b"
}

### ROUTETABLES & ASSOCIATION ###

# route table for public subnet
resource "aws_route_table" "pub-route" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# route table for private subnet
resource "aws_route_table" "priv-route" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-priv-subnet.id
  }
}

# associate the route table with public subnet 1
resource "aws_route_table_association" "pub-route-assc-1" {
  subnet_id      = aws_subnet.pub-sub-1.id
  route_table_id = aws_route_table.pub-route.id
}

# associate the route table with public subnet 2
resource "aws_route_table_association" "pub-route-assc-2" {
  subnet_id      = aws_subnet.pub-sub-2.id
  route_table_id = aws_route_table.pub-route.id
}

# associate the route table with private subnet
resource "aws_route_table_association" "priv-route-assc" {
  subnet_id      = aws_subnet.priv-sub.id
  route_table_id = aws_route_table.priv-route.id
}

# subnet linking to database
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name       = "postgresubgroup"
  subnet_ids = [aws_subnet.pub-sub-1.id,aws_subnet.pub-sub-2.id]
}

### LOADBALANCER ###

resource "aws_lb" "pcls-loadbalancer" {
  name               = "pcls-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer-securitygroups.id]
  subnets            = [aws_subnet.pub-sub-1.id, aws_subnet.pub-sub-2.id]
  depends_on         = [aws_internet_gateway.gw]
}

resource "aws_lb_target_group" "pcls-targetgroup" {
  name     = "pcls-targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
}

resource "aws_lb_listener" "pcls-listener" {
  load_balancer_arn = aws_lb.pcls-loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pcls-targetgroup.arn
  }
}
