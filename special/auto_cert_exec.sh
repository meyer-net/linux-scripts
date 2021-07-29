#!/bin/sh
####################################################################################
# 使用本脚本，主要针对证书过期操作。默认是按照caddy的证书生成进行的操作
####################################################################################

# SLACK配置信息
SLACK_PATH=`which slack`

#配置RC文件
TMP_CURRENT_RC_FILE_NAME=".auto-certrc"
AUTO_CERT_IGNORE_SOURCE_DOMAINS="${AUTO_CERT_IGNORE_DOMAINS}"
AUTO_CERT_EXPIRED_ACTION="echo 'exec cert expired action'"

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

function exec_1min()
{
    local TMP_AUTO_CERT_LOCAL_LS_DIRS=`ls ${AUTO_CERT_LOCAL_ROOT_DIR}`
    local TMP_AUTO_CERT_LOCAL_ARR_DIRS=(${TMP_AUTO_CERT_LOCAL_LS_DIRS//,/})
    
    slack ">Start check cert folders in '${AUTO_CERT_LOCAL_ROOT_DIR}'，it takes ${#TMP_AUTO_CERT_LOCAL_ARR_DIRS[@]} files。"
    for CERT_DOMAIN in ${TMP_AUTO_CERT_LOCAL_ARR_DIRS[@]}; do
        local TMP_CURRENT_DOMAIN_IGNORE=`echo "${AUTO_CERT_IGNORE_FINAL_DOMAINS[@]}" | grep -wq "${CERT_DOMAIN}" &&  echo "Yes" || echo "No"`
        if [ "$TMP_CURRENT_DOMAIN_IGNORE" = "Yes" ]; then
            slack ">Checked cert of domain '${CERT_DOMAIN}' set ignore，just will be continue。"
            continue
        fi
        
        # 跨进程执行文件，变量传递待修复
        local TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS_OUTPUT_PATH="/tmp/cert_checker/${CERT_DOMAIN}"
        local TMP_ASYNC_ACTION=`cert_checker "${CERT_DOMAIN}"`
        local TMP_LEFT_DAYS_FOR_CURRENT_DOMAIN=`cat ${TMP_CURRENT_CHECK_DOMAIN_LEFT_DAYS_OUTPUT_PATH}`
                
        if [ ${TMP_LEFT_DAYS_FOR_CURRENT_DOMAIN} -lt 30 ]; then
            echo "HTTPS cert will be expired less ${TMP_LEFT_DAYS_FOR_CURRENT_DOMAIN} days。"
        else
            echo "upper 30，left ${TMP_LEFT_DAYS_FOR_CURRENT_DOMAIN} days。"
        fi

        # "${AUTO_CERT_EXPIRED_ACTION}"
# 此处开始归类
        # 1：检测证书目录
        # 2：每天运行1次
        # 3：大于30天，记录MD5，小于30天，对比MD5，开始更新证书并同步。
        # 4：不存在的，未归类的，则每分钟执行一次
        # 小于1天，每小时检查
        # 小于7天，每天检查
        # 小于30天，每周检查
        # ??? 缺少执行逻辑
        # ??? 缺少同步证书逻辑
        # ??? 缺少安装植入逻辑
        # ??? 缺少定时逻辑
        # ??? 修复安装的域名同步问题
        echo "---------------------------------------"
    done
    
    slack ">Cert folders in '${AUTO_CERT_LOCAL_ROOT_DIR}' checked。"
}

function exec_1day()
{
    echo "1day"
}

function exec_1week()
{
    echo "1week"
}

function async_cert()
{
    echo "async_cert"
}

#鉴别脚本所需参数的正确性
function init_params() {
    # for must input params
    if [ -z "${1:-}" ]; then
        echo 'error: Missed required arguments.' > /dev/stderr
        echo 'note: Please follow this example:' > /dev/stderr
        echo 'params：' > /dev/stderr
        echo '      \$split_type：1min/1day/1week' > /dev/stderr
        echo '  $ auto_cert.sh "\$split_type(*)"' > /dev/stderr
        exit 3
    fi

    if [ -z "${AUTO_CERT_LOCAL_ROOT_DIR:-}" ]; then
        echo 'error: Please configure environment variable: ' > /dev/stderr
        echo '  $ AUTO_CERT_LOCAL_ROOT_DIR' > /dev/stderr
        exit 2
    fi

    # 最终确认版参数（遇到指定了参数得情况，则忽略环境变量中得赋值）
    local AUTO_CERT_IGNORE_CUSTOM_DOMAINS=`echo "${@}" | sed "s@ @|@g"`
    AUTO_CERT_IGNORE_FINAL_DOMAINS=${AUTO_CERT_IGNORE_CUSTOM_DOMAINS:-${AUTO_CERT_IGNORE_DOMAINS}}

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
        
        # 没加载到则重新从加载后得环境变量中读取
        AUTO_CERT_IGNORE_DOMAINS=${AUTO_CERT_IGNORE_SOURCE_DOMAINS:-${AUTO_CERT_IGNORE_DOMAINS}}
    fi

    init_params ${@}

    local TMP_AUTO_CERT_EXEC_SPLIT_TYPE="${1}"
    shift
    exec_${TMP_AUTO_CERT_EXEC_SPLIT_TYPE} ${@}
    
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