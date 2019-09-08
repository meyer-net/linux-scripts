#!/bin/sh
####################################################################################
# 使用本脚本，最好UAT/PRE环境的路径，与生产发布项目的路径一致，不然会引起一些列的改动
# 使用时，配置路径在所有项目的根路径时，以micrpay 项目为例，最好svn checkout 命令，按单个项目来checkout
####################################################################################

# SLACK配置信息
SLACK_PATH=`which slack`

# SVN配置信息
SVN_PATH=`which svn`

# 配置RC文件
TMP_CURRENT_RC_FILE_NAME=".svn-packrc"

# 检测原始参数
SVN_PACKAGE_IGNORE_SOURCE_FILES="${SVN_PACKAGE_IGNORE_FILES}"

# 删除软连接
# 参数1：指定检查的根路径
function remove_slink() {
    local tmp_check_root="${1:-}"
    if [ -n "${tmp_check_root}" ]; then
        find ${tmp_check_root} | xargs -I {} sh -c '[ -L "$1" ] && rm -rf $1' -- {}
    fi

    return $?
}

# 删除排除文件
# 参数1：指定检查的根路径
function remove_ignores() {
    local tmp_check_root="${1:-}"
    if [ -n "${tmp_check_root}" ]; then
        find ${tmp_check_root} | grep -E "$SVN_PACKAGE_IGNORE_FINAL_FILES" | xargs rm -rf
    fi

    return $?
}

