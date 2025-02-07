#!/bin/bash

export NGCTL_INSTALL=/home/nicolas/dev/ngctl/
export NGCTL_ENABLED=/home/nicolas/dev/ngctl/sites-enabled/
export NGCTL_AVAILABLE=/home/nicolas/dev/ngctl/sites-available/
export NGCTL_LOG=/home/nicolas/dev/ngctl/log/

case ":$PATH:" in
    *:"$NGCTL_INSTALL":*)
        ;;
    *)
        export PATH="$NGCTL_INSTALL:$PATH"
        ;;
esac