#!/bin/bash
# Adding php wrapper
user="$1"
domain="$2"
ip="$3"
#/home
home_dir="$4"
#Full route to /public_html
docroot="$5"


workingfolder="/home/$user/web/$domain"

cd $workingfolder


if [ ! -f "$workingfolder/.remove_to_reinstall_django" ]; then
    # this is new project, setup example page

    virtualenv -p python3 venv
    source venv/bin/activate

    mkdir /home/admin/web/test.gorlik.pl/djangoapp/
    touch /home/$user/web/$domain/djangoapp/requirements.txt
    echo "Django==3.2.9">> /home/$user/web/$domain/djangoapp/requirements.txt
    pip install gunicorn psycopg2-binary
    pip install -r /home/$user/web/$domain/djangoapp/requirements.txt

    cd djangoapp
    django-admin startproject djangoapp .
    ./manage.py makemigrations
    ./manage.py migrate

    chown $user:$user db.sqlite3
    chown $user:$user manage.py
    chown $user:$user requirements.txt
    chown -R $user:$user djangoapp

    echo "
STATIC_ROOT = BASE_DIR / 'static'
" >> $workingfolder/djangoapp/djangoapp/settings.py
    ./manage.py collectstatic

    # update hostname
    sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \['$domain'\]/" "$workingfolder/djangoapp/djangoapp/settings.py"
    
    cd ..
    chown -R $user:$user venv
    chown -R $user:$user djangoapp

else
# This is normal project load it normally

source venv/bin/activate

# get djangoapp_name
djangoapp_name="djangoapp"
if [ -f "$workingfolder/djangoapp_name.txt" ]; then
    djangoapp_name=$(cat "$workingfolder/djangoapp_name.txt")
    # TODO check is that path exist and prevent path traversial
fi

# try install requirements
if [ -f "$workingfolder/djangoapp/requirements.txt" ]; then
    pip install -r /home/$user/web/$domain/djangoapp/requirements.txt
fi

# ForceInstall Gunicorn
pip install gunicorn psycopg2-binary

cd $djangoapp_name
./manage.py makemigrations
./manage.py migrate

chown $user:$user db.sqlite3
chown $user:$user manage.py
chown $user:$user requirements.txt
chown -R $user:$user $djangoapp_name
chown -R $user:$user venv

./manage.py collectstatic

cd ..

fi


# At this stage you can test that it works executing:
# gunicorn -b 0.0.0.0:8000 djangoapp.wsgi:application
# *after* adding your domain to ALLOWED_HOSTS

# This following part adds Gunicorn socket and service,
# and needs to be improved, particularly to allow multiple
# Django applications running in the same server.

# This is intended for Ubuntu. It will require some testing to check how this works
# in other distros.

if [ ! -f "/etc/systemd/system/$domain-gunicorn.socket" ]; then

echo "[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/$domain-gunicorn.sock

[Install]
WantedBy=sockets.target" > /etc/systemd/system/$domain-gunicorn.socket

fi

if [ ! -f "/etc/systemd/system/$domain-gunicorn.service" ]; then

    echo "[Unit]
Description=Gunicorn daemon for $domain
Requires=$domain-gunicorn.socket
After=network.target

[Service]
User=$user
Group=$user
WorkingDirectory=$workingfolder/$djangoapp

ExecStart=$workingfolder/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/$domain-gunicorn.sock -m 007 $djangoapp.wsgi:application

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/$domain-gunicorn.service

fi

systemctl restart $domain-gunicorn.socket

systemctl start $domain-gunicorn.socket

systemctl enable $domain-gunicorn.socket

# Start the socket
curl --unix-socket /run/$domain-gunicorn.sock localhost

sudo systemctl daemon-reload

sudo systemctl restart gunicorn

exit 0
