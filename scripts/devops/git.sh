#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#         https://www.jianshu.com/p/bbf1f72dd939
#         https://juejin.im/post/5cb9204be51d456e541b4ccd
#------------------------------------------------
# Gitlab的服务有很多的组件构成的,如:
# nginx:              静态web服务器
# gitlab‐workhorse:   轻量级的反向代理服务器
# logrotate：         日志文件管理工具
# postgresql：        数据库
# redis：             缓存数据库
# sidekiq：           用于在后台执行队列任务(异步执行),(Ruby)
# unicorn：           An HTTP server for Rack applications，GitLab Rails应用是托管在这个服务器上面的。（RubyWeb Server,主要使用Ruby编写）
# 
# 修改root密码：
# gitlab-rails console -e production
# user.password = '12345678'
# user.password_confirmation = '12345678'
# user.save!
#------------------------------------------------

local TMP_GIT_SETUP_PORT=10180

##########################################################################################################

# 1-配置环境
function set_env_gitlab()
{
    cd ${__DIR}

    soft_yum_check_setup "patch"

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_gitlab()
{
	## 源模式
	curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | sudo bash

	soft_yum_check_setup "gitlab-ce"

	# 创建日志软链
	local TMP_GIT_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/gitlab
	local TMP_GIT_SETUP_LNK_DATA_DIR=${DATA_DIR}/gitlab
	local TMP_GIT_SETUP_LOGS_DIR=${TMP_GIT_SETUP_DIR}/logs
	local TMP_GIT_SETUP_DATA_DIR=${TMP_GIT_SETUP_DIR}/data

	# 先清理文件，再创建文件
	path_not_exists_create ${TMP_GIT_SETUP_DIR}
	
	cd ${TMP_GIT_SETUP_DIR}
	
	rm -rf ${TMP_GIT_SETUP_LOGS_DIR}
	rm -rf ${TMP_GIT_SETUP_DATA_DIR}
	path_not_exists_create "${TMP_GIT_SETUP_LNK_LOGS_DIR}"
	path_not_exists_create "${TMP_GIT_SETUP_LNK_DATA_DIR}"
    
	ln -sf ${TMP_GIT_SETUP_LNK_LOGS_DIR} ${TMP_GIT_SETUP_LOGS_DIR}
	ln -sf ${TMP_GIT_SETUP_LNK_DATA_DIR} ${TMP_GIT_SETUP_DATA_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_gitlab()
{
	cd ${TMP_GIT_SETUP_DIR}
	
	local TMP_GIT_SETUP_LNK_ETC_DIR=${ATT_DIR}/gitlab
	local TMP_GIT_SETUP_ETC_DIR=${TMP_GIT_SETUP_DIR}/etc #(该路径安装完成后即存在)
	local TMP_GIT_SETUP_DATA_DIR=${TMP_GIT_SETUP_DIR}/data

    # 开始配置
    sed -i "s@^external_url.*@external_url http://${LOCAL_HOST}:${TMP_GIT_SETUP_PORT}@g" /etc/gitlab/gitlab.rb
    
    ## 以下设置 解决gitlab占用大量内存问题
    sed -i "s@^# puma\['worker_processes'\].*@puma['worker_processes'] = 4@g" /etc/gitlab/gitlab.rb
    sed -i "s@^# postgresql\['max_worker_processes'\].*@postgresql['max_worker_processes'] = 4@g" /etc/gitlab/gitlab.rb
    sed -i "s@^# nginx\['worker_processes'\].*@nginx['worker_processes'] = 4@g" /etc/gitlab/gitlab.rb

    ## 修改仓储目录
    cat >>/etc/gitlab/gitlab.rb<<EOF
git_data_dirs({
  "default" => {
    "path" => "${TMP_GIT_SETUP_DATA_DIR}"
   }
})
EOF

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_GIT_SETUP_ETC_DIR} ${TMP_GIT_SETUP_LNK_ETC_DIR}
    cp /etc/gitlab/gitlab.rb ${TMP_GIT_SETUP_LNK_ETC_DIR}/gitlab_initbak.rb
    mv /etc/gitlab/gitlab.rb ${TMP_GIT_SETUP_LNK_ETC_DIR}/
    rm -rf /etc/gitlab

	# 替换原路径链接
	ln -sf ${TMP_GIT_SETUP_LNK_ETC_DIR} /etc/gitlab
	ln -sf ${TMP_GIT_SETUP_LNK_ETC_DIR} ${TMP_GIT_SETUP_ETC_DIR}
	
	return $?
}

##########################################################################################################

# 4-启动软件
function boot_gitlab()
{
	cd ${TMP_GIT_SETUP_DIR}
	
	# 验证安装
	cat embedded/service/gitlab-rails/VERSION
	gitlab gitlab-rake gitlab:check SANITIZE=true --trace
    gitlab-ctl check-config
    gitlab-ctl upgrade-check

    # 当前启动命令 && 等待启动
	echo
    echo "Starting gitlab，Waiting for a moment"
    echo "--------------------------------------------"
    gitlab-ctl reconfigure > logs/boot.log
    gitlab-rake cache:clear RAILS_ENV=production
    gitlab-ctl start >> logs/boot.log
    sleep 5

    cat logs/boot.log
    echo "--------------------------------------------"

	# 启动状态检测
	lsof -i:${TMP_GIT_SETUP_PORT}
	gitlab-ctl status
	
	# 添加系统启动命令(自带启动，此处略)
    echo_startup_config "gitlab" "${TMP_GIT_SETUP_DIR}" "gitlab-ctl tail" "" "99"

	# 授权iptables端口访问
	echo_soft_port ${TMP_GIT_SETUP_PORT}

    # 生成web授权访问脚本
    echo_web_service_init_scripts "gitlab${LOCAL_ID}" "gitlab${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_GIT_SETUP_PORT} "${LOCAL_HOST}"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_gitlab()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_gitlab()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_gitlab()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_GIT_SETUP_DIR=${SETUP_DIR}/gitlab
    
	set_env_gitlab 

	setup_gitlab 

	conf_gitlab 

    # down_plugin_gitlab 
    # setup_plugin_gitlab 

	boot_gitlab 

	# reconf_gitlab 

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_gitlab()
{
	local TMP_GIT_SETUP_LNK_DATA_DIR=${DATA_DIR}/gitlab
    path_not_exists_action "${TMP_GIT_SETUP_LNK_DATA_DIR}" "exec_step_gitlab" "gitlab was installed"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "gitlab" "check_setup_gitlab"