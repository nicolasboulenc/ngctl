# NGINX Site Manager 

## Table of Contents

- [Intro](#intro)
- [License](#license)


## Intro

`ngctl` allows you to quickly manage sites on NGINX via the command line.


## Installation 

Run as root
```sh
sudo ln -s /home/nicolas/dev/ngctl/ngctl.sh ngctl.sh
```

Run as user (make sure user is part of www-data)
```sh
sudo chown -R root:www-data /etc/nginx/sites-enabled/
sudo chmod 775 /etc/nginx/sites-enabled/
sudo chmod 664 /etc/nginx/sites-enabled/*
sudo chown root:www-data /var/log/nginx/
sudo chmod 775 /var/log/nginx/
```

In the /etc/nginx/nginx.conf file change 
```pid /run/nginx.pid;```
to
```pid /var/log/nginx/nginx.pid;```

Add this to your .bashrc file
```sh
export NGCTL_INSTALL="$HOME/dev/ngctl"
export PATH="$NGCTL_INSTALL:$PATH"
```

**Example:**
```sh
$ ngctl start
location enabled: /home/nicolas/dev/ngctl/
 --> http://localhost:8080/
$ ngctl version
v16.9.1
```

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./nginx-selfsigned.key -out ./nginx-selfsigned.crt

Simple as that!

## License

See [LICENSE.md](./LICENSE.md).
