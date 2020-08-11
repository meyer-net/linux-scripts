#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function setupEpel()
{
	#?? 安装失败
	sudo rpm -ivh https://mirrors.ustc.edu.cn/epel/epel-release-latest-7.noarch.rpm
	sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
	sudo yum -y install "epel-release"
	sudo yum repolist
	sudo yum -y install yum-priorities
	sudo yum -y install yum-plugin-fastestmirror
	
	soft_yum_check_install "wget"
	soft_yum_check_install "git"

	#更改镜像为国内镜像
	#http://centos.ustc.edu.cn/
	#http://mirrors.aliyun.com/repo/Centos-7.repo
	cd /etc/yum.repos.d
	local TMP_SETED_MIRRORS=`cat /etc/yum.repos.d/CentOS-Base.repo | grep 'mirror.centos.org'`
	if [ -z "$TMP_SETED_MIRRORS" ]; then
		if [ ! -f "CentOS-Base.repo.backup" ]; then
			mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
		fi
	fi
	
	sudo yum clean all
	sudo yum makecache fast
	
	return $?
}

setup_soft_basic "Centos7_64bit EPEL Repository" "setupEpel"