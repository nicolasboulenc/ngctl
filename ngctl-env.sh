#!/bin/bash

NGCTL_INSTALL=~/.ngctl/
NGCTL_ENABLED=~/.ngctl/sites-enabled/
NGCTL_AVAILABLE=~/.ngctl/sites-available/
NGCTL_LOG=~/.ngctl/log/

case ":$PATH:" in
    *:"$NGCTL_INSTALL":*)
        ;;
    *)
        export PATH="$NGCTL_INSTALL:$PATH"
        ;;
esac