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
    cd ${__DIR}

    soft_yum_check_action ""

	return $?
}

# 2-安装软件
function setup_$soft_name()
{
	local TMP_$soft_upper_short_name_SETUP_DIR=${1}

	## 直装模式
    sudo cat << EOF > /etc/yum.repos.d/$setup_name.repo
[$setup_name]
name=$setup_name
enabled=1
baseurl=
gpgkey=
gpgcheck=1
EOF
	sudo yum -y install $soft_name

	# 创建日志软链
	local TMP_$soft_upper_short_name_LNK_LOGS_DIR=${LOGS_DIR}/$setup_name
	local TMP_$soft_upper_short_name_LNK_DATA_DIR=${DATA_DIR}/$setup_name
	local TMP_$soft_upper_short_name_LOGS_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/logs
	local TMP_$soft_upper_short_name_DATA_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_$soft_upper_short_name_LOGS_DIR}/*
	rm -rf ${TMP_$soft_upper_short_name_DATA_DIR}/*
	mkdir -pv ${TMP_$soft_upper_short_name_LNK_LOGS_DIR}
	mkdir -pv ${TMP_$soft_upper_short_name_LNK_DATA_DIR}
	
	# 特殊多层结构下使用
    mkdir -pv `dirname ${TMP_$soft_upper_short_name_LOGS_DIR}`
    mkdir -pv `dirname ${TMP_$soft_upper_short_name_DATA_DIR}`

	ln -sf ${TMP_$soft_upper_short_name_LNK_LOGS_DIR} ${TMP_$soft_upper_short_name_LOGS_DIR}
	ln -sf ${TMP_$soft_upper_short_name_LNK_DATA_DIR} ${TMP_$soft_upper_short_name_DATA_DIR}

	# 授权权限，否则无法写入
	chown -R $setup_owner:$setup_owner_group ${TMP_$soft_upper_short_name_SETUP_DIR}

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
    sudo systemctl daemon-reload
    sudo systemctl enable $setup_name
    sudo systemctl start $setup_name
    systemctl status $setup_name
    # journalctl -u $setup_name --no-pager | less
    # sudo systemctl reload $setup_name

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
    
	set_environment "${TMP_$soft_upper_short_name_SETUP_DIR}"

	setup_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	conf_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

    # down_plugin_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	boot_$soft_name "${TMP_$soft_upper_short_name_SETUP_DIR}"

	return $?
}

# x1-下载软件
function check_setup_$soft_name()
{
    soft_yum_check_action "$soft_name" "exec_step_$soft_name"

	return $?
}

#安装主体
setup_soft_basic "$title_name" "check_setup_$soft_name"
