#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_kibana()
{
    groupadd elk
    useradd -g elk elk

    # 安装插件需要提前安装nodejs
    cd $WORK_PATH
    source scripts/lang/nodejs.sh

	return $?
}

function setup_kibana()
{
	KIBANA_CURRENT_DIR=`pwd`

	cd ..
	local KIBANA_DIR=$SETUP_DIR/kibana
	mv $KIBANA_CURRENT_DIR $KIBANA_DIR
	chown -R elk:elk $KIBANA_DIR

	cd $KIBANA_DIR
    sed -i "s@#server\.port@server.port@g" config/kibana.yml
    sed -i "s@#server\.host.*@server.host: \"0.0.0.0\"@g" config/kibana.yml

	local ELASTICSEARCH_HOST=$LOCAL_HOST
    input_if_empty "ELASTICSEARCH_HOST" "Kibana: Please ender your ${red}elasticsearch host address${reset} like '$LOCAL_HOST'"
    sed -i "s@#elasticsearch\.url:.*@elasticsearch.url: \"http://$ELASTICSEARCH_HOST:9200\"@g" config/kibana.yml
	
	local KIBANA_LOGS_DIR=$KIBANA_DIR/logs
	local KIBANA_DATA_DIR=$KIBANA_DIR/data

	mkdir -pv $LOGS_DIR/kibana
	mkdir -pv $DATA_DIR/kibana
	ln -sf $LOGS_DIR/kibana $KIBANA_LOGS_DIR 
	ln -sf $DATA_DIR/kibana $KIBANA_DATA_DIR 

	chown -R elk:elk $KIBANA_DATA_DIR
	chown -R elk:elk $KIBANA_LOGS_DIR

	boot_kibana $KIBANA_DIR

    echo_soft_port 5601

	return $?
}

function boot_kibana()
{
	KIBANA_DIR=$1

	cd $KIBANA_DIR

	su - elk -c "cd $KIBANA_DIR && nohup bash bin/kibana &"
	
    echo_startup_config "kibana" "$KIBANA_DIR" "screen bash bin/kibana"

	return $?
}

function down_kibana()
{
	set_kibana
    setup_soft_wget "kibana" "https://artifacts.elastic.co/downloads/kibana/kibana-7.3.1-linux-x86_64-linux-x86_64.tar.gz" "setup_kibana"

	return $?
}

setup_soft_basic "Kibana" "down_kibana"
