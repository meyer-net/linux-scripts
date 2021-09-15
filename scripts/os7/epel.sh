#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------

function setup_epel()
{	
	soft_yum_check_setup "wget"

	#https://github.com/stedolan/jq
	soft_yum_check_setup "jq"
	soft_yum_check_setup "git"
	
	input_if_empty "COUNTRY_CODE" "Please sure ${green}your country code${reset}"

	if [ "${COUNTRY_CODE}" == "CN" ]; then
		rpm -ivh https://mirrors.ustc.edu.cn/epel/epel-release-latest-${OS_VERS}.noarch.rpm
		rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${OS_VERS}

		rpm -e yum

		#更改镜像为国内镜像
		#http://centos.ustc.edu.cn/
		#http://mirrors.aliyun.com/repo/Centos-${OS_VERS}.repo
		# echo "Change repos to CN..."
		# local TMP_SETED_MIRRORS=`cat /etc/yum.repos.d/CentOS-Base.repo | grep 'mirror.centos.org'`
		# if [ -n "$TMP_SETED_MIRRORS" ]; then
		# 	if [ ! -f "/etc/yum.repos.d/CentOS-Base.repo.backup" ]; then
		# 		mv /etc/yum.repos.d/CentOS-Base.repo /tmp/CentOS-Base.repo.backup
		# 		rm -rf /etc/yum.repos.d/*
		# 		wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-${OS_VERS}.repo
		# 		mv /tmp/CentOS-Base.repo.backup /etc/yum.repos.d/
		# 		echo "" >> /etc/yum.repos.d/CentOS-Base.repo
		# 		echo "# At "`date +%Y%m%d`" init" >> /etc/yum.repos.d/CentOS-Base.repo
		# 	fi
		# fi
				
		echo "Reseting yum rpms to CN-ustc.edu..."
		rpm -ivh http://mirrors.ustc.edu.cn/centos/${OS_VERS}/os/x86_64/Packages/yum-3.4.3-168.el${OS_VERS}.centos.noarch.rpm
		rpm -ivh http://mirrors.ustc.edu.cn/centos/${OS_VERS}/os/x86_64/Packages/yum-metadata-parser-1.1.4-10.el${OS_VERS}.x86_64.rpm
		rpm -ivh http://mirrors.ustc.edu.cn/centos/${OS_VERS}/os/x86_64/Packages/yum-plugin-fastestmirror-1.1.31-54.el${OS_VERS}_8.noarch.rpm

		# # 创建docker目录
		# mkdir -p /etc/docker
		# # 创建配置文件
		# tee /etc/docker/daemon.json <<-'EOF'
		# {
		# "registry-mirrors": ["https://registry.docker-cn.com"]
		# }
		# EOF
		# # 加载新的配置文件
		# systemctl daemon-reload
		# # 重启docker服务
		# systemctl restart docker
	else
		rpm -ivh http://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERS}.noarch.rpm
		rpm -ivh  http://rpms.famillecollet.com/enterprise/remi-release-${OS_VERS}.rpm
	fi

	yum -y install epel-release

	echo "Clearing yum cache..."
	yum clean all
	yum makecache fast

	yum repolist
	yum -y install yum-priorities
	yum -y install yum-plugin-fastestmirror
	
	soft_yum_check_setup "jsawk"
	
	return $?
}

setup_soft_basic "Centos7_64bit EPEL Repository" "setup_epel"