#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
    # 需要提前安装Java,Hadoop
    cd $WORK_PATH
    source scripts/lang/java.sh

	return $?
}

function setup_flume()
{
	FLUME_CURRENT_DIR=`pwd`

    cd ..
    mv $FLUME_CURRENT_DIR $FLUME_DIR

    local FLUME_DIR=$SETUP_DIR/flume
	local FLUME_LOGS_DIR=$FLUME_DIR/logs
	local FLUME_DATA_DIR=$FLUME_DIR/data

    mkdir -pv $LOGS_DIR/flume
    mkdir -pv $DATA_DIR/flume

	ln -sf $LOGS_DIR/flume $FLUME_LOGS_DIR 
	ln -sf $DATA_DIR/flume $FLUME_DATA_DIR 

    echo "FLUME_HOME=$FLUME_DIR" >> /etc/profile
    echo "FLUME_BIN=\$FLUME_HOME/bin" >> /etc/profile
    echo "PATH=\$FLUME_BIN:\$PATH" >> /etc/profile
    source /etc/profile
    export PATH FLUME_HOME FLUME_BIN

    cd $FLUME_DIR
    # cp conf/flume-conf.properties.template conf/flume-conf.properties

    cat > conf/local-port8124-listener-conf.properties <<EOF
# The configuration file needs to define the sources,
# the channels and the sinks.
# Sources, channels and sinks are defined per agent,
# in this case called 'agent'

a1.sources = r1
a1.channels = c1
a1.sinks = s1

# For each one of the sources, the type is defined
a1.sources.r1.type = netcat
a1.sources.r1.bind = localhost
a1.sources.r1.port = 8124

# The channel can be defined as follows.
a1.sources.r1.channels = c1

# Each sink's type must be defined
a1.sinks.s1.type = logger
a1.sinks.s1.sink.directory = $FLUME_LOGS_DIR

#Specify the channel the sink should use
a1.sinks.s1.channel = c1

# Each channel's type is defined.
a1.channels.c1.type = memory

# Other config values specific to each type of channel(sink or source)
# can be defined as well
# In this case, it specifies the capacity of the memory channel
a1.channels.c1.capacity = 1000
a1.channels.c1.transactionCapacity = 100  
EOF

    sed -i "s@flume\.log\.dir=.*@flume\.log\.dir=$FLUME_LOGS_DIR@g" conf/log4j.properties
    
    setup_drivers

    echo_startup_config "flume" "$FLUME_DIR" "screen bin/flume-ng agent -n a1 --c conf -f conf/local-port8124-listener-conf.properties -Dflume.root.logger=INFO,console" "" "100"

	return $?
}

function setup_drivers()
{
    # https://dev.mysql.com/downloads/connector/
    mkdir -pv plugins.d/sql-source/libext
    #https://github.com/keedio/flume-ng-sql-source  -b feature/check-compatibility-latest-stable
    cp target/flume-ng-sql-source-1.5.0.jar $SETUP_DIR/flume/lib/
    #https://github.com/baniuyao/flume-ng-kafka-source
    #https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.35.tar.gz
    #https://download.microsoft.com/download/A/F/B/AFB381FF-7037-46CE-AF9B-6B1875EA81D7/sqljdbc_6.0.8112.200_chs.tar.gz

	return $?
}

function down_flume()
{
    set_environment
    setup_soft_wget "flume" "http://mirrors.hust.edu.cn/apache/flume/stable/apache-flume-1.9.0-bin.tar.gz" "setup_flume"

	return $?
}

setup_soft_basic "Flume" "down_flume"
