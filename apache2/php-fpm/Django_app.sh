#!/bin/bash
# Adding php wrapper
user="$1"
domain="$2"
ip="$3"
#/home
home_dir="$4"
#Full route to /public_html
docroot="$5"

# Consts
workingfolder="/home/$user/web/$domain"
RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

CREATE_NEW=0 # 0-false 1-true
appname=""


# Check config file
if [ ! -f "$workingfolder/djangoapp.config" ]; then 
	CREATE_NEW=1
else
	source $workingfolder/djangoapp.config
fi

if [ "$appname" = "" ]; then
	CREATE_NEW=1
fi
if [ $CREATE_NEW = 1 ]; then
	echo -e "${BLUE}Create Config file ${NC}"
	echo "appname=djangoapp" > $workingfolder/djangoapp.config
	chown $user:$user $workingfolder/djangoapp.config
	chmod 777 $workingfolder/djangoapp.config
fi

# Load config file
source $workingfolder/djangoapp.config
echo -e "${RED}appname = $appname \n${NC}"


echo -e "${BLUE}Go to $workingfolder ${NC}"
cd $workingfolder


if [ $CREATE_NEW = 1 ]; then
	# this is new project, setup example page
	echo -e "${BLUE}New project ${NC}"
	
	echo -e "${BLUE}Delete venv and djangoapp ${NC}"
	rm -r $workingfolder/venv/
	rm -r $workingfolder/djangoapp/
	
	echo -e "${BLUE}Create venv ${NC}"
	virtualenv -p python3 venv
	source venv/bin/activate
	
	echo -e "${BLUE}create djangoapp folder ${NC}"
	mkdir $workingfolder/djangoapp/

	echo -e "${BLUE}create requirements.txt ${NC}"
	touch $workingfolder/djangoapp/requirements.txt
	echo "Django==3.2.9">> $workingfolder/djangoapp/requirements.txt
	
	echo -e "${BLUE}install requirements.txt ${NC}"
	pip install gunicorn psycopg2-binary
	pip install -r $workingfolder/djangoapp/requirements.txt
	
	echo -e "${BLUE}Setup django project ${NC}"
	cd djangoapp
	django-admin startproject $appname .
	
	echo -e "${BLUE}Patching... ${NC}"
	echo "
STATIC_ROOT = BASE_DIR / 'staticfiles'
" >> $workingfolder/djangoapp/$appname/settings.py
	# update hostname
	sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['$domain'\]/" "$workingfolder/djangoapp/$appname/settings.py"


	echo -e "${BLUE}Preparing... ${NC}"
	./manage.py makemigrations
	./manage.py migrate
	./manage.py collectstatic --no-input > /dev/null


else
	# load project
	echo -e "${BLUE}Load project ${NC}"
	
	echo -e "${BLUE}activate venv ${NC}"
	source venv/bin/activate

	echo -e "${BLUE}install requirements.txt ${NC}"
	pip install gunicorn psycopg2-binary
	pip install -r $workingfolder/djangoapp/requirements.txt
	
	echo -e "${BLUE}Setup django project ${NC}"
	cd djangoapp
	./manage.py makemigrations
	./manage.py migrate

fi



echo -e "${BLUE}Setup permissions ${NC}"
chown -R $user:$user $workingfolder/djangoapp/
chown -R $user:$user $workingfolder/venv/



echo -e "${BLUE}should i create /etc/systemd/system/$domain-gunicorn.socket? ${NC}"
if [ ! -f "/etc/systemd/system/$domain-gunicorn.socket" ]; then
echo "[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/$domain-gunicorn.sock

[Install]
WantedBy=sockets.target" > /etc/systemd/system/$domain-gunicorn.socket
fi


echo -e "${BLUE}should i create /etc/systemd/system/$domain-gunicorn.service? ${NC}"
if [ ! -f "/etc/systemd/system/$domain-gunicorn.service" ]; then
echo "[Unit]
Description=Gunicorn daemon for $domain
Requires=$domain-gunicorn.socket
After=network.target

[Service]
User=$user
Group=$user
WorkingDirectory=$workingfolder/djangoapp
# EnvironmentFile=$workingfolder/djangoapp/.env
ExecStart=$workingfolder/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/$domain-gunicorn.sock -m 007 $appname.wsgi:application

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$domain-gunicorn.service
fi


echo -e "${BLUE}systemctl demaon-reload ${NC}"
sudo systemctl daemon-reload

echo -e "${BLUE}systemctl restart $domain-gunicorn.socket ${NC}"
systemctl restart $domain-gunicorn.socket

echo -e "${BLUE}systemctl start $domain-gunicorn.socket ${NC}"
systemctl start $domain-gunicorn.socket

echo -e "${BLUE}systemctl enable $domain-gunicorn.socket ${NC}"
systemctl enable $domain-gunicorn.socket


Start the socket
echo -e "${BLUE}Jakis curl ${NC}"
curl --unix-socket /run/$domain-gunicorn.sock localhost > /dev/null

echo -e "${BLUE}systemctl demaon-reload ${NC}"
sudo systemctl daemon-reload

echo -e "${BLUE}systemctl restart $domain-gunicorn.service ${NC}"
sudo systemctl restart $domain-gunicorn.service

exit 0
