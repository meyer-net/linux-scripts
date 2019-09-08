#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

#---------- SYS ---------- {
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

NVM_PATH=~/.nvm/nvm.sh
CURRENT_USER=`whoami`
#---------- SYS ---------- }

#---------- DIR ---------- {
DOWN_DIR=/tmp

# 默认找最大的磁盘
MOUNT_DIR=$(df -k | awk '{print $2}' | awk '{if (NR>2) {print}}' | awk 'BEGIN {max = 0} {if ($1+0 > max+0) {max=$1 ;content=$0} } END {print content}' | xargs -I {} sh -c 'df -k | grep "$1" | awk "{print \$NF}"' -- {})
MOUNT_DIR=${MOUNT_DIR:-"/clouddisk"}/work
SETUP_DIR=/opt
DEFAULT_DIR=/home/$CURRENT_USER/default
ATT_DIR=$MOUNT_DIR/attach
DATA_DIR=$MOUNT_DIR/data
LOGS_DIR=$MOUNT_DIR/logs

MYCAT_DIR=$SETUP_DIR/mycat

SUPERVISOR_CONF_ROOT=$ATT_DIR/supervisor

SYNC_DIR=$MOUNT_DIR/svr_sync
WWW_DIR=$SYNC_DIR/wwwroot
APP_DIR=$SYNC_DIR/applications
BOOT_DIR=$SYNC_DIR/boots
PRJ_DIR=$WWW_DIR/prj/www
OR_DIR=$PRJ_DIR/or
PY_DIR=$PRJ_DIR/py
HTML_DIR=$PRJ_DIR/html
NGINX_DIR=$PRJ_DIR/nginx
DOCKER_DIR=$DATA_DIR/docker

JAVA_HOME=$SETUP_DIR/java
#---------- DIR ---------- }

#---------- SYSTEM ---------- {
MAJOR_VERSION=`grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | cut -d "." -f1`
LOCAL_TIME=`date +"%Y-%m-%d %H:%M:%S"`
#---------- SYSTEM ---------- }

#---------- HARDWARE ---------- {
#主机名称
SYS_NAME=`hostname`

# 系统位数
CPU_ARCHITECTURE=`lscpu | awk NR==1 | awk -F' ' '{print $NF}'`

# 系统版本
OS_VERSION=`cat /etc/redhat-release | awk -F'release' '{print $2}' | awk -F'.' '{print $1}' | awk -F' ' '{print $1}'`

# 处理器核心数
PROCESSOR_COUNT=`cat /proc/cpuinfo | grep "processor"| wc -l`

# 空闲内存数
MEMORY_FREE=`awk '($1 == "MemFree:"){print $2/1048576}' /proc/meminfo`

# GB -> BYTES
MEMORY_GB_FREE=${MEMORY_FREE%.*}

# 本机IP
# NET_HOST=`ping -c 1 -t 1 enginx.net | grep 'PING' | awk '{print $3}' | sed 's/[(,)]//g'`
NET_HOST=`curl -s icanhazip.com | awk 'NR==1'`

# NR==1 第一行
LOCAL_IPV4="$NET_HOST"
LOCAL_IPV6="$NET_HOST"
#ip addr | grep "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*/[0-9]*.*brd" | awk '{print $2}' | awk -F'/' '{print $1}' | awk 'END {print}'
LOCAL_HOST=`ip a | grep inet | grep -v inet6 | grep -v 127 | grep -v docker | awk '{print $2}' | awk -F'/' '{print $1}' | awk 'END {print}'`
LOCAL_ID=`echo \${LOCAL_HOST##*.}`
#---------- HARDWARE ---------- }

CHOICE_CTX="x"
TMP_SPLITER="------------------------------------------------------"
TMP_SPLITER_LEN=${#TMP_SPLITER}-2

function echo_title()
{
    # Make sure only root can run our script
    [[ $EUID -ne 0 ]] && echo -e "[${red}Error${reset}] This script must be run as root!" && exit 1

    # Clear deleted
    kill_deleted
    
	clear
    TMP_FILL_RIGHT_TITLE_FORMAT="|${green}%${reset}|"
    TMP_FILL_RIGHT_ITEM_FORMAT="|%|"

    echo $TMP_SPLITER
    echo_fill_right "Function Boots Of Centos7" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_TITLE_FORMAT
    echo_fill_right "Copy Right Meyer - http://www.thiskpi.com" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_TITLE_FORMAT
    echo $TMP_SPLITER
    
    echo_fill_right "System Name: $SYS_NAME" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "OS Version: CentOS.$OS_VERSION" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "Localhost: $LOCAL_HOST($LOCAL_ID)" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "IpV4: $LOCAL_IPV4" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "IpV6: $LOCAL_IPV6" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "Processor: $PROCESSOR_COUNT" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "FreeMemory: ${MEMORY_GB_FREE}GB" "" $TMP_SPLITER_LEN $TMP_FILL_RIGHT_ITEM_FORMAT

    return $?
}