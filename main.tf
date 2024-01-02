#create shared S3 bucket
resource "aws_s3_bucket" "s3bucket" {
  bucket = "nextcloud-aio-bucket-pcls"
  tags = {
    Name        = "NC Shared Bucket"
  }
}

#create database
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

#create redis
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

  user_data = filebase64("bashscript.sh")
}




