#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
	yum -y install curl curl-devel

	sudo groupadd lnmp
	sudo useradd -g lnmp php

	return $?
}

function setup_php56()
{
	PHP56_CURRENT_DIR=`pwd`

	PHP56_SETUP_DIR=$SETUP_DIR/php56
	PHP56_ATT_DIR=$ATT_DIR/php56
	PHP56_ATT_CONF_DIR=$PHP56_ATT_DIR/etc

	mkdir -pv $PHP56_ATT_CONF_DIR

	#部分系统编译可能会出现错误，解决方案如右：http://www.poluoluo.com/jzxy/201505/364819.html
	#缺少安装包的情况，下载MCrypt，Libmcrypt：https://sourceforge.net/projects/mcrypt/files/
	#MHASH：https://sourceforge.net/projects/mhash/files/mhash/0.9.9.9/mhash-0.9.9.9.tar.gzSETUP_DIR
	#参考：http://www.cnblogs.com/huangzhen/archive/2012/09/12/2681861.html
	#或安装第三方yum源 wget http://www.atomicorp.com/installers/atomic && sh ./atomic
	sudo ./configure --prefix=$PHP56_SETUP_DIR --with-config-file-path=$PHP56_ATT_CONF_DIR --with-libdir=lib64 --enable-fpm --with-fpm-user=php --with-fpm-group=lnmp --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=$SETUP_DIR/freetype --with-jpeg-dir --with-png-dir --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --enable-intl
	sudo make -j4 && sudo make -j4 install
	
	conf_environment

	return $?
}

function conf_environment()
{
    echo "Link to php-bin..."
	ln -sf $PHP56_SETUP_DIR/bin/php /usr/bin/php
	ln -sf $PHP56_SETUP_DIR/bin/phpize /usr/bin/phpize
	ln -sf $PHP56_SETUP_DIR/bin/pear /usr/bin/pear
	ln -sf $PHP56_SETUP_DIR/bin/pecl /usr/bin/pecl

	echo "Modify php.ini..."
	sed -i 's/memory_limit =.*/memory_limit = 4096M/g' php.ini-production
	sed -i 's/post_max_size =.*/post_max_size = 50M/g' php.ini-production
	sed -i 's/post_max_size =.*/post_max_size = 50M/g' php.ini-production
	sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' php.ini-production
	sed -i 's/;date.timezone =.*/date.timezone = PRC/g' php.ini-production
	sed -i 's/short_open_tag =.*/short_open_tag = On/g' php.ini-production
	sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' php.ini-production
	sed -i 's/max_execution_time =.*/max_execution_time = 300/g' php.ini-production
	sed -i 's/disable_functions =.*/disable_functions = exec,system,chroot,scandir,chgrp,chown,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,passthru,proc_open,proc_get_status,shell_exec/g' php.ini-production
	
	echo "Copy new php configure file..."
	cp php.ini-production $PHP56_ATT_CONF_DIR/php.ini

	pear config-set php_ini $PHP56_ATT_CONF_DIR/php.ini
	pecl config-set php_ini $PHP56_ATT_CONF_DIR/php.ini

	echo "Copy init.d.php-fpm into startup and start..."
	sed -i "s@php_fpm_conf=.*@php_fpm_conf=$PHP56_ATT_CONF_DIR/php-fpm.conf@g" sapi/fpm/init.d.php-fpm
	chmod +x sapi/fpm/init.d.php-fpm
	cp sapi/fpm/init.d.php-fpm $PHP56_ATT_DIR/php-fpm
	ln -sf $PHP56_ATT_DIR/php-fpm /usr/bin/php-fpm 
	
    echo_startup_config "php_fpm" "$PHP56_ATT_DIR" "php-fpm start"	

	rm -rf $PHP56_CURRENT_DIR

	return $?
}

function down_php()
{
	set_environment
    setup_soft_wget "php56" "http://cn2.php.net/distributions/php-5.6.24.tar.gz" "setup_php56"

	return $?
}

#安装主体
setup_soft_basic "PHP" "down_php"

#安装插件
function setup_phpredis()
{
	PHPREDIS_CURRENT_DIR=`pwd`

	PHPREDIS_SETUP_DIR=$SETUP_DIR/phpredis

	#部分系统编译可能会出现错误，解决方案如右：http://www.poluoluo.com/jzxy/201505/364819.html
	#缺少安装包的情况，下载MCrypt，Libmcrypt：https://sourceforge.net/projects/mcrypt/files/
	#MHASH：https://sourceforge.net/projects/mhash/files/mhash/0.9.9.9/mhash-0.9.9.9.tar.gzSETUP_DIR
	#参考：http://www.cnblogs.com/huangzhen/archive/2012/09/12/2681861.html
	#或安装第三方yum源 wget http://www.atomicorp.com/installers/atomic && sh ./atomic
	phpize
	./configure --prefix=$PHPREDIS_SETUP_DIR --with-php-config=$PHP56_SETUP_DIR/bin/php-config --with-openssl # 
	make -j4 && sudo make -j4 install
	echo "extension=\"redis.so\"" >> $PHP56_ATT_CONF_DIR/php.ini

	echo "Creating new php-fpm configure file..."
	cat >$PHP56_ATT_CONF_DIR/php-fpm.conf<<EOF
[global]
pid = $PHP56_SETUP_DIR/var/run/php-fpm.pid
error_log = $PHP56_SETUP_DIR/var/log/php-fpm.log
log_level = notice
rlimit_files = 65536
process_control_timeout = 5

[www]
listen = $PHP56_ATT_DIR/php-fcgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = php
listen.group = lnmp
listen.mode = 0666
user = php
group = lnmp
pm = dynamic
pm.max_children = 256
pm.max_requests=10000
pm.start_servers = 64
pm.min_spare_servers = 64
pm.max_spare_servers = 128
request_terminate_timeout = 100
request_slowlog_timeout = 1
slowlog = var/log/slow.log
EOF

	return $?
}

function boot_php()
{
	php-fpm start
	php -v

	return $?
}

function down_phpredis()
{
    setup_soft_git "PhpRedis" "https://github.com/phpredis/phpredis" "setup_phpredis"

	return $?
}

setup_soft_basic "PHP-Redis" "down_phpredis"

function setup_phpredis()
{
	sudo mkdir -pv $PHP56_SETUP_DIR/zend
	cp ZendGuardLoader.so $PHP56_SETUP_DIR/zend
	echo "Write ZendGuardLoader to php.ini..."
	cat >>$PHP56_ATT_CONF_DIR/php.ini<<EOF

;eaccelerator

;ionCube

;opcache

[Zend ZendGuard Loader]
zend_extension=$PHP56_SETUP_DIR/zend/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=

;xcache

EOF

	echo "Start Install Composer..."
	curl -sS https://getcomposer.org/installer | php -- --install-dir=$PHP56_SETUP_DIR/bin
	ln -sf $PHP56_SETUP_DIR/bin/composer.phar /usr/bin/composer

	return $?
}

function down_phpzend56()
{
    setup_soft_wget "PhpZend" "http://downloads.zend.com/guard/7.0.0/zend-loader-php5.6-linux-x86_64.tar.gz" "setup_phpzend56"

	return $?
}

setup_soft_basic "PHP-Zend" "down_phpzend56"
boot_php