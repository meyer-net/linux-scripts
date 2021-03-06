#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：$title_name
# 软件名称：$soft_name
# 软件大写名称：$soft_upper_name
# 软件大写分组与简称：$soft_upper_short_name
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
	local TMP_$soft_upper_name_SETUP_DIR=${1}
	local TMP_$soft_upper_name_CURRENT_DIR=`pwd`

	# 编译模式
	./configure --prefix=${TMP_$soft_upper_name_SETUP_DIR}
	sudo make -j4 && make -j4 install

	# 创建日志软链
	local TMP_$soft_upper_short_name_LNK_LOGS_DIR=${LOGS_DIR}/$setup_name
	local TMP_$soft_upper_short_name_LNK_DATA_DIR=${DATA_DIR}/$setup_name
	local TMP_$soft_upper_short_name_LOGS_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/logs
	local TMP_$soft_upper_short_name_DATA_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_$soft_upper_short_name_LOGS_DIR}
	rm -rf ${TMP_$soft_upper_short_name_DATA_DIR}
	mkdir -pv ${TMP_$soft_upper_short_name_LNK_LOGS_DIR}
	mkdir -pv ${TMP_$soft_upper_short_name_LNK_DATA_DIR}

	ln -sf ${TMP_$soft_upper_short_name_LNK_LOGS_DIR} ${TMP_$soft_upper_short_name_LOGS_DIR}
	ln -sf ${TMP_$soft_upper_short_name_LNK_DATA_DIR} ${TMP_$soft_upper_short_name_DATA_DIR}
	
	# 环境变量或软连接
	echo "$soft_upper_name_HOME=${TMP_$soft_upper_name_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$$soft_upper_name_HOME/bin:$PATH' >> /etc/profile
	echo "export PATH $soft_upper_name_HOME" >> /etc/profile
	source /etc/profile
	# ln -sf ${TMP_$soft_upper_short_name_SETUP_DIR}/bin/$setup_name /usr/bin/$setup_name

	# 移除源文件
	rm -rf ${TMP_$soft_upper_name_CURRENT_DIR}

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
	local TMP_$soft_upper_short_name_SETUP_DIR=${1}

	cd ${TMP_$soft_upper_short_name_SETUP_DIR}
	
	# 验证安装
    $setup_name -v

	# 当前启动命令
	bin/$soft_name

	# 添加系统启动命令
    echo_startup_config "$soft_name" "${TMP_$soft_upper_short_name_SETUP_DIR}" "bin/$soft_name" "" "100"

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
	local TMP_$soft_upper_short_name_SETUP_DIR=${1}
    
	set_environment "${TMP_$soft_upper_short_name_SETUP_DIR}"

	setup_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	conf_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

    # down_plugin_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	boot_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	return $?
}

# x1-下载软件
function down_$soft_name()
{
	TMP_$soft_upper_short_name_SETUP_NEWER="1.0.0"
	set_github_soft_releases_newer_version "TMP_$soft_upper_short_name_SETUP_NEWER" "meyer-net/snake"
	exec_text_format "TMP_$soft_upper_short_name_SETUP_NEWER" "https://www.xxx.com/downloads/$setup_name-%s.tar.gz"
	# set_url_list_newer_date_link_filename "TMP_$soft_upper_short_name_SETUP_NEWER" "http://www.xxx.net/projects/releases/" "$setup_name-.*.tar.gz"
	# set_url_list_newer_href_link_filename "TMP_$soft_upper_short_name_SETUP_NEWER" "http://www.xxx.net/projects/releases/" "$setup_name-().tar.gz"
	# exec_text_format "TMP_$soft_upper_short_name_SETUP_NEWER" "http://www.xxx.net/projects/releases/%s"
    setup_soft_wget "$setup_name" "${TMP_$soft_upper_short_name_SETUP_NEWER}" "exec_step_$soft_name"

	return $?
}

#安装主体
setup_soft_basic "$title_name" "down_$soft_name"
