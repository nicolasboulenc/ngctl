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
