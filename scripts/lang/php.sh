#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
	sudo groupadd lnmp
	sudo useradd -g lnmp php

	return $?
}

#设置PHP配置文件
#参数1：PHP配置文件路径
function set_phpini()
{
	local TMP_PHP_INI_PATH=$1

	echo "---------------------------------------------------------------------------"
	echo "Start to modify php.ini, the path of php.ini is '$TMP_PHP_INI_PATH'"

	local TMP_PHP_CURRENT_MEMORY_SIZE_M=`expr $MEMORY_GB_FREE / 2 \* 1024 + 1024`
	
	sed -i "s@memory_limit =.*@memory_limit = ${TMP_PHP_CURRENT_MEMORY_SIZE_M}M@g" $TMP_PHP_INI_PATH
	sed -i 's@[;]*post_max_size =.*@post_max_size = 50M@g' $TMP_PHP_INI_PATH
	sed -i 's@[;]*upload_max_filesize =.*@upload_max_filesize = 50M@g' $TMP_PHP_INI_PATH
	sed -i 's@[;]*date.timezone =.*@date.timezone = PRC@g' $TMP_PHP_INI_PATH
	sed -i 's@[;]*short_open_tag =.*@short_open_tag = On@g' $TMP_PHP_INI_PATH
	sed -i 's@[;]*cgi.fix_pathinfo=.*@cgi.fix_pathinfo=1@g' $TMP_PHP_INI_PATH
	sed -i 's@[;]*max_execution_time =.*@max_execution_time = 300@g' $TMP_PHP_INI_PATH
	sed -i 's@[;]*always_populate_raw_post_data@always_populate_raw_post_data@g' $TMP_PHP_INI_PATH
	sed -i 's@[;]*disable_functions =.*@disable_functions = exec,system,chroot,scandir,chgrp,chown,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,passthru,proc_open,proc_get_status,shell_exec@g' $TMP_PHP_INI_PATH

	# 提供给后续全局的通用变量
	PHP_SETUP_COMPOSER_VERSION=`php -v | grep -oP '\d*\.\d+' | awk 'NR == 1{print}'`
	PHP_SETUP_COMPOSER_VERSION_NO_FLOAT=`echo ${PHP_SETUP_COMPOSER_VERSION} | sed 's@\.@@g'`

	return $?
}

#设置PHP-FPM
#参数1：PHP-FPM全局配置文件路径
#参数1：PHP-FPM区域配置文件路径
function set_phpfpm()
{
	local TMP_PHP_FPM_GLOBAL_PATH=$1
	local TMP_PHP_FPM_WWW_PATH=${2:-$TMP_PHP_FPM_GLOBAL_PATH}

	echo "----------------------------------------------------------------------------------------------------"
	echo "Start to modify php-fpm.conf, the current section of 'global' in php-fpm is $TMP_PHP_FPM_GLOBAL_PATH"

	# 全局修改
	sed -i 's@[;]*rlimit_files =.*@rlimit_files = 65536@g' $TMP_PHP_FPM_GLOBAL_PATH
	sed -i 's@[;]*process_control_timeout =.*@process_control_timeout = 5@g' $TMP_PHP_FPM_GLOBAL_PATH
	
	# 区域修改
	echo "Start to modify php-fpm.conf, the current section of 'www' in php-fpm is $TMP_PHP_FPM_WWW_PATH"

	sed -i 's@[;]*listen =.*@listen = /var/www/php-fcgi.sock@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*listen.allowed_clients =.*@listen.allowed_clients = 127.0.0.1@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*listen.owner =.*@listen.owner = project@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*listen.group =.*@listen.group = orsys@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*listen.mode =.*@listen.mode = 0666@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*listen.backlog =.*@listen.backlog = -1@g' $TMP_PHP_FPM_WWW_PATH

	sed -i 's@[;]*pm =.*@pm = dynamic@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*pm.max_children =.*@pm.max_children = 2048@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*pm.max_requests =.*@pm.max_requests = 10000@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*pm.start_servers =.*@pm.start_servers = 128@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*pm.min_spare_servers =.*@pm.min_spare_servers = 128@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*pm.max_spare_servers =.*@pm.max_spare_servers = 512@g' $TMP_PHP_FPM_WWW_PATH

	sed -i 's@[;]*user =.*@user = php@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*group =.*@group = lnmp@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*request_terminate_timeout =.*@request_terminate_timeout = 100@g' $TMP_PHP_FPM_WWW_PATH
	sed -i 's@[;]*request_slowlog_timeout =.*@request_slowlog_timeout = 1@g' $TMP_PHP_FPM_WWW_PATH

	return $?
}

