#!/bin/sh

#####################################################################
# usage:
# sh stop.sh -- stop application @dev
# sh stop.sh ${env} -- stop application @${env}

# examples:
# sh stop.sh prod -- use conf/nginx-prod.conf to stop Nginx
# sh stop.sh -- use conf/nginx-dev.conf to stop Nginx
#####################################################################

mkdir -p logs & mkdir -p tmp
nginx -s stop -p `pwd`/ -c conf/nginx.conf
