#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
# ADD nginx/php PPA's
add-apt-repository ppa:ondrej/php
add-apt-repository ppa:ondrej/nginx
# MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

echo "====================== UPDATE & UPGRADE ====================="
apt-get update -q
# Lets speed up the script
# apt dist-upgrade -y -q
# apt autoremove -y -q
apt-get install software-properties-common git

# MongoDB
echo "==================== INSTALLING MongoDB ====================="
apt-get install -y -q mongodb-org
# DB directory
mkdir -p /data/db
# Start and enable MongoDB
systemctl start mongod
systemctl enable mongod

# MySQL
echo "==================== INSTALLING MySQL ====================="
apt-get install -y -q mysql-server
echo "=================== CONFIGURING MySQL ====================="
# Expose
sed -i -e 's/bind-addres/#bind-address/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i -e 's/skip-external-locking/#skip-external-locking/g' /etc/mysql/mysql.conf.d/mysqld.cnf
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root'; FLUSH privileges;"
# Dashboard sql
mysql -u root -proot -e "CREATE DATABASE laravel;"

echo "==================== CONFIGURING MongoDB ====================="
# Add root user
mongo << 'EOF'
use admin
db.createUser({user:"admin", pwd:"admin", roles:[{role:"root", db:"admin"}]})
EOF
# Add Auth to daemon
sed -i "s/ExecStart=.*/ExecStart=\/usr\/bin\/mongod --auth --config \/etc\/mongod.conf/" /lib/systemd/system/mongod.service
# Expose
sed -i "s/  bindIp.*/  bindIp: 0.0.0.0/" /etc/mongod.conf

# INSTALL NODE & YARN
echo "==================== INSTALLING NODEJS ====================="
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
apt-get update -q
apt-get install -y -q nodejs yarn openssl libssl-dev

# PHP 7.4
echo "==================== INSTALLING PHP 7.4 ====================="
apt-get install -y -q composer php7.4-fpm php7.4-common php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php-mongodb unzip
echo "==================== CONFIGURING PHP ========================"
# Config
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.4/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.4/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 20M/" /etc/php/7.4/fpm/php.ini
echo "cgi.fix_pathinfo = 0" >> /etc/php/7.4/fpm/php.ini
echo "date.timezone = \"Europe/Lisbon\"" >> /etc/php/7.4/fpm/php.ini
sed -i "s/user = .*/user = vagrant/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/group = .*/group = vagrant/" /etc/php/7.4/fpm/pool.d/www.conf

# Nginx
echo "==================== INSTALLING NGINX ====================="
apt-get install -y -q nginx
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
# Dashboard
git clone https://github.com/mripta/dashboard.git
cd dashboard
composer install
cp .env.example .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=root/" .env
php artisan key:generate
php artisan migrate
# Broker
cd ..
git clone https://github.com/mripta/broker.git
cd broker
npm install

# Restart Services
echo "=================== RESTARTING SERVICES ===================="
systemctl daemon-reload
systemctl restart mongod
systemctl restart mysql
systemctl restart php7.4-fpm
systemctl restart nginx

echo "========================== VERSIONS ========================"
echo "NPM " `npm -v`
echo "PHP " `php -v | head -n 1`
echo "YARN " `yarn --version`
echo "MySQL " `mysql --version | head -n 1`
echo "NODEJS " `nodejs -v`
echo "MongoDB " `mongod --version | head -n 1`
echo "============================== :) ==========================="