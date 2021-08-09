#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

#---------- DIR ---------- {
# Set magic variables for current file & dir
__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__FILE="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__CONF="$(cd; pwd)"
readonly __DIR __FILE __CONF
#---------- DIR ---------- }

# 清理系统缓存后执行
echo 3 > /proc/sys/vm/drop_caches

#---------- BASE ---------- {
# 统一将日志指向挂载盘
function link_logs()
{
    # 先创建，避免存在有些系统存在或不存在的问题。一般存在
    mkdir -pv /logs

    local TMP_LOGS_IS_LINK=`ls -il /logs | grep "\->"`
    if [ -z "${TMP_LOGS_IS_LINK}" ]; then
        mv /logs ${LOGS_DIR}
        ln -sf ${LOGS_DIR} /logs
    fi
    
    local TMP_VARLOG_IS_LINK=`ls -il /var/log | grep "\->"`
    if [ -z "${TMP_VARLOG_IS_LINK}" ]; then
        chattr -a /var/log/messages 

        cp -ra /var/log/* ${LOGS_DIR}/
        rm -rf /var/log 
        ln -sf ${LOGS_DIR} /var/log

        chattr +a /var/log/messages 
    fi

	return $?
}

function mkdirs()
{
    # 检测到有未挂载磁盘，默认将挂载第一个磁盘为/mountdisk，并重置变量
    if [ ${#LSBLK_DISKS_STR} -gt 0 ] && [ -z "${LSBLK_MOUNT_ROOT}" ]; then
        echo "----------------------------------------------------------------------------------------"
        echo "Checking Start：There's no mountdisk was mounted。Please step by step to create & format"
        echo "----------------------------------------------------------------------------------------"
        resolve_unmount_disk "${MOUNT_ROOT}"
        source common/common_vars.sh
    fi

    #path_not_exists_action "$DEFAULT_DIR" "mkdir -pv $SETUP_DIR && cp --parents -av ~/.* . && sed -i \"s@$CURRENT_USER:/.*:/bin/bash@$CURRENT_USER:$DEFAULT_DIR:/bin/bash@g\" /etc/passwd"
    path_not_exits_create "${DOWN_DIR}"
    path_not_exits_create "${SETUP_DIR}"
    path_not_exits_create "${WWW_DIR}"
    path_not_exits_create "${APP_DIR}"
    path_not_exits_create "${BOOT_DIR}"
    path_not_exits_create "${HTML_DIR}"
    
    path_not_exists_action "${LOGS_DIR}" "link_logs"

    sudo yum makecache fast

    return $?
}

function choice_type()
{   
	echo_title

	exec_if_choice "CHOICE_CTX" "Please choice your setup type" "Update_libs,From_clean,From_bak,Mount_unmount_disks,Gen_ngx_conf,Gen_sup_conf,Proxy_by_ss,Exit" "${TMP_SPLITER}"

	return $?
}

function update_libs()
{
    source scripts/os${OS_VERSION}/optimize.sh
    source scripts/os${OS_VERSION}/epel.sh
    source scripts/os${OS_VERSION}/libs.sh
    
    source scripts/softs/supervisor.sh
    
	return $?
}

function from_clean()
{
    echo_title

    exec_if_choice "CHOICE_TYPE" "Please choice your setup your setup type" "...,Lang,DevOps,Cluster,BI,ServiceMesh,Database,Web,Ha,Network,Softs,Tools,Exit" "${TMP_SPLITER}"

	return $?
}

function lang()
{
    exec_if_choice "CHOICE_LANG" "Please choice which dev lang you want to setup" "...,Python,Java,Scala,ERLang,Php,NodeJs,Exit" "${TMP_SPLITER}" "scripts/lang"

	return $?
}

function devops()
{
    exec_if_choice "CHOICE_DEVOPS" "Please choice which devops compoment you want to setup" "...,Git,Jenkins,Exit" "${TMP_SPLITER}" "scripts/devops"

	return $?
}

function cluster()
{
    exec_if_choice "CHOICE_CLUSTER" "Please choice which cluster compoment you want to setup" "...,JumpServer,STF,Exit" "${TMP_SPLITER}" "scripts/cluster"

	return $?
}

function bi()
{
    exec_if_choice "CHOICE_ELK" "Please choice which bi compoment you want to setup" "...,ElasticSearch,LogStash,Kibana,FileBeat,Flume,Redis,RabbitMQ,Kafka,ZeroMQ,Flink,Exit" "${TMP_SPLITER}" "scripts/bi"
	
    return $?
}

function servicemesh()
{
    exec_if_choice "CHOICE_SERVICEMESH" "Please choice which service-mesh compoment you want to setup" "...,Docker,MiniKube,Kubernetes,Istio,Exit" "${TMP_SPLITER}" "scripts/servicemesh"
	
    return $?
}

function database()
{
	exec_if_choice "CHOICE_DATABASE" "Please choice which database compoment you want to setup" "...,MySql,Mycat,PostgreSql,ClickHouse,RethinkDB,Exit" "${TMP_SPLITER}" "scripts/database"
	
    return $?
}

function web()
{
	exec_if_choice "CHOICE_WEB" "Please choice which web compoment you want to setup" "...,OpenResty,Caddy,Kong,Webhook,Exit" "${TMP_SPLITER}" "scripts/web"
	
    return $?
}

function ha()
{
	exec_if_choice "CHOICE_HA" "Please choice which ha compoment you want to setup" "...,Zookeeper,Hadoop,Consul,Exit" "${TMP_SPLITER}" "scripts/ha"
	
    return $?
}

function network()
{
	exec_if_choice "CHOICE_NETWORK" "Please choice which network you want to setup" "...,N2N,Frp,OpenClash,Shadowsocks,Exit" "${TMP_SPLITER}" "scripts/network"
	
    return $?
}

function softs()
{
	exec_if_choice "CHOICE_SOFTS" "Please choice which soft you want to setup" "...,Supervisor,Exit" "${TMP_SPLITER}" "scripts/softs"
	
    return $?
}

function tools()
{
	exec_if_choice "CHOICE_TOOLS" "Please choice which soft you want to setup" "...,Yasm,Graphics-Magick,Pkg-Config,Protocol-Buffers,Exit" "${TMP_SPLITER}" "scripts/tools"
	
    return $?
}

function from_bak()
{
    source scripts/reset_os.sh

	return $?
}

function mount_unmount_disks()
{
    resolve_unmount_disk
    
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

# 初始基本参数启动目录
function bootstrap() {
    cd ${__DIR}

    # 全部给予执行权限
    chmod +x -R scripts/*.sh
    chmod +x -R common/*.sh
    source common/common_vars.sh
    source common/common.sh

    #---------- BASE ---------- {
    # 迁移packages
    yes | cp packages/* ${DOWN_DIR}
    #}

    yum versionlock clear
    #---------- CHANGE ---------- {
    SYS_IP_CONNECT=`echo ${LOCAL_HOST} | sed 's@\.@-@g' | xargs -I {} echo "{}"`
    SYS_NEW_NAME="ip-${SYS_IP_CONNECT}"
    sudo hostnamectl set-hostname ${SYS_NEW_NAME}
    #---------- CHANGE ---------- }

    mkdirs
 
    choice_type
}

if [ "${BASH_SOURCE[0]:-}" != "${0}" ]; then
    export -f bootstrap
else
    bootstrap ${@}
    exit $?
fi
