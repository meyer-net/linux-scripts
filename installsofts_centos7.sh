#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
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
    
    path_not_exists_create "${DATA_DIR}"
    path_not_exists_action "${LOGS_DIR}" "link_logs"

    sudo yum makecache fast

    return $?
}

function choice_type()
{
	echo_title

	exec_if_choice "TMP_CHOICE_CTX" "Please choice your setup type" "Update_Libs,From_Clean,From_Bak,Mount_Unmount_Disks,Gen_Ngx_Conf,Gen_Sup_Conf,Share_Dir,SSH_Transfer,Proxy_By_SS,Exit" "${TMP_SPLITER}"

	return $?
}

function update_libs()
{
    #---------- CHANGE ---------- {
    sudo hostnamectl set-hostname ${SYS_NEW_NAME}
    #---------- CHANGE ---------- }

    source scripts/os${OS_VERS}/optimize.sh
    source scripts/os${OS_VERS}/epel.sh
    source scripts/os${OS_VERS}/libs.sh
    
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
    # ,Scala
    exec_if_choice "TMP_CHOICE_LANG" "Please choice which env lang you need to setup" "...,Python,Java,ERLang,Php,NodeJs,Exit" "${TMP_SPLITER}" "scripts/lang"

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
    # ,Flume
    exec_if_choice "TMP_CHOICE_ELK" "Please choice which ELK compoment you want to setup" "...,ElasticSearch,LogStash,Kibana,FileBeat,Exit" "${TMP_SPLITER}" "scripts/elk"
	
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
	exec_if_choice "TMP_CHOICE_DATABASE" "Please choice which database compoment you want to setup" "...,MySql,PostgresQL,ClickHouse,MongoDB,RethinkDB,Exit" "${TMP_SPLITER}" "scripts/database"
	
    return $?
}

function web()
{
	exec_if_choice "TMP_CHOICE_WEB" "Please choice which web compoment you want to setup" "...,OpenResty,Kong,Caddy,Webhook,Exit" "${TMP_SPLITER}" "scripts/web"
	
    return $?
}

function ha()
{
	exec_if_choice "TMP_CHOICE_HA" "Please choice which ha compoment you want to setup" "...,Zookeeper,Hadoop,Consul,Exit" "${TMP_SPLITER}" "scripts/ha"
	
    return $?
}

function network()
{
	exec_if_choice "TMP_CHOICE_NETWORK" "Please choice which network compoment you want to setup" "...,Frp,N2N,OpenClash,Shadowsocks,Exit" "${TMP_SPLITER}" "scripts/network"
	
    return $?
}

function softs()
{
	exec_if_choice "TMP_CHOICE_SOFTS" "Please choice which soft you want to setup" "...,Supervisor,Rocket.Chat,Exit" "${TMP_SPLITER}" "scripts/softs"
	
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
	local TMP_GEN_SUP_CONF_NAME="test"
    input_if_empty "TMP_GEN_SUP_CONF_NAME" "GEN_SUP_CONF：Please ender ${green}the program name${reset}"

	local TMP_GEN_SUP_CONF_BOOT_DIR="${SETUP_DIR}"
    input_if_empty "TMP_GEN_SUP_CONF_BOOT_DIR" "GEN_SUP_CONF：Please ender ${green}the program boot dir${reset}"

	local TMP_GEN_SUP_CONF_COMMAND=""
    input_if_empty "TMP_GEN_SUP_CONF_COMMAND" "GEN_SUP_CONF：Please ender ${green}the boot command${reset}"

	local TMP_GEN_SUP_CONF_ENV=""
    input_if_empty "TMP_GEN_SUP_CONF_ENV" "GEN_SUP_CONF：Please ender ${green}the dependency of env var${reset}"

	local TMP_GEN_SUP_CONF_PRIORITY=99
    input_if_empty "" "GEN_SUP_CONF：Please ender ${green}the boot priority${reset} of your program"

	local TMP_GEN_SUP_CONF_SOURCE="/etc/profile"
    input_if_empty "TMP_GEN_SUP_CONF_SOURCE" "GEN_SUP_CONF：Please ender ${green}the dependency of env source file${reset}"

	local TMP_GEN_SUP_CONF_USER="root"
    input_if_empty "TMP_GEN_SUP_CONF_USER" "GEN_SUP_CONF：Please ender ${green}the boot user of your program${reset}"

    # 授权
    create_user_if_not_exists "${TMP_GEN_SUP_CONF_USER}" "${TMP_GEN_SUP_CONF_USER}"
    chown -R ${TMP_GEN_SUP_CONF_USER}:${TMP_GEN_SUP_CONF_USER} ${TMP_GEN_SUP_CONF_BOOT_DIR}

    # 日志转储
    if [ -d "${TMP_GEN_SUP_CONF_BOOT_DIR}/logs" ]; then
        mv ${TMP_GEN_SUP_CONF_BOOT_DIR}/logs ${LOGS_DIR}/${TMP_GEN_SUP_CONF_NAME}
        ln -sf ${LOGS_DIR}/${TMP_GEN_SUP_CONF_NAME} ${TMP_GEN_SUP_CONF_BOOT_DIR}/logs
    fi
    
    echo_startup_config "${TMP_GEN_SUP_CONF_NAME}" "${TMP_GEN_SUP_CONF_BOOT_DIR}" "${TMP_GEN_SUP_CONF_COMMAND}" "${TMP_GEN_SUP_CONF_ENV}" ${TMP_GEN_SUP_CONF_PRIORITY} "${TMP_GEN_SUP_CONF_SOURCE}" "${TMP_GEN_SUP_CONF_USER}"

	return $?
}

