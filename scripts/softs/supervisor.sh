#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

# 1-配置环境
function set_environment()
{
    # 需要提前安装Python
    source ${__DIR}/scripts/lang/python.sh

	return $?
}

# 2-安装软件
function setup_supervisor()
{
    path_not_exists_create "${SUPERVISOR_ATT_DIR}"
    path_not_exists_create "${TMP_SFT_SUPERVISOR_VTL_SETUP_DIR}"
    
	return $?
}

# 3-设置软件
function set_supervisor()
{
	local TMP_SFT_SUPERVISOR_CONF_PATH=${SUPERVISOR_ATT_DIR}/supervisor.conf
    path_not_exists_action "${TMP_SFT_SUPERVISOR_CONF_PATH}" "set_supervisor_conf"

    local TMP_SFT_SUPERVISOR_VTL_BIN_PATH=${TMP_SFT_SUPERVISOR_VTL_SETUP_DIR}/supervisor
    path_not_exists_action "${TMP_SFT_SUPERVISOR_VTL_BIN_PATH}" "set_supervisor_bin"

	return $?
}

function set_supervisor_conf()
{
    # 规范特殊安装的目录
	local TMP_SFT_SUPERVISOR_CONF_PATH=${1}
	local TMP_SFT_SUPERVISOR_VTL_SETUP_CONF_PATH=${TMP_SFT_SUPERVISOR_VTL_SETUP_DIR}/supervisor.conf

    rm -rf /etc/supervisor.conf
    rm -rf ${TMP_SFT_SUPERVISOR_VTL_SETUP_CONF_PATH}
    sudo echo_supervisord_conf > ${TMP_SFT_SUPERVISOR_CONF_PATH}

    ln -sf ${TMP_SFT_SUPERVISOR_CONF_PATH} /etc/supervisor.conf
    ln -sf ${TMP_SFT_SUPERVISOR_CONF_PATH} ${TMP_SFT_SUPERVISOR_VTL_SETUP_CONF_PATH}
    
    # 规范日志的目录
    local TMP_SFT_SUPERVISOR_LNK_LOGS_DIR=${LOGS_DIR}/supervisor
	local TMP_SFT_SUPERVISOR_VTL_LOGS_DIR=${TMP_SFT_SUPERVISOR_VTL_SETUP_DIR}/logs

    path_not_exists_create "${TMP_SFT_SUPERVISOR_LNK_LOGS_DIR}"

	rm -rf ${TMP_SFT_SUPERVISOR_VTL_LOGS_DIR}
    ln -sf ${TMP_SFT_SUPERVISOR_LNK_LOGS_DIR} ${TMP_SFT_SUPERVISOR_VTL_LOGS_DIR}

    sed -i "s@^[;]*logfile=.*@logfile=${TMP_SFT_SUPERVISOR_LNK_LOGS_DIR}/supervisor.log@g" ${TMP_SFT_SUPERVISOR_CONF_PATH}
    sed -i "s@^[;]*\[include\]@\[include\]@g" ${TMP_SFT_SUPERVISOR_CONF_PATH}
    sed -i "s@^[;]*files = .*@files = ${SUPERVISOR_ATT_DIR}/conf/*.conf@g" ${TMP_SFT_SUPERVISOR_CONF_PATH}

    # 规范后期配置文件及脚本存放路径
	local TMP_SFT_SUPERVISOR_CONF_DIR="${SUPERVISOR_ATT_DIR}/conf"
	local TMP_SFT_SUPERVISOR_SCRIPTS_DIR="${SUPERVISOR_ATT_DIR}/scripts"
    local TMP_SFT_SUPERVISOR_VTL_CONF_DIR=${TMP_SFT_SUPERVISOR_VTL_SETUP_DIR}/conf
    local TMP_SFT_SUPERVISOR_VTL_SCRIPTS_DIR=${TMP_SFT_SUPERVISOR_VTL_SETUP_DIR}/scripts
    
	path_not_exists_create "${TMP_SFT_SUPERVISOR_CONF_DIR}"
	path_not_exists_create "${TMP_SFT_SUPERVISOR_SCRIPTS_DIR}"

    rm -rf ${TMP_SFT_SUPERVISOR_VTL_CONF_DIR}
    rm -rf ${TMP_SFT_SUPERVISOR_VTL_SCRIPTS_DIR}
    ln -sf ${TMP_SFT_SUPERVISOR_CONF_DIR} ${TMP_SFT_SUPERVISOR_VTL_CONF_DIR}
    ln -sf ${TMP_SFT_SUPERVISOR_SCRIPTS_DIR} ${TMP_SFT_SUPERVISOR_VTL_SCRIPTS_DIR}

	return $?
}

