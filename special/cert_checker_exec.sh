#!/bin/sh
####################################################################################
# 使用本脚本，主要针对证书过期操作。默认是按照caddy的证书生成进行的操作
####################################################################################

# SLACK配置信息
SLACK_PATH=`which slack`

#配置RC文件
TMP_CURRENT_RC_FILE_NAME=".cert-checkerrc"

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

# 备份脚本，用于循环目录
# AUTO_CERT_LOCAL_ROOT_DIR="/opt/caddy/data/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory"
# local TMP_AUTO_CERT_LOCAL_DIRS=`ls ${AUTO_CERT_LOCAL_ROOT_DIR}`
# for cert_dir in ${TMP_AUTO_CERT_LOCAL_DIRS[@]}; do
#     echo "---------------------------------------"
# done

# 1：检测证书目录
# 2：每天运行1次
# 3：大于30天，记录MD5，小于30天，对比MD5，开始更新证书并同步。
function exec_program()
{
    local TMP_CURRENT_CHECK_DOMAIN=${1}

    local TMP_CURRENT_CHECK_DOMAIN_END_TIME=$(echo | timeout 1 openssl s_client -servername ${TMP_CURRENT_CHECK_DOMAIN} -connect ${TMP_CURRENT_CHECK_DOMAIN}:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | awk -F '=' '{print $2}' )
    # ([ $? -ne 0 ] || [[ ${TMP_CURRENT_CHECK_DOMAIN_END_TIME} == '' ]]) &&  exit 10
    if [ $? -ne 0 ] || [[ ${TMP_CURRENT_CHECK_DOMAIN_END_TIME} == '' ]]; then
        echo "Can't get end time of cert from ${TMP_CURRENT_CHECK_DOMAIN}"
        slack ">Checked domain '${TMP_CURRENT_CHECK_DOMAIN}' failure, can't get cert end time。"
        exit 10
    fi

    local TMP_CURRENT_CHECK_DOMAIN_END_TIMES=`date -d "${TMP_CURRENT_CHECK_DOMAIN_END_TIME}" +%s `
    local TMP_CURRENT_CHECK_DOMAIN_CURRENT_TIME=`date -d "$(date -u '+%b %d %T %Y GMT') " +%s `

    let TMP_CURRENT_CHECK_DOMAIN_LEFT_TIMES=${TMP_CURRENT_CHECK_DOMAIN_END_TIMES}-${TMP_CURRENT_CHECK_DOMAIN_CURRENT_TIME}
    local TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS=`expr $TMP_CURRENT_CHECK_DOMAIN_LEFT_TIMES / 86400`
    echo "Current Check domain：\"${TMP_CURRENT_CHECK_DOMAIN}\" Left days: ${TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS}"
    slack ">Checked domain '${TMP_CURRENT_CHECK_DOMAIN}' success, it left days ${TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS}。"

    # 跨进程执行文件，变量传递待修复
    local TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS_OUTPUT_PATH="/tmp/cert_checker"
    if [ ! -d "${TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS_OUTPUT_PATH}" ]; then
        mkdir -pv ${TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS_OUTPUT_PATH}
    fi

    echo "${TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS}" > ${TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS_OUTPUT_PATH}/${TMP_CURRENT_CHECK_DOMAIN}
}

#鉴别脚本所需参数的正确性
function init_params() {
    # for must input params
    if [ -z "${1:-}" ]; then
        echo 'error: Missed required arguments.' > /dev/stderr
        echo 'note: Please follow this example:' > /dev/stderr
        echo 'params：' > /dev/stderr
        echo '      \$check_domain：www.google.com' > /dev/stderr
        echo '  $ cert_checker.sh "\$check_domain(*)"' > /dev/stderr
        exit 3
    fi

    return $?
}

#校验启动器
function bootstrap() {
    # Set magic variables for current file & dir
    __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
    __conf="$(cd; pwd)"
    readonly __dir __file __conf

    cd ${__dir}

    if [ -f ${__conf}/${TMP_CURRENT_RC_FILE_NAME} ]; then
        . ${__conf}/${TMP_CURRENT_RC_FILE_NAME}

        # 变更slack附加环境变量
        sed -i "s@^TMP_COVER_RC_FILE_NAME=.*@TMP_COVER_RC_FILE_NAME=\"${TMP_CURRENT_RC_FILE_NAME}\"@g" ${SLACK_PATH}
    fi

    init_params ${@}
    exec_program ${@}
    
    # 还原slack附加环境变量
    sed -i "s@^TMP_COVER_RC_FILE_NAME=.*@TMP_COVER_RC_FILE_NAME=\"\"@g" ${SLACK_PATH}

    return $?
}

if [ "${BASH_SOURCE[0]:-}" != "${0}" ]; then
    export -f bootstrap
else
    bootstrap ${@}
    exit $?
fi