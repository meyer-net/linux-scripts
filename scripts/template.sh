#!/bin/bash
#------------------------------------------------
#      centos7 project env installscript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

#临时变量
local TMP_SETUP_TEMPLATE_DIR=$SETUP_DIR/template

#全局变量
local TEMPLATE_LOGS_DIR=$LOGS_DIR/template

function set_environment()
{
	return $?
}

function setup_template()
{
    echo "setup"
	return $?
}


function down_template()
{
	local TMP_CURRENT_UNZIP_DIR="$1"

    cd ..
	
    mv template $TMP_SETUP_TEMPLATE_DIR

    #软连接
    #ln -sf /usr/local/template $TMP_SETUP_TEMPLATE_DIR

    mkdir -pv $TEMPLATE_LOGS_DIR
    ln -sf $TEMPLATE_LOGS_DIR $TMP_SETUP_TEMPLATE_DIR/logs

    echo "----------------------------------------------------"
    echo "Template: System start find the newer stable version"
    echo "----------------------------------------------------"
	local TMP_TEMPLATE_NEWER_VERSION=``
    local TMP_TEMPLATE_DOWNLOAD_URL=""

    echo "Template: The newer stable version is $TMP_TEMPLATE_NEWER_VERSION"
    echo "----------------------------------------------------"
    setup_soft_wget "Template" "$TMP_TEMPLATE_DOWNLOAD_URL" "setup_template"

	return $?
}

set_environment
setup_soft_basic "Template" "down_template"
