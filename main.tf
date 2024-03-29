
# Create first EC2 instance
resource "aws_instance" "server" {
  ami           = "ami-0014ce3e52359afbd"
  instance_type = "t3.micro"
  availability_zone = "eu-north-1a"
  key_name = "pcls-sshkey"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.pcls-networkinterface.id
  }

  user_data = templatefile("setup.sh.tpl", {
access_key = var.access_key
secret_key = var.secret_key
postgres_host = aws_db_instance.postgres.address
postgres_db = aws_db_instance.postgres.db_name
postgres_user = aws_db_instance.postgres.username
postgres_password = aws_db_instance.postgres.password
s3_bucket = aws_s3_bucket.s3bucket.bucket
})
}


#create shared S3 bucket
resource "aws_s3_bucket" "s3bucket" {
  bucket = "nextcloud-aio-bucket-pcls"
}

#create database
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.small"
  db_name              = "postgres"
  username             = "nextcloud"
  password             = "nextcloud"
  skip_final_snapshot  = true
  publicly_accessible = true
  vpc_security_group_ids = [aws_security_group.ec2-securitygroups.id]
  db_subnet_group_name = aws_db_subnet_group.postgres_subnet_group.name
  depends_on = [aws_internet_gateway.gw]
}

### AUTOSCALING GROUP ###

# Launch template for ec2
resource "aws_launch_template" "ec2-template" {
  image_id      = "ami-0014ce3e52359afbd"
  instance_type = "t3.micro"
  user_data     = filebase64("NewInstance.sh")

  network_interfaces {
    associate_public_ip_address = false
    subnet_id                   = aws_subnet.priv-sub.id
    security_groups             = [aws_security_group.ec2-securitygroups.id]
  }

}

# Autoscaling group, 1-3 instances, created in private subnet
resource "aws_autoscaling_group" "pcls-autoscaling" {
  desired_capacity = 2
  max_size         = 4
  min_size         = 1

  target_group_arns = [aws_lb_target_group.pcls-targetgroup.arn]

  vpc_zone_identifier = [aws_subnet.priv-sub.id]

  launch_template {
    id      = aws_launch_template.ec2-template.id
    version = "$Latest"
  }
}



