#!/bin/sh
####################################################################################
# 使用本脚本，最好UAT/PRE环境的路径，与生产发布项目的路径一致，不然会引起一些列的改动
# 使用时，配置路径在所有项目的根路径时，以micrpay 项目为例，最好svn checkout 命令，按单个项目来checkout
####################################################################################
# SVN配置信息
SVN_PATH=`which svn`

# SLACK配置信息
SLACK_PATH=`which slack`

# 配置RC文件
TMP_CURRENT_RC_FILE_NAME=".svn-updaterc"

# 更新时间
TMP_CURRENT_TIME=`date "+%Y%m%d.%H%M%S"`

# 检测根目录
SVN_UPDATE_IGNORE_SOURCE_DIRS="${SVN_UPDATE_IGNORE_DIRS}"

set -o pipefail
set -o errexit
set -o nounset
#set -o xtrace

# 结构逻辑，鉴于脚本的通用性，建议路径规则初始化之后修改
function init_struct() {
    if [ ! -f ${SVN_UPDATE_LOCAL_ROOT_DIR} ]; then
        mkdir -pv ${SVN_UPDATE_LOCAL_ROOT_DIR}
    fi

    cd ${SVN_UPDATE_LOCAL_ROOT_DIR}
    if [ `ls | wc -l ` -eq 0 ]; then
        for project in $($SVN_PATH list "${SVN_UPDATE_REMOTE_ROOT_URL}"); do
            local project_name=`echo $project | grep -E -o '[^/]+'`            
            local project_ignore=`echo "${SVN_UPDATE_IGNORE_FINAL_DIRS[@]}" | grep -wq "$project_name" &&  echo "Yes" || echo "No"`
            if [ "$project_ignore" = "Yes" ]; then
                continue
            fi

            slack ">Start checkout svn project from '${SVN_UPDATE_REMOTE_ROOT_URL}/${project_name}' by user '${SVN_USER}'."
            $SVN_PATH checkout ${SVN_UPDATE_REMOTE_ROOT_URL}/$project_name --username ${SVN_USER} --password ${SVN_PASS}
        done
    fi

    # 以micr-pay项目为例：
    # mkdir -pv /clouddisk/svr_sync/wwwroot/prj/www/html/micr-pay-v2
    # mv backstage.co-ltd.com /clouddisk/svr_sync/wwwroot/prj/www/html/micr-pay-v2
    # mv cashier.micrpay.com /clouddisk/svr_sync/wwwroot/prj/www/html/micr-pay-v2
    
    # mkdir -pv /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-as
    # mv pay-cashier /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-as
    # mv pay-merchant /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-as
    # mv pay-operation /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-as

    # mkdir -pv /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-context
    # mv micro-security /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-context

    # mkdir -pv /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-domain
    # mv as-service /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-domain
    # mv pay-service /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-domain
    # mv micro-robot /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-domain
    # mv micro-billing /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-domain

    # mkdir -pv /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-scheduler
    # mv pay-strategy /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-scheduler

    # mkdir -pv /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-monitoring
    # mv micro-mysql-to-mq /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-monitoring

    # mkdir -pv /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-infrastructure
    # mv micro-task /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-infrastructure
    # mv micro-buffer /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-infrastructure
    # mv micro-config /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-infrastructure
    # mv micro-leaf /clouddisk/svr_sync/wwwroot/prj/www/java/micr-pay-v2/micro-infrastructure

    # HOOK辅助脚本，如执行错误执行 xargs sed -i "/^[[:space:]]*$/d" 删除空行，或xargs -I {} sh -c 'sed -i "7i source /etc/profile" $1' -- {} 插入行
    # find ${SVN_UPDATE_LOCAL_ROOT_DIR} -name updater_hook.sh | grep -v leaf | grep -v config | xargs -I {} sh -c 'echo "source /etc/profile" >> $1' -- {}
    # find ${SVN_UPDATE_LOCAL_ROOT_DIR} -name updater_hook.sh | grep -v leaf | grep -v config | xargs -I {} sh -c 'echo "BOOT_RESULT=\`bash 2.0.0-alpha/bin/bootstrap.sh reload | grep \"Starting\"\`" >> $1' -- {}
    # find ${SVN_UPDATE_LOCAL_ROOT_DIR} -name updater_hook.sh | grep -v leaf | grep -v config | xargs -I {} sh -c 'echo "slack \">\$BOOT_RESULT\"" >> $1' -- {}
}

