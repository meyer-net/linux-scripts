#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
#https://www.jianshu.com/p/ea15478f51e3

function set_es()
{	
    groupadd elk
    useradd -g elk elk
	passwd elk

    # 安装插件需要提前安装nodejs
    # cd $WORK_PATH
    # source scripts/lang/nodejs.sh

	return $?
}

function setup_es()
{
	ES_CURRENT_DIR=`pwd`

	cd ..
	local ES_DIR=$SETUP_DIR/elasticsearch
	mv $ES_CURRENT_DIR $ES_DIR
	chown -R elk:elk $ES_DIR

	cd $ES_DIR
    # sed -i "s@#path.data:.*@path.data: $ES_DATA_DIR@g" config/elasticsearch.yml
    # sed -i "s@#path.logs:.*@path.logs: $ES_LOGS_DIR@g" config/elasticsearch.yml

	local ES_LOGS_DIR=$ES_DIR/logs
	local ES_DATA_DIR=$ES_DIR/data

	mkdir -pv $LOGS_DIR/elasticsearch
	mkdir -pv $DATA_DIR/elasticsearch

	ln -sf $LOGS_DIR/elasticsearch $ES_LOGS_DIR
	ln -sf $DATA_DIR/elasticsearch $ES_DATA_DIR

	chown -R elk:elk $ES_DATA_DIR
	chown -R elk:elk $ES_LOGS_DIR

	ulimit -HSn 65536
	echo "262144" > /proc/sys/vm/max_map_count
	sysctl -p
    sed -i "s@#network\.host:.*@network.host: 0.0.0.0@g" config/elasticsearch.yml

	echo 'http.cors.enabled: true' >> config/elasticsearch.yml
	echo 'http.cors.allow-origin: "*"' >> config/elasticsearch.yml

	boot_es $ES_DIR

	return $?
}

function boot_es()
{
	ES_DIR=$1

	cd $ES_DIR

	#影响设定的启动文件.bash_profile、/etc/profile或/etc/security/limits.conf
	su - elk -c "cd $ES_DIR && screen bash bin/elasticsearch"

    echo_startup_config "elasticsearch" "$ES_DIR" "su elk && bash bin/elasticsearch"

	return $?
}

function down_es()
{
	set_es
    setup_soft_wget "elasticsearch" "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.3.1.tar.gz" "setup_es"

	return $?
}

setup_soft_basic "ElasticSearch" "down_es"
