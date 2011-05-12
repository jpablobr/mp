#!/usr/bin/env bash

# From http://freelancing-gods.com/posts/script_nginx

echo "Starting Phusion Passenger via Nginx in `pwd`:"

# Make directories if needed
[ ! -d `pwd`/tmp ] && mkdir `pwd`/tmp
[ ! -d `pwd`/logs ] && mkdir `pwd`/logs

/opt/nginx/sbin/nginx -p `pwd`/ -c ~/.nginx-dir.conf -g "error_log `pwd`/logs/nginx.error.log; pid `pwd`/logs/nginx.pid;";
