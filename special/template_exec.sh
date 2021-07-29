#!/bin/sh

# SLACK配置信息
SLACK_PATH=`which slack`

#???配置RC文件
TMP_CURRENT_RC_FILE_NAME=".variable"

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

function exec_program()
{
	echo "execute"
}

#鉴别脚本所需参数的正确性
function init_params() {

    # must defined，you may declare ENV vars in /etc/profile.d/template.sh
    # if [ -z "${TMP_CURRENT_VARIABLE1:-}" ]; then
    #     echo 'error: Please configure environment variable: ' > /dev/stderr
    #     echo '  TMP_CURRENT_VARIABLE1' > /dev/stderr
    #     exit 2
    # fi

    # for must input params
    # if [ -z "${1:-}" ]; then
    #     echo 'error: Missed required arguments.' > /dev/stderr
    #     echo 'note: Please follow this example:' > /dev/stderr
    #     echo '  $ template.sh "#param1,param2" Some message here. ' > /dev/stderr
    #     exit 3
    # fi

    # for read all in params, col to row
    dynamic_variables=(${TMP_CURRENT_VARIABLE2:-})
    
    # get else left
    connect_variables=${@}

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

        # 变更slack附加环境变量（用途为了解决当前slack通知得差异性问题，待修改为调用脚本区分）
        sed -i "s@^TMP_COVER_RC_FILE_NAME=.*@TMP_COVER_RC_FILE_NAME=\"${TMP_CURRENT_RC_FILE_NAME}\"@g" ${SLACK_PATH}
    fi

    declare -a dynamic_variables

    init_params ${@}
    exec_program
    
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