#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

#---------- DIR ---------- {
WORK_PATH=`pwd`
#---------- DIR ---------- }

# 清理系统缓存后执行
echo 3 > /proc/sys/vm/drop_caches

# 全部给予执行权限
chmod +x -R scripts/*.sh
chmod +x -R common/*.sh
source common/common.sh

#---------- BASE ---------- {
# 迁移packages
yes | cp packages/* $DOWN_DIR
#}

#---------- CHANGE ---------- {
SYS_IP_CONNECT=`echo $LOCAL_HOST | sed 's@\.@-@g' | xargs -I {} echo "{}"`
SYS_NEW_NAME="ip-$SYS_IP_CONNECT"
sudo hostnamectl set-hostname $SYS_NEW_NAME
#---------- CHANGE ---------- }

#---------- BASE ---------- {
function link_logs()
{
    mkdir -pv /logs

    local TMP_LOGS_IS_LINK=`ls -il /logs | grep "\->"`
    if [ -z "$TMP_LOGS_IS_LINK" ]; then
        if [ -d "/logs" ]; then
            mv /logs $LOGS_DIR
            ln -sf $LOGS_DIR /logs
        fi
    fi
    
	return $?
}

function mkdirs()
{
    #path_not_exits_action "$DEFAULT_DIR" "mkdir -pv $SETUP_DIR && cp --parents -av ~/.* . && sed -i \"s@$CURRENT_USER:/.*:/bin/bash@$CURRENT_USER:$DEFAULT_DIR:/bin/bash@g\" /etc/passwd"
    path_not_exits_create "${SETUP_DIR}"
    path_not_exits_create "${WWW_DIR}"
    path_not_exits_create "${APP_DIR}"
    path_not_exits_create "${BOOT_DIR}"
    path_not_exits_create "${HTML_DIR}"
    path_not_exits_create "${PIP_PACKAGES_DIR}"
    
    path_not_exits_action "${LOGS_DIR}" "link_logs"

    return $?
}

mkdirs
#}

function choice_type()
{    
	echo_title

	setup_if_choice "CHOICE_CTX" "Please choice your setup type" "Update_libs,From_clean,From_bak,Gen_ngx_conf,Gen_sup_conf,Proxy_by_ss,Exit" "$TMP_SPLITER"

	return $?
}

function update_libs()
{
    source scripts/os$OS_VERSION/optimize.sh
    source scripts/os$OS_VERSION/epel.sh
    source scripts/os$OS_VERSION/libs.sh
    
    source scripts/softs/supervisor.sh
    
	return $?
}

function from_clean()
{
    echo_title

    setup_if_choice "CHOICE_TYPE" "Please choice your setup your setup type" "...,Lang,ELK,ServiceMesh,Softs,Ha,Exit" "$TMP_SPLITER"

	return $?
}

function lang()
{
    setup_if_choice "CHOICE_LANG" "Please choice which dev lang you want to setup" "...,Python,Java,Scala,Php,NodeJs,Exit" "$TMP_SPLITER" "scripts/lang"
	return $?
}

function elk()
{
    setup_if_choice "CHOICE_ELK" "Please choice which elk compoment you want to setup" "...,ElasticSearch,LogStash,Kibana,Flume,FileBeat,Exit" "$TMP_SPLITER" "scripts/elk"
	return $?
}

function servicemesh()
{
    setup_if_choice "CHOICE_SERVICEMESH" "Please choice which service-mesh compoment you want to setup" "...,Docker,MiniKube,Kong,Kubernetes,Istio,Exit" "$TMP_SPLITER" "scripts/servicemesh"
	return $?
}

function softs()
{
	setup_if_choice "CHOICE_SOFT" "Please choice which soft you want to setup" "...,OpenResty,Redis,Kafka,Mycat,MySql,PostgreSql,ClickHouse,Flink,Exit" "$TMP_SPLITER" "scripts/softs"
	return $?
}

function ha()
{
	setup_if_choice "CHOICE_HA" "Please choice which ha compoment you want to setup" "...,Zookeeper,Hadoop,Consul,Mesos,Docker,JumpServer,Exit" "$TMP_SPLITER" "scripts/ha"
	return $?
}

function from_bak()
{
    source scripts/reset_os.sh

	return $?
}

function gen_ngx_conf()
{
    gen_nginx_starter
    
	return $?
}

function gen_sup_conf()
{
	return $?
}

choice_type 