# 安装composer
# 参数1：PHP安装BIN目录
function setup_composer()
{
	local TMP_PHP_SETUP_BIN_DIR=$1

	echo "------------------------------------------------------------------------------"
	echo "Start to setup composer for '${PHP_SETUP_COMPOSER_VERSION}', the current php setup bin is '${TMP_PHP_SETUP_BIN_DIR}'"
	echo "------------------------------------------------------------------------------"
	curl -sS https://getcomposer.org/installer | php -- --install-dir=$TMP_PHP_SETUP_BIN_DIR
	ln -sf $TMP_PHP_SETUP_BIN_DIR/composer.phar /usr/bin/composer

	# 依据版本安装依赖，否则composer会报错（可设置循环模式）
	sudo yum -y install php${PHP_SETUP_COMPOSER_VERSION_NO_FLOAT}-php-xml

	return $?
}

# 安装插件
# 参数1：PHP安装BIN目录
# 参数2：PHP安装配置文件路径
function setup_phpredis()
{
	local TMP_PHP_SETUP_BIN_DIR=${1:-}
	local TMP_PHP_SETUP_CONF_PATH=${2:-}
	local TMP_PHP_SETUP_PHPCONFIG_PATH=${TMP_PHP_SETUP_BIN_DIR}/php-config

    path_not_exits_action "$TMP_PHP_SETUP_PHPCONFIG_PATH" "yum -y install php${PHP_SETUP_COMPOSER_VERSION_NO_FLOAT}-php-phpiredis"
	if [ $? -eq 0 ]; then
		phpize
		./configure --with-php-config=$TMP_PHP_SETUP_PHPCONFIG_PATH
		sudo make -j4 && sudo make -j4 install
		echo "extension=\"redis.so\"" >> $TMP_PHP_SETUP_CONF_PATH
	fi

	return $?
}

##########################################################################################################

# 下载插件
function down_phpredis56()
{
    setup_soft_wget "PhpRedis" "http://pecl.php.net/get/redis-4.3.0.tgz" "setup_phpredis $PHP56_SETUP_BIN_DIR $PHP56_ATT_CONF_PATH"

	return $?
}

function setup_phpzend56()
{
	PHP56_SETUP_ZEND_DIR=$1

	local PHP56_ZEND_CURRENT_DIR=`pwd`

	sudo mkdir -pv $PHP56_SETUP_ZEND_DIR
	cp ZendGuardLoader.so $PHP56_SETUP_ZEND_DIR
	echo "-----------------------------------"
	echo "Write ZendGuardLoader to php.ini..."
	cat >>$PHP56_ATT_CONF_PATH<<EOF
;eaccelerator
;ionCube
;opcache

[Zend ZendGuard Loader]
zend_extension=$PHP56_SETUP_ZEND_DIR/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=

;xcache
EOF

	rm -rf $PHP56_ZEND_CURRENT_DIR

	return $?
}

function down_phpzend56()
{
    setup_soft_wget "PhpZend" "http://downloads.zend.com/guard/7.0.0/zend-loader-php5.6-linux-x86_64.tar.gz" "setup_phpzend56"

	return $?
}

function setup_php56()
{
	PHP56_SETUP_DIR=$1

	PHP56_CURRENT_DIR=`pwd`

	PHP56_SETUP_BIN_DIR=$PHP56_SETUP_DIR/bin
	PHP56_ATT_DIR=$ATT_DIR/php56
	PHP56_ATT_CONF_DIR=$PHP56_ATT_DIR/etc
	PHP56_ATT_CONF_PATH=$PHP56_ATT_CONF_DIR/php.ini
	PHP56_ATT_FPM_CONF_PATH=$PHP56_ATT_CONF_DIR/php-fpm.conf

	mkdir -pv $PHP56_ATT_CONF_DIR

	#部分系统编译可能会出现错误，解决方案如右：http://www.poluoluo.com/jzxy/201505/364819.html
	#缺少安装包的情况，下载MCrypt，Libmcrypt：https://sourceforge.net/projects/mcrypt/files/
	#MHASH：https://sourceforge.net/projects/mhash/files/mhash/0.9.9.9/mhash-0.9.9.9.tar.gzSETUP_DIR
	#参考：http://www.cnblogs.com/huangzhen/archive/2012/09/12/2681861.html
	#或安装第三方yum源 wget http://www.atomicorp.com/installers/atomic && sh ./atomic
	sudo ./configure --prefix=$PHP56_SETUP_DIR --with-config-file-path=$PHP56_ATT_CONF_DIR --with-libdir=lib64 --enable-fpm --with-fpm-user=php --with-fpm-group=lnmp --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=$SETUP_DIR/freetype --with-jpeg-dir --with-png-dir --with-zlib --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --enable-intl
	sudo make -j4 && sudo make -j4 install

	return $?
}

function down_php56()
{
    setup_soft_wget "php56" "http://cn2.php.net/distributions/php-5.6.24.tar.gz" "setup_php56"

	return $?
}

