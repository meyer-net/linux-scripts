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
	soft_yum_check_install "apt"
	sudo apt-get update

	sudo yum -y update
	sudo yum -y groupinstall "Development Tools"
	soft_yum_check_install "yum-utils"
	sudo yum clean all
	sudo yum-complete-transaction --cleanup-only

	soft_yum_check_install "lsof"
	soft_yum_check_install "gcc*"
	soft_yum_check_install "autoconf"
	soft_yum_check_install "freetype*"
	soft_yum_check_install "libxml2*"
	soft_yum_check_install "install"
	soft_yum_check_install "libxml2-*"
	soft_yum_check_install "zlib*"
	soft_yum_check_install "glibc*"
	soft_yum_check_install "glib2*"
	soft_yum_check_install "bzip2*"
	soft_yum_check_install "ncurses*"
	soft_yum_check_install "curl*"
	soft_yum_check_install "e2fsprogs*"
	soft_yum_check_install "krb5*"
	soft_yum_check_install "libidn*"
	soft_yum_check_install "openssl*"
	soft_yum_check_install "openldap*"
	soft_yum_check_install "nss_ldap"
	soft_yum_check_install "openldap-clients"
	soft_yum_check_install "openldap-servers"
	soft_yum_check_install "patch"
	soft_yum_check_install "make"
	soft_yum_check_install "jpackage-utils"
	soft_yum_check_install "build-essential"
	soft_yum_check_install "bzip"
	soft_yum_check_install "bison"
	soft_yum_check_install "pkgconfig"
	soft_yum_check_install "glib-devel"
	soft_yum_check_install "httpd-devel"
	soft_yum_check_install "fontconfig"
	soft_yum_check_install "pango-devel"
	soft_yum_check_install "ruby"
	soft_yum_check_install "ruby-rdoc"
	soft_yum_check_install "gtkhtml38-devel"
	soft_yum_check_install "gettext"
	soft_yum_check_install "gcc-g77"
	soft_yum_check_install "automake"
	soft_yum_check_install "fiex*"
	soft_yum_check_install "libX11-devel"
	soft_yum_check_install "libx11*"
	soft_yum_check_install "libiconv"
	soft_yum_check_install "libmcrypt*"
	soft_yum_check_install "libtool-ltdl-devel*"
	soft_yum_check_install "pcre*"
	soft_yum_check_install "cmake"
	soft_yum_check_install "mhash*"
	soft_yum_check_install "libevent"
	soft_yum_check_install "libevent-devel"
	soft_yum_check_install "gif*"
	soft_yum_check_install "libtiff*"
	soft_yum_check_install "libjpeg*"
	soft_yum_check_install "libpng* "
	soft_yum_check_install "mcrypt"
	soft_yum_check_install "libuuid*"
	soft_yum_check_install "iptables-services"
	soft_yum_check_install "rsync"
	soft_yum_check_install "xinetd"
	soft_yum_check_install "htop"
	soft_yum_check_install "httpie"
	soft_yum_check_install "tmpwatch"
	soft_yum_check_install "qperf"
	soft_yum_check_install "vim"
	soft_yum_check_install "screen"
	soft_yum_check_install "lrzsz"
	sudo tmpwatch 168 /tmp

	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	soft_yum_check_install "ntp"
	soft_yum_check_install "ntpdate"
	
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