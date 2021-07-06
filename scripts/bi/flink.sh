#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
    # 需要提前安装Java,Hadoop
    cd ${__DIR}
    
    source scripts/lang/java.sh
    source scripts/ha/hadoop.sh

	return $?
}

function setup_flink()
{
    FLINK_DIR=$SETUP_DIR/flink

    cd ..
    mv flink-1.7.2 $FLINK_DIR

    cd $FLINK_DIR

    sed -i "s@web\.port:.*@web\.port: 9010@g" conf/flink-conf.yaml
    echo_soft_port 9010

    local FLINK_CLUSTER_MASTER_HOSTS="$LOCAL_HOST"
    exec_while_read "FLINK_CLUSTER_MASTER_HOSTS" "Hadoop: Please ender cluster-master-host part \$I of address like '$LOCAL_HOST'"
    echo "$FLINK_CLUSTER_MASTER_HOSTS" | sed "s@,@\n@g" | awk -F'.' '{print "lnxsvr.ha"$4}' > conf/masters
    cat conf/masters
    echo 

    sed -i "s@jobmanager\.rpc\.address:.*@jobmanager\.rpc\.address: $FLINK_CLUSTER_MASTER_HOSTS@g" conf/flink-conf.yaml
    sed -i "s@taskmanager\.numberOfTaskSlots:.*@taskmanager\.numberOfTaskSlots: $PROCESSOR_COUNT@g" conf/flink-conf.yaml

    local FLINK_CLUSTER_SLAVE_HOSTS="$LOCAL_HOST"
    exec_while_read "FLINK_CLUSTER_SLAVE_HOSTS" "Hadoop: Please ender cluster-slave-host part \$I of address like '$LOCAL_HOST'"
    echo "$FLINK_CLUSTER_SLAVE_HOSTS" | sed "s@,@\n@g" | awk -F'.' '{print "lnxsvr.ha"$4}' > conf/slaves
    cat conf/slaves
    echo 

    exec_yn_action "start_flink" "Flink: Please Sure You If This Is A Boot Server"

    # cd $FLINK_DIR/resources/python
    # python setup.py install

    echo_startup_config "flink" "$FLINK_DIR/bin" "bash start-cluster.sh" "" "100"
    
	return $?
}

function start_flink()
{
    bash $FLINK_DIR/bin/start-cluster.sh
    jps -m

	return $?
}

function down_flink()
{
    set_environment
    setup_soft_wget "flink" "http://mirror.bit.edu.cn/apache/flink/flink-1.7.2/flink-1.7.2-bin-hadoop28-scala_2.12.tgz" "setup_flink"

	return $?
}

setup_soft_basic "Flink" "down_flink"
