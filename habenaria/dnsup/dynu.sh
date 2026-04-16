#!/bin/sh

# Disable glob to avoid wildcard expantion
set -f

source $HOME/.env

curl -u $DYNU_UN:$DYNU_PW "https://api.dynu.com/nic/update"
