#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------

#---------- SYS ---------- {
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

SETUP_DIR=/opt
# NVM_PATH=~/.nvm/nvm.sh
NVM_PATH=${SETUP_DIR}/nvm/nvm.sh
CURRENT_USER=`whoami`
#---------- SYS ---------- }

#---------- DIR ---------- {
DOWN_DIR=/tmp/downloads
RPMS_DIR=${DOWN_DIR}/rpms
REPO_DIR=/etc/yum.repos.d
CURL_DIR=${DOWN_DIR}/curl

# 默认找最大的磁盘 
# MOUNT_ROOT=$(df -k | awk '{print $2}' | awk '{if (NR>2) {print}}' | awk 'BEGIN {max = 0} {if ($1+0 > max+0) {max=$1 ;content=$0} } END {print content}' | xargs -I {} sh -c 'df -k | grep "$1" | awk "{print \$NF}" | cut -c2' -- {})
# 默认认可第一个挂载的磁盘为数据盘
# 修复PVE挂载盘后规则不一样，出现默认sdb，新增sda的情况
FDISK_L_SYS_DEFAULT=`fdisk -l | grep '^/dev/' | awk -F' ' '{print \$1}' | awk 'NR==1' | tr -d '0-9'  | awk -F'/' '{print \$NF}'`
LSBLK_DISKS_STR=`lsblk | grep "0 disk" | grep -v "^${FDISK_L_SYS_DEFAULT}" | awk 'NR==1{print \$1}' | xargs -I {} echo '/dev/{}'`
LSBLK_MOUNT_ROOT=`df -h | grep ${LSBLK_DISKS_STR:-":"} | awk -F' ' '{print \$NF}'`
if [ "${LSBLK_MOUNT_ROOT}" == "/" ]; then
    LSBLK_MOUNT_ROOT=
fi

MOUNT_ROOT=${LSBLK_MOUNT_ROOT:-"/mountdisk"}
MOUNT_DIR=${MOUNT_ROOT}
DEFAULT_DIR=/home/${CURRENT_USER}/default
ATT_DIR=${MOUNT_DIR}/etc
DATA_DIR=${MOUNT_DIR}/data
LOGS_DIR=${MOUNT_DIR}/logs

CRTB_LOGS_DIR=${LOGS_DIR}/crontab
SYNC_DIR=${MOUNT_DIR}/svr_sync
WWW_DIR=${SYNC_DIR}/wwwroot
WWW_INIT_DIR=${WWW_DIR}/init
APP_DIR=${SYNC_DIR}/applications
PYA_DIR=${APP_DIR}/py
BOOT_DIR=${SYNC_DIR}/boots
PRJ_DIR=${WWW_DIR}/prj/www
OR_DIR=${PRJ_DIR}/or
PY_DIR=${PRJ_DIR}/py
JV_DIR=${PRJ_DIR}/java
HTML_DIR=${PRJ_DIR}/html
NGINX_DIR=${BOOT_DIR}/nginx
DOCKER_DIR=${DATA_DIR}/docker

JAVA_HOME=${SETUP_DIR}/java
MYCAT_DIR=${SETUP_DIR}/mycat
PY_PKGS_SETUP_DIR=${SETUP_DIR}/python_packages
PY3_PKGS_SETUP_DIR=${SETUP_DIR}/python3_packages
SUPERVISOR_ATT_DIR=${ATT_DIR}/supervisor

CDY_API_PORT=12019
#---------- DIR ---------- }

CHOICE_CTX="x"
TMP_SPLITER="------------------------------------------------------"
TMP_FILL_RIGHT_TITLE_FORMAT="|${green}%${reset}|"
TMP_FILL_RIGHT_ITEM_FORMAT="|%|"

function echo_title()
{
    # Make sure only root can run our script
    [[ $EUID -ne 0 ]] && echo -e "[${red}Error${reset}] This script must be run as root!" && exit 1

    # 路径转化
    convert_path "NVM_PATH"

    # Clear deleted
    kill_deleted

    echo "Current script __dir：${__DIR}"
    echo "Current script __file：${__FILE}"
    echo "Current script __conf：${__CONF}"
    
	clear

    local TMP_SPLITER_LEN=${#TMP_SPLITER}-2

    echo ${TMP_SPLITER}
    echo_fill_right "Function Boots Of Centos7" "" ${TMP_SPLITER_LEN} ${TMP_FILL_RIGHT_TITLE_FORMAT}
    echo_fill_right "Copy Right Meyer - http://www.epudev.com" "" ${TMP_SPLITER_LEN} ${TMP_FILL_RIGHT_TITLE_FORMAT}
    echo ${TMP_SPLITER}
    
    echo_fill_right "System Name: ${SYS_NAME}" "" ${TMP_SPLITER_LEN} $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "Product Name: ${SYS_PRODUCT_NAME}(${SYSTEMD_DETECT_VIRT})" "" ${TMP_SPLITER_LEN} $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "OS Version: CentOS.${OS_VERS}" "" ${TMP_SPLITER_LEN} $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "Localhost: ${LOCAL_HOST}(${LOCAL_ID})" "" ${TMP_SPLITER_LEN} $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "IpV4: ${LOCAL_IPV4}" "" ${TMP_SPLITER_LEN} $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "IpV6: ${LOCAL_IPV6}" "" ${TMP_SPLITER_LEN} $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "Processor: ${PROCESSOR_COUNT}" "" ${TMP_SPLITER_LEN} $TMP_FILL_RIGHT_ITEM_FORMAT
    echo_fill_right "FreeMemory: ${MEMORY_GB_FREE}GB" "" ${TMP_SPLITER_LEN} $TMP_FILL_RIGHT_ITEM_FORMAT

    return $?
}