function share_dir()
{
    exec_if_choice "TMP_SHARE_DIR_CHOICE_TYPE" "Please choice which share type you want to use" "...,Server,Client,Exit" "${TMP_SPLITER}" "share_dir_"

    return $?
}

function share_dir_server()
{
    local TMP_SHARE_DIR_SVR_LCL_DIR="${PRJ_DIR}"
    input_if_empty "TMP_SHARE_DIR_SVR_LCL_DIR" "SHARE_DIR_SERVER：Please ender ${green}the dir${reset} which u want to share"

    local TMP_SHARE_DIR_SVR_ALLOWS=`echo ${LOCAL_HOST} | sed "s@\.${LOCAL_ID}$@.0/24@G"`
    input_if_empty "TMP_SHARE_DIR_SVR_ALLOWS" "SHARE_DIR_SERVER：Please ender ${green}the host network area${reset} which u allows to share"

    local TMP_SHARE_DIR_SVR_PERS="rw,no_root_squash"
    local TMP_SHARE_DIR_SVR_PERS_NOTICE="SHARE_DIR_SERVER：Please ender ${green}the permissions${reset} for ref clients(${TMP_SHARE_DIR_SVR_ALLOWS})
    # rw：可读写的权限  \
    # ro：只读的权限  \
    # no_root_squash：登入到NFS主机的用户如果是root，该用户即拥有root权限（不添加此选项ROOT只有RO权限）  \
    # root_squash：登入NFS主机的用户如果是root，该用户权限将被限定为匿名使用者nobody  \
    # all_squash：不管登陆NFS主机的用户是何权限都会被重新设定为匿名使用者nobody  \
    # anonuid：将登入NFS主机的用户都设定成指定的user id，此ID必须存在于/etc/passwd中  \
    # anongid：同anonuid，但是变成group ID就是了  \
    # sync：资料同步写入存储器中  \
    # async：资料会先暂时存放在内存中，不会直接写入硬盘  \
    # insecure：允许从这台机器过来的非授权访问"
    input_if_empty "TMP_SHARE_DIR_SVR_PERS" "${TMP_SHARE_DIR_SVR_PERS_NOTICE}"

    echo "${TMP_SHARE_DIR_SVR_LCL_DIR} ${TMP_SHARE_DIR_SVR_ALLOWS}(${TMP_SHARE_DIR_SVR_PERS})" >> /etc/exports
    exportfs -rv

    echo

    showmount -e localhost

    echo_soft_port 111 "${TMP_SHARE_DIR_SVR_ALLOWS}"
    echo_soft_port 2049 "${TMP_SHARE_DIR_SVR_ALLOWS}"

    echo
    echo "SHARE_DIR_SERVER：Done -> (Dir of '${green}${TMP_SHARE_DIR_SVR_LCL_DIR}${reset}' shared for '${red}${TMP_SHARE_DIR_SVR_ALLOWS}${reset}')"
    echo

    return $?
}

