#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
	yum -y install postgresql-devel pcre-devel openssl-devel libunwind gperftools*

	return $?
}

function setup_openresty()
{
    local TMP_PACK_DIR=`pwd`
    cd $DOWN_DIR

    if [ ! -d "nginx_upstream_check_module" ]; then
        git clone https://github.com/xiaokai-wang/nginx_upstream_check_module.git
    fi

    if [ ! -d "nginx_http_subs_filter_module" ]; then
        git clone git://github.com/yaoweibin/ngx_http_substitutions_filter_module.git nginx_http_subs_filter_module
    fi
    
    if [ ! -d "nginx_eval_module" ]; then
        git clone git://github.com/openresty/nginx-eval-module.git nginx_eval_module
    fi
    
    #  --add-module=$DOWN_DIR/nginx_echo_module
    # if [ ! -d "nginx_echo_module" ]; then
    #     git clone git://github.com/openresty/echo-nginx-module.git nginx_echo_module
    # fi
    
    # --add-dynamic-module==$DOWN_DIR/nginx_srcache_module
    # if [ ! -d "nginx_srcache_module" ]; then
    #     if [ ! -f "nginx_srcache_module" ]; then
    #         wget https://github.com/openresty/srcache-nginx-module/archive/v0.31.tar.gz -O srcache_nginx_module.tar.gz
    #     fi

    #     tar -zxvf srcache_nginx_module.tar.gz
    #     mv srcache-nginx-module-0.31 nginx_srcache_module
    # fi

    cd $TMP_PACK_DIR
    #patch -p1 < $DOWN_DIR/nginx_upstream_check_module/check_1.9.2+.patch
    cp $DOWN_DIR/nginx_upstream_check_module/check_1.9.2+.patch patches
    sudo ./configure --prefix=$TMP_SETUP_OPENRESTY_DIR --add-module=$DOWN_DIR/nginx_upstream_check_module --add-module=$DOWN_DIR/nginx_http_subs_filter_module --add-module=$DOWN_DIR/nginx_eval_module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-ipv6 --with-luajit --without-http_redis2_module --with-http_iconv_module --with-http_realip_module --with-threads --with-http_postgres_module --with-google_perftools_module -j4  # --with-http_drizzle_module
    sudo make -j4 && make -j4 install

    #若是升级操作，则在此之前停止，完成以下操作
    #cp $MOUNT_DIR/bin/openresty/nginx/sbin/nginx $MOUNT_DIR/bin/openresty/nginx/sbin/nginx.bak
    #cp $MOUNT_DIR/tmp/openresty-1.15.8.1rc1/build/nginx-1.11.2/objs/nginx  $MOUNT_DIR/bin/openresty/nginx/sbin/

    #创建软连接
    ln -sf $TMP_SETUP_OPENRESTY_NGX_DIR/nginx /usr/bin/nginx

    #添加开机启动项
    #echo "nginx -c $cfgPath" >> /etc/rc.local
    echo_soft_port 80

    #创建所需目录
    sudo mkdir -pv $TMP_SETUP_OPENRESTY_ATT_DIR/logs/application
    sudo mkdir -pv $TMP_SETUP_OPENRESTY_ATT_DIR/logs/error
    sudo mkdir -pv $TMP_SETUP_OPENRESTY_ATT_DIR/logs/access
    sudo mkdir -pv $TMP_SETUP_OPENRESTY_ATT_DIR/logs/proxy
    sudo mkdir -pv $TMP_SETUP_OPENRESTY_ATT_DIR/conf/vhosts

    #创建软连接，启动NGINX服务
    ln -sf $TMP_SETUP_OPENRESTY_DIR/nginx/sbin/nginx /usr/bin/nginx
    ln -sf $TMP_SETUP_OPENRESTY_DIR/luajit/bin/luajit /usr/bin/luajit

    #just for thrift
    ln -sf $TMP_SETUP_OPENRESTY_DIR/luajit/lib/libluajit-5.1.so /usr/lib64/libluajit-5.1.so
    ln -sf $TMP_SETUP_OPENRESTY_DIR/luajit/lib/libluajit-5.1.so.2 /usr/lib64/libluajit-5.1.so.2

    #添加环境变量        
    echo "LUAJIT_LIB=$TMP_SETUP_OPENRESTY_DIR/luajit/lib" >> /etc/profile
    echo "LUAJIT_INC=$TMP_SETUP_OPENRESTY_DIR/luajit/include/luajit-2.1" >> /etc/profile

    echo "RESTY_BIN=$TMP_SETUP_OPENRESTY_DIR/bin" >> /etc/profile
    echo "NGINX_BIN=$TMP_SETUP_OPENRESTY_DIR/nginx/sbin" >> /etc/profile
    echo "PATH=\$PATH:\$NGINX_BIN:\$RESTY_BIN" >> /etc/profile

    source /etc/profile

    #创建一个线程目录，这里将文件放在.../tmp/tcmalloc下
    sudo mkdir -pv $TMP_SETUP_OPENRESTY_DIR/tmp/tcmalloc

    groupadd orsys
    useradd -g orsys project

    mkdir -pv $OR_DIR
    chown project:orsys -R $OR_DIR
    chown project:orsys $TMP_SETUP_OPENRESTY_DIR/tmp/tcmalloc

    nginx -v
    luajit -v

	return $?
}

