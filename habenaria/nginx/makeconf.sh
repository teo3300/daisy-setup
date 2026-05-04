#!/usr/bin/env bash

# TODO: Check 20_envsubst_on_template

# COUNTRY_WHITELIST="US NL ..."
# Whitelist countries
COUNTRIES=""
for c in $COUNTRY_WHITELIST; do
    COUNTRIES+="$c 0; "
done
export COUNTRY_WHITELIST=$COUNTRIES

# Ugly ass templated macros
export GEOBLOCK='if ($geo_block) { return 444; }'

export PASSWORD='auth_basic "Password protected"; auth_basic_user_file /etc/nginx/.htpasswd;'

TOTP_SECRET=$(head -c 20 /dev/urandom | base64)
export TOTP="auth_totp_cookie \"nginx-totp\"; auth_totp_expiry 30m; auth_totp_file /etc/nginx/totp.conf; auth_totp_realm \"TOTP Protected\"; auth_totp_secret \"${TOTP_SECRET}\";"

# You must list here what variables to substitute (to avoid breaking regex)

envsubst\
  '${SERVER_DOMAIN} ${COUNTRY_WHITELIST} ${GEOBLOCK} ${WG_NET} ${PASSWORD} ${TOTP}'\
  < /etc/nginx/template-nginx.conf > /etc/nginx/nginx.conf
