#/usr/bin/env sh

GITREPO="git/daisy-setup/habenaria"

cp docker-compose.yml $GITREPO/

cp archived/dnsupdate.{service,timer} $GITREPO/archived/

cp dns/{config,dnsup} $GITREPO/dns/

cp docker/addkey $GITREPO/docker/

cp traefik/* $GITREPO/traefik/

cp wireguard/setup_{client,server} $GITREPO/wireguard/

cp .tmux.conf $GITREPO/

cp gitdump.sh $GITREPO/
