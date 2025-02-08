#!/bin/bash

# if NGCTL_INSTALL was not loaded with .bashrc / ngctl-env.sh, try to load it locally
if [ -z $NGCTL_INSTALL ]; then
    source ./ngctl-env.sh
fi
# if NGCTL_INSTALL still wasnt found exit
if [ -z $NGCTL_INSTALL ]; then
    echo "Error: unable to find install folder, you need to run this script from its folder!"
    exit 1
fi

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

if [ $NGCTL_DEV -eq 0 ]; then
    if [ -d $NGCTL_INSTALL ]; then 
        rm -R $NGCTL_INSTALL
    else
        echo "Info: Install folder not found $NGCTL_INSTALL"
    fi
fi

echo "Info: Uninstall complete.\n"
