# ngctl 

## Table of Contents

- [Intro](#Intro)
- [Installation](#Installation)
- [Usage](#Usage)
- [Todo](#Todo)
- [License](#License)


## Intro

`ngctl` allows you to quickly manage NGINX servers via the command line.


## Installation 

Run as root
```sh
sudo ln -s /home/nicolas/dev/ngctl/ngctl ngctl
```

Run as user 

Make sure user is part of www-data, we'll manage access through the www-data group
```sh
sudo usermod -a -G www-data nicolas
```

Allow ngctl to start and stop nginx
In the /etc/nginx/nginx.conf file change 
```pid /run/nginx.pid;```
to
```pid /var/log/nginx/nginx.pid;```

Give access to relevant folder
```sh
sudo chown -R root:www-data /var/log/nginx/
sudo chmod 775 /var/log/nginx/
sudo chmod 664 /var/log/nginx/*
```

Allow ngctl to create, remove and enable/disable servers
Give access to relevant folder
```sh
sudo chown -R root:www-data /etc/nginx/sites-enabled/
sudo chmod 775 /etc/nginx/sites-enabled/
sudo chmod 664 /etc/nginx/sites-enabled/*
sudo chown -R root:www-data /etc/nginx/sites-available/
sudo chmod 775 /etc/nginx/sites-available/
sudo chmod 664 /etc/nginx/sites-available/*
```

Add this to your .bashrc file
```sh
export NGCTL_INSTALL="$HOME/dev/ngctl"
export PATH="$NGCTL_INSTALL:$PATH"
```


## Usage

```sh
$ ngctl start
location enabled: /home/nicolas/dev/ngctl/
 --> http://localhost:8080/
$ ngctl version
v16.9.1
```
Simple as that!


## Todo

- check for requirement (awk, nginx, /etc/nginx/sites-available, /etc/nginx/sites-enabled, systemctl)
- implement nginx_safe_start
- implement nginx_conf_is_valid
- remove systemctl, awk and head dependencies
- allow for ssl template
    - sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./nginx-selfsigned.key -out ./nginx-selfsigned.crt
- allow for php template
- implemet ngctl del
- try to add an include with different path in the nginx.conf file, so we dont have to manage access so much

## License

See [LICENSE.md](./LICENSE.md).
