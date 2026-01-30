#!/bin/zsh

# Disable glob to avoid wildcard expantion
set -f

source $HOME/.env
if [ -z "$SERVER_DOMAIN" ]; then
  echo specify at least one domain in \$SERVER_DOMAIN
  exit 1
fi

if [ -z "$SERVER_SUBDOMAINS" ]; then
  echo You can specify the subdomains in \$SERVER_SUBDOMAINS
fi

# Stop nginx if running
docker container stop nginx
docker container rm nginx

echo Creating cert for: $SERVER_DOMAIN
SERVER_SUBDOMAIN="$SERVER_DOMAIN" docker compose up certbot-new

for SUBDOMAIN in ${(s: :)SERVER_SUBDOMAINS}; do
  echo Creating cert for: $SUBDOMAIN.$SERVER_DOMAIN
  SERVER_SUBDOMAIN="$SUBDOMAIN.$SERVER_DOMAIN" docker compose up certbot-new
done

docker compose up -d nginx
