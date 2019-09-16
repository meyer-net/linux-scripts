#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
    # 需要提前安装Java
    cd $WORK_PATH
    source scripts/lang/java.sh

	return $?
}

function setup_zookeeper()
{
    local TMP_SETUP_DIR=$1
    local TMP_UNZIP_DIR=`pwd`

    cd ..

    ZOOKEEPER_DIR=$TMP_SETUP_DIR
    ZOOKEEPER_DATA_DIR=$DATA_DIR/zookeeper
    mv $TMP_UNZIP_DIR $ZOOKEEPER_DIR

    cd $ZOOKEEPER_DIR

    mv conf/zoo_sample.cfg conf/zoo.cfg
    mkdir -pv $ZOOKEEPER_DATA_DIR
    sed -i "s@dataDir=.*@dataDir=$ZOOKEEPER_DATA_DIR@g" conf/zoo.cfg
    sed -i "s@clientPort=2181@clientPort=2233@g" conf/zoo.cfg

    input_if_empty "CLUSTER_ID" "ZooKeeper: Please Ender This Server Of Index In Cluster Like '1'"
    echo $CLUSTER_ID > $ZOOKEEPER_DATA_DIR/myid

    CLUSTER_CHILD_ADDRS="$LOCAL_HOST"
    exec_while_read "CLUSTER_CHILD_ADDRS" "ZooKeeper: Please Ender Cluster Child.\$I Address Like '$LOCAL_HOST'" "" "
        echo \"Port of 4001 allowed for '\$CURRENT'\"
        echo_soft_port 4001 \$CURRENT
        echo \"Port of 4002 allowed for '\$CURRENT'\"
        echo_soft_port 4002 \$CURRENT

        if [ \$CURRENT -eq \$CLUSTER_ID ]; then
            CURRENT='0.0.0.0'
        fi
        echo \"server.\$I=\$CURRENT:4001:4002\" >> conf/zoo.cfg
        echo \"Cluster Child-\$I Of '\$CURRENT' Was Added To conf/zoo.cfg\"
        echo \"Please Input 'echo \$I > myid' In '$ZOOKEEPER_DATA_DIR' Of \$CURRENT\"
    "

    echo "ZOOKEEPER_HOME=$ZOOKEEPER_DIR" >> /etc/profile
    echo "ZOOKEEPER_BIN=\$ZOOKEEPER_HOME/bin" >> /etc/profile
    echo "PATH=\$ZOOKEEPER_BIN:\$PATH" >> /etc/profile
    source /etc/profile
    export PATH ZOOKEEPER_HOME ZOOKEEPER_BIN

    #screen sh bin/zookeeper-server-start.sh config/zookeeper.properties
    bash bin/zkServer.sh start
    sleep 1
    bash bin/zkServer.sh status
    
    echo_startup_config "zookeeper" "$ZOOKEEPER_DIR/bin" "bash zkServer.sh start" "" "1"

	return $?
}


function down_zookeeper()
{
    set_environment
    setup_soft_wget "zookeeper" "http://mirrors.hust.edu.cn/apache/zookeeper/stable/zookeeper-3.4.12.tar.gz" "setup_zookeeper"

	return $?
}

setup_soft_basic "Zookeeper" "down_zookeeper"
