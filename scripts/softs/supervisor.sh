#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 相关参考：
#		  
#------------------------------------------------
local TMP_SUP_SETUP_HTTP_PORT=19001

##########################################################################################################

# 1-配置环境
function set_env_supervisor()
{
    cd ${__DIR}

    # soft_yum_check_setup ""

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_supervisor()
{
	## 直装模式
	cd `dirname ${TMP_SUP_CURRENT_DIR}`

	path_not_exists_create ${TMP_SUP_SETUP_DIR}

	cd ${TMP_SUP_SETUP_DIR}

	# 创建日志软链
	local TMP_SUP_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/supervisor
	local TMP_SUP_SETUP_LNK_DATA_DIR=${DATA_DIR}/supervisor
	local TMP_SUP_SETUP_LOGS_DIR=${TMP_SUP_SETUP_DIR}/logs
	local TMP_SUP_SETUP_DATA_DIR=${TMP_SUP_SETUP_DIR}/scripts

	# 先清理文件，再创建文件
	rm -rf ${TMP_SUP_SETUP_LOGS_DIR}
	rm -rf ${TMP_SUP_SETUP_DATA_DIR}
	mkdir -pv ${TMP_SUP_SETUP_LNK_LOGS_DIR}
	mkdir -pv ${TMP_SUP_SETUP_LNK_DATA_DIR}

	ln -sf ${TMP_SUP_SETUP_LNK_LOGS_DIR} ${TMP_SUP_SETUP_LOGS_DIR}
	ln -sf ${TMP_SUP_SETUP_LNK_DATA_DIR} ${TMP_SUP_SETUP_DATA_DIR}

	# 环境变量或软连接
	echo "SUPERVISOR_HOME=${TMP_SUP_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$SUPERVISOR_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH SUPERVISOR_HOME' >> /etc/profile

	# 移动bin
	mkdir bin
    echo "" > bin/supervisor

    # # 重新加载profile文件
	# source /etc/profile
	
    # 安装初始
    cat >bin/supervisor<<EOF
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
        rm -rf ${TMP_SUP_SETUP_LOGS_DIR}/*
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
    ln -sf `pwd`/bin/supervisor /usr/bin/supervisor #/etc/init.d/supervisord
   
    chmod +x bin/supervisor

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_supervisor()
{
	cd ${TMP_SUP_SETUP_DIR}
	
	local TMP_SUP_SETUP_LNK_ETC_DIR=${ATT_DIR}/supervisor
	local TMP_SUP_SETUP_ETC_DIR=${TMP_SUP_SETUP_DIR}/etc

	# ①-N：不存在配置文件：
	rm -rf ${TMP_SUP_SETUP_ETC_DIR}
    path_not_exists_action "/etc/supervisor.conf" "echo_supervisord_conf > /etc/supervisor.conf"
    path_not_exists_create "${TMP_SUP_SETUP_LNK_ETC_DIR}/conf"

	# 替换原路径链接（存在etc下时，不能作为软连接存在）
    ln -sf /etc/supervisor.conf ${TMP_SUP_SETUP_LNK_ETC_DIR}/supervisor.conf
    ln -sf ${TMP_SUP_SETUP_LNK_ETC_DIR} ${TMP_SUP_SETUP_ETC_DIR}

	# 开始配置
    sed -i "s@9001@${TMP_SUP_SETUP_HTTP_PORT}@g" etc/supervisor.conf
    sed -i "s@^[;]*logfile=.*@logfile=`pwd`/logs/supervisor.log@g" etc/supervisor.conf
    sed -i "s@^[;]*\[include\]@\[include\]@g" etc/supervisor.conf
    sed -i "s@^[;]*files = .*@files = `pwd`/etc/conf/*.conf@g" etc/supervisor.conf

	# 授权权限，否则无法写入
	# chown -R $setup_owner:$setup_owner_group ${TMP_SUP_SETUP_LNK_ETC_DIR}

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_supervisor()
{
	cd ${TMP_SUP_SETUP_DIR}
	
	# 验证安装
    supervisord -v
	
	# 启动配置加载
	sudo tee /usr/lib/systemd/system/supervisor.service <<-EOF
# Supervisord service for systemd (CentOS 7.0+)
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

    systemctl daemon-reload

	# 设定启动运行
    chkconfig supervisor on
    chkconfig --list | grep supervisor
    systemctl enable supervisor.service
    systemctl start supervisor.service
	
	# 启动状态检测
	# lsof -i:${TMP_SUP_SETUP_HTTP_PORT}

    rm -rf /tmp/supervisor*
    
	# 授权iptables端口访问
	echo_soft_port ${TMP_SUP_SETUP_HTTP_PORT}
    
	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_supervisor()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_supervisor()
{
	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_supervisor()
{
	# 变量覆盖特性，其它方法均可读取
	# local TMP_SUP_SETUP_DIR=${1} 
    
    # 默认pip安装的目录在packages中，此处不取用
	local TMP_SUP_SETUP_DIR=${SETUP_DIR}/supervisor
	local TMP_SUP_CURRENT_DIR=`pwd`
    
	set_env_supervisor 

	setup_supervisor 

	conf_supervisor 

    # down_plugin_supervisor 
    # setup_plugin_supervisor 

	boot_supervisor 

	# reconf_supervisor 

	return $?
}

##########################################################################################################

# x1-下载软件
function down_supervisor()
{
    setup_soft_pip "supervisor" "exec_step_supervisor"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "Supervisor" "down_supervisor"
