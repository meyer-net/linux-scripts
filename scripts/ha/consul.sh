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
    # source scripts/lang/java.sh

	return $?
}

function setup_consul()
{
    local TMP_SETUP_PATH=$1
    local TMP_UNZIP_PATH=`pwd`/consul

    CONSUL_DIR=$TMP_SETUP_PATH
    CONSUL_ATT_DIR=$ATT_DIR/consul
    CONSUL_DATA_DIR=$DATA_DIR/consul
    
    mkdir -pv $CONSUL_DIR
    mkdir -pv $CONSUL_ATT_DIR/bootstrap
    mkdir -pv $CONSUL_ATT_DIR/server
    mkdir -pv $CONSUL_ATT_DIR/agent
    mkdir -pv $CONSUL_DATA_DIR
    mv $TMP_UNZIP_PATH $CONSUL_DIR

    cd $CONSUL_DIR

    #-advertise：通知展现地址用来改变我们给集群中的其他节点展现的地址，一般情况下-bind地址就是展现地址
    #-bootstrap：用来控制一个server是否在bootstrap模式，在一个datacenter中只能有一个server处于bootstrap模式，当一个server处于bootstrap模式时，可以自己选举为raft leader。
    #-bootstrap-expect：在一个datacenter中期望提供的server节点数目，当该值提供的时候，consul一直等到达到指定sever数目的时候才会引导整个集群，该标记不能和bootstrap公用
    #-bind：该地址用来在集群内部的通讯，集群内的所有节点到地址都必须是可达的，默认是0.0.0.0
    #-client：consul绑定在哪个client地址上，这个地址提供HTTP、DNS、RPC等服务，默认是127.0.0.1
    #-config-file：明确的指定要加载哪个配置文件
    #-config-dir：配置文件目录，里面所有以.json结尾的文件都会被加载
    #-data-dir：提供一个目录用来存放agent的状态，所有的agent允许都需要该目录，该目录必须是稳定的，系统重启后都继续存在
    #-dc：该标记控制agent允许的datacenter的名称，默认是dc1
    #-encrypt：指定secret key，使consul在通讯时进行加密，key可以通过consul keygen生成，同一个集群中的节点必须使用相同的key
    #-join：加入一个已经启动的agent的ip地址，可以多次指定多个agent的地址。如果consul不能加入任何指定的地址中，则agent会启动失败，默认agent启动时不会加入任何节点。
    #-retry-join：和join类似，但是允许你在第一次失败后进行尝试。
    #-retry-interval：两次join之间的时间间隔，默认是30s
    #-retry-max：尝试重复join的次数，默认是0，也就是无限次尝试
    #-log-level：consul agent启动后显示的日志信息级别。默认是info，可选：trace、debug、info、warn、err。
    #-node：节点在集群中的名称，在一个集群中必须是唯一的，默认是该节点的主机名
    #-protocol：consul使用的协议版本
    #-rejoin：使consul忽略先前的离开，在再次启动后仍旧尝试加入集群中。
    #-server：定义agent运行在server模式，每个集群至少有一个server，建议每个集群的server不要超过5个
    #-syslog：开启系统日志功能，只在linux/osx上生效
    #-pid-file:提供一个路径来存放pid文件，可以使用该文件进行SIGINT/SIGHUP(关闭/更新)agent

    KEYGEN=`$CONSUL_DIR/consul keygen`
    input_if_empty "KEYGEN" "Consul: Please Ender Cluster KeyGen Like '$KEYGEN'"
    echo "The Keygen Used：'${red}$KEYGEN${reset}', ${red}Please use it for other cluster host${reset}"

    CLUSTER_LEADER_ADDR=`echo $LOCAL_HOST`
    input_if_empty "CLUSTER_LEADER_ADDR" "Consul: Please Ender Cluster Of Leader Address"

    CLUSTER_CHILD_ADDRS="$LOCAL_HOST"
    exec_while_read "CLUSTER_CHILD_ADDRS" "Consul: Please Ender Cluster Child.\$I Address Like '$LOCAL_HOST'" "\"%\"" "
        echo \"Port of 8300 allowed for '\$CURRENT'\"
        echo_soft_port 8300 \$CURRENT
        echo \"Port of 8301 allowed for '\$CURRENT'\"
        echo_soft_port 8301 \$CURRENT
        echo \"Port of 8302 allowed for '\$CURRENT'\"
        echo_soft_port 8302 \$CURRENT
        echo \"Port of 8400 allowed for '\$CURRENT'\"
        echo_soft_port 8400 \$CURRENT
        echo \"Port of 8600 allowed for '\$CURRENT'\"
        echo_soft_port 8600 \$CURRENT
    "
    cat > $CONSUL_ATT_DIR/bootstrap/config.json <<EOF
{
	"ui" : true,
	"bootstrap": true,
	"server": true,
	"datacenter": "ost-aws",
    "node_name": "bootstrap-$LOCAL_ID",
	"data_dir": "$CONSUL_DATA_DIR",
	"advertise_addr": "$LOCAL_HOST",
	"log_level": "INFO",
	"encrypt": "$KEYGEN",
	"addresses": {
        "http": "0.0.0.0"
    },
	"enable_syslog": true
}
EOF

    cat > $CONSUL_ATT_DIR/server/config.json <<EOF
{
	"ui" : true,
	"bootstrap": false,
	"server": true,
	"datacenter": "ost-aws",
    "node_name": "server-$LOCAL_ID",
	"data_dir": "$CONSUL_DATA_DIR",
	"advertise_addr": "$LOCAL_HOST",
	"log_level": "INFO",
	"encrypt": "$KEYGEN",
	"addresses": {
        "http": "0.0.0.0"
    },
	"enable_syslog": true,
	"start_join": ["$CLUSTER_CHILD_ADDRS"]
}
EOF

    cat > $CONSUL_ATT_DIR/agent/config.json <<EOF
{
	"ui" : true,
	"server": false,
	"datacenter": "ost-aws",
    "node_name": "agent-$LOCAL_ID",
	"data_dir": "$CONSUL_DATA_DIR",
	"advertise_addr": "$LOCAL_HOST",
	"log_level": "INFO",
	"encrypt": "$KEYGEN",
	"addresses": {
        "http": "0.0.0.0"
    },
	"enable_syslog": true,
	"start_join": ["$CLUSTER_LEADER_ADDR"]
}
EOF

    echo "CONSUL_HOME=$CONSUL_DIR" >> /etc/profile
    echo "CONSUL_BIN=\$CONSUL_HOME" >> /etc/profile
    echo "PATH=\$CONSUL_BIN:\$PATH" >> /etc/profile
    source /etc/profile
    export PATH CONSUL_HOME CONSUL_BIN

    # 判断如果是主节点
    if [ "$CLUSTER_LEADER_ADDR" = "$LOCAL_HOST" ]; then
        start_bootstrap
    else
        BOOT_MODE=1
        setup_if_choice "BOOT_MODE" "Consul: Please Sure This Server Mode" "server,agent" "" "start_"
    fi

	return $?
}

