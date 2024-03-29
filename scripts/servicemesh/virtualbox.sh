#!/bin/bash
#------------------------------------------------
#      centos7 project env installscript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------

function set_environment()
{
    yum -y install gcc make

    yum -y update kernel
    yum -y install kernel-headers-$(uname -r) kernel-devel-$(uname -r)

	return $?
}

function setup_virtualbox()
{
	tee /etc/yum.repos.d/virtualbox.repo <<-'EOF'
[virtualbox]
name=Oracle Linux / RHEL / CentOS-$releasever / $basearch - VirtualBox
baseurl=https://mirrors.tuna.tsinghua.edu.cn/virtualbox/rpm/el$releasever/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://www.virtualbox.org/download/oracle_vbox.asc

EOF
    #while_wget "https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo" "mv virtualbox.repo /etc/yum.repos.d"
    #wget https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo -P /etc/yum.repos.d

    yum makecache
    yum -y install VirtualBox-5.2
    /sbin/vboxconfig
    /sbin/rcvboxdrv setup

    VBoxManage --version

	return $?
}

function check_virtualbox()
{
    soft_yum_check_action "virtualbox" "setup_virtualbox" "VirtualBox was installed"

	return $?
}

set_environment
setup_soft_basic "VirtualBox" "check_virtualbox"
