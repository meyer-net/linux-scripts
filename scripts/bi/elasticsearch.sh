#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
#https://www.jianshu.com/p/ea15478f51e3

# 1-配置环境
function set_environment()
{
	create_user_if_not_exists elk elk

	ulimit -HSn 65536
	echo "262144" > /proc/sys/vm/max_map_count
	sysctl -p

	return $?
}

# 2-安装软件
function setup_elasticsearch()
{
	local TMP_ELK_ES_SETUP_DIR=${1}
	local TMP_ELK_ES_CURRENT_DIR=`pwd`
	
	cd ..
	mv ${TMP_ELK_ES_CURRENT_DIR:-} ${TMP_ELK_ES_SETUP_DIR}

	local TMP_ELK_ES_LNK_LOGS_DIR=${LOGS_DIR}/elasticsearch
	local TMP_ELK_ES_LNK_DATA_DIR=${DATA_DIR}/elasticsearch
	local TMP_ELK_ES_LOGS_DIR=${TMP_ELK_ES_SETUP_DIR}/logs
	local TMP_ELK_ES_DATA_DIR=${TMP_ELK_ES_SETUP_DIR}/data

	# 先清理文件，再创建文件
	rm -rf ${TMP_ELK_ES_LOGS_DIR}
	rm -rf ${TMP_ELK_ES_DATA_DIR}
	mkdir -pv ${TMP_ELK_ES_LNK_LOGS_DIR}
	mkdir -pv ${TMP_ELK_ES_LNK_DATA_DIR}

	ln -sf ${TMP_ELK_ES_LNK_LOGS_DIR} ${TMP_ELK_ES_LOGS_DIR}
	ln -sf ${TMP_ELK_ES_LNK_DATA_DIR} ${TMP_ELK_ES_DATA_DIR}

	# 授权权限，否则无法写入
	chown -R elk:elk ${TMP_ELK_ES_SETUP_DIR}
	chown -R elk:elk ${TMP_ELK_ES_LNK_LOGS_DIR}
	chown -R elk:elk ${TMP_ELK_ES_LNK_DATA_DIR}

    echo_soft_port 9200

	return $?
}

# 3-设置软件
function set_elasticsearch()
{
	cd ${1}

    sed -i "s@#node\.name:.*@node.name: node-default@g" config/elasticsearch.yml
    sed -i "s@#cluster\.initial_master_nodes:.*@cluster.initial_master_nodes: [\"node-default\"]@g" config/elasticsearch.yml
	
    sed -i "s@#network\.host:.*@network.host: 0.0.0.0@g" config/elasticsearch.yml
    sed -i "s@discovery\.seed_hosts:.*@discovery.seed_hosts: [\"[::1]\"]@g" config/elasticsearch.yml

	echo 'http.cors.enabled: true' >> config/elasticsearch.yml
	echo 'http.cors.allow-origin: "*"' >> config/elasticsearch.yml

	return $?
}

# 4-启动软件
function boot_elasticsearch()
{
	local TMP_ELK_ES_SETUP_DIR=${1}

	#影响设定的启动文件.bash_profile、/etc/profile或/etc/security/limits.conf
	# su - elk -c "nohup bash bin/elasticsearch >/dev/null 2>&1 &"
	su - elk -c "cd ${TMP_ELK_ES_SETUP_DIR} && nohup bash bin/elasticsearch &"
	
    echo_startup_config "elasticsearch" "${TMP_ELK_ES_SETUP_DIR}" "bash bin/elasticsearch" "" "1" "" "elk"

	return $?
}

# x-执行步骤
function exec_step_elasticsearch()
{
	local TMP_ELK_ES_SETUP_DIR=${1}

	set_environment "${TMP_ELK_ES_SETUP_DIR}"

	setup_elasticsearch "${TMP_ELK_ES_SETUP_DIR}"

	set_elasticsearch "${TMP_ELK_ES_SETUP_DIR}"

	boot_elasticsearch "${TMP_ELK_ES_SETUP_DIR}"

	return $?
}

# x-下载软件
function down_elasticsearch()
{
	ELK_ELASTICSEARCH_SETUP_NEWER="7.8.0"
	set_github_soft_releases_newer_version "ELK_ELASTICSEARCH_SETUP_NEWER" "elastic/elasticsearch"
	exec_text_format "ELK_ELASTICSEARCH_SETUP_NEWER" "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-%-linux-x86_64.tar.gz"
    setup_soft_wget "elasticsearch" "$ELK_ELASTICSEARCH_SETUP_NEWER" "exec_step_elasticsearch"

	return $?
}

setup_soft_basic "ElasticSearch" "down_elasticsearch"
