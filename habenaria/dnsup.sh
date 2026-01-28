#!/bin/sh

# Disable glob to avoid wildcard expantion
set -f

BASE_LINK='https://dynamicdns.park-your-domain.com'
HOSTS='@ *'

source $HOME/.env
if [ -z $SERVER_DOMAIN ]; then
  echo specify at least one domain in \$SERVER_DOMAIN
  exit 1
fi

if [ -z $DNSUP_PASSWORD ]; then
  echo specify the password for DNS record update in \$DNSUP_PASSWORD
  exit 1
fi

for HOST in ${(s: :)HOSTS}; do
  curl "$BASE_LINK/update?host=$HOST&domain=$SERVER_DOMAIN&password=$DNSUP_PASSWORD"
done
