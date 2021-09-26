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
	## 源模式
	# -- 1：
	local TMP_$soft_upper_short_name_SETUP_RPM_NEWER="$soft_name.noarch.rpm"
	local TMP_$soft_upper_short_name_DOWN_URL_BASE="http://www.xxx.net/rpm/stable/x86_64/"
	# set_newer_by_url_list_link_date "TMP_$soft_upper_short_name_SETUP_RPM_NEWER" "${TMP_$soft_upper_short_name_DOWN_URL_BASE}" "$setup_name-.*.noarch.rpm"
	set_newer_by_url_list_link_text "TMP_$soft_upper_short_name_SETUP_RPM_NEWER" "${TMP_$soft_upper_short_name_DOWN_URL_BASE}" "$setup_name-().noarch.rpm"
	exec_text_format "TMP_$soft_upper_short_name_SETUP_RPM_NEWER" "${TMP_$soft_upper_short_name_DOWN_URL_BASE}%s"
    while_wget "--content-disposition http://xxx.xyz.com/get/${TMP_$soft_upper_short_name_SETUP_RPM_NEWER}" "rpm -ivh ${TMP_$soft_upper_short_name_SETUP_RPM_NEWER}"
	
	soft_yum_check_setup "$soft_name"

	# -- 2：
	# local TMP_$soft_upper_short_name_SETUP_SH_NEWER="v0.0.0"
	# local TMP_$soft_upper_short_name_SETUP_SH_FILE_NEWER="install_$soft_name.sh"
	# set_github_soft_releases_newer_version "TMP_$soft_upper_short_name_SETUP_SH_NEWER" "${git_repo}"
	# exec_text_format "TMP_$soft_upper_short_name_SETUP_SH_NEWER" "https://raw.githubusercontent.com/${git_repo}/%s/install.sh"
    # while_curl "${TMP_$soft_upper_short_name_SETUP_SH_NEWER} -o ${TMP_$soft_upper_short_name_SETUP_SH_FILE_NEWER} | bash ${TMP_$soft_upper_short_name_SETUP_SH_FILE_NEWER}"

	# 创建日志软链
	local TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR=${DATA_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_LOGS_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/logs
	local TMP_$soft_upper_short_name_SETUP_DATA_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/data

	# 先清理文件，再创建文件
	path_not_exists_create "${TMP_$soft_upper_short_name_SETUP_DIR}"
	
	cd ${TMP_$soft_upper_short_name_SETUP_DIR}
	
	rm -rf ${TMP_$soft_upper_short_name_SETUP_LOGS_DIR}
	rm -rf ${TMP_$soft_upper_short_name_SETUP_DATA_DIR}
	path_not_exists_create "${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR}"
	path_not_exists_create "${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}"
	# mv /var/lib/$setup_name ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}
	## cp /var/lib/$setup_name ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR} -Rp
    ## mv /var/lib/$setup_name ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}_empty
	
	# 特殊多层结构下使用
    path_not_exists_create `dirname ${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR}`
    path_not_exists_create `dirname ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}`

	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR} ${TMP_$soft_upper_short_name_SETUP_LOGS_DIR}
	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR} ${TMP_$soft_upper_short_name_SETUP_DATA_DIR}
	# ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR} /var/lib/$setup_name

	# 授权权限，否则无法写入
	# create_user_if_not_exists $setup_owner $setup_owner_group
	# chown -R $setup_owner:$setup_owner_group ${TMP_$soft_upper_short_name_SETUP_LNK_LOGS_DIR}
	# chown -R $setup_owner:$setup_owner_group ${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}

    # 安装初始

	rm -rf ${TMP_$soft_upper_short_name_SETUP_RPM_NEWER}

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_$soft_name()
{
	cd ${TMP_$soft_upper_short_name_SETUP_DIR}
	
	local TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR=${ATT_DIR}/$setup_name
	local TMP_$soft_upper_short_name_SETUP_ETC_DIR=${TMP_$soft_upper_short_name_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_$soft_upper_short_name_SETUP_ETC_DIR} ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}

	# ①-N：不存在配置文件：
	# rm -rf ${TMP_$soft_upper_short_name_SETUP_ETC_DIR}
	# path_not_exists_create "${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}"

	# 特殊多层结构下使用
    # path_not_exists_create `dirname ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}`

	# 替换原路径链接
    # ln -sf /etc/$soft_name ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR} 
    # ln -sf /etc/$soft_name ${TMP_$soft_upper_short_name_SETUP_ETC_DIR} 
	ln -sf ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR} ${TMP_$soft_upper_short_name_SETUP_ETC_DIR}
	
    # 开始配置

    systemctl daemon-reload

	# 授权权限，否则无法写入
	# chown -R $setup_owner:$setup_owner_group ${TMP_$soft_upper_short_name_SETUP_LNK_ETC_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_$soft_name()
{
	cd ${TMP_$soft_upper_short_name_SETUP_DIR}
	
	# 验证安装
    $setup_name -v  # lsof -i:${TMP_$soft_upper_short_name_SETUP_PORT}

    # 当前启动命令 && 等待启动
	chkconfig $setup_name on
	chkconfig --list | grep $setup_name
	echo
    echo "Starting $soft_name，Waiting for a moment"
    echo "--------------------------------------------"
    nohup systemctl start $setup_name.service > logs/boot.log 2>&1 &
	# nohup bin/$setup_name > logs/boot.log 2>&1 &
    sleep 15

    cat logs/boot.log
    cat /var/log/$setup_name/$setup_name.log
    # journalctl -u $setup_name --no-pager | less
    # systemctl reload $setup_name.service
    echo "--------------------------------------------"

	# 启动状态检测
	systemctl status $setup_name.service
	lsof -i:${TMP_$soft_upper_short_name_SETUP_PORT}

	# 添加系统启动命令（RPM还是需要）
    # echo_startup_config "$setup_name" "${TMP_$soft_upper_short_name_SETUP_DIR}" "bin/$setup_name" "" "100"
	systemctl enable $setup_name.service

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
	local TMP_$soft_upper_short_name_SETUP_DIR=${SETUP_DIR}/$setup_name
    
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
function check_setup_$soft_name()
{
	# local TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR=${DATA_DIR}/$setup_name
    # path_not_exists_action "${TMP_$soft_upper_short_name_SETUP_LNK_DATA_DIR}" "exec_step_$soft_name" "$title_name was installed"

	soft_rpm_check_action "$setup_name" "exec_step_$soft_name" "$title_name was installed"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "$title_name" "check_setup_$soft_name"

