#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

# Disable selinux
function disable_selinux() {
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi

	return $?
}

function check_libs()
{
	path_not_exits_action "$SETUP_DIR/lib_installed" "setup_libs"

	return $?
}

function setup_libs()
{
	sudo rpm -ivh http://www.rpmfind.net/linux/dag/redhat/el7/en/x86_64/dag/RPMS/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm
	sudo rpm --import /etc/pki/rpm-gpg/RPM*
	sudo yum -y install apt
	sudo apt-get update

	sudo yum -y update
	sudo yum -y groupinstall "Development Tools"
	sudo yum -y install yum-utils
	sudo yum clean all
	sudo yum-complete-transaction --cleanup-only

	sudo yum -y install lsof
	sudo yum -y install gcc*
	sudo yum -y install autoconf
	sudo yum -y install freetype*
	sudo yum -y install libxml2* install libxml2-*
	sudo yum -y install zlib*
	sudo yum -y install glibc* glib2*
	sudo yum -y install bzip2*
	sudo yum -y install ncurses*
	sudo yum -y install curl*
	sudo yum -y install e2fsprogs*
	sudo yum -y install krb5*
	sudo yum -y install libidn*
	sudo yum -y install openssl*
	sudo yum -y install openldap*
	sudo yum -y install nss_ldap
	sudo yum -y install openldap-clients openldap-servers
	sudo yum -y install patch
	sudo yum -y install make
	sudo yum -y install jpackage-utils
	sudo yum -y install build-essential
	sudo yum -y install bzip
	sudo yum -y install bison
	sudo yum -y install pkgconfig
	sudo yum -y install glib-devel
	sudo yum -y install httpd-devel
	sudo yum -y install fontconfig
	sudo yum -y install pango-devel
	sudo yum -y install ruby
	sudo yum -y install ruby-rdoc
	sudo yum -y install gtkhtml38-devel
	sudo yum -y install gettext
	sudo yum -y install gcc-g77
	sudo yum -y install automake
	sudo yum -y install fiex*
	sudo yum -y install libX11-devel libx11* libiconv
	sudo yum -y install libmcrypt*
	sudo yum -y install libtool-ltdl-devel*
	sudo yum -y install pcre*
	sudo yum -y install cmake
	sudo yum -y install mhash*
	sudo yum -y install libevent
	sudo yum -y install libevent-devel
	sudo yum -y install gif*
	sudo yum -y install libtiff* libjpeg* libpng* 
	sudo yum -y install mcrypt
	sudo yum -y install libuuid*
	sudo yum -y install iptables-services
	sudo yum -y install rsync
	sudo yum -y install xinetd
	sudo yum -y install htop
	sudo yum -y install httpie
	sudo yum -y install tmpwatch
	sudo yum -y install qperf
	sudo yum -y install vim
	sudo yum -y install screen
	sudo yum -y install lrzsz
	sudo tmpwatch 168 /tmp

	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	sudo yum -y install ntp ntpdate
	ntpdate cn.pool.ntp.org
	hwclock --systohc
	hwclock -w
	timedatectl

	# 关闭SElinux
	disable_selinux

	swapoff -a && sysctl -w vm.swappiness=0
	sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab  # 取消开机挂载swap
	free -m

	#IPTABLES 失效
	/usr/sbin/iptables-restore /etc/sysconfig/iptables
	
	echo "" >> $SETUP_DIR/lib_installed

	return $?
}

setup_soft_basic "Public Libs" "check_libs"