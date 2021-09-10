#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
local TMP_ELK_ES_SETUP_HTTP_PORT=19200
local TMP_ELK_ES_SETUP_TRANS_PORT=19300

##########################################################################################################

# 1-配置环境
function set_env_elasticsearch()
{
    cd ${__DIR}

	ulimit -HSn 65536
	echo "262144" > /proc/sys/vm/max_map_count
	sysctl -p
	
	# 自带jdk，暂省略

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_elasticsearch()
{
	## 直装模式
	cd `dirname ${TMP_ELK_ES_CURRENT_DIR}`

	mv ${TMP_ELK_ES_CURRENT_DIR} ${TMP_ELK_ES_SETUP_DIR}

	cd ${TMP_ELK_ES_SETUP_DIR}

	# 创建日志软链
	local TMP_ELK_ES_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/elasticsearch
	local TMP_ELK_ES_SETUP_LOGS_DIR=${TMP_ELK_ES_SETUP_DIR}/logs

	# 先清理文件，再创建文件
	rm -rf ${TMP_ELK_ES_SETUP_LOGS_DIR}
	mkdir -pv ${TMP_ELK_ES_SETUP_LNK_LOGS_DIR}

	ln -sf ${TMP_ELK_ES_SETUP_LNK_LOGS_DIR} ${TMP_ELK_ES_SETUP_LOGS_DIR}

	# 环境变量或软连接
	echo "ELASTICSEARCH_HOME=${TMP_ELK_ES_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$ELASTICSEARCH_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH ELASTICSEARCH_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

	# 授权权限，否则无法写入
	create_user_if_not_exists elk elk
	chown -R elk:elk ${TMP_ELK_ES_SETUP_DIR}
	chown -R elk:elk ${TMP_ELK_ES_SETUP_LNK_LOGS_DIR}
	
    # 安装初始

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_elasticsearch()
{
	cd ${TMP_ELK_ES_SETUP_DIR}
	
	local TMP_ELK_ES_SETUP_LNK_ETC_DIR=${ATT_DIR}/elasticsearch
	local TMP_ELK_ES_SETUP_ETC_DIR=${TMP_ELK_ES_SETUP_DIR}/config

	# ①-Y：存在配置文件：原路径文件放给真实路径
	mv ${TMP_ELK_ES_SETUP_ETC_DIR} ${TMP_ELK_ES_SETUP_LNK_ETC_DIR}

	ln -sf ${TMP_ELK_ES_SETUP_LNK_ETC_DIR} ${TMP_ELK_ES_SETUP_ETC_DIR}

	# 开始配置
    sed -i "s@^#cluster\.name:.*@#cluster.name: es-cluster-${LOCAL_ID}@g" config/elasticsearch.yml
    sed -i "s@^#node\.name:.*@node.name: es-node-${LOCAL_ID}@g" config/elasticsearch.yml
    sed -i "s@^#cluster\.initial_master_nodes:.*@cluster.initial_master_nodes: [\"es-node-${LOCAL_ID}\"]@g" config/elasticsearch.yml
	
    sed -i "s@^#network\.host:.*@network.host: ${LOCAL_HOST}@g" config/elasticsearch.yml
    sed -i "s@^#http\.port:.*@http.port: ${TMP_ELK_ES_SETUP_HTTP_PORT}@g" config/elasticsearch.yml
    sed -i "/http\.port/a transport.port: ${TMP_ELK_ES_SETUP_TRANS_PORT}" config/elasticsearch.yml
    sed -i "s@^discovery\.seed_hosts:.*@discovery.seed_hosts: [\"[::1]\"]@g" config/elasticsearch.yml

	echo 'http.cors.enabled: true' >> config/elasticsearch.yml
	echo 'http.cors.allow-origin: "*"' >> config/elasticsearch.yml
	
	chown -R elk:elk ${TMP_ELK_ES_SETUP_LNK_ETC_DIR}

	return $?
}

function reconf_elasticsearch()
{
	cd ${TMP_ELK_ES_SETUP_DIR}

	local TMP_ELK_ES_SETUP_LNK_DATA_DIR=${DATA_DIR}/elasticsearch
	local TMP_ELK_ES_SETUP_DATA_DIR=${TMP_ELK_ES_SETUP_DIR}/data

	# 先清理文件，再创建文件
	cp data ${TMP_ELK_ES_SETUP_LNK_DATA_DIR} -Rp
    mv data ${TMP_ELK_ES_SETUP_LNK_DATA_DIR}_empty

	ln -sf ${TMP_ELK_ES_SETUP_LNK_DATA_DIR} ${TMP_ELK_ES_SETUP_DATA_DIR}
	
	# 授权权限，否则无法写入
	chgrp -R elk ${TMP_ELK_ES_SETUP_LNK_DATA_DIR}
	chown -R elk:elk ${TMP_ELK_ES_SETUP_LNK_DATA_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_elasticsearch()
{
	cd ${TMP_ELK_ES_SETUP_DIR}
	
	# 验证安装
    bin/elasticsearch -V

	# 当前启动命令
	#影响设定的启动文件.bash_profile、/etc/profile或/etc/security/limits.conf
	# su - elk -c "nohup bin/elasticsearch >/dev/null 2>&1 &"
	su - elk -c "cd ${TMP_ELK_ES_SETUP_DIR} && nohup bin/elasticsearch > logs/boot.log 2>&1 &"
	
    # 等待启动
    echo "Starting elasticsearch，Waiting for a moment，it will take 1 minutes..."
    echo "--------------------------------------------"
    sleep 60

    cat logs/boot.log
    echo "--------------------------------------------"

	# 启动状态检测
	lsof -i:${TMP_ELK_ES_SETUP_HTTP_PORT}

	# 添加系统启动命令
    echo_startup_config "elasticsearch" "${TMP_ELK_ES_SETUP_DIR}" "bin/elasticsearch" "" "1" "" "elk"
	
	# 授权iptables端口访问
	echo_soft_port ${TMP_ELK_ES_SETUP_HTTP_PORT}
	echo_soft_port ${TMP_ELK_ES_SETUP_TRANS_PORT}

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_elasticsearch()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_elasticsearch()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_elasticsearch()
{
	# 变量覆盖特性，其它方法均可读取
	local TMP_ELK_ES_SETUP_DIR=${1}
	local TMP_ELK_ES_CURRENT_DIR=`pwd`
    
	set_env_elasticsearch 

	setup_elasticsearch 

	conf_elasticsearch 

    # down_plugin_elasticsearch 
    # setup_plugin_elasticsearch 

	boot_elasticsearch 

	reconf_elasticsearch 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_elasticsearch()
{
	local TMP_ELK_ES_SETUP_NEWER="7.8.0"
	set_github_soft_releases_newer_version "TMP_ELK_ES_SETUP_NEWER" "elastic/elasticsearch"
	exec_text_format "TMP_ELK_ES_SETUP_NEWER" "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-%s-linux-x86_64.tar.gz"
    setup_soft_wget "elasticsearch" "${TMP_ELK_ES_SETUP_NEWER}" "exec_step_elasticsearch"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "ElasticSearch" "down_elasticsearch"
