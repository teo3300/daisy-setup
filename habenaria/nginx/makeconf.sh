#!/usr/bin/env bash

# COUNTRY_WHITELIST="US NL ..."
# Whitelist countries
COUNTRIES=""
for c in $COUNTRY_WHITELIST; do
    COUNTRIES+="$c 0; "
done

export COUNTRY_WHITELIST=$COUNTRIES

# Ugly ass templated macros
export GEOBLOCK='if ($geo_block) { return 444; }'

export PASSWORD='auth_basic "Protected"; auth_basic_user_file /etc/nginx/.htpasswd;'

# You must list here what variables to substitute (to avoid breaking regex)

envsubst\
  '${SERVER_DOMAIN} ${COUNTRY_WHITELIST} ${GEOBLOCK} ${WG_NET} ${PASSWORD}'\
  < /etc/nginx/template-nginx.conf > /etc/nginx/nginx.conf