function share_dir_client()
{
    local TMP_SHARE_DIR_CLT_SVR_HOST="${LOCAL_HOST}"
    input_if_empty "TMP_SHARE_DIR_CLT_SVR_HOST" "SHARE_DIR_CLIENT：Please ender ${green}the host${reset} which u want to mount dir"
    
    showmount -e ${TMP_SHARE_DIR_CLT_SVR_HOST}
    
    local TMP_SHARE_DIR_CLT_SVR_DIR="${PRJ_DIR}"
    input_if_empty "TMP_SHARE_DIR_CLT_SVR_DIR" "SHARE_DIR_CLIENT：Please ender ${green}the dir${reset} which u want to mount from '${red}${TMP_SHARE_DIR_CLT_SVR_HOST}${reset}'"

    local TMP_SHARE_DIR_CLT_LCL_DIR="${HTML_DIR}"
    input_if_empty "TMP_SHARE_DIR_CLT_LCL_DIR" "SHARE_DIR_CLIENT：Please ender ${green}the dir${reset} which u want to display on local from '${red}${TMP_SHARE_DIR_CLT_SVR_HOST}(${TMP_SHARE_DIR_CLT_SVR_DIR})${reset}'"

    # mount -t nfs ${TMP_SHARE_DIR_CLT_SVR_HOST}:${TMP_SHARE_DIR_CLT_SVR_DIR} ${TMP_SHARE_DIR_CLT_LCL_DIR}
    echo "${TMP_SHARE_DIR_CLT_SVR_HOST}:${TMP_SHARE_DIR_CLT_SVR_DIR} ${TMP_SHARE_DIR_CLT_LCL_DIR} nfs defaults 0 0" >> /etc/fstab
    mount -a

    df -h
    
    echo
    echo "SHARE_DIR_CLIENT：Done -> (Dir of '${green}${TMP_SHARE_DIR_CLT_LCL_DIR}${reset}' from '${red}${TMP_SHARE_DIR_CLT_SVR_HOST}(${TMP_SHARE_DIR_CLT_SVR_DIR})${reset}')"
    echo
    
    return $?
}

