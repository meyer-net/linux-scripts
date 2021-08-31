#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
#https://github.com/MyCATApache/Mycat-Server
function set_environment()
{
    # 需要提前安装Java
    cd ${__DIR}
    source scripts/lang/java.sh

	return $?
}

function setup_mycat()
{
    cd ..
    mv mycat $SETUP_DIR

    echo "MYCAT_HOME=$MYCAT_DIR" >> /etc/profile
    echo "PATH=\$PATH:\$MYCAT_HOME" >> /etc/profile
    source /etc/profile

    sed -i "s@^wrapper.java.command=.*@wrapper.java.command=$JAVA_HOME/bin/java@g" $MYCAT_DIR/conf/wrapper.conf
    #192.168.1.200:3306 && password="" /conf/schema.conf

    #添加软链接与服务启动
    ln -sf $MYCAT_DIR/bin/mycat /usr/local/bin/mycat

    mycat start  #启动Nginx-Master
    #echo "service mycat start" >> /etc/rc.local
    echo_startup_config "mycat" "$MYCAT_DIR/bin" "mycat start"

	return $?
}


function down_mycat()
{
    set_environment
    # setup_soft_wget "mycat" "http://dl.mycat.io/1.6-RELEASE/Mycat-server-1.6-RELEASE-20161028204710-linux.tar.gz" "setup_mycat"
    setup_soft_wget "mycat" "http://dl.mycat.io/1.6.6.1/http://dl.mycat.io/1.6.6.1/Mycat-server-1.6.6.1-release-20181031195535-linux.tar.gz" "setup_mycat"

	return $?
}

setup_soft_basic "MyCat" "down_mycat"
