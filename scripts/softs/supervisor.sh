#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function setup_libs()
{
    # 需要提前安装Python
    cd $WORK_PATH
    source scripts/lang/python.sh

	return $?
}

function setup_supervisor()
{
    mkdir -pv $SUPERVISOR_CONF_ROOT/conf
    mkdir -pv $SUPERVISOR_CONF_ROOT/scripts

    SUPERVISOR_LOGS_DIR=$LOGS_DIR/supervisor
    mkdir -pv $SUPERVISOR_LOGS_DIR
    ln -sf $SUPERVISOR_LOGS_DIR $SUPERVISOR_CONF_ROOT/logs

	SUPERVISOR_CONF_PATH=$SUPERVISOR_CONF_ROOT/supervisor.conf

    cd $SUPERVISOR_CONF_ROOT
    if [ ! -f "supervisor.conf" ]; then
        echo_supervisord_conf > $SUPERVISOR_CONF_PATH
    fi

    if [ ! -f "supervisor" ]; then
        cat >$SUPERVISOR_CONF_ROOT/supervisor<<EOF
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
    SUPERVISORD_RUNNING_DATA=`ps -fe | grep supervisord | grep -v grep`
    if [ -z "\$SUPERVISORD_RUNNING_DATA" ]; then
        echo "Clean pid & lock files"
        rm -rf /tmp/supervisor*
        rm -rf $SUPERVISOR_CONF_ROOT/logs/*
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
    pid=[pid]
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
    if running ; then
        RETVAL=0
    else
        RETVAL=1
    fi
    ;;
*)
    echo $"Usage: \$0 {start|stop|status|restart|reload|force-reload|condrestart}"
    exit 1
esac

exit \$RETVAL
EOF

        sed -i "s@^[[:space:]]*pid=[pid]@    pid=\`cat $PIDFILE\`@g" $SUPERVISOR_CONF_ROOT/supervisor
    fi

    chmod +x supervisor
    #添加软链接与服务启动
    rm -rf /etc/supervisor.conf
    ln -sf $SUPERVISOR_CONF_PATH /etc/supervisor.conf
    ln -sf $SUPERVISOR_CONF_ROOT/supervisor /usr/bin/supervisor #/etc/init.d/supervisord

    sed -i "s@^;\[include\]@\[include\]@g" $SUPERVISOR_CONF_PATH
    sed -i "s@^;files = .*@files = $SUPERVISOR_CONF_ROOT/conf/*.conf@g" $SUPERVISOR_CONF_PATH

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

    chkconfig supervisord on
    chkconfig --list | grep supervisord
    systemctl enable supervisord.service

    rm -rf /tmp/supervisor*
    supervisor start
    
	return $?
}

function down_supervisor()
{
    setup_soft_pip "supervisor" "setup_supervisor" "setup_libs"

	return $?
}

setup_soft_basic "Supervisor" "down_supervisor"