function set_php56()
{
	echo "--------------------------------------------"
    echo "Creating the soft link of php to bin path..."
	
	rm -rf /usr/bin/php
	rm -rf /usr/bin/phpize
	rm -rf /usr/bin/pear
	rm -rf /usr/bin/pecl

	ln -sf $PHP56_SETUP_DIR/bin/php /usr/bin/php
	ln -sf $PHP56_SETUP_DIR/bin/phpize /usr/bin/phpize
	ln -sf $PHP56_SETUP_DIR/bin/pear /usr/bin/pear
	ln -sf $PHP56_SETUP_DIR/bin/pecl /usr/bin/pecl

	echo "Copy new php configure file..."
	cp $PHP56_CURRENT_DIR/php.ini-production $PHP56_ATT_CONF_PATH

	pear config-set php_ini $PHP56_ATT_CONF_PATH
	pecl config-set php_ini $PHP56_ATT_CONF_PATH

	echo "Creating the soft link of php-fpm to bin path..."
	ln -sf $PHP56_SETUP_DIR/sbin/php-fpm /usr/bin/php-fpm
	
	echo "Creating a new php-fpm configure file..."
	echo "----------------------------------------"
	cp $PHP56_SETUP_DIR/etc/php-fpm.conf.default $PHP56_ATT_FPM_CONF_PATH
	ln -sf $PHP56_ATT_FPM_CONF_PATH $PHP56_SETUP_DIR/etc/php-fpm.conf
	
    echo_startup_config "php_fpm" "$PHP56_ATT_DIR" "php-fpm start"	

	rm -rf $PHP56_CURRENT_DIR
	
	return $?
}

##########################################################################################################

function setup_remi_php73()
{
	yum -y install php73-php-fpm php73-php-cli php73-php-bcmath php73-php-gd php73-php-json php73-php-mbstring php73-php-mcrypt php73-php-mysqlnd php73-php-opcache php73-php-pdo php73-php-pecl-crypto php73-php-pecl-mcrypt php73-php-pecl-geoip php73-php-pecl-swoole php73-php-recode php73-php-snmp php73-php-soap php73-php-xmll

	return $?
}

function set_remi_php73()
{
	# 迁移配置
	mv /etc/opt/remi/* $ATT_DIR/

	# 清除已有链接
	rm -rf /usr/bin/phpize

	# 路径变量
	PHP73_SETUP_BIN_DIR=/opt/remi/php73/root/bin
	PHP73_ATT_DIR=$ATT_DIR/php73
	PHP73_ATT_CONF_DIR=$PHP73_ATT_DIR
	PHP73_ATT_CONF_PATH=$PHP73_ATT_CONF_DIR/php.ini
	PHP73_ATT_FPM_GLOBAL_CONF_PATH=$PHP73_ATT_CONF_DIR/php-fpm.conf
	PHP73_ATT_FPM_WWW_CONF_PATH=$PHP73_ATT_CONF_DIR/php-fpm.d/www.conf

	# 创建软连接兼容（后续修改为循环模式）
	ln -sf $PHP73_ATT_DIR /etc/opt/remi/php73

	# 创建全局路径
	ln -sf $PHP73_SETUP_BIN_DIR/php /usr/bin/php
	ln -sf $PHP73_SETUP_BIN_DIR/phpize /usr/bin/phpize
}

function setup_remi_rpm()
{
    while_wget "--content-disposition http://rpms.remirepo.net/enterprise/remi-release-7.rpm" "yum -y install remi-release-7.rpm"

	return $?
}

##########################################################################################################

function check_setup_php56()
{
	yum -y install curl curl-devel

	set_environment

	#安装主体
	setup_soft_basic "PHP" "down_php56"

	set_php56

	set_phpini "$PHP56_ATT_CONF_PATH"

	set_phpfpm "$PHP56_ATT_FPM_CONF_PATH"

	setup_composer "$PHP56_SETUP_BIN_DIR"

	setup_soft_basic "PHP-Redis" "down_phpredis56"

	setup_soft_basic "PHP-Zend" "down_phpzend56"

	php-fpm start

	php -v

	return $?
}

function check_setup_remi_php73()
{
	# https://learnku.com/articles/40202
	yum install epel-release yum-utils

	set_environment
	
    soft_rpm_check_action "remi" "setup_remi_rpm" "Remi-Rpm was installed"

    soft_yum_check_action "php73" "setup_remi_php73" "Remi-Php7.3 was installed"

	set_remi_php73

	set_phpini "$PHP73_ATT_CONF_PATH"

	set_phpfpm "$PHP73_ATT_FPM_GLOBAL_CONF_PATH" "$PHP73_ATT_FPM_WWW_CONF_PATH"

	setup_composer "$PHP73_SETUP_BIN_DIR"

	setup_soft_basic "PHP-Redis" "setup_phpredis"

	php73 -v
	
	sudo systemctl enable php73-php-fpm
	sudo systemctl start php73-php-fpm
	sudo systemctl status php73-php-fpm

	return $?
}

exec_if_choice "CHOICE_PHPVER" "Please choice which php version you want to setup" "...,PHP56,Remi_PHP73,Exit" "$TMP_SPLITER" "check_setup_"