function exec_program()
{
    echo "SvnUpdater：Start to find the path of '${SVN_UPDATE_LOCAL_ROOT_DIR}', please waitting."
    local TMP_SVN_LOCAL_DIRS=`find ${SVN_UPDATE_LOCAL_ROOT_DIR} -name .svn`
    local TMP_SVN_LOCAL_DIRS_COUNT=`echo "$TMP_SVN_LOCAL_DIRS" | grep -vE "^$" | wc -l`
    for I in `seq $TMP_SVN_LOCAL_DIRS_COUNT`; do
        # 获取.svn文件夹上级路径
        local SVN_LOCAL_DIR=`echo "${TMP_SVN_LOCAL_DIRS}" | awk "NR == $I" | xargs -I {} dirname {}`
        local SVN_LOCAL_NAME=`echo "$SVN_LOCAL_DIR" | awk -F '/' '{print $NF}'`
        local SVN_LOCAL_PARENT_DIR=`dirname ${SVN_LOCAL_DIR}`

        # 必须在本文件夹工作，避开svn路径检测
        cd $SVN_LOCAL_DIR

        # 计算百分比
        local TMP_DIR_DONE_PERCENT=`printf "%d%%" $(($I*100/$TMP_SVN_LOCAL_DIRS_COUNT))`

        # 获取当前版本信息
        local TMP_CURRENT_INFO=`$SVN_PATH info`
        local TMP_CURRENT_VERS=`echo $TMP_CURRENT_INFO | grep -E -o '最后修改的版本: [0-9]+' | awk '{print $2}'`

        # 获取更新文件清单文件清单
        local TMP_CURRENT_UPDATE_LIST=`$SVN_PATH update | grep "\." | grep -v "升级" | grep -vE "^$"`
        local TMP_CURRENT_UPDATE_COUNT=`echo "$TMP_CURRENT_UPDATE_LIST" | awk '{if($0!="") print}' | wc -l`

        # 获取更新后的版本信息
        local TMP_CURRENT_NEWER_INFO=`$SVN_PATH info`
        local TMP_CURRENT_NEWER_VERS=`echo $TMP_CURRENT_NEWER_INFO | grep -E -o '最后修改的版本: [0-9]+' | awk '{print $2}'`

        # 编写特定的命令，也可以使用hook的方式另起脚本，保持通用性，此处使用hook
        if [ ! -f "updater_hook.sh" ]; then
            cat > updater_hook.sh <<EOF
#!/bin/sh
#------------------------------------------------
#  Project Updater Hook Script
#  Telegram: meyer_com
#  Generate by svn-package.sh
#------------------------------------------------
EOF
            chmod +x updater_hook.sh
        fi

        # 通知信息
        echo "---------------------------------------------------"
        echo "SvnUpdater：Version '${SVN_LOCAL_NAME}@${TMP_CURRENT_VERS}:${TMP_CURRENT_NEWER_VERS}' takes ${TMP_CURRENT_UPDATE_COUNT} updates."
        if [ ${TMP_CURRENT_UPDATE_COUNT} -gt 0 ]; then
            slack ">Start update svn project '${SVN_LOCAL_NAME}@${TMP_CURRENT_VERS}:${TMP_CURRENT_NEWER_VERS}', it takes ${TMP_CURRENT_UPDATE_COUNT} updates, percent ${TMP_DIR_DONE_PERCENT}."
        
	        tee ${SVN_UPDATE_LOCAL_ROOT_DIR}/logs/${SVN_LOCAL_NAME}_${TMP_CURRENT_TIME}.txt <<-EOF
$TMP_CURRENT_UPDATE_LIST
EOF

            bash updater_hook.sh
        fi
    done

    echo "---------------------------------------------------"
    echo "SvnUpdater：Executed at: ${TMP_CURRENT_TIME}"
    echo -e "\n"
}

#鉴别脚本所需参数的正确性
function init_params() {
    # must defined，you may declare ENV vars in /etc/profile.d/template.sh
    if [ -z "${SVN_UPDATE_LOCAL_ROOT_DIR:-}" ]; then
        echo 'error: Please configure environment variable: ' > /dev/stderr
        echo '  $ SVN_UPDATE_LOCAL_ROOT_DIR' > /dev/stderr
        exit 2
    fi

    # 最终确认版参数（遇到指定了参数得情况，则忽略环境变量中得赋值）
    local SVN_UPDATE_IGNORE_CUSTOM_DIRS=`echo "${@}" | sed "s@ @|@g"`
    SVN_UPDATE_IGNORE_FINAL_DIRS=${SVN_UPDATE_IGNORE_CUSTOM_DIRS:-${SVN_UPDATE_IGNORE_DIRS}}

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

    # 如果有其它变量在运行，则不执行当前脚本，谨防穿插
    local TMP_COVER_RC_FILE_NAME_VALUE=`cat $SLACK_PATH | grep "TMP_COVER_RC_FILE_NAME=" | awk -F'=' '{print $2}' | sed 's@\"@@g'`
    if [ -n "${TMP_COVER_RC_FILE_NAME_VALUE:-}" ]; then
		echo "svn_updater is waitting..." >> $updating_file
        exit $?
    fi

    if [ -f ${__conf}/$TMP_CURRENT_RC_FILE_NAME ]; then
        . ${__conf}/$TMP_CURRENT_RC_FILE_NAME

        # 变更slack附加环境变量
        sed -i "s@^TMP_COVER_RC_FILE_NAME=.*@TMP_COVER_RC_FILE_NAME=\"$TMP_CURRENT_RC_FILE_NAME\"@g" $SLACK_PATH

        # 没加载到则重新从加载后得环境变量中读取
        SVN_UPDATE_IGNORE_DIRS=${SVN_UPDATE_IGNORE_SOURCE_DIRS:-${SVN_UPDATE_IGNORE_DIRS}}
    fi

    init_params ${@}
    init_struct
    
    cd ${SVN_UPDATE_LOCAL_ROOT_DIR}
	local logs_dir="${SVN_UPDATE_LOCAL_ROOT_DIR}/logs"
	local updating_file="${SVN_UPDATE_LOCAL_ROOT_DIR}/updating"

    mkdir -pv $logs_dir
	echo $TMP_CURRENT_TIME >> $logs_dir/svn-update.log

	if [ ! -f "$updating_file" ]; then
		echo "svn_updater is updating..." >> $updating_file
        exec_program
		echo "svn_updater was updated..." >> $updating_file
    	rm -rf $updating_file
	fi
    
    # 还原slack附加环境变量
    sed -i "s@^TMP_COVER_RC_FILE_NAME=.*@TMP_COVER_RC_FILE_NAME=\"\"@g" $SLACK_PATH

    return $?
}

if [ "${BASH_SOURCE[0]:-}" != "${0}" ]; then
    export -f bootstrap
else
    bootstrap ${@}
    exit $?
fi

#首先在在机器上 通过 svn list 按流程完成账户输入
#crontab -e
#* * * * * svn_updater >> /logs/svn-updater.log 2>&1
#service crond restart