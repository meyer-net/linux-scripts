#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_env()
{
	yum -y install tcl

    # fix the version upper then 6.0
    yum -y install centos-release-scl
    yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
    scl enable devtoolset-9 bash
    gcc -v
    # echo "source /opt/rh/devtoolset-9/enable" >> /etc/profile

	return $?
}

function setup_redis()
{
    local REDIS_DIR=$SETUP_DIR/redis
    ln -sf $REDIS_DIR/bin/redis-cli /usr/bin/redis-cli
    ln -sf $REDIS_DIR/bin/redis-server /usr/bin/redis-server
    sed -i "s@PREFIX?=/usr/local@PREFIX?=$REDIS_DIR@g" src/Makefile
    sudo make -j4 #MALLOC=libc
    sudo make -j4 install

    # Set Init Script.
    echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
    #echo "redis-server $TMP_SETUP_REDIS_CONF_DIR/redis.conf" >> /etc/rc.local
    rm -rf /etc/redis.conf
    TMP_SETUP_REDIS_CONF_DIR=$ATT_DIR/redis/conf

    if [ ! -f "$TMP_SETUP_REDIS_CONF_DIR/redis.conf" ]; then
        mkdir -pv $TMP_SETUP_REDIS_CONF_DIR

        sed -i "s@^daemonize no@daemonize yes@g" redis.conf
        sed -i "s@^127.0.0.1@0.0.0.0@g" redis.conf
        cp redis.conf $TMP_SETUP_REDIS_CONF_DIR
    fi

    ln -sf $TMP_SETUP_REDIS_CONF_DIR/redis.conf /etc/redis.conf
    echo_startup_config "redis" "/usr/bin" "redis-server /etc/redis.conf"

    redis-server /etc/redis.conf
    sysctl vm.overcommit_memory=1
    echo "Redis Started。"
	return $?
}


function down_redis()
{
    set_env
    setup_soft_wget "redis" "http://download.redis.io/redis-stable.tar.gz" "setup_redis"

	return $?
}

setup_soft_basic "Redis" "down_redis"
