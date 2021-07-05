#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function setup_epel()
{
	local TMP_COUNTRY_CODE="CN"
	get_country_code "TMP_COUNTRY_CODE"

	if [ "${TMP_COUNTRY_CODE}" -eq "CN"]; then
		sudo rpm -ivh https://mirrors.ustc.edu.cn/epel/epel-release-latest-7.noarch.rpm
		sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

		sudo rpm -e yum
		
		sudo rpm -ivh http://mirrors.ustc.edu.cn/centos/7/os/x86_64/Packages/yum-3.4.3-168.el7.centos.noarch.rpm
		sudo rpm -ivh http://mirrors.ustc.edu.cn/centos/7/os/x86_64/Packages/yum-metadata-parser-1.1.4-10.el7.x86_64.rpm
		sudo rpm -ivh http://mirrors.ustc.edu.cn/centos/7/os/x86_64/Packages/yum-plugin-fastestmirror-1.1.31-54.el7_8.noarch.rpm

		#更改镜像为国内镜像
		#http://centos.ustc.edu.cn/
		#http://mirrors.aliyun.com/repo/Centos-7.repo
		local TMP_SETED_MIRRORS=`cat /etc/yum.repos.d/CentOS-Base.repo | grep 'mirror.centos.org'`
		if [ -z "$TMP_SETED_MIRRORS" ]; then
			if [ ! -f "/etc/yum.repos.d/CentOS-Base.repo.backup" ]; then
				mv /etc/yum.repos.d/CentOS-Base.repo /tmp/CentOS-Base.repo.backup
				sudo rmp -rf /etc/yum.repos.d/*
				wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
				mv /tmp/CentOS-Base.repo.backup /etc/yum.repos.d/
				echo "" >> `date +%Y%m%d`.baktime
			fi
		fi

		# # 创建docker目录
		# sudo mkdir -p /etc/docker
		# # 创建配置文件
		# sudo tee /etc/docker/daemon.json <<-'EOF'
		# {
		# "registry-mirrors": ["https://registry.docker-cn.com"]
		# }
		# EOF
		# # 加载新的配置文件
		# sudo systemctl daemon-reload
		# # 重启docker服务
		# sudo systemctl restart docker
	else
		sudo rpm -ivh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    	sudo rpm -ivh  http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
	fi

	sudo yum clean all
	sudo yum makecache fast

	sudo yum -y install "epel-release"
	sudo yum repolist
	sudo yum -y install yum-priorities
	sudo yum -y install yum-plugin-fastestmirror
	
	soft_yum_check_setup "wget"
	soft_yum_check_setup "git"
	
	return $?
}

setup_soft_basic "Centos7_64bit EPEL Repository" "setup_epel"