# HestiaCP Python 3 templates

## Careful! This is still in development and will probably break your server.

Python templates for [HestiaCP](https://www.hestiacp.com/).

This project was originally based on the work done by [anton-bozhina](https://github.com/anton-bozhina) and [refsigregory](https://github.com/refsigregory/vestacp-python-template/commits?author=refsigregory). However, a new approach has been taken.

## Disclaimer

1. This code comes without warranty of any kind. Please refer to `README.md` for more details about this and the license to which this software is bounded. 
2. All this is still in experimental stage.
3. These templates will install application **in debug mode and without database connection**. Is therefore your responsibility to complete the configuration process and make the app safe.

## Requirements

- HestiaCP
- Python 3.6.X (you can check your Python version using `python3 --version`)

I presume it can be adapted to VestaCP after small modifications.

## Tested with

- [X] HestiaCP 1.1.1
- [X] Ubuntu 18.04
- [X] Python 3.6.9


If you have tested it with a different version or different distro, feel free to contact me to provide feedback.

## Instructions for Ubuntu:

1. __Make sure you have an updated backup of your system and that it can go into maintenance if necessary__.
2. Install `pip3`, `virtualenv`, and their dependencies:
```bash
sudo apt update
sudo apt install python3-pip virtualenv
python3 -m pip install --upgrade pip
sudo apt install python3.12-venv
```

3. Download the templates to the correct location:

- Apache2 templates goes into `/usr/local/hestia/data/templates/web/apache2/php-fpm/`
- Chage he permissions to `.sh` files using the command `chmod +x *.sh` in the `/usr/local/hestia/data/templates/web/apache2/php-fpm/` folder.
- NGINX templates goes into `/usr/local/hestia/data/templates/web/nginx/`

4. Activate the template NGINX proxy template

5. Activate the desired Apache2 template. It is recommended to set the backend template to `no-php`.

6. Complete the setup process of the terminal. This includes setting up the database, adding the users, disabling the debug/setting environment to production, modifying the allowed hosts, and so on.
