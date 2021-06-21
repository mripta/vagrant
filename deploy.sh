#!/bin/bash

# Deploy
echo "========================= DEPLOY ==========================="
cd /vagrant
# Dashboard
git clone https://github.com/mripta/dashboard.git
cd dashboard
composer install --ignore-platform-reqs
cp .env.example .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=root/" .env
php artisan key:generate
php artisan migrate
php artisan db:seed
# Broker
cd ..
git clone https://github.com/mripta/broker.git
cd broker
cp .env.example .env
yarn global add nodemon
yarn install
# Start the MQTT broker
screen -dmS broker nodemon -L index.js