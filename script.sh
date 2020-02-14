#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
# Mysql root password
debconf-set-selections <<< 'mariadb-server mysql-server/root_password password root'
debconf-set-selections <<< 'mariadb-server mysql-server/root_password_again password root'
# ADD PPA
add-apt-repository ppa:ondrej/php
add-apt-repository ppa:ondrej/nginx
# MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

echo "====================== UPDATE & UPGRADE ====================="
apt update -q
apt dist-upgrade -y -q
apt autoremove -y -q
apt install software-properties-common git

# MongoDB
echo "==================== INSTALLING MongoDB ====================="
apt install -y -q mongodb-org
# Start services
sudo systemctl start mongod
sudo systemctl enable mongod

# MariaDB
echo "==================== INSTALLING MariaDB ====================="
apt install -y -q mariadb-server
echo "=================== CONFIGURING MariaDB ====================="
sed -i -e 's/^\(bind-address\)/#\1/g' /etc/mysql/mariadb.conf.d/50-server.cnf
echo "GRANT ALL on *.* TO root@'%' identified by 'root'" | mysql -uroot -proot
echo "FLUSH PRIVILEGES" | mysql -uroot -proot
# dashboard sql
echo "CREATE DATABASE IF NOT EXISTS dashboard" | mysql -uroot -proot
echo "CREATE USER 'vagrant'@'localhost' IDENTIFIED BY 'vagrant'" | mysql -uroot -proot
echo "GRANT ALL PRIVILEGES ON dashboard.* TO 'vagrant'@'localhost' IDENTIFIED BY 'vagrant'" | mysql -uroot -proot

# INSTALL NODE & YARN
echo "==================== INSTALLING NODEJS ====================="
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt update -q
apt install -y -q nodejs yarn openssl libssl-dev 

# PHP STUFF
echo "==================== INSTALLING PHP 7.4 ====================="
apt install -y -q composer php7.4-fpm php7.4-common php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip unzip
echo "==================== CONFIGURING PHP ========================"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.4/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.4/fpm/php.ini
#sed -i "s/user .*;/user www-data;/" /etc/nginx/nginx.conf
echo "cgi.fix_pathinfo = 0" >> /etc/php/7.4/fpm/php.ini
echo "date.timezone = \"Europe/Lisbon\"" >> /etc/php/7.4/fpm/php.ini

# Nginx
echo "==================== INSTALLING NGINX ====================="
apt install -y -q nginx
echo "==================== CONFIGURING NGINX ===================="
cp /vagrant/nginx-default.conf /etc/nginx/conf.d/default.conf

# System
echo "==================== CONFIGURING SYSTEM ===================="
# Timezone
echo "Europe/Lisbon" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Deploy
echo "========================= DEPLOY ==========================="
cd /vagrant
#git clone https://github.com/mripta/dashboard.git

# Restart Services
echo "=================== RESTARTING SERVICES ===================="
service nginx restart
service php7.4-fpm restart
service mysql restart

echo "========================== VERSIONS ========================"
echo "NPM " `npm -v`
echo "PHP " `php -v | head -n 1`
echo "YARN " `yarn --version`
echo "MySQL " `mysql --version | head -n 1`
echo "NODEJS " `nodejs -v`
echo "MongoDB " `mongod --version | head -n 1`
echo "============================== :) ==========================="