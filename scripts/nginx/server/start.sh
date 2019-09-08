#!/bin/sh

#####################################################################
# usage:
# sh start.sh -- start application @dev
# sh start.sh ${env} -- start application @${env}

# examples:
# sh start.sh prod -- use conf/nginx-prod.conf to start Nginx
# sh start.sh -- use conf/nginx-dev.conf to start Nginx
#####################################################################

mkdir -p logs & mkdir -p tmp
nginx -p `pwd`/ -c conf/nginx.conf
