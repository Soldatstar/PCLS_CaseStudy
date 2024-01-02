#!/bin/bash
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt install docker.io -y
  sudo docker run -d -p 80:80 \
       --name NextCloudContainer  \
       nextcloud
  sleep 20
  sudo docker exec NextCloudContainer bash -c "apt update && apt install curl -y"
  sudo docker exec NextCloudContainer bash -c "curl 'https://onlyforconfig.s3.eu-north-1.amazonaws.com/config.php' -o /var/www/html/config/config.php"
  sudo docker exec NextCloudContainer  rm /var/www/html/config/CAN_INSTALL
  sudo docker exec NextCloudContainer  chown -R 33:33 /var/
  sudo docker exec NextCloudContainer  touch /var/www/html/data/.ocdata