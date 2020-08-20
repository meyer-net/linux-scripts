#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：$title_name
# 软件名称：$soft_name
# 软件安装大写名称：$setup_upper_name
# 软件安装大写分组与简称：$setup_upper_short_name
# 软件安装名称：$setup_name
# 软件授权用户名称&组：$setup_owner/$setup_owner_group
#------------------------------------------------

# 1-配置环境
function set_environment()
{	
	return $?
}

# 2-安装软件
function setup_$soft_name()
{
	local TMP_$setup_upper_short_name_SETUP_DIR=${1}
	local TMP_$setup_upper_short_name_CURRENT_DIR=`pwd`

	## 直装模式

	cd ..

	mv ${TMP_$setup_upper_short_name_CURRENT_DIR} ${TMP_$setup_upper_short_name_SETUP_DIR}

	local TMP_$setup_upper_short_name_LNK_LOGS_DIR=${LOGS_DIR}/$setup_name
	local TMP_$setup_upper_short_name_LNK_DATA_DIR=${DATA_DIR}/$setup_name
	local TMP_$setup_upper_short_name_LOGS_DIR=${TMP_$setup_upper_short_name_SETUP_DIR}/logs
	local TMP_$setup_upper_short_name_DATA_DIR=${TMP_$setup_upper_short_name_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_$setup_upper_short_name_LOGS_DIR}
	rm -rf ${TMP_$setup_upper_short_name_DATA_DIR}
	mkdir -pv ${TMP_$setup_upper_short_name_LNK_LOGS_DIR}
	mkdir -pv ${TMP_$setup_upper_short_name_LNK_DATA_DIR}

	ln -sf ${TMP_$setup_upper_short_name_LNK_LOGS_DIR} ${TMP_$setup_upper_short_name_LOGS_DIR}
	ln -sf ${TMP_$setup_upper_short_name_LNK_DATA_DIR} ${TMP_$setup_upper_short_name_DATA_DIR}

	# 环境变量或软连接
	echo "$setup_upper_short_name_HOME=${$setup_upper_short_name_HOME}" >> /etc/profile
	source /etc/profile
	# ln -sf ${TMP_$setup_upper_short_name_SETUP_DIR}/bin/$setup_name /usr/bin/$setup_name

	# 授权权限，否则无法写入
	# chown -R $setup_owner:$setup_owner_group ${TMP_$setup_upper_short_name_SETUP_DIR}

	return $?
}

# 3-设置软件
function conf_$soft_name()
{
	cd ${1}

	return $?
}

# 4-启动软件
function boot_$soft_name()
{
	local TMP_$setup_upper_short_name_SETUP_DIR=${1}

	cd ${TMP_$setup_upper_short_name_SETUP_DIR}

    echo_startup_config "$soft_name" "${TMP_$setup_upper_short_name_SETUP_DIR}" "bin/$soft_name-ng agent -n a1 --c conf -f conf/local-port8124-listener-conf.properties -D$soft_name.root.logger=INFO,console" "" "100"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_$soft_name()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_$soft_name()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_$soft_name()
{
	local TMP_$setup_upper_short_name_SETUP_DIR=${1}
    
	set_environment "${TMP_$setup_upper_short_name_SETUP_DIR}"

	setup_$soft_name "${TMP_$setup_upper_short_name_SETUP_DIR}"

	set_$soft_name "${TMP_$setup_upper_short_name_SETUP_DIR}"

    # down_plugin_$soft_name "${TMP_$setup_upper_short_name_SETUP_DIR}"

	boot_$soft_name "${TMP_$setup_upper_short_name_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_$soft_name()
{
	TMP_$setup_upper_short_name_SETUP_NEWER="1.0.0"
	set_github_soft_releases_newer_version "TMP_$setup_upper_short_name_SETUP_NEWER" "meyer-net/snake"
	exec_text_format "TMP_$setup_upper_short_name_SETUP_NEWER" "https://www.xxx.com/downloads/$soft_name-%.tar.gz"
    setup_soft_wget "$setup_name" "${TMP_$setup_upper_short_name_SETUP_NEWER}" "exec_step_$soft_name"

	return $?
}

#安装主体
setup_soft_basic "$title_name" "down_$soft_name"