function setup_luarocks()
{
    sudo ./configure --prefix=$TMP_SETUP_LUAROCKS_DIR --with-lua=$TMP_SETUP_OPENRESTY_DIR/luajit --lua-suffix=jit --with-lua-include=$TMP_SETUP_OPENRESTY_DIR/luajit/include/luajit-2.1
    sudo make -j4 build && sudo make -j4 install

    #创建软连接
    ln -sf $TMP_SETUP_LUAROCKS_DIR/bin/luarocks /usr/bin/luarocks

    #利用luarocks安装插件
    luarocks install lua-resty-session
    luarocks install lua-resty-jwt
    luarocks install lua-resty-cookie
    luarocks install lua-resty-template
    luarocks install lua-resty-http
    luarocks install lua-resty-redis
    luarocks install luasocket
    luarocks install busted 
    luarocks install luasql-sqlite3
    luarocks install lzlib
    luarocks install luafilesystem
    luarocks install luasec
    luarocks install md5
    luarocks install multipart  
    luarocks install lua-resty-rsa 

    # cd $TMP_SETUP_LUAROCKS_DIR/lib/luarocks/rocks
    # git clone https://github.com/juce/lua-resty-shell

    return $?
}

function check_setup_lor()
{
    path_not_exits_action "$TMP_SETUP_OPENRESTY_DIR/luafws/lor" "print_lor" "Lor was installed"
    lord -v

    exec_yn_action "check_setup_orange" "Orange: Please sure if u want to got a orange server"

	return $?
}

function print_lor()
{
    setup_soft_basic "Lor" "setup_lor"

	return $?
}

function setup_lor()
{
    if [ ! -d "lor" ]; then
        git clone https://github.com/sumory/lor.git #https://github.com/sumory/lor
    fi

    cd lor
    sed -i "s@LOR_HOME ?=.*@LOR_HOME = $TMP_SETUP_OPENRESTY_DIR/luafws@g" Makefile
    sed -i "s@LORD_BIN ?=.*@LORD_BIN = $TMP_SETUP_OPENRESTY_DIR/luafws/lor@g" Makefile
    make install

    ln -sf $TMP_SETUP_OPENRESTY_DIR/luafws/lor/lord /usr/bin/lord

    setup_libs

	return $?
}

function setup_libs()
{
    wget_unpack_dist "https://github.com/doujiang24/lua-resty-kafka/archive/master.zip" "lib/resty" "$TMP_SETUP_OPENRESTY_DIR/lualib"
    wget_unpack_dist "http://www.inf.puc-rio.br/~roberto/lpeg/lpeg-1.0.1.tar.gz" "lpeg.so" "$TMP_SETUP_OPENRESTY_DIR/lualib" "
        sed -i \"s@LUADIR =.*@LUADIR = $TMP_SETUP_OPENRESTY_DIR/luajit/include/luajit-2.1@g\" makefile
        sudo make -j4
    "
	return $?
}

function check_setup_orange()
{
    ORANGE_DIR="$TMP_SETUP_OPENRESTY_DIR/luafws/lor/dependprj/gateway"
    path_not_exits_action "$ORANGE_DIR" "print_orange" "Orange was installed"
	return $?
}

function print_orange()
{
    setup_soft_basic "Orange" "setup_orange"
	return $?
}

function setup_kong()
{
    # https://www.jianshu.com/p/5049b3bb4b80
    # https://docs.konghq.com/install/centos/?_ga=2.110225728.474733574.1547721700-1679220384.1547721700
	return $?
}