# SSH 端口转发
# 参考：https://blog.51cto.com/wavework/1608937 | https://blog.csdn.net/zhouguoqionghai/article/details/81869554
function ssh_transfer()
{
    # 反向：ssh -fCNR 0.0.0.0:22000:localhost:22 root@1.1.1.1 -p 22，监听远程22000，互通本地22
    # 正向：ssh -fCNL 0.0.0.0:22000:localhost:22 root@2.2.2.2 -p 22，监听本地22000，互通远程22
    typeset -u TMP_SSH_TRANS_TUNNEL_MODE
    local TMP_SSH_TRANS_TUNNEL_MODE="L"
    input_if_empty "TMP_SSH_TRANS_TUNNEL_MODE" "SSH-Transfer：Please ender ${green}the tunnel mode(Local/L、Remote/R、Dynamic/D)${reset}?"

    local TMP_SSH_TRANS_TUNNEL_MODE_NAME_LOWER="dynamic"
    local TMP_SSH_TRANS_TUNNEL_MODE_NAME_OPPOSITE_LOWER="dynamic"
	case ${TMP_SSH_TRANS_TUNNEL_MODE} in
		"L")
            TMP_SSH_TRANS_TUNNEL_MODE_NAME_LOWER="local"
            TMP_SSH_TRANS_TUNNEL_MODE_NAME_OPPOSITE_LOWER="remote"
		;;
		"R")
            TMP_SSH_TRANS_TUNNEL_MODE_NAME_LOWER="remote"
            TMP_SSH_TRANS_TUNNEL_MODE_NAME_OPPOSITE_LOWER="local"
		;;
		*)
        TMP_SSH_TRANS_TUNNEL_MODE_NAME_LOWER="dynamic"
	esac
        
    local TMP_SSH_TRANS_DEST_HOST="xyz.ipssh.net"
    input_if_empty "TMP_SSH_TRANS_DEST_HOST" "SSH-Transfer：Please ender ${green}which dest address${reset} you want to login on remote"
    
    local TMP_SSH_TRANS_DEST_USER="root"
    input_if_empty "TMP_SSH_TRANS_DEST_USER" "SSH-Transfer：Please ender ${green}which user of dest(${TMP_SSH_TRANS_DEST_HOST})${reset} on remote by ssh to login"

    local TMP_SSH_TRANS_TUNNEL_HOST1="localhost" 
    input_if_empty "TMP_SSH_TRANS_TUNNEL_HOST1" "SSH-Transfer：Please ender ${green}which ${TMP_SSH_TRANS_TUNNEL_MODE_NAME_LOWER} address${reset} you want to listen"
    
    local TMP_SSH_TRANS_TUNNEL_PORT1="80"
    input_if_empty "TMP_SSH_TRANS_TUNNEL_PORT1" "SSH-Transfer：Please ender ${green}the port${reset} u want to listener on ${TMP_SSH_TRANS_TUNNEL_MODE_NAME_LOWER}"
        
    local TMP_SSH_TRANS_TUNNEL_HOST2="localhost" 
    input_if_empty "TMP_SSH_TRANS_TUNNEL_HOST2" "SSH-Transfer：Please ender ${green}which ${TMP_SSH_TRANS_TUNNEL_MODE_NAME_OPPOSITE_LOWER} address${reset} you want to listen"
    
    local TMP_SSH_TRANS_TUNNEL_PORT2="${TMP_SSH_TRANS_TUNNEL_PORT1}"
    input_if_empty "TMP_SSH_TRANS_TUNNEL_PORT2" "SSH-Transfer：Please ender ${green}which ${TMP_SSH_TRANS_TUNNEL_MODE_NAME_OPPOSITE_LOWER} address port${reset} you want to listen"

    function _nopwd_login()
    {
        nopwd_login "${TMP_SSH_TRANS_DEST_HOST}" "${TMP_SSH_TRANS_DEST_USER}"
    }

    exec_yn_action "_nopwd_login" "SSH-Transfer: Please sure if u want to nopass login in '${TMP_SSH_TRANS_DEST_USER}@${TMP_SSH_TRANS_DEST_HOST}'"

    # -f 后台执行ssh指令
    # -C 允许压缩数据
    # -N 不执行远程指令
    # -R 将远程主机(服务器)的某个端口转发到本地端指定机器的指定端口
    # -L 将本地机(客户机)的某个端口转发到远端指定机器的指定端口
    # -p 指定远程主机的端口
    local TMP_SSH_TRANS_SCRIPTS="-CN${TMP_SSH_TRANS_TUNNEL_MODE} ${TMP_SSH_TRANS_TUNNEL_HOST1}:${TMP_SSH_TRANS_TUNNEL_PORT1}:${TMP_SSH_TRANS_TUNNEL_HOST2}:${TMP_SSH_TRANS_TUNNEL_PORT2} ${TMP_SSH_TRANS_DEST_USER}@${TMP_SSH_TRANS_DEST_HOST}"
    
    ssh -f ${TMP_SSH_TRANS_SCRIPTS}

    # 本地模式需要放开端口
    if [ "${TMP_SSH_TRANS_TUNNEL_MODE}" == "L" ]; then
        echo_soft_port ${TMP_SSH_TRANS_TUNNEL_PORT1} 
    fi

    if [ "${TMP_SSH_TRANS_TUNNEL_HOST1}" == "*" ]; then
        TMP_SSH_TRANS_TUNNEL_HOST1="ALL"
    fi

    source /etc/profile
    
    local TMP_SSH_TRANS_SUP_NAME="ssh_transfer_${TMP_SSH_TRANS_TUNNEL_MODE}_${TMP_SSH_TRANS_DEST_USER}_${TMP_SSH_TRANS_DEST_HOST}_${TMP_SSH_TRANS_TUNNEL_HOST1}_${TMP_SSH_TRANS_TUNNEL_PORT1}_${TMP_SSH_TRANS_TUNNEL_HOST2}_${TMP_SSH_TRANS_TUNNEL_PORT2}"
    local TMP_SSH_TRANS_ETC_FILE="${SUPERVISOR_HOME}/etc/${TMP_SSH_TRANS_SUP_NAME}.conf"

    function _echo_startup_config()
    {
        echo_startup_config "${TMP_SSH_TRANS_SUP_NAME}" "${SUPERVISOR_HOME}/scripts" "ssh ${TMP_SSH_TRANS_SCRIPTS}" "" 1
    }

    path_not_exists_action "${TMP_SSH_TRANS_ETC_FILE}" "_echo_startup_config"

    echo
    echo "SSH-Transfer：Done -> (ssh ${TMP_SSH_TRANS_SCRIPTS})"
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

    mkdirs
 
    choice_type
}

if [ "${BASH_SOURCE[0]:-}" != "${0}" ]; then
    export -f bootstrap
else
    bootstrap ${@}
    exit $?
fi