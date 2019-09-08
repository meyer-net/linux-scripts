#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_logstash()
{	
    groupadd elk
    useradd -g elk elk
	echo

	return $?
}

function setup_logstash()
{
	LOGSTASH_CURRENT_DIR=`pwd`

	cd ..
	local LOGSTASH_DIR=$SETUP_DIR/logstash
	mv $LOGSTASH_CURRENT_DIR $LOGSTASH_DIR
	chown -R elk:elk $LOGSTASH_DIR

	cd $LOGSTASH_DIR

	local LOGSTASH_LOGS_DIR=$LOGSTASH_DIR/logs
	local LOGSTASH_DATA_DIR=$LOGSTASH_DIR/data

	mkdir -pv $LOGS_DIR/logstash
	mkdir -pv $DATA_DIR/logstash

	ln -sf $LOGSTASH_LOGS_DIR $LOGS_DIR/logstash
	ln -sf $LOGSTASH_DATA_DIR $DATA_DIR/logstash

	chown -R elk:elk $LOGSTASH_DATA_DIR
	chown -R elk:elk $LOGSTASH_LOGS_DIR

	cp config/logstash-sample.conf config/logstash.conf

	local ELASTICSEARCH_HOST=$LOCAL_HOST
    input_if_empty "ELASTICSEARCH_HOST" "Logstash: Please ender your ${red}elasticsearch host address${reset} like '$LOCAL_HOST'"
    sed -i "s@localhost@$ELASTICSEARCH_HOST@g" config/logstash.conf

	boot_logstash $LOGSTASH_DIR

	return $?
}

function boot_logstash()
{
	LOGSTASH_DIR=$1

	cd $LOGSTASH_DIR
	
	# （1）测试启动，看配置文件是否正确：
	bin/logstash -f first-pipeline.conf --config.test_and_exit
	# （2）以config.reload.automatic方式启动，这样在修改配置文件后无需重新启动，它会自动加载：bin/logstash -f first-pipeline.conf --config.reload.automatic
	# （3）列出所有已安装的插件：
	bin/logstash-plugin list
	# （4）安装外部的插件：bin/logstash-plugin install [插件名称]
	# （5）更新所有插件：
	bin/logstash-plugin update
	# （6）更新指定插件：bin/logstash-plugin update logstash-output-kafka
	# （7）删除指定插件：bin/logstash-plugin remove logstash-output-kafka
	# 测试conf文件是否正确配置
	bin/logstash -f config/logstash.conf --config.test_and_exit

	# 启动logstash，如果有修改conf会自动加载
	su - elk -c "cd $LOGSTASH_DIR && nohup bin/logstash -f config/logstash.conf --config.reload.automatic &" 
	
    echo_startup_config "logstash" "$LOGSTASH_DIR" "screen bash bin/logstash -f config/logstash.conf --config.reload.automatic"

	return $?
}

function down_logstash()
{
	set_logstash
    setup_soft_wget "logstash" "https://artifacts.elastic.co/downloads/logstash/logstash-7.1.1.tar.gz" "setup_logstash"

	return $?
}

setup_soft_basic "LogStash" "down_logstash"
