#!/bin/bash

# if NGCTL_INSTALL was not loaded with .bashrc / ngctl-env.sh, try to load it locally
if [ -z $NGCTL_INSTALL ]; then
    source ./ngctl-env.sh
fi
# if NGCTL_INSTALL still wasnt found exit
if [ -z $NGCTL_INSTALL ]; then
    echo "Error: unable to load ngctl-env.sh!"
    exit 1
fi

# Create folders structure and copy files
[ ! -d "$NGCTL_INSTALL" ] && mkdir "$NGCTL_INSTALL"
[ ! -d "$NGCTL_ENABLED" ] && mkdir "$NGCTL_ENABLED"
[ ! -d "$NGCTL_AVAILABLE" ] && mkdir "$NGCTL_AVAILABLE"
[ ! -d "$NGCTL_LOG" ] && mkdir "$NGCTL_LOG"

if [ ! -d "$NGCTL_INSTALL" ]; then
    echo "Error: unable to create install folder!"
    exit 1
fi

cp -f ngctl "$NGCTL_INSTALL"
cp -f ngctl-env.sh "$NGCTL_INSTALL"
cp -f ngctl-install.sh "$NGCTL_INSTALL"
cp -f ngctl-uninstall.sh "$NGCTL_INSTALL"
cp -f LICENSE.md "$NGCTL_INSTALL"

# Update .bashrc
cp -f ~/.bashrc ~/.bashrc.backup
# sed -i "/.*NGCTL_.*/D" ~/.bashrc
sed -i "/.*ngctl-env.*/D" ~/.bashrc

# printf "export NGCTL_INSTALL=$NGCTL_INSTALL\n" >> ~/.bashrc
# printf "export NGCTL_ENABLED=$NGCTL_ENABLED\n" >> ~/.bashrc
# printf "export NGCTL_AVAILABLE=$NGCTL_AVAILABLE\n" >> ~/.bashrc
# printf "export NGCTL_LOG=$NGCTL_LOG\n" >> ~/.bashrc
# printf "export PATH=\"\$NGCTL_INSTALL:\$PATH\"\n" >> ~/.bashrc

printf "[ -f \"${NGCTL_INSTALL}ngctl-env.sh\" ] && source \"${NGCTL_INSTALL}ngctl-env.sh\"\n"  >> ~/.bashrc

# Update nginx.conf
if [ -f /run/nginx.pid ]; then
    sudo nginx -s stop
fi
if [ -f ${NGCTL_INSTALL}nginx.pid ]; then
    nginx -s stop
fi
sudo cp -f /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
# Comment the user directive as nginx will be launched as the user
sudo sed -i -e "s/user /#user /" /etc/nginx/nginx.conf
# Move the pid file to install
sudo sed -i -e "s#pid .*#pid ${NGCTL_INSTALL}nginx.pid;#" /etc/nginx/nginx.conf
# Include ngctl location for server files
sudo sed -i -e "s#include /etc/nginx/sites-enabled/\*#include $NGCTL_ENABLED*#" /etc/nginx/nginx.conf

# Change log files to install logs
#   For some reason changing log files location seem impossible, maybe a default is builtin at compile time?
#   Changing error_log in the nginx.conf file for another path doesnt seem to work
#   Changing error_log in the nginx.conf file to /dev/null
#   Using -c command line with a seperate conf file doesnt seem to work either
#   Using -e command line might be an option although only availabe in version 1.19.x
# sudo sed -i -e "s#access_log .*#access_log ${NGCTL_LOG}access.log;#" /etc/nginx/nginx.conf
# sudo sed -i -e "s#error_log .*#error_log ${NGCTL_LOG}error.log;#" /etc/nginx/nginx.conf
# sudo sed -i -e "s#error_log .*#error_log /dev/null;#" /etc/nginx/nginx.conf
# Move the log files to install logs

# This is an alternative whilst I find a way to resolve the error_log issue
sudo chmod 666 /var/log/nginx/*

# Check nginx config
nginx -t

# User has to do this in order 
echo "Info: Run \"source ~/.bashrc\" in order for changes to take effect."