function setup_orange()
{
    if [ ! -d "orange" ]; then
        git clone https://github.com/sumory/orange.git
    fi
    
    cd orange

    mkdir -pv $ORANGE_DIR/orange
    mkdir -pv $ORANGE_DIR/bin

    #创建软连接及安装路径
    ln -sf $ORANGE_DIR/bin/orange /usr/local/bin/orange
    ln -sf $ORANGE_DIR/bin/resty /usr/local/bin/resty
    sed -i "s@ORANGE_HOME ?=.*@ORANGE_HOME ?= $ORANGE_DIR/orange/@g" Makefile
    sed -i "s@ORANGE_BIN ?=.*@ORANGE_BIN ?= $ORANGE_DIR/bin/orange@g" Makefile

    sudo make -j4 install

    cd $ORANGE_DIR
    sed -i "s@/usr/local/orange@$ORANGE_DIR/orange@g" $ORANGE_DIR/orange/bin/cmds/reload.lua
    sed -i "s@/usr/local/orange@$ORANGE_DIR/orange@g" $ORANGE_DIR/orange/bin/cmds/restart.lua
    sed -i "s@/usr/local/orange@$ORANGE_DIR/orange@g" $ORANGE_DIR/orange/bin/cmds/start.lua
    sed -i "s@/usr/local/orange@$ORANGE_DIR/orange@g" $ORANGE_DIR/orange/bin/cmds/stop.lua
    sed -i "s@/usr/local/orange@$ORANGE_DIR/orange@g" $ORANGE_DIR/orange/bin/cmds/store.lua

    echo_startup_config "orange" "" "orange start" "$TMP_SETUP_OPENRESTY_DIR/bin"
        
    nginx -v

    TMP_SETUP_ORANGE_DBADDRESS="127.0.0.1"
    TMP_SETUP_ORANGE_DBUNAME="root"
    TMP_SETUP_ORANGE_DBPWD="dborg#1it"
    TMP_SETUP_ORANGE_DBNAME="gateway"
	input_if_empty "TMP_SETUP_ORANGE_DBADDRESS" "Orange.Mysql: Please ender ${red}mysql host address${reset}"
	input_if_empty "TMP_SETUP_ORANGE_DBUNAME" "Orange.Mysql: Please ender ${red}mysql user name${reset} of '$TMP_SETUP_ORANGE_DBADDRESS'"
	input_if_empty "TMP_SETUP_ORANGE_DBPWD" "Orange.Mysql: Please ender ${red}mysql password${reset} of $TMP_SETUP_ORANGE_DBUNAME@$TMP_SETUP_ORANGE_DBADDRESS"
	input_if_empty "TMP_SETUP_ORANGE_DBNAME" "Orange.Mysql: Please ender ${red}mysql database name${reset} of orange($TMP_SETUP_ORANGE_DBADDRESS)"

    mysql -h $TMP_SETUP_ORANGE_DBADDRESS -u$TMP_SETUP_ORANGE_DBUNAME -p$TMP_SETUP_ORANGE_DBPWD -e"
    create database $TMP_SETUP_ORANGE_DBNAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
    use $TMP_SETUP_ORANGE_DBNAME;
    source $DOWN_DIR/orange/install/orange-v0.6.4.sql;
    exit"
    
    sed -i "/charset UTF-8;/a more_clear_headers 'Server';" $ORANGE_DIR/orange/conf/nginx.conf
    sed -i "/charset UTF-8;/a server_tokens off;" $ORANGE_DIR/orange/conf/nginx.conf
    sed -i "s@server localhost:8001@server localhost:9999@g" $ORANGE_DIR/orange/conf/nginx.conf

    #lua_package_path '../?.lua;$MOUNT_DIR/bin/openresty/luafws/lor/?.lua;;';
    sed -i "s@[[:space:]]*lua_package_path '$TMP_SETUP_OPENRESTY_DIR/luafws/lor/dependprj/gateway/orange//?.lua;/usr/local/lor/?.lua;;';@    lua_package_path '../?.lua;$ATT_DIR/openresty/integration_libs/?.lua;$TMP_SETUP_LUAROCKS_DIR/share/lua/5.1/?.lua;$TMP_SETUP_OPENRESTY_DIR/luafws/lor/?.lua;$TMP_SETUP_OPENRESTY_DIR/luafws/lor/dependprj/gateway/orange/?.lua;;';@g" $ORANGE_DIR/orange/conf/nginx.conf

    sed -i "s@[[:space:]]*\"database\": \"orange\",@            \"database\": \"$TMP_SETUP_ORANGE_DBNAME\",@g" $ORANGE_DIR/orange/conf/orange.conf
    sed -i "s@[[:space:]]*\"password\": \"\",@            \"password\": \"$TMP_SETUP_ORANGE_DBPWD\",@g" $ORANGE_DIR/orange/conf/orange.conf

    chown project:orsys -R $ORANGE_DIR

    if [ "$TMP_SETUP_ORANGE_DBADDRESS" = "127.0.0.1" ] || [ "$TMP_SETUP_ORANGE_DBADDRESS" = "localhost" ]; then
        exec_yn_action "set_orange_conf" "[Warning]Orange.Mycat: Do you sure to overwrite the existing configuration files"
    fi

	return $?
}

