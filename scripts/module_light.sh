#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
# 安装标题：$title_name
# 软件名称：$soft_name
# 软件端口：$soft_port
# 软件大写名称：$soft_upper_name
# 软件大写分组与简称：$soft_upper_short_name
# 软件安装名称：$setup_name
# 软件授权用户名称&组：$setup_owner/$setup_owner_group
# 软件GIT仓储名称：${git_repo}
#------------------------------------------------
local TMP_$soft_upper_short_name_SETUP_PORT=1$soft_port

##########################################################################################################

# 1-配置环境
function set_env_$soft_name()
{
    cd ${__DIR}

    # soft_yum_check_setup ""

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_$soft_name()
{
	## 直装模式
	cd `dirname ${TMP_$soft_upper_short_name_CURRENT_DIR}`

	mv ${TMP_$soft_upper_short_name_CURRENT_DIR} ${TMP_$soft_upper_short_name_SETUP_DIR}

	cd ${TMP_$soft_upper_short_name_SETUP_DIR}

	# 创建日志软链
	local TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR=${DATA_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_LOGS_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/logs
	local TMP_$soft_upper_short_name_SETUP_DATA_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_$soft_upper_short_name_SETUP_LOGS_DIR}
	rm -rf ${TMP_$soft_upper_short_name_SETUP_DATA_DIR}
	path_not_exists_create "${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR}"
	path_not_exists_create "${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}"
	# mv /var/lib/$setup_name ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}
	## cp /var/lib/$setup_name ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR} -Rp
    ## mv /var/lib/$setup_name ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}_empty
	
	# 特殊多层结构下使用
    # path_not_exists_create `dirname ${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR}`
    # path_not_exists_create `dirname ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}`

	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR} ${TMP_$soft_upper_short_name_SETUP_LOGS_DIR}
	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR} ${TMP_$soft_upper_short_name_SETUP_DATA_DIR}
	# ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR} /var/lib/$setup_name

	# 环境变量或软连接
	echo "$soft_upper_name_HOME=${TMP_$soft_upper_short_name_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$$soft_upper_name_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH $soft_upper_name_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile
	# ln -sf ${TMP_$soft_upper_short_name_SETUP_DIR}/bin/$setup_name /usr/bin/$setup_name

	# 授权权限，否则无法写入
	# create_user_if_not_exists $setup_owner $setup_owner_group
	# chown -R $setup_owner:$setup_owner_group ${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR}
	# chown -R $setup_owner:$setup_owner_group ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_$soft_name()
{
	cd ${TMP_$soft_upper_short_name_SETUP_DIR}
	
	local TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR=${ATT_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_ETC_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/etc

	# 开始配置

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_$soft_upper_short_name_SETUP_ETC_DIR} ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}

	# ①-N：不存在配置文件：
	# rm -rf ${TMP_$soft_upper_short_name_SETUP_ETC_DIR}
	# path_not_exists_create "${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}"

	# 特殊多层结构下使用
    # path_not_exists_create `dirname ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}`

	# 替换原路径链接（存在etc下时，不能作为软连接存在）
    # ln -sf /etc/$soft_name ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR} 
    # ln -sf /etc/$soft_name ${TMP_$soft_upper_short_name_SETUP_ETC_DIR} 
	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR} ${TMP_$soft_upper_short_name_SETUP_ETC_DIR}

# 	# -- 服务配置加载
# 	tee /usr/lib/systemd/system/$setup_name.service <<-EOF
# [Unit]
# Description=$soft_upper_name Server Service
# After=network.target

# [Service]
# Type=simple
# User=$setup_owner
# Restart=on-failure
# RestartSec=5s
# ExecStart=/usr/bin/$setup_name -c /etc/$setup_name/$setup_name.ini
# LimitNOFILE=infinity
# LimitNPROC=infinity
# LimitCORE=infinity

