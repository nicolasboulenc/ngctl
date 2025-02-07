#!/bin/bash

export NGCTL_INSTALL=~/.ngctl/
export NGCTL_ENABLED=~/.ngctl/sites-enabled/
export NGCTL_AVAILABLE=~/.ngctl/sites-available/
export NGCTL_LOG=~/.ngctl/log/

case ":$PATH:" in
    *:"$NGCTL_INSTALL":*)
        ;;
    *)
        export PATH="$NGCTL_INSTALL:$PATH"
        ;;
esac