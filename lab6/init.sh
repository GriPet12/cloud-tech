#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx

echo "Hello World from $(hostname)" | sudo tee /var/www/html/index.html

sudo mkdir -p /var/www/html/image
sudo mkdir -p /var/www/html/video
echo "Image page on $(hostname)" | sudo tee /var/www/html/image/index.html
echo "Video page on $(hostname)" | sudo tee /var/www/html/video/index.html