# [Install]
# WantedBy=multi-user.target
# EOF
#
#     systemctl daemon-reload

	# -- 授权权限，否则无法写入
	# chown -R $setup_owner:$setup_owner_group ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_$soft_name()
{
	cd ${TMP_$soft_upper_short_name_SETUP_DIR}
	
	# 验证安装
    bin/$setup_name -v
	
    # 当前启动命令 && 等待启动
#     chkconfig $setup_name on
#     chkconfig --list | grep $setup_name
	echo
    echo "Starting $soft_name，Waiting for a moment"
    echo "--------------------------------------------"
	nohup bin/$setup_name > logs/boot.log 2>&1 &
#     nohup systemctl start $setup_name.service > logs/boot.log 2>&1 &
    sleep 15

    cat logs/boot.log
    # cat /var/log/$setup_name/$setup_name.log
    echo "--------------------------------------------"

	# 启动状态检测
	# systemctl status $setup_name.service
	# lsof -i:${TMP_$soft_upper_short_name_SETUP_PORT}
	bin/$setup_name status  

	# 添加系统启动命令
    echo_startup_config "$setup_name" "${TMP_$soft_upper_short_name_SETUP_DIR}" "bin/$setup_name" "" "100"
#     systemctl enable $setup_name.service
	
	# 授权iptables端口访问
	echo_soft_port ${TMP_$soft_upper_short_name_SETUP_PORT}

    # 生成web授权访问脚本
    #echo_web_service_init_scripts "$soft_name${LOCAL_ID}" "$soft_name${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_$soft_upper_short_name_SETUP_PORT} "${LOCAL_HOST}"

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
	# 变量覆盖特性，其它方法均可读取
	local TMP_$soft_upper_short_name_SETUP_DIR=${1}
	local TMP_$soft_upper_short_name_CURRENT_DIR=`pwd`
    
	set_env_$soft_name 

	setup_$soft_name 

	conf_$soft_name 

    # down_plugin_$soft_name 
    # setup_plugin_$soft_name 

	boot_$soft_name 

	# reconf_$soft_name 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_$soft_name()
{
	# local TMP_$soft_upper_short_name_SETUP_OFFICIAL_STABLE_VERS=`curl -s https://www.xxx.com`
	# echo "$title_name: The newer stable version is ${TMP_$soft_upper_short_name_SETUP_OFFICIAL_STABLE_VERS}"
    # local TMP_$soft_upper_short_name_SETUP_NEWER="${TMP_$soft_upper_short_name_SETUP_OFFICIAL_STABLE_VERS}"

	# setup_soft_git "$setup_name" "https://github.com/${git_repo}" "exec_step_$soft_name"
	local TMP_$soft_upper_short_name_SETUP_NEWER="1.0.0"
	set_github_soft_releases_newer_version "TMP_$soft_upper_short_name_SETUP_NEWER" "${git_repo}"
	exec_text_format "TMP_$soft_upper_short_name_SETUP_NEWER" "https://www.xxx.com/downloads/$setup_name-%s.tar.gz"
	# local TMP_$soft_upper_short_name_DOWN_URL_BASE="http://www.xxx.net/projects/releases/"
	# set_newer_by_url_list_link_date "TMP_$soft_upper_short_name_SETUP_NEWER" "${TMP_$soft_upper_short_name_DOWN_URL_BASE}" "$setup_name-.*.tar.gz"
	# set_newer_by_url_list_link_text "TMP_$soft_upper_short_name_SETUP_NEWER" "${TMP_$soft_upper_short_name_DOWN_URL_BASE}" "$setup_name-().tar.gz"
	# exec_text_format "TMP_$soft_upper_short_name_SETUP_NEWER" "${TMP_$soft_upper_short_name_DOWN_URL_BASE}%s"
    setup_soft_wget "$setup_name" "${TMP_$soft_upper_short_name_SETUP_NEWER}" "exec_step_$soft_name"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "$title_name" "down_$soft_name"
