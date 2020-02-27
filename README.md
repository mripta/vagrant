# Vagrant
![GitHub issues](https://img.shields.io/github/issues/mripta/vagrant)
![GitHub pull requests](https://img.shields.io/github/issues-pr/mripta/vagrant)

## Description
This repository will setup a development environment for the [MRIPTA](https://github.com/mripta) project. It is using the [bionic64](https://app.vagrantup.com/ubuntu/boxes/bionic64) base image and then running the [script.sh](https://github.com/mripta/vagrant/blob/master/script.sh) to install and configure all the required services and proceed with the deployment.

## Services 
The services versions installed in this image was carefully selected to be as close possible to the ones running on the production server.
* Ubuntu 18.04 LTS
* PHP 7.4
* NodeJS 12.16 LTS
* NPM 6.13
* MongoDB 4.2
* MySQL 5.7
* Nginx 1.16
* YARN 1.21

## Access Data
* MongoDB <br>
Username: `admin` <br>
Password: `admin`
* MySQL <br>
Username: `root` <br>
Password: `root`

## Port Mapping
| Host | Guest | Service |
| ---- | ----- | ------- |
|  80  |  80   |  HTTP   |
| 1883 | 1883  |  MQTT   |
| 3306 | 3306  |  MySQL  |
| 8888 | 8888  |WebSocket|
|27017 | 27017 | MongoDB |

## Dashboard
[Dashboard Repository](https://github.com/mripta/dashboard)

## Broker
[Broker Repository](https://github.com/mripta/broker) <br>
The broker script is running inside a `screen` with `nodemon` constantly checking for new file changes and consequently restarting the process to load them.

### screen
To list the screen processes <br>
`screen -ls` <br>
Attach <br>
`screen -r` <br>
Detach <br>
`CTRL + A D` <br>
Create a new broker session <br>
`screen -dmS broker nodemon -L index.js`
