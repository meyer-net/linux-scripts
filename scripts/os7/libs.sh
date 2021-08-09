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
	path_not_exists_action "${SETUP_DIR}/lib_installed" "setup_libs"

	return $?
}

function setup_libs()
{
	sudo rpm -ivh http://www.rpmfind.net/linux/dag/redhat/el7/en/x86_64/dag/RPMS/rpmforge-release-0.5.3-1.el7.rf.x86_64.rpm
	sudo rpm --import /etc/pki/rpm-gpg/RPM*
	soft_yum_check_setup "apt"
	sudo apt-get update

	sudo yum -y update
	sudo yum -y groupinstall "Development Tools"
	soft_yum_check_setup "yum-utils"
	sudo yum clean all
	sudo yum-complete-transaction --cleanup-only

	soft_yum_check_setup "lsof"
	soft_yum_check_setup "gcc*"
	soft_yum_check_setup "autoconf"
	soft_yum_check_setup "freetype*"
	soft_yum_check_setup "libxml2*"
	soft_yum_check_setup "install"
	soft_yum_check_setup "libxml2-*"
	soft_yum_check_setup "zlib*"
	soft_yum_check_setup "glibc*,glib2*"
	soft_yum_check_setup "bzip2*"
	soft_yum_check_setup "ncurses*"
	soft_yum_check_setup "curl*"
	soft_yum_check_setup "e2fsprogs*"
	soft_yum_check_setup "krb5*"
	soft_yum_check_setup "libidn*"
	soft_yum_check_setup "openssl*,openldap*,nss_ldap"
	soft_yum_check_setup "openssl-devel"
	soft_yum_check_setup "openldap-clients,openldap-servers"
	soft_yum_check_setup "patch"
	soft_yum_check_setup "make"
	soft_yum_check_setup "jpackage-utils"
	soft_yum_check_setup "build-essential"
	soft_yum_check_setup "bzip"
	soft_yum_check_setup "bison"
	soft_yum_check_setup "pkgconfig"
	soft_yum_check_setup "glib-devel"
	soft_yum_check_setup "httpd-devel"
	soft_yum_check_setup "fontconfig"
	soft_yum_check_setup "pango-devel"
	soft_yum_check_setup "ruby,ruby-rdoc"
	soft_yum_check_setup "gtkhtml38-devel"
	soft_yum_check_setup "gettext"
	soft_yum_check_setup "gcc-g77"
	soft_yum_check_setup "automake"
	soft_yum_check_setup "fiex*"
	soft_yum_check_setup "libX11-devel"
	soft_yum_check_setup "libx11*"
	soft_yum_check_setup "libiconv"
	soft_yum_check_setup "libmcrypt*"
	soft_yum_check_setup "libtool-ltdl-devel*"
	soft_yum_check_setup "pcre*"
	soft_yum_check_setup "cmake"
	soft_yum_check_setup "mhash*"
	soft_yum_check_setup "libevent"
	soft_yum_check_setup "libevent-devel"
	soft_yum_check_setup "gif*"
	soft_yum_check_setup "libffi-devel"
	soft_yum_check_setup "libtiff*,libjpeg*,libpng* "
	soft_yum_check_setup "mcrypt"
	soft_yum_check_setup "libuuid*"
	# soft_yum_check_setup "iptables-services"
	soft_yum_check_setup "rsync"
	soft_yum_check_setup "xinetd"
	soft_yum_check_setup "htop,iftop"
	soft_yum_check_setup "httpie"
	soft_yum_check_setup "tmpwatch"
	soft_yum_check_setup "qperf"
	soft_yum_check_setup "vim-enhanced"
	soft_yum_check_setup "screen"
	soft_yum_check_setup "lrzsz"

	# gcc 切换：https://www.cnblogs.com/jixiaohua/p/11732225.html
	soft_yum_check_setup "centos-release-scl"

	sudo tmpwatch 168 /tmp

	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	soft_yum_check_setup "ntp"
	soft_yum_check_setup "ntpdate"
	
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
	
	echo "" >> ${SETUP_DIR}/lib_installed

	return $?
}

setup_soft_basic "Public Libs" "check_libs"