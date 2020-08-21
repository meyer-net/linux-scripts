#!/bin/sh

#####################################################################
# usage:
# sh reload.sh -- reload application @dev
# sh reload.sh ${env} -- reload application @${env}

# examples:
# sh reload.sh prod -- use conf/nginx-prod.conf to reload Nginx
# sh reload.sh -- use conf/nginx-dev.conf to reload Nginx
#####################################################################

mkdir -p logs & mkdir -p tmp
nginx -s reload -p `pwd`/ -c conf/nginx.conf
