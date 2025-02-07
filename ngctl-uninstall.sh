#!/bin/bash

source ./ngctl-env.sh

# Recover .bashrc
if [ -f ~/.bashrc.realbackup ]; then 
    sudo cp -f ~/.bashrc.realbackup ~/.bashrc
else
    echo "Info: Unable to recover ~/.bashrc.realbackup\n"
fi
# try to reverse changes rather than recover a backup which might not be recent
# sed -i "/.*NGCTL_.*/D" ~/.bashrc

# Recover nginx.conf
if [ -f /etc/nginx/nginx.conf.realbackup ]; then 
    sudo cp -f /etc/nginx/nginx.conf.realbackup /etc/nginx/nginx.conf
else
    echo "Info: Unable to recover /etc/nginx/nginx.conf.realbackup\n"
fi

if [ -d $NGCTL_INSTALL ]; then 
    rm -R $NGCTL_INSTALL
else
    echo "Info: Install folder not found $NGCTL_INSTALL"
fi

