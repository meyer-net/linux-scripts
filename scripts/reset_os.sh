#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------

function reset_passwd()
{
    passwd root

	return $?
}

function reset_dns()
{
    currentTime=`date "+%Y-%m-%d %H:%M:%S"`
    currentTimeStamp=`date -d "$currentTime" +%s` 
    cp /etc/resolv.conf /etc/resolv.$currentTimeStamp.conf
    cat >/etc/resolv.conf<<EOF
# Generated by NetworkManager
search $SYS_NAME
nameserver 223.5.5.5
nameserver 180.76.76.76
EOF
    cat /etc/resolv.conf

	return $?
}

function reset_ip()
{
    ls -l /etc/sysconfig/network-scripts/ifcfg-en*
    echo "SYS: Please Ender Your Network-Num By Prefix Command Output Text 'en********' Text Like 'o16777736' Or Else"
    read -e NETWORK_NUM

    if [ "$NETWORK_NUM" != "" ]; then
        echo "SYS: Please Ender New Ip Address Like '192.168.1.185' Or Else"
        read -e IP_ADDR
        sed -i "s@^IPADDR=.*@IPADDR=\"$IP_ADDR\"@g" /etc/sysconfig/network-scripts/ifcfg-en$NETWORK_NUM
        cat /etc/sysconfig/network-scripts/ifcfg-en$NETWORK_NUM
        service network restart
    fi

    source /etc/profile

	return $?
}

function reset_os()
{
    SYS_NAME=`hostname`
    input_if_empty "SYS_NAME" "SYS: Please Ender ${green}System Name${reset} Like 'LnxSvr' Or Else"
    hostnamectl set-hostname $SYS_NAME

    exec_yn_action "reset_passwd" "SYS: Please sure you want to ${green}Change Password${reset}"
    exec_yn_action "reset_dns" "SYS: Please sure you want to ${green}Change DNS${reset}"
    exec_yn_action "reset_ip" "SYS: Please sure you want to ${green}Change Local Ip${reset}"

	return $?
}

reset_os