function set_supervisor_bin()
{
    local TMP_SFT_SUPERVISOR_VTL_BIN_PATH=${1}

    cat >${TMP_SFT_SUPERVISOR_VTL_BIN_PATH}<<EOF
#!/bin/bash
#
# supervisord   This scripts turns supervisord on
# chkconfig:    345 83 04
# description:  supervisor is a process control utility.  It has a web based
#              xmlrpc interface as well as a few other nifty features.
#
# examples: supervisorctl -c /etc/supervisor.conf start xxx

# source function library
. /etc/rc.d/init.d/functions

set -a

PREFIX=/usr

SUPERVISORD=\$PREFIX/bin/supervisord
SUPERVISORCTL=\$PREFIX/bin/supervisorctl

PIDFILE=/tmp/supervisord.pid
LOCKFILE=/tmp/supervisord.lock

OPTIONS="-c /etc/supervisor.conf"

# unset this variable if you don't care to wait for child processes to shutdown before removing the $LOCKFILE-lock
WAIT_FOR_SUBPROCESSES=yes

# remove this if you manage number of open files in some other fashion
ulimit -n 96000

RETVAL=0

# Fix exception Running
if [ -e \$PIDFILE ]; then 
    SUPERVISORD_RUNNING_DATA=\`ps -fe | grep supervisord | grep -v grep\`
    if [ -z "\$SUPERVISORD_RUNNING_DATA" ]; then
        echo "Clean pid & lock files"
        rm -rf /tmp/supervisor*
        rm -rf $SUPERVISOR_ATT_DIR/logs/*
    fi
fi

running_pid()
{
    # Check if a given process pid's cmdline matches a given name
    pid=\$1
    name=\$2
    [ -z "\$pid" ] && return 1
    [ ! -d /proc/\$pid ] && return 1
    (cat /proc/\$pid/cmdline | tr "\000" "\n"|grep -q \$name) || return 1
    return 0
}

running()
{
    # Check if the process is running looking at /proc
    # (works for all users)

    # No pidfile, probably no daemon present
    [ ! -f "\$PIDFILE" ] && return 1
    # Obtain the pid and check it against the binary name
    pid=\`cat \$PIDFILE\`
    running_pid \$pid \$SUPERVISORD || return 1
    return 0
}

start() 
{
    echo "Starting supervisord: "

    if [ -e \$PIDFILE ]; then 
        echo "ALREADY STARTED"
        return 1
    fi

    # start supervisord with options from sysconfig (stuff like -c)
    \$SUPERVISORD \$OPTIONS

    # show initial startup status
    \$SUPERVISORCTL \$OPTIONS status

    # only create the subsyslock if we created the PIDFILE
    [ -e \$PIDFILE ] && touch \$LOCKFILE
}

stop() 
{
    total_sleep=0
    echo -n "Stopping supervisord: "
    \$SUPERVISORCTL \$OPTIONS shutdown
    if [ -n "\$WAIT_FOR_SUBPROCESSES" ]; then 
        echo "Waiting roughly 60 seconds for \$PIDFILE to be removed after child processes exit"
        for sleep in 2 2 2 2 4 4 4 4 8 8 8 8 0; do
            if [[ ! -e \$PIDFILE ]] ; then
                echo "Supervisord exited as expected in under \$total_sleep seconds"
                break
            else
                if [ \$sleep -eq 0 ]; then
                    echo "Supervisord still working on shutting down. We've waited roughly 60 seconds, we'll let it do its thing from here"
                    return 1
                else
                    echo "taking for \$sleep seconds wait..."
                    sleep \$sleep
                    total_sleep+=\$sleep
                fi
            fi
        done
    fi

    # always remove the subsys. We might have waited a while, but just remove it at this point.
    rm -f \$LOCKFILE
    rm -f \$PIDFILE
}

restart() 
{
    stop
    start
}

case "\$1" in
start)
    start
    RETVAL=$?
    ;;
stop)
    stop
    RETVAL=$?
    ;;
restart|force-reload)
    restart
    RETVAL=$?
    ;;
reload)
    \$SUPERVISORCTL \$OPTIONS reload
    RETVAL=$?
    ;;
condrestart)
    [ -f \$LOCKFILE ] && restart
    RETVAL=$?
    ;;
status)
    \$SUPERVISORCTL \$OPTIONS status
    running
    RETVAL=$?
    ;;
*)
    echo $"Usage: \$0 {start|stop|status|restart|reload|force-reload|condrestart}"
    exit 1
esac

exit \$RETVAL
EOF

    #添加软链接与服务启动
    rm -rf /usr/bin/supervisor
    ln -sf ${TMP_SFT_SUPERVISOR_VTL_BIN_PATH} /usr/bin/supervisor #/etc/init.d/supervisord
    
    chmod +x ${TMP_SFT_SUPERVISOR_VTL_BIN_PATH}

	return $?
}

# 4-启动软件
function boot_supervisor()
{
    # 创建启动服务
    cat >/lib/systemd/system/supervisord.service<<EOF
# supervisord service for systemd (CentOS 7.0+)
# https://github.com/Supervisor/initscripts
[Unit]
Description=Supervisor daemon
After=rc-local.service

[Service]
Type=forking
ExecStart=/usr/bin/supervisor start
ExecStop=/usr/bin/supervisor stop
ExecReload=/usr/bin/supervisor reload
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

    rm -rf /tmp/supervisor*

    chkconfig supervisord on
    chkconfig --list | grep supervisord
    systemctl enable supervisord.service
    systemctl start supervisord.service

	return $?
}

# x-执行步骤
function exec_step_supervisor()
{
    # 全局变量，因supervisor本身非编译安装方式，所以创建虚拟路径
    TMP_SFT_SUPERVISOR_VTL_SETUP_DIR=${SETUP_DIR}/supervisor

    # 局部变量，对supervisor来说，无效。因为其自身根据pip的路径进行安装 ??? 规范待改进
	local TMP_SFT_SPV_SETUP_DIR=${1}

	set_environment "${TMP_SFT_SPV_SETUP_DIR}"

    setup_supervisor "${TMP_SFT_SPV_SETUP_DIR}"

    set_supervisor "${TMP_SFT_SPV_SETUP_DIR}"

	boot_supervisor "${TMP_SFT_SPV_SETUP_DIR}"

	return $?
}

function down_supervisor()
{
    setup_soft_pip "supervisor" "exec_step_supervisor"

	return $?
}

setup_soft_basic "Supervisor" "down_supervisor"