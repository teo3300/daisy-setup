#!/bin/sh

# Disable glob to avoid wildcard expantion
set -f

source $HOME/.env

IP=$(curl -s ipinfo.io/ip)

# Make sure CLOUDFLARE_DN_IDS are in the same order as
domains=("@" "*")

for ((i=0; i<${#CLOUDFLARE_DNS_IDS[@]}; i++)); do
    id=${CLOUDFLARE_DNS_IDS[$i]}
    name="${domains[$i]}"
    curl -s https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$id \
        -X PUT \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer "$CLOUDFLARE_API_TOKEN \
        -d '{
              "ttl": 3600,
              "name": "'${name}'",
              "type": "A",
              "content": "'${IP}'",
              "proxied": true
           }'\
       | jq 'select (.errors != [])'
done
