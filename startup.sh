#!/bin/bash
####################################################################################
# 运行时，自动弹出配置slack提示
####################################################################################

#---------- DIR ---------- {
WORK_PATH=`pwd`
#---------- DIR ---------- }

# 清理系统缓存后执行
echo 3 > /proc/sys/vm/drop_caches

# 全部给予执行权限
chmod +x -R common/*.sh
source common/common.sh

# 定制化的脚本，独有的依赖系统通知
source special/slack.sh

function choice_type()
{
	echo_title

	exec_if_choice "CHOICE_CTX" "Please choice your startup type" "Svn.Updater,Svn.Packager,Kong.Api,Exit" "$TMP_SPLITER" "special"

	return $?
}

choice_type 