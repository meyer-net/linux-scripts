#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_filebeat()
{	
    groupadd elk
    useradd -g elk elk

	return $?
}

function setup_filebeat()
{
	FILEBEAT_CURRENT_DIR=`pwd`

	cd ..
	local FILEBEAT_DIR=$SETUP_DIR/filebeat
	mv $FILEBEAT_CURRENT_DIR $FILEBEAT_DIR
	chown -R elk:elk $FILEBEAT_DIR

	local FILEBEAT_INPUTS_LINE=`cat $FILEBEAT_DIR/filebeat.yml | awk '/filebeat.inputs:/ {print NR}'`
	local FILEBEAT_PATHS_LINE_IN_PART=`cat $FILEBEAT_DIR/filebeat.yml | grep -A 15 "filebeat.inputs:" | awk '/  paths:/ {print NR}'`
	local FILEBEAT_PATHS_FILE_LINE=$((FILEBEAT_INPUTS_LINE+FILEBEAT_PATHS_LINE_IN_PART))
	find $SYNC_DIR -name *.log | sed 's@\w*.log$@*.log@g' | uniq | xargs -I {} sed -i "${FILEBEAT_PATHS_FILE_LINE}a\    - {}" $FILEBEAT_DIR/filebeat.yml

	local FILEBEAT_ENABLED_LINE_IN_PART=`cat $FILEBEAT_DIR/filebeat.yml | grep -A 10 "filebeat.inputs:" | awk '/enabled:/ {print NR}'`
	local FILEBEAT_ENABLED_FILE_LINE=$((FILEBEAT_INPUTS_LINE+FILEBEAT_ENABLED_LINE_IN_PART-1))
	sed -i "${FILEBEAT_ENABLED_FILE_LINE}s@enabled: false@enabled: true@g" $FILEBEAT_DIR/filebeat.yml


	boot_filebeat $FILEBEAT_DIR

	return $?
}

function boot_filebeat()
{
	FILEBEAT_DIR=$1
	su - elk -c "cd $FILEBEAT_DIR && nohup filebeat -e -c filebeat.yml -d \"publish\" &" 
	
    echo_startup_config "filebeat" "$FILEBEAT_DIR" "screen ./filebeat -e -c filebeat.yml -d \"publish\""

	return $?
}

function down_filebeat()
{
	set_filebeat
	
    setup_soft_wget "filebeat" "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.3.1-linux-x86_64-linux-x86_64.tar.gz" "setup_filebeat"

	return $?
}

setup_soft_basic "FileBeat" "down_filebeat"
