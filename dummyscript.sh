#!/bin/bash

# Update the package list and install updates
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Apache (httpd)
sudo apt-get install -y apache2

# Start and enable Apache service
sudo systemctl start apache2
sudo systemctl enable apache2

# Create a simple index.html file with a greeting
echo "<h1>Hello World from $(hostname -f)</h1>" | sudo tee /var/www/html/index.html
