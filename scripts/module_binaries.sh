#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 安装标题：$title_name
# 软件名称：$soft_name
# 软件大写分组与简称：$soft_upper_short_name
# 软件安装名称：$setup_name
# 软件授权用户名称&组：$setup_owner/$setup_owner_group
#------------------------------------------------
local TMP_$soft_upper_short_name_SETUP_PORT=1$soft_port

##########################################################################################################

# 1-配置环境
function set_env_$soft_name()
{
    cd ${__DIR}

    soft_yum_check_action ""

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_$soft_name()
{
	local TMP_$soft_upper_short_name_SETUP_DIR=${1}

	## 源模式
	sudo tee /etc/yum.repos.d/$setup_name.repo <<-'EOF'
[$setup_name]
name=$setup_name
enabled=1
baseurl=
gpgkey=
gpgcheck=1
EOF

	soft_yum_check_setup "$soft_name"

	# local TMP_$soft_upper_short_name_SETUP_RPM_NAME=""
    # while_wget "--content-disposition http://dev.mysql.com/get/${TMP_$soft_upper_short_name_SETUP_RPM_NAME}" "rpm -ivh ${TMP_$soft_upper_short_name_SETUP_RPM_NAME}"

	# 创建日志软链
	local TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR=${DATA_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_LOGS_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/logs
	local TMP_$soft_upper_short_name_SETUP_DATA_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/data

	# 先清理文件，再创建文件
	path_not_exits_create ${TMP_$soft_upper_short_name_SETUP_DIR}
	rm -rf ${TMP_$soft_upper_short_name_SETUP_LOGS_DIR}
	rm -rf ${TMP_$soft_upper_short_name_SETUP_DATA_DIR}
	mkdir -pv ${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}
	
	# 特殊多层结构下使用
    mkdir -pv `dirname ${TMP_$soft_upper_short_name_SETUP_LOGS_DIR}`
    mkdir -pv `dirname ${TMP_$soft_upper_short_name_SETUP_DATA_DIR}`

	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR} ${TMP_$soft_upper_short_name_SETUP_LOGS_DIR}
	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR} ${TMP_$soft_upper_short_name_SETUP_DATA_DIR}

	# 授权权限，否则无法写入
	# create_user_if_not_exists $setup_owner $setup_owner_group
	# chgrp -R $setup_owner ${TMP_$soft_upper_short_name_SETUP_DIR}
	# chown -R $setup_owner:$setup_owner_group ${TMP_$soft_upper_short_name_SETUP_DIR}

	# rm -rf /etc/yum.repos.d/$setup_name.repo
	
    # sudo yum clean all && sudo yum makecache fast

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_$soft_name()
{
	local TMP_$soft_upper_short_name_SETUP_DIR=${1}

	cd ${TMP_$soft_upper_short_name_SETUP_DIR}
	
	local TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR=${ATT_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_ETC_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_$soft_upper_short_name_SETUP_ETC_DIR} ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}

	# ①-N：不存在配置文件：
	# rm -rf ${TMP_$soft_upper_short_name_SETUP_ETC_DIR}
	# mkdir -pv ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}

	# 替换原路径链接
	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR} ${TMP_$soft_upper_short_name_SETUP_ETC_DIR}
    ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR} /etc/$soft_name
	
    # 开始配置

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_$soft_name()
{
	local TMP_$soft_upper_short_name_SETUP_DIR=${1}

	cd ${TMP_$soft_upper_short_name_SETUP_DIR}
	
	# 验证安装
    $setup_name -v  # lsof -i:${TMP_$soft_upper_short_name_SETUP_PORT}

	# 当前启动命令
    sudo systemctl daemon-reload
    sudo systemctl enable $setup_name.service
    sudo systemctl start $setup_name.service
    systemctl status $setup_name.service
    # journalctl -u $setup_name --no-pager | less
    # sudo systemctl reload $setup_name.service

	# 授权iptables端口访问
	echo_soft_port ${TMP_$soft_upper_short_name_SETUP_PORT}

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
	local TMP_$soft_upper_short_name_SETUP_DIR=${SETUP_DIR}/$setup_name
    
	set_env_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	setup_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	conf_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

    # down_plugin_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	boot_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_$soft_name()
{
    soft_yum_check_action "$setup_name" "exec_step_$soft_name"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "$title_name" "check_setup_$soft_name"
