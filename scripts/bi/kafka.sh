#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function setup_kafka()
{
    local TMP_SETUP_DIR=$1
    local TMP_UNZIP_DIR=`pwd`

    KAFKA_DIR=$TMP_SETUP_DIR
    KAFKA_DATA_DIR=$DATA_DIR/zookeeper/kafka
    KAFKA_LOGS_DIR=$LOGS_DIR/zookeeper/kafka

    mkdir -pv ${KAFKA_DATA_DIR}
    mkdir -pv ${KAFKA_LOGS_DIR}

    cd ..
    mv ${TMP_UNZIP_DIR} ${KAFKA_DIR}
    cd ${KAFKA_DIR}

    mkdir -pv ${KAFKA_DATA_DIR}
    sed -i "s@dataDir=.*@dataDir=${KAFKA_DATA_DIR}@g" config/zookeeper.properties
    sed -i "s@clientPort=.*@clientPort=2233@g" config/zookeeper.properties
    sed -i "s@#listeners@listeners@g" config/server.properties

    TMP_SETUP_KAFKA_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_SETUP_KAFKA_HOST" "Kafka: Please Ender Listener Internal Host Address"
    if [ -n "${TMP_SETUP_KAFKA_HOST}" ]; then
        sed -i "s@#advertised.listeners=.*@advertised.listeners=PLAINTEXT://${TMP_SETUP_KAFKA_HOST}:9092@g" config/server.properties
    fi

    mkdir -pv ${KAFKA_DATA_DIR}
    sed -i "s@log.dirs=.*@log.dirs=${KAFKA_DATA_DIR}@g" config/server.properties

    TMP_SETUP_KAFKA_BROKER="${LOCAL_ID}"
    input_if_empty "TMP_SETUP_KAFKA_BROKER" "Kafka: Please Ender Broker.Id"
    sed -i "s@broker.id=0@broker.id=${TMP_SETUP_KAFKA_BROKER}@g" config/server.properties

    TMP_SETUP_KAFKA_ZK_HOSTS="${LOCAL_HOST}"
    # ??? 端口未生效，待修改
    exec_while_read "TMP_SETUP_KAFKA_ZK_HOSTS" "Kafka.Zookeeper: Please Ender Zookeeper Cluster Line Address Like '${LOCAL_HOST}'" "%s:2233" "
        if [ \"\$CURRENT\" == \"\${LOCAL_HOST}\" ]; then
            echo_soft_port 2233 \"\$CURRENT\"
            echo_soft_port 6123 \"\$CURRENT\"
            echo_soft_port 9092 \"\$CURRENT\"
        else
            echo \"Please allow the port of '\${red}2233,6123,9092\${reset}' for '\${red}\${LOCAL_HOST}\${reset}' from the zookeeper host '\$CURRENT'\"
        fi
    "
    echo_soft_port 10000

    sed -i "s@zookeeper.connect=.*@zookeeper.connect=${TMP_SETUP_KAFKA_ZK_HOSTS}@g" config/server.properties

    sed -i "/export KAFKA_HEAP_OPTS=/a export JMX_PORT=\"10000\"" bin/kafka-server-start.sh

    echo "${TMP_SETUP_KAFKA_HOST} $SYS_NAME" >> /etc/hosts 
    JMX_PORT=10000 && nohup sh bin/kafka-server-start.sh config/server.properties > ${KAFKA_LOGS_DIR}/kafka.log 2>&1 &
    
    echo_startup_config "kafka" "${KAFKA_DIR}" "bash bin/kafka-server-start.sh config/server.properties" "JMX_PORT=10000" "999"
    #bin/kafka-topics.sh --create --zookeeper 192.168.1.100:2233,192.168.1.109:2233,192.168.1.110:2233 --replication-factor 2 --partitions 100 --topic test
    #bin/kafka-topics.sh  --describe  --zookeeper  192.168.1.185:2233 –-topic test
    #bin/kafka-console-producer.sh --broker-list 192.168.1.100:9092,192.168.1.109:9092,192.168.1.110:9092 --topic test
    #bin/kafka-console-consumer.sh --bootstrap-server 192.168.1.100:9092,192.168.1.109:9092,192.168.1.110:9092 --topic test --from-beginning
        
	return $?
}

function setup_zookeeper()
{
    cd ${__DIR} 
    
    source scripts/ha/zookeeper.sh

    return $?
}

function  setup_kafka_eagle()
{
    tar -zxvf kafka-eagle-web-2.0.5-bin.tar.gz

    KAFKA_EAGLE_DIR=$SETUP_DIR/kafka_eagle
    mv kafka-eagle-web-2.0.5 $KAFKA_EAGLE_DIR

    echo "KE_HOME=$KAFKA_EAGLE_DIR" >> /etc/profile
    echo "KE_BIN=\$KE_HOME/bin" >> /etc/profile
    echo "PATH=\$KE_BIN:\$PATH" >> /etc/profile
    echo "export PATH KE_HOME KE_BIN" >> /etc/profile
    source /etc/profile

    TMP_SETUP_KAFKA_ZK_HOSTS="${LOCAL_HOST}"
    exec_while_read "TMP_SETUP_KAFKA_ZK_HOSTS" "Kafka.Zookeeper: Please Ender Zookeeper Cluster Line Address Like '${LOCAL_HOST}'" "%s:2233"

    cd $KAFKA_EAGLE_DIR
    sed -i "s@kafka\.eagle\.zk\.cluster\.alias=cluster1.*@kafka.eagle.zk.cluster.alias=cluster1@g" conf/system-config.properties
    sed -i "s@cluster1\.zk\.list=.*@cluster1.zk.list=$TMP_SETUP_KAFKA_ZK_HOSTS@g" conf/system-config.properties
    sed -i "s@cluster2\.zk\.list=@#cluster2.zk.list=@g" conf/system-config.properties
    
    TMP_SETUP_KAFKA_EAGLE_DBADDRESS="127.0.0.1"
    TMP_SETUP_KAFKA_EAGLE_DBPORT="3306"
    TMP_SETUP_KAFKA_EAGLE_DBUNAME="root"
    TMP_SETUP_KAFKA_EAGLE_DBPWD="123456"
	input_if_empty "TMP_SETUP_KAFKA_EAGLE_DBADDRESS" "KafkaEagle.Mysql: Please ender ${red}mysql host address${reset}"
	input_if_empty "TMP_SETUP_KAFKA_EAGLE_DBPORT" "KafkaEagle.Mysql: Please ender ${red}mysql database port${reset} of $TMP_SETUP_KAFKA_EAGLE_DBADDRESS"
	input_if_empty "TMP_SETUP_KAFKA_EAGLE_DBUNAME" "KafkaEagle.Mysql: Please ender ${red}mysql user name${reset} of '$TMP_SETUP_KAFKA_EAGLE_DBADDRESS'"
	input_if_empty "TMP_SETUP_KAFKA_EAGLE_DBPWD" "KafkaEagle.Mysql: Please ender ${red}mysql password${reset} of $TMP_SETUP_KAFKA_EAGLE_DBUNAME@$TMP_SETUP_KAFKA_EAGLE_DBADDRESS"

    sed -i "s@kafka\.eagle\.driver=.*@kafka.eagle.driver=com.mysql.jdbc.Driver@g" conf/system-config.properties
    sed -i "s@kafka\.eagle\.url=.*@kafka.eagle.url=jdbc:mysql://$TMP_SETUP_KAFKA_EAGLE_DBADDRESS:$TMP_SETUP_KAFKA_EAGLE_DBPORT/ke?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=convertToNull@g" conf/system-config.properties
    sed -i "s@kafka\.eagle\.username=.*@kafka.eagle.username=$TMP_SETUP_KAFKA_EAGLE_DBUNAME@g" conf/system-config.properties
    sed -i "s@kafka\.eagle\.password=.*@kafka.eagle.password=$TMP_SETUP_KAFKA_EAGLE_DBPWD@g" conf/system-config.properties

    #禁用Email
    EMAIL_LINE_START=`awk '/mail.enable=true/ {print NR}' conf/system-config.properties`
    EMAIL_LINE_END=$(($EMAIL_LINE_START+5))
    sed -i "$EMAIL_LINE_START,$EMAIL_LINE_END s/^/#/" conf/system-config.properties

    chmod +x bin/ke.sh
    bin/ke.sh start

    echo_soft_port 8048

    echo_startup_config "kafka_eagle" "$KAFKA_EAGLE_DIR/bin" "bash ke.sh start" "JAVA_HOME=\'$JAVA_HOME\',JAVA_BIN=\'$JAVA_HOME/bin\',KE_HOME=\'$KAFKA_EAGLE_DIR\'"
    
    return $?
}

function print_kafka()
{
    set_env_kafka

    setup_soft_basic "Kafka" "down_kafka"

	return $?
}

function print_kafka_eagle()
{
    setup_soft_basic "Kafka_Eagle" "down_kafka_eagle"

	return $?
}

function print_kafka_manager()
{
    setup_soft_basic "Kafka_manager" "down_kafka_manager"

	return $?
}

function set_env_kafka()
{
    # 需要提前安装Zookeeper    
    exec_yn_action "setup_zookeeper" "Kafka: Please sure if u want to got a zookeeper server"
    echo ""

	return $?
}

function down_kafka()
{
    cd ${__DIR}

    setup_soft_wget "kafka" "https://mirrors.cnnic.cn/apache/kafka/2.8.0/kafka_2.12-2.8.0.tgz" "setup_kafka" 

	return $?
}

function down_kafka_eagle()
{
    # 需要提前安装Java
    cd ${__DIR}
    source scripts/lang/java.sh

    setup_soft_wget "kafka_eagle" "https://codeload.github.com/smartloli/kafka-eagle-bin/tar.gz/v2.0.5" "setup_kafka_eagle" 
    
	return $?
}

function down_kafka_manager()
{
	return $?
}

exec_if_choice "CHOICE_KAFKA" "Please choice which Kafka compoment you want to setup" "...,Kafka,Kafka_Manager,Kafka_Eagle,Exit" "" "print_"
