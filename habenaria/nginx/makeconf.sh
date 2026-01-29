#!/usr/bin/env bash

# You must list here what variables to substitute (to avoid breaking regex)

envsubst\
  '${SERVER_DOMAIN}'\
  < /etc/nginx/template-nginx.conf > /etc/nginx/nginx.conf
