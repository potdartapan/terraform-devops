#! /bin/bash
sudo apt install nginx -y
sudo unlink /etc/nginx/sites-enabled/default
# add nginx configuration text file here (done)
cd /etc/nginx/sites-available/
sudo git init
sudo git remote add origin https://github.com/potdartapan/webserver
sudo git fetch origin
sudo git checkout origin/main -- example.com
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/ #link new configuration file
sudo systemctl restart nginx
sudo mkdir /var/www/example.com
#pull index.html and rest of the website files to /var/www/example.com
cd /var/www/example.com
sudo git init
sudo git remote add origin http://github.com/potdartapan/webserver
sudo git fetch origin
sudo git checkout origin/main -- index.html

