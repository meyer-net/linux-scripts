#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
# 安装标题：MongoDB
# 软件名称：mongodb
# 软件端口：$soft_port
# 软件大写分组与简称：MGDB
# 软件安装名称：mongodb
# 软件授权用户名称&组：mongod/mongod
#------------------------------------------------
local TMP_MGDB_SETUP_PORT=27017

##########################################################################################################

# 1-配置环境
function set_env_mongodb()
{
    cd ${__DIR}

    soft_yum_check_setup "check-update"

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_mongodb()
{
	## 源模式
	cat << EOF | sudo tee -a /etc/yum.repos.d/mongodb-org-4.0.repo
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF

	soft_yum_check_setup "mongodb-org"

	# 创建日志软链
	local TMP_MGDB_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/mongodb
	local TMP_MGDB_SETUP_LNK_DATA_DIR=${DATA_DIR}/mongodb
	local TMP_MGDB_SETUP_LOGS_DIR=${TMP_MGDB_SETUP_DIR}/logs
	local TMP_MGDB_SETUP_DATA_DIR=${TMP_MGDB_SETUP_DIR}/data

	# 先清理文件，再创建文件
    rm -rf ${TMP_MGDB_SETUP_LOGS_DIR}
	path_not_exists_create ${TMP_MGDB_SETUP_DIR}
	
	cd ${TMP_MGDB_SETUP_DIR}
	
	rm -rf ${TMP_MGDB_SETUP_LOGS_DIR}
	rm -rf ${TMP_MGDB_SETUP_DATA_DIR}
	path_not_exists_create ${TMP_MGDB_SETUP_LNK_LOGS_DIR}
	cp /var/lib/mongo ${TMP_MGDB_SETUP_LNK_DATA_DIR} -Rp
    mv /var/lib/mongo ${TMP_MGDB_SETUP_LNK_DATA_DIR}_empty
	
	ln -sf ${TMP_MGDB_SETUP_LNK_LOGS_DIR} ${TMP_MGDB_SETUP_LOGS_DIR}
	ln -sf ${TMP_MGDB_SETUP_LNK_DATA_DIR} ${TMP_MGDB_SETUP_DATA_DIR}
	ln -sf ${TMP_MGDB_SETUP_LNK_DATA_DIR} /var/lib/mongo

	# 授权权限，否则无法写入
	create_user_if_not_exists mongod mongod
	chown -R mongod:mongod ${TMP_MGDB_SETUP_LNK_LOGS_DIR}
	chown -R mongod:mongod ${TMP_MGDB_SETUP_LNK_DATA_DIR}

	rm -rf /etc/yum.repos.d/mongodb.repo
	
    sudo yum clean all && sudo yum makecache fast
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_mongodb()
{
	cd ${TMP_MGDB_SETUP_DIR}
	
	local TMP_MGDB_SETUP_LNK_ETC_DIR=${ATT_DIR}/mongodb
	local TMP_MGDB_SETUP_ETC_DIR=${TMP_MGDB_SETUP_DIR}/etc

	# ①-Y：存在配置文件：原路径文件放给真实路径
	rm -rf ${TMP_MGDB_SETUP_ETC_DIR}
	path_not_exists_create "${TMP_MGDB_SETUP_LNK_ETC_DIR}"
    
	# 替换原路径链接
    ln -sf /etc/mongod.conf ${TMP_MGDB_SETUP_LNK_ETC_DIR}/mongod.conf
	ln -sf ${TMP_MGDB_SETUP_LNK_ETC_DIR} ${TMP_MGDB_SETUP_ETC_DIR}
	
    # 开始配置(默认依照rc需求安装配置)
    sed -i "s@^#  engine:@  engine: mmapv1@" etc/mongod.conf
    sed -i "s@^#replication:@replication:\n  replSetName: rs01@" etc/mongod.conf 

    sed -i "s@^  port:@  port: ${TMP_MGDB_SETUP_PORT}/" etc/mongod.conf
    sed -i "s@^  bindIp:@  bindIp: ${LOCAL_HOST}/" etc/mongod.conf

	# 授权权限，否则无法写入
	# chown -R mongod:mongod ${TMP_MGDB_SETUP_LNK_ETC_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_mongodb()
{
	cd ${TMP_MGDB_SETUP_DIR}
	
	# 验证安装
    mongo --version  # lsof -i:${TMP_MGDB_SETUP_PORT}

	# 当前启动命令
    sudo systemctl daemon-reload
    sudo systemctl enable mongod.service

    # 等待启动
    echo "Starting mongodb，Waiting for a moment"
    echo "--------------------------------------------"
    sudo systemctl start mongod.service
    sleep 5
    mongo --eval "printjson(rs.initiate())"
    sleep 5

	sudo systemctl status mongod.service
    sudo chkconfig mongod on
    # journalctl -u mongod --no-pager | less
    # sudo systemctl reload mongod.service
    echo "--------------------------------------------"

	# 授权iptables端口访问
	echo_soft_port ${TMP_MGDB_SETUP_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_mongodb()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_mongodb()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_mongodb()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_MGDB_SETUP_DIR=${SETUP_DIR}/mongodb
    
	set_env_mongodb 

	setup_mongodb 

	conf_mongodb 

    # down_plugin_mongodb 
    # setup_plugin_mongodb 

	boot_mongodb 

	# reconf_mongodb 

	return $?
}

##########################################################################################################

# x1-下载软件
function check_setup_mongodb()
{
    soft_yum_check_action "mongodb-org" "exec_step_mongodb" "MongoDB was installed"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "MongoDB" "check_setup_mongodb"

