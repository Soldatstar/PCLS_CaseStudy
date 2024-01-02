#!/bin/bash
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt install docker.io -y
  sudo docker run -d -p 8080:80 \
       --name NextCloudContainer  \
       -e POSTGRES_HOST=${aws_db_instance.postgres.address} \
       -e POSTGRES_DB=${aws_db_instance.postgres.identifier} \
       -e POSTGRES_USER=${aws_db_instance.postgres.username} \
       -e POSTGRES_PASSWORD=${aws_db_instance.postgres.password} \
       -e OBJECTSTORE_S3_HOST=s3.eu-north-1.amazonaws.com \
       -e OBJECTSTORE_S3_BUCKET=${aws_s3_bucket.s3bucket.bucket} \
       -e OBJECTSTORE_S3_KEY=${var.access_key} \
       -e OBJECTSTORE_S3_SECRET=${var.secret_key} \
       -e OBJECTSTORE_S3_REGION=eu-north-1 \
       nextcloud