function exec_program()
{
    # 当前本地版本
    local TMP_CURRENT_LOCAL_VERSION=v`date "+%Y%m%d.%H%M%S"`

    # 匹配包含.svn路径的根目录，意图探索包含何种项目
    echo "SvnPackager：Start to find the path of '${SVN_PACKAGE_CHECK_LOCAL_ROOT_DIR}', please waitting."
    echo "---------------------------------------------------"
    local TMP_SVN_LOCAL_DIRS=`find $SVN_PACKAGE_CHECK_LOCAL_ROOT_DIR -name .svn | grep -vE "^$"`
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
    
        # 上一次行至版本
        local WORK_PACKAGE_PREV_VERSION=`[ -f prev_version ] && cat prev_version`
        
        # 查询当前项目最开始的版本号
        if [ "${#WORK_PACKAGE_PREV_VERSION}" -eq 0 ]; then
            WORK_PACKAGE_PREV_VERSION=`svn log -q | grep "|" | awk 'END {print}' | awk '{print $1}'`
        fi

        # 获取当前版本信息
        local TMP_CURRENT_INFO=`$SVN_PATH info`
        local TMP_CURRENT_VERSION=`echo "$TMP_CURRENT_INFO" | grep -E -o "最后修改的版本: [0-9]+" | awk '{print $2}'`

        # 获取上次版本与本次版本的差异文件清单
        local TMP_CURRENT_DIFF_LIST=`$SVN_PATH diff -r $WORK_PACKAGE_PREV_VERSION:HEAD --summarize | grep -E "\.\w*$" | grep -vE "^$" | grep -vE "${SVN_PACKAGE_IGNORE_FINAL_FILES}"`
        local TMP_CURRENT_DIFF_COUNT=`echo "$TMP_CURRENT_DIFF_LIST" | grep -vE "^$" | wc -l`
        
        # 通知信息        
        echo "SvnPackager：Version '${SVN_LOCAL_NAME}@${WORK_PACKAGE_PREV_VERSION}:${TMP_CURRENT_VERSION}' takes ${TMP_CURRENT_DIFF_COUNT} different files."
        echo "---------------------------------------------------"

        if [ ${TMP_CURRENT_DIFF_COUNT} -gt 0 ]; then
            slack ">Start package svn project '${SVN_LOCAL_NAME}@${WORK_PACKAGE_PREV_VERSION}:${TMP_CURRENT_VERSION}', it takes ${TMP_CURRENT_DIFF_COUNT} differents, percent ${TMP_DIR_DONE_PERCENT}."

            # 当前文件夹名称
            local TMP_CURRENT_RELATIVE_DIR=`echo $SVN_LOCAL_DIR | sed "s@${SVN_PACKAGE_CHECK_LOCAL_ROOT_DIR}@@g"`
            #local TMP_CURRENT_ABSOLUTE_DIR="${WORK_HOLDER_DIR}${TMP_CURRENT_RELATIVE_DIR}"

            # 脚本工作目录，以时间戳为基准，作为针对上个版本的更新
            local WORK_HOLDER_DIR=`dirname "${SVN_PACKAGE_CHECK_LOCAL_ROOT_DIR}"`/packages/$TMP_CURRENT_LOCAL_VERSION
            local WORK_HOLDER_PATCH_DIR="$WORK_HOLDER_DIR/patch${TMP_CURRENT_RELATIVE_DIR}"
            local WORK_HOLDER_RESTORE_DIR="$WORK_HOLDER_DIR/restore${TMP_CURRENT_RELATIVE_DIR}"

            mkdir -pv $WORK_HOLDER_RESTORE_DIR
            mkdir -pv $WORK_HOLDER_PATCH_DIR
            echo "---------------------------------------------------"

            # 输出更新脚本
            if [ ! -f ${WORK_HOLDER_DIR}/patch.sh ]; then
                cat > ${WORK_HOLDER_DIR}/patch.sh <<EOF
#!/bin/sh
#------------------------------------------------
#  Project Patch Script
#  Telegram: meyer_com
#  PatchVersion：${TMP_CURRENT_LOCAL_VERSION}
#  Generate by svn_package.sh
#------------------------------------------------
__script_dir="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
cd \$__script_dir

EOF
            else
                echo -e "\n#------------------------------------------------------------------------------------------------\n" >> ${WORK_HOLDER_DIR}/patch.sh
            fi

            cat >> ${WORK_HOLDER_DIR}/patch.sh <<EOF
`echo "$TMP_CURRENT_INFO" | sed "s@^@# @g"`
#------------------------------------------------
`echo "# 上一版本：$WORK_PACKAGE_PREV_VERSION"`
`echo "# 更新文件清单："`
`echo "$TMP_CURRENT_DIFF_LIST" | sed "s@^@# @g"`
rsync -av patch${TMP_CURRENT_RELATIVE_DIR} ${SVN_LOCAL_PARENT_DIR}

EOF
            
            if [ ! -f ${WORK_HOLDER_DIR}/restore.sh ]; then
                cat > ${WORK_HOLDER_DIR}/restore.sh <<EOF
#!/bin/sh
#------------------------------------------------
#  Project Restore Script
#  Telegram: meyer_com
#  Generate by svn_package.sh
#------------------------------------------------
__script_dir="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
cd \$__script_dir

EOF
            else
                echo -e "\n#------------------------------------------------------------------------------------------------\n" >> ${WORK_HOLDER_DIR}/restore.sh
            fi

            cat >> ${WORK_HOLDER_DIR}/restore.sh <<EOF
`echo "$TMP_CURRENT_INFO" | sed "s@^@# @g"`
#------------------------------------------------
`echo "# 上一版本：$WORK_PACKAGE_PREV_VERSION"`
`echo "# 更新文件清单："`
`echo "$TMP_CURRENT_DIFF_LIST" | sed "s@^@# @g"`
rsync -av restore${TMP_CURRENT_RELATIVE_DIR} ${SVN_LOCAL_PARENT_DIR}
    
EOF

            # 遍历差异清单，通过动作，形成更新shell
            for J in `seq $TMP_CURRENT_DIFF_COUNT`; do
                #读取当前行
                local TMP_FIELD=`echo "$TMP_CURRENT_DIFF_LIST" | awk "NR == $J"`

                # 拆分变量
                local TMP_FIELD_ACTION=`echo "$TMP_FIELD" | awk '{print $1}'`
                local TMP_FIELD_PATH=`echo "$TMP_FIELD" | awk '{print $2}'`

                # 计算百分比
                local TMP_PRJ_DONE_PERCENT=`printf "%d%%" $(($J*100/$TMP_CURRENT_DIFF_COUNT))`

                # 输出信息
                echo "[$TMP_DIR_DONE_PERCENT][$TMP_PRJ_DONE_PERCENT]SvnPackager：Start operate file '${TMP_FIELD_PATH}' on action '${TMP_FIELD_ACTION}'"

                # 是文件的情况下才执行
                if [ "${TMP_FIELD_PATH}" != "." ]; then
                    # 更新打包，从本地拿
                    echo "SvnPackager.Patch：${WORK_HOLDER_PATCH_DIR}"

                    # 生成执行更新的命令脚本
                    local TMP_HOLDER_OPERATE_REMOTE_PATH="${SVN_LOCAL_DIR}/${TMP_FIELD_PATH}"
                    case "$TMP_FIELD_ACTION" in
                        "A" | "M")
                            # 更新脚本
                            cp --parents -av ${TMP_FIELD_PATH} ${WORK_HOLDER_PATCH_DIR}

                            # 回滚脚本
                            if [ "$TMP_FIELD_ACTION" == "A" ]; then
                                echo "rm -rf ${TMP_HOLDER_OPERATE_REMOTE_PATH}" >> ${WORK_HOLDER_DIR}/restore.sh
                            fi
                        ;;
                        *)
                            # 更新脚本
                            echo "rm -rf ${TMP_HOLDER_OPERATE_REMOTE_PATH}" >> ${WORK_HOLDER_DIR}/patch.sh
                        ;;
                    esac
                else
                    echo "SvnPackager: Jump out of invalid path '$TMP_FIELD_PATH'"
                fi

                echo "---------------------------------------------------"
            done
            
            slack ">Svn project '${SVN_LOCAL_NAME}@${WORK_PACKAGE_PREV_VERSION}:${TMP_CURRENT_VERSION}', package done."

            # 删除升级包软连接
            remove_slink $WORK_HOLDER_PATCH_DIR

            # 保存副本
            cp -r . $WORK_HOLDER_RESTORE_DIR

            # 保存当前版本号
            echo "$TMP_CURRENT_VERSION" > prev_version
            
            # 删除还原包软连接
            remove_slink $WORK_HOLDER_RESTORE_DIR

            # 存储上一版（更新到上一次打包版本号）
            cd $WORK_HOLDER_RESTORE_DIR && $SVN_PATH update -r $WORK_PACKAGE_PREV_VERSION

            # 删除还原包排除文件
            remove_ignores $WORK_HOLDER_RESTORE_DIR
        fi
    done

    slack "\`All project from svn was package done.\`"

    return $?
}

#配置RC文件
function init_params() {
    # 最终确认版参数
    local SVN_PACKAGE_IGNORE_CUSTOM_FILES=`echo "${@}" | sed "s@ @|@g"`
    SVN_PACKAGE_IGNORE_FINAL_FILES=${SVN_PACKAGE_IGNORE_CUSTOM_FILES:-${SVN_PACKAGE_IGNORE_FILES:-"\\.svn"}}

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

    if [ -f ${__conf}/$TMP_CURRENT_RC_FILE_NAME ]; then
        . ${__conf}/$TMP_CURRENT_RC_FILE_NAME

        # 变更slack附加环境变量
        sed -i "s@^TMP_COVER_RC_FILE_NAME=.*@TMP_COVER_RC_FILE_NAME=\"$TMP_CURRENT_RC_FILE_NAME\"@g" $SLACK_PATH

        # 填写地址变量加载
        SVN_PACKAGE_IGNORE_FILES=${SVN_PACKAGE_IGNORE_SOURCE_FILES:-${SVN_PACKAGE_IGNORE_FILES}}
    fi

    init_params ${@}
    exec_program
    
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

# 还原原始slack配置
source $SLACK_CONFIG_PATH