#!/bin/bash
export NGCTL_DEV=1

if [$NGCTL_DEV -eq 0]; then
    export NGCTL_INSTALL=~/.ngctl/
else
    export NGCTL_INSTALL=~/dev/ngctl/
fi

export NGCTL_ENABLED="${NGCTL_INSTALL}"sites-enabled/
export NGCTL_AVAILABLE="${NGCTL_INSTALL}"sites-available/
export NGCTL_LOG="${NGCTL_INSTALL}"log/

case ":$PATH:" in
    *:"$NGCTL_INSTALL":*)
        ;;
    *)
        export PATH="$NGCTL_INSTALL:$PATH"
        ;;
esac