function start_bootstrap()
{
    CLUSTER_CHILD_ADDRS_COUNT=`cat $CLUSTER_CHILD_ADDRS | awk -F',' '{for(i=1;i<=NF;i++) if($i==$NF) {print i}}'`
    screen $CONSUL_DIR/consul agent -config-dir $CONSUL_ATT_DIR/bootstrap -bootstrap-expect=$CLUSTER_CHILD_ADDRS_COUNT
    echo_startup_config "consul" "$CONSUL_DIR" "consul agent -config-dir $CONSUL_ATT_DIR/bootstrap -bootstrap-expect=$CLUSTER_CHILD_ADDRS_COUNT" "" "1"
    return $?
}

function start_server()
{
    screen $CONSUL_DIR/consul agent -config-dir $CONSUL_ATT_DIR/server
    echo_startup_config "consul" "$CONSUL_DIR" "consul agent -config-dir $CONSUL_ATT_DIR/server" "" "1"
    return $?
}

function start_agent()
{
    screen $CONSUL_DIR/consul agent -config-dir $CONSUL_ATT_DIR/agent
    echo "Port of 8500 allowed from iptables"
    echo_soft_port 8500 $CURRENT

    echo_startup_config "consul" "$CONSUL_DIR" "consul agent -config-dir $CONSUL_ATT_DIR/agent" "" "1"
    return $?
}

function down_consul()
{
    set_environment
    setup_soft_wget "consul" "https://releases.hashicorp.com/consul/1.5.0/consul_1.5.0_linux_amd64.zip" "setup_consul"

	return $?
}

setup_soft_basic "Consul" "down_consul"
