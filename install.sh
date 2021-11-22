#!/bin/bash

sudo apt update
sudo apt install python3-pip virtualenv
python3 -m pip install --upgrade pip

sudo cp apache2/php-fpm/* /usr/local/hestia/data/templates/web/apache2/php-fpm/
sudo chmod +x /usr/local/hestia/data/templates/web/apache2/php-fpm/*.sh
sudo cp nginx/* /usr/local/hestia/data/templates/web/nginx/

echo Done
