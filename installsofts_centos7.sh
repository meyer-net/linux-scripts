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
    path_not_exists_create "${RPMS_DIR}"
    path_not_exists_create "${REPO_DIR}"
    path_not_exists_create "${CURL_DIR}"
    path_not_exists_create "${SETUP_DIR}"
    path_not_exists_create "${WWW_DIR}"
    path_not_exists_create "${APP_DIR}"
    path_not_exists_create "${BOOT_DIR}"
    path_not_exists_create "${HTML_DIR}"
    
    path_not_exists_create "${DATA_DIR}"
    path_not_exists_action "${LOGS_DIR}" "link_logs"

    sudo yum makecache fast

    return $?
}

function choice_type()
{
	echo_title

	exec_if_choice "TMP_CHOICE_CTX" "Please choice your setup type" "Update_Libs,From_Clean,From_Bak,Mount_Unmount_Disks,Gen_Ngx_Conf,Gen_Sup_Conf,SSH_Redict,Proxy_By_SS,Exit" "${TMP_SPLITER}"

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

    exec_if_choice "TMP_CHOICE_TYPE" "Please choice your setup your setup type" "...,Lang,DevOps,Cluster,ELK,BI,ServiceMesh,Database,Web,Ha,Network,Softs,Exit" "${TMP_SPLITER}"

	return $?
}

function lang()
{
    exec_if_choice "TMP_CHOICE_LANG" "Please choice which env lang you need to setup" "...,Python,Java,Scala,ERLang,Php,NodeJs,Exit" "${TMP_SPLITER}" "scripts/lang"

	return $?
}

function devops()
{
    exec_if_choice "TMP_CHOICE_DEVOPS" "Please choice which devops compoment you want to setup" "...,Git,Jenkins,Exit" "${TMP_SPLITER}" "scripts/devops"

	return $?
}

function cluster()
{
    exec_if_choice "TMP_CHOICE_CLUSTER" "Please choice which cluster compoment you want to setup" "...,JumpServer,STF,Exit" "${TMP_SPLITER}" "scripts/cluster"

	return $?
}

function elk()
{
    exec_if_choice "TMP_CHOICE_ELK" "Please choice which ELK compoment you want to setup" "...,ElasticSearch,LogStash,Kibana,FileBeat,Flume,Exit" "${TMP_SPLITER}" "scripts/elk"
	
    return $?
}

function bi()
{
    exec_if_choice "TMP_CHOICE_BI" "Please choice which bi compoment you want to setup" "...,Redis,RabbitMQ,Kafka,ZeroMQ,Flink,Exit" "${TMP_SPLITER}" "scripts/bi"
	
    return $?
}

function servicemesh()
{
    exec_if_choice "TMP_CHOICE_SERVICEMESH" "Please choice which service-mesh compoment you want to setup" "...,Docker,MiniKube,Kubernetes,Istio,Exit" "${TMP_SPLITER}" "scripts/servicemesh"
	
    return $?
}

function database()
{
	exec_if_choice "TMP_CHOICE_DATABASE" "Please choice which database compoment you want to setup" "...,MySql,PostgresQL,ClickHouse,RethinkDB,Exit" "${TMP_SPLITER}" "scripts/database"
	
    return $?
}

function web()
{
	exec_if_choice "TMP_CHOICE_WEB" "Please choice which web compoment you want to setup" "...,OpenResty,Caddy,Kong,Webhook,Exit" "${TMP_SPLITER}" "scripts/web"
	
    return $?
}

function ha()
{
	exec_if_choice "TMP_CHOICE_HA" "Please choice which ha compoment you want to setup" "...,Zookeeper,Hadoop,Consul,Exit" "${TMP_SPLITER}" "scripts/ha"
	
    return $?
}

function network()
{
	exec_if_choice "TMP_CHOICE_NETWORK" "Please choice which network compoment you want to setup" "...,N2N,Frp,OpenClash,Shadowsocks,Exit" "${TMP_SPLITER}" "scripts/network"
	
    return $?
}

function softs()
{
	exec_if_choice "TMP_CHOICE_SOFTS" "Please choice which soft you want to setup" "...,Supervisor,Exit" "${TMP_SPLITER}" "scripts/softs"
	
    return $?
}

# function tools()
# {
# 	exec_if_choice "TMP_CHOICE_TOOLS" "Please choice which soft you want to setup" "...,Yasm,Graphics-Magick,Pkg-Config,Protocol-Buffers,Exit" "${TMP_SPLITER}" "scripts/tools"
	
#     return $?
# }

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

# SSH 端口转发
function ssh_redirect()
{
    local TMP_SSH_REDIR_TUNNEL_MODE="L"
    input_if_empty "TMP_SSH_REDIR_TUNNEL_MODE" "SSH-Redirect：Please ender ${green}the tunnel mode(Local/L、Remote/R、Dynamic/D)${reset}?"

    local TMP_SSH_REDIR_TUNNEL_PORT="80"
    input_if_empty "TMP_SSH_REDIR_TUNNEL_PORT" "SSH-Redirect：Please ender ${green}the port${reset} u want to listener?"
            
    local TMP_SSH_REDIR_DEST_ADDRESS="xyz.ipssh.net"
    input_if_empty "TMP_SSH_REDIR_DEST_ADDRESS" "SSH-Redirect：Please ender ${green}which dest address${reset} you want to redirect?"
    
    local TMP_SSH_REDIR_DEST_USER="root"
    input_if_empty "TMP_SSH_REDIR_DEST_USER" "SSH-Redirect：Please ender ${green}which user of dest(${TMP_SSH_REDIR_DEST_ADDRESS})${reset} by ssh to redirect?"
    
    local TMP_SSH_REDIR_DEST_NATIVE_ADDRESS="localhost" 
    input_if_empty "TMP_SSH_REDIR_DEST_NATIVE_ADDRESS" "SSH-Redirect：Please ender ${green}which dest address on '${TMP_SSH_REDIR_DEST_ADDRESS}'${reset} you want to redirect?"
    
    local TMP_SSH_REDIR_DEST_NATIVE_PORT="${TMP_SSH_REDIR_LOCAL_PORT}"
    input_if_empty "TMP_SSH_REDIR_DEST_NATIVE_PORT" "SSH-Redirect：Please ender ${green}which dest address port on '${TMP_SSH_REDIR_DEST_ADDRESS}'${reset} you want to redirect?"

    local TMP_SSH_REDIR_SCRIPTS="ssh -C -f -N -${TMP_SSH_REDIR_TUNNEL_MODE} ${TMP_SSH_REDIR_TUNNEL_PORT}:${TMP_SSH_REDIR_DEST_NATIVE_ADDRESS}:${TMP_SSH_REDIR_DEST_NATIVE_PORT}  ${TMP_SSH_REDIR_DEST_USER}@${TMP_SSH_REDIR_DEST_ADDRESS}"
    
    ${TMP_SSH_REDIR_SCRIPTS}

    echo
    echo "SSH-Redirect：Done -> (${TMP_SSH_REDIR_SCRIPTS})"
    echo

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
    if [ -d packages ]; then
        yes | cp packages/* ${DOWN_DIR}
    fi
    #}

    bash -c "yum versionlock clear"
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