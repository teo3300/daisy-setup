#/usr/bin/env sh

## This file is used to copy the current state into git

source ~/.env

if [ -z $GITDUMP_TARGET ]; then
  echo define \$GITDUMP_TARGET as target git root
  exit 1
fi
GITREPO=$GITDUMP_TARGET

# Main compose
cp docker-compose.yml $GITREPO/

# Sytemd timer and service for dns (now using crontab)
# cp archived/dnsupdate.{service,timer} $GITREPO/archived/

# Crontab conf file
cp crontab $GITREPO/

# Script used to update dns recordsd
cp dnsup.sh $GITREPO/

# Small script to generate a random key to use in docker variables
cp docker/addkey $GITREPO/docker/

# Traefik config (now switching to nginx
cp traefik/* $GITREPO/traefik/

# Nginx config
cp nginx/* $GITREPO/nginx/

# Scripts to create a wireguard interface
cp wireguard/setup_{client,server} $GITREPO/wireguard/

# Tmux configuration
cp .tmux.conf $GITREPO/

# This file
cp gitdump.sh $GITREPO/
