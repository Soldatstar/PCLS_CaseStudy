#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install docker.io -y
sudo docker run -d -p 8080:80 \
--name NextCloudContainer  \
-e POSTGRES_HOST=${postgres_host} \
-e POSTGRES_DB=${postgres_db} \
-e POSTGRES_USER=${postgres_user} \
-e POSTGRES_PASSWORD=${postgres_password} \
-e OBJECTSTORE_S3_HOST=s3.eu-north-1.amazonaws.com \
-e OBJECTSTORE_S3_BUCKET=${s3_bucket} \
-e OBJECTSTORE_S3_KEY=${access_key} \
-e OBJECTSTORE_S3_SECRET=${secret_key} \
-e OBJECTSTORE_S3_REGION=eu-north-1 \
nextcloud