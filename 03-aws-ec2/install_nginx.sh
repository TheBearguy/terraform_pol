#!/bin/bash

sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

echo "<h1> Terraform installed nginx </h1>" | sudo tee /var/www/html/index.html