function set_orange_conf()
{
    cp $MYCAT_DIR/conf/server.xml $MYCAT_DIR/conf/server-bak.xml
    sed -i "s@TESTDB@$TMP_SETUP_ORANGE_DBNAME@g" $MYCAT_DIR/conf/server.xml

    TMP_SETUP_ORANGE_MDBADDRESS=$TMP_SETUP_ORANGE_DBADDRESS
    TMP_SETUP_ORANGE_MDBUNAME=$TMP_SETUP_ORANGE_DBUNAME
    TMP_SETUP_ORANGE_MDBPWD=$TMP_SETUP_ORANGE_DBPWD
	input_if_empty "TMP_SETUP_ORANGE_MDBADDRESS" "Orange.Mycat(MySql-Master): Please ender ${red}mysql host address${reset}"
	input_if_empty "TMP_SETUP_ORANGE_MDBUNAME" "Orange.Mycat(MySql-Master): Please ender ${red}mysql user name${reset} of '$TMP_SETUP_ORANGE_MDBADDRESS'"
	input_if_empty "TMP_SETUP_ORANGE_MDBPWD" "Orange.Mycat(MySql-Master): Please ender ${red}mysql password${reset} of '$TMP_SETUP_ORANGE_MDBUNAME@$TMP_SETUP_ORANGE_MDBADDRESS'"

    TMP_SETUP_ORANGE_SDBADDRESS=$TMP_SETUP_ORANGE_DBADDRESS
    TMP_SETUP_ORANGE_SDBUNAME=$TMP_SETUP_ORANGE_DBUNAME
    TMP_SETUP_ORANGE_SDBPWD=$TMP_SETUP_ORANGE_DBPWD
	input_if_empty "TMP_SETUP_ORANGE_SDBADDRESS" "Orange.Mycat(MySql-Slave): Please ender ${red}mysql host address${reset}"
	input_if_empty "TMP_SETUP_ORANGE_SDBUNAME" "Orange.Mycat(MySql-Slave): Please ender ${red}mysql user name${reset} of '$TMP_SETUP_ORANGE_SDBADDRESS'"
	input_if_empty "TMP_SETUP_ORANGE_SDBPWD" "Orange.Mycat(MySql-Slave): Please ender ${red}mysql password${reset} of '$TMP_SETUP_ORANGE_SDBUNAME@$TMP_SETUP_ORANGE_SDBADDRESS'"
    
    cp $MYCAT_DIR/conf/schema.xml $MYCAT_DIR/conf/schema-bak.xml
    cat >$MYCAT_DIR/conf/schema.xml<<EOF
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
    <!-- sqlMaxLimit设置limit防止错误sql查询大量数据 -->
    <schema name="$TMP_SETUP_ORANGE_DBNAME" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn_$TMP_SETUP_ORANGE_DBNAME" />

    <!-- 数据节点 -->
    <dataNode name="dn_$TMP_SETUP_ORANGE_DBNAME" dataHost="localhost1" database="$TMP_SETUP_ORANGE_DBNAME" />

    <!-- 数据分流配置 -->
    <dataHost name="localhost1" maxCon="1000" minCon="10" balance="1" writeType="0" dbType="mysql" dbDriver="native" switchType="2"  slaveThreshold="100">
        <heartbeat>select user()</heartbeat>
            <!-- can have multi write hosts -->
            <writeHost host="hostM1" url="$TMP_SETUP_ORANGE_MDBADDRESS:3306" user="$TMP_SETUP_ORANGE_MDBUNAME" password="$MPATMP_SETUP_ORANGE_MDBPWDSSWORD">
            <!-- can have multi read hosts -->
            <readHost host="hostS2" url="$TMP_SETUP_ORANGE_SDBADDRESS:3306" user="$TMP_SETUP_ORANGE_SDBUNAME" password="$TMP_SETUP_ORANGE_SDBPWD" />
        </writeHost>
    </dataHost>
</mycat:schema>
EOF

    mycat restart
    orange start

	return $?
}

function down_openresty()
{
    setup_soft_wget "openresty" "https://openresty.org/download/openresty-1.15.8.1rc1.tar.gz" "setup_openresty"

	return $?
}

function down_luarocks()
{
    setup_soft_wget "luarocks" "http://luarocks.github.io/luarocks/releases/luarocks-3.0.4.tar.gz" "setup_luarocks"

	return $?
}

local TMP_SETUP_OPENRESTY_DIR=$SETUP_DIR/openresty
local TMP_SETUP_OPENRESTY_ATT_DIR=$ATT_DIR/openresty
local TMP_SETUP_LUAROCKS_DIR=$SETUP_DIR/luarocks
local TMP_SETUP_OPENRESTY_NGX_DIR=$TMP_SETUP_OPENRESTY_DIR/nginx/sbin

set_environment
setup_soft_basic "Openresty" "down_openresty"
setup_soft_basic "Luarocks" "down_luarocks"
exec_yn_action "check_setup_lor" "Please Sure You Want To Need ${red}Lor-Framework${reset}"
lsof -n | grep tcmalloc
