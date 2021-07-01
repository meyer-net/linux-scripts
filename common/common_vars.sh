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

# 默认找最大的磁盘  ??? 优化为自动识别是否存在未挂载大磁盘 
MOUNT_DIR=$(df -k | awk '{print $2}' | awk '{if (NR>2) {print}}' | awk 'BEGIN {max = 0} {if ($1+0 > max+0) {max=$1 ;content=$0} } END {print content}' | xargs -I {} sh -c 'df -k | grep "$1" | awk "{print \$NF}" | cut -c2' -- {})
MOUNT_DIR=${MOUNT_DIR:-"/mountdisk"}/work
SETUP_DIR=/opt
DEFAULT_DIR=/home/${CURRENT_USER}/default
ATT_DIR=${MOUNT_DIR}/attach
DATA_DIR=${MOUNT_DIR}/data
LOGS_DIR=${MOUNT_DIR}/logs

SYNC_DIR=${MOUNT_DIR}/svr_sync
WWW_DIR=${SYNC_DIR}/wwwroot
APP_DIR=${SYNC_DIR}/applications
BOOT_DIR=${SYNC_DIR}/boots
PRJ_DIR=${WWW_DIR}/prj/www
OR_DIR=${PRJ_DIR}/or
PY_DIR=${PRJ_DIR}/py
HTML_DIR=${PRJ_DIR}/html
NGINX_DIR=${PRJ_DIR}/nginx
DOCKER_DIR=${DATA_DIR}/docker

JAVA_HOME=${SETUP_DIR}/java
MYCAT_DIR=${SETUP_DIR}/mycat
SUPERVISOR_ATT_DIR=${ATT_DIR}/supervisor
#---------- DIR ---------- }

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