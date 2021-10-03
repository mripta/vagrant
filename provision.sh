#!/bin/bash

# Fix machine time
rm /etc/localtime && ln -s /usr/share/zoneinfo/Europe/Lisbon /etc/localtime

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Add NodeJS repo
curl -s http://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
sudo sh -c "echo deb http://deb.nodesource.com/node_14.x focal main > /etc/apt/sources.list.d/nodesource.list"
#curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Add MongoDB Repo
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

# Add nginx/php PPA's
add-apt-repository ppa:ondrej/php
add-apt-repository ppa:ondrej/nginx

echo "====================== UPDATE & UPGRADE ====================="
apt dist-upgrade -y
apt autoremove -y
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
# Create root user and collections
mongo << 'EOF'
use admin
db.createUser({user:"admin", pwd:"admin", roles:[{role:"root", db:"admin"}]})
use aedes
db.createCollection("persistence")
db.createCollection("publish")
db.createCollection("subscribe")
db.createCollection("logs")
use dashboard
db.createCollection("logs")
EOF
# Add Auth to daemon
sed -i "s/ExecStart=.*/ExecStart=\/usr\/bin\/mongod --auth --config \/etc\/mongod.conf/" /lib/systemd/system/mongod.service
# Expose
sed -i "s/  bindIp.*/  bindIp: 0.0.0.0/" /etc/mongod.conf

# INSTALL NODE & YARN
echo "==================== INSTALLING NODEJS ====================="
apt-get install -y -q nodejs yarn openssl libssl-dev

# PHP 7.4
echo "==================== INSTALLING PHP 7.4 ====================="
apt-get install -y php7.4-fpm php7.4-common php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php-mongodb unzip
echo "==================== CONFIGURING PHP ========================"
# Config
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.4/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.4/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 20M/" /etc/php/7.4/fpm/php.ini
echo "cgi.fix_pathinfo = 0" >> /etc/php/7.4/fpm/php.ini
echo "date.timezone = \"Europe/Lisbon\"" >> /etc/php/7.4/fpm/php.ini
sed -i "s/user = .*/user = vagrant/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/group = .*/group = vagrant/" /etc/php/7.4/fpm/pool.d/www.conf

# Install mongodb php extension
pecl install mongodb
echo "extension=mongodb.so" >> /etc/php/7.4/fpm/php.ini

# Install composer
echo "==================== INSTALLING COMPOSER ===================="
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
# php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Nginx
echo "==================== INSTALLING NGINX ====================="
apt-get install -y -q nginx
echo "==================== CONFIGURING NGINX ===================="
cp /vagrant/nginx-default.conf /etc/nginx/conf.d/default.conf

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
echo "NODEJS " `node -v`
echo "MongoDB " `mongod --version | head -n 1`
echo "============================== :) ==========================="