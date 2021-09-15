#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------
# 安装标题：
#------------------------------------------------
local TMP_ORST_SETUP_HTTP_PORT=80
local TMP_ORST_SETUP_HTTPS_PORT=443

##########################################################################################################

# 1-配置环境
function set_env_openresty()
{
    cd ${__DIR}

    soft_yum_check_setup "postgresql-devel,pcre-devel,openssl-devel,libunwind,gperftools*"

	return $?
}

##########################################################################################################

# 2-安装软件
function setup_openresty()
{
	local TMP_ORST_SETUP_DIR=${1}
	local TMP_ORST_CURRENT_DIR=${2}

	cd ${TMP_ORST_CURRENT_DIR}

    # if [ ! -d "nginx_upstream_check_module" ]; then
    #     git clone https://github.com/xiaokai-wang/nginx_upstream_check_module.git
    # fi

    if [ ! -d "nginx_http_subs_filter_module" ]; then
        git clone git://github.com/yaoweibin/ngx_http_substitutions_filter_module.git nginx_http_subs_filter_module
    fi
    
    if [ ! -d "nginx_eval_module" ]; then
        git clone git://github.com/openresty/nginx-eval-module.git nginx_eval_module
    fi

	# 编译模式
    # cp nginx_upstream_check_module/check_1.9.2+.patch patches
    #  --add-module=nginx_upstream_check_module
	./configure --prefix=${TMP_ORST_SETUP_DIR} --add-module=nginx_http_subs_filter_module --add-module=nginx_eval_module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-ipv6 --with-luajit --without-http_redis2_module --with-http_iconv_module --with-http_realip_module --with-threads --with-http_postgres_module --with-google_perftools_module -j4  # --with-http_drizzle_module
	make -j4 && make -j4 install
    
    #若是升级操作，则在此之前停止，完成以下操作
    #cp ${MOUNT_DIR}/bin/openresty/nginx/sbin/nginx ${MOUNT_DIR}/bin/openresty/nginx/sbin/nginx.bak
    #cp ${MOUNT_DIR}/tmp/openresty-1.19.3.2/build/nginx-1.11.2/objs/nginx  ${MOUNT_DIR}/bin/openresty/nginx/sbin/

	cd ${TMP_ORST_SETUP_DIR}

	# 创建日志软链
	local TMP_ORST_SETUP_LNK_LOGS_DIR=${LOGS_DIR}/openresty
	local TMP_ORST_SETUP_LOGS_DIR=${TMP_ORST_SETUP_DIR}/logs

	# 先清理文件，再创建文件
	rm -rf ${TMP_ORST_SETUP_LOGS_DIR}
	
    mv nginx/logs ${TMP_ORST_SETUP_LNK_LOGS_DIR}
    path_not_exists_create "${TMP_ORST_SETUP_LNK_LOGS_DIR}/application"
    path_not_exists_create "${TMP_ORST_SETUP_LNK_LOGS_DIR}/error"
    path_not_exists_create "${TMP_ORST_SETUP_LNK_LOGS_DIR}/access"
    path_not_exists_create "${TMP_ORST_SETUP_LNK_LOGS_DIR}/proxy"
	
	ln -sf ${TMP_ORST_SETUP_LNK_LOGS_DIR} `pwd`/nginx/logs
	ln -sf ${TMP_ORST_SETUP_LNK_LOGS_DIR} ${TMP_ORST_SETUP_LOGS_DIR}
	
    #just for thrift
    ln -sf ${TMP_ORST_SETUP_DIR}/luajit/lib/libluajit-5.1.so /usr/lib64/libluajit-5.1.so
    ln -sf ${TMP_ORST_SETUP_DIR}/luajit/lib/libluajit-5.1.so.2 /usr/lib64/libluajit-5.1.so.2
	
	# 环境变量或软连接
    echo "OPENRESTY_HOME=${TMP_ORST_SETUP_DIR}" >> /etc/profile
	echo 'PATH=$OPENRESTY_HOME/bin:$PATH' >> /etc/profile
	echo 'export PATH OPENRESTY_HOME' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile
    
    # 创建一个线程目录，这里将文件放在.../tmp/tcmalloc
    path_not_exists_create `pwd`/nginx/tmp/tcmalloc

	# 移除源文件
	rm -rf ${TMP_ORST_CURRENT_DIR}

    # 创建源码目录
    path_not_exists_create "${NGINX_DIR}"
    path_not_exists_create "${HTML_DIR}"
    path_not_exists_create "${OR_DIR}"

	return $?
}

##########################################################################################################

# 3-设置软件
function conf_openresty()
{
	local TMP_ORST_SETUP_DIR=${1}

	cd ${TMP_ORST_SETUP_DIR}
	
	local TMP_ORST_SETUP_LNK_ETC_DIR=${ATT_DIR}/openresty
	local TMP_ORST_SETUP_ETC_DIR=${TMP_ORST_SETUP_DIR}/conf

	# ①-N：不存在配置文件：
	rm -rf ${TMP_ORST_SETUP_ETC_DIR}
	mv nginx/conf ${TMP_ORST_SETUP_LNK_ETC_DIR}
	
	# 替换原路径链接（存在etc下时，不能作为软连接存在
    path_not_exists_create "${TMP_ORST_SETUP_LNK_ETC_DIR}/vhosts"
	ln -sf ${TMP_ORST_SETUP_LNK_ETC_DIR} `pwd`/nginx/conf
	ln -sf ${TMP_ORST_SETUP_LNK_ETC_DIR} ${TMP_ORST_SETUP_ETC_DIR}

	# 开始配置

	return $?
}

# 环境绑定nginx，作为附加安装
function rouse_nginx()
{
	local TMP_ORST_SETUP_DIR=${1}

    cd ${TMP_ORST_SETUP_DIR}
    
    # 指向nginx到安装目录
	local TMP_ORST_SETUP_NGX_DIR=`dirname ${TMP_ORST_SETUP_DIR}`/nginx
    if [ ! -d "${TMP_ORST_SETUP_NGX_DIR}" ]; then
        ln -sf ${TMP_ORST_SETUP_DIR}/nginx ${TMP_ORST_SETUP_NGX_DIR}
    fi

    if [ -z "${NGINX_SBIN}" ] || [ ! -f "/usr/bin/nginx" ] || [ ! -f "/usr/local/bin/nginx" ]; then
        echo "NGINX_SBIN=${TMP_ORST_SETUP_DIR}/nginx/sbin" >> /etc/profile
	    echo 'PATH=$NGINX_SBIN:$PATH' >> /etc/profile
        
        # 修改默认nginx配置性能瓶颈问题
        local TMP_ORST_SETUP_NGX_CONF_PATH=${TMP_ORST_SETUP_NGX_DIR}/conf/nginx.conf

        # 备份初始文件
        mv nginx/conf/nginx.conf nginx/conf/nginx.conf.bak

        # 覆写优化配置(???相关参数待优化为按机器计算数值)
        tee ${TMP_ORST_SETUP_NGX_CONF_PATH} <<-'EOF'
#user  nobody;
worker_processes  auto;

#更改Nginx进程的最大打开文件数限制，理论值应该是最多打开文件数（ulimit -n）与nginx进程数相除，该值控制 “too many open files” 的问题
worker_rlimit_nofile 65535;  #此处为65535/4

#进程文件
pid        tmp/nginx.pid;

#工作模式与连接数上限
events {
    #参考事件模型，use [ kqueue | rtsig | epoll | /dev/poll | select | poll ]; epoll模型是Linux 2.6以上版本内核中的高性能网络I/O模型，如果跑在FreeBSD上面，就用kqueue模型。
    use epoll;
    multi_accept on; #告诉nginx收到一个新连接通知后接受尽可能多的连接。
    accept_mutex off;
    worker_connections  65535; #单个进程最大连接数（最大连接数=连接数*进程数），1核默认配8000。
}

http {
    #文件扩展名与文件类型映射表
    include mime.types;

    #默认文件类型
    default_type  text/html;

    #默认编码
    charset utf-8;

    #日志格式设定
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    log_format  json  '{"@timestamp":"$time_iso8601",'
                      '"slb_user":"$remote_user",'
                      '"slb_ip":"$remote_addr",'
                      '"client_ip":"$http_x_forwarded_for",'
                      '"server_ip":"$server_addr",'
                      '"size":$body_bytes_sent,'
                      '"response_time":$request_time,'
                      '"domain":"$host",'
                      '"method":"$request_method",'
                      '"request_uri":"$request_uri",'
                      '"url":"$uri",'
                      '"app_version":"$HTTP_APP_VERS",'
                      '"referer":"$http_referer",'
                      '"agent":"$http_user_agent",'
                      '"status":"$status",'
                      '"device_code":"$HTTP_HA",'
                      '"upstream_response_time":$upstream_response_time,'
                      '"upstream_addr":"$upstream_addr",'
                      '"upstream_status":"$upstream_status",'
                      '"upstream_cache_status":"$upstream_cache_status"}';

    #是否开启重写日志
    rewrite_log on;

    #日志文件缓存
    #   max:设置缓存中的最大文件描述符数量，如果缓存被占满，采用LRU算法将描述符关闭。
    #   inactive:设置存活时间，默认是10s
    #   min_uses:设置在inactive时间段内，日志文件最少使用多少次后，该日志文件描述符记入缓存中，默认是1次
    #   valid:设置检查频率，默认60s
    #   off：禁用缓存
    #open_log_file_cache max=1000 inactive=20s valid=1m min_uses=2;

    #关闭在错误页面中的nginx版本数字
    server_tokens off;

    #服务器名字的hash表大小
    server_names_hash_bucket_size 128; 

    #上传文件大小限制，一般一个请求的头部大小不会超过1k
    client_header_buffer_size 4k; 

    #设定请求缓存
    large_client_header_buffers 4 64k; 

    #设定请求缓存
    client_max_body_size 8m; 

    #开启目录列表访问，合适下载服务器，默认关闭。
    autoindex off; 

    #开启高效文件传输模式，sendfile指令指定nginx是否调用sendfile函数来输出文件。
    #对于普通应用设为 on，如果用来进行下载等应用磁盘IO重负载应用，可设置为off，以平衡磁盘与网络I/O处理速度，降低系统的负载。
    #注意：如果图片显示不正常把这个改成off。
    sendfile        on;
    sendfile_max_chunk 512k;  #该指令可以减少阻塞方法 sendfile() 调用的所花费的最大时间，每次无需发送整个文件，只发送 512KB 的块数据

    #通用代理设置
    proxy_headers_hash_max_size 51200; #设置头部哈希表的最大值，不能小于你后端服务器设置的头部总数
    proxy_headers_hash_bucket_size 6400; #设置头部哈希表大小

    tcp_nopush on; #防止网络阻塞(告诉nginx在一个数据包里发送所有头文件，而不一个接一个的发送)
    tcp_nodelay on; #防止网络阻塞(告诉nginx不要缓存数据，而是一段一段的发送，当需要及时发送数据时，就应该给应用设置这个属性)

    #长连接超时时间，单位是秒
    keepalive_timeout 15; 

    #设置请求头的超时时间
    client_header_timeout 5;

    #设置请求体的超时时间
    client_body_timeout 10;

    #关闭不响应的客户端连接。这将会释放那个客户端所占有的内存空间。
    reset_timedout_connection on;

    #指定客户端的响应超时时间。这个设置不会用于整个转发器，而是在两次客户端读取操作之间。如果在这段时间内，客户端没有读取任何数据，nginx就会关闭连接。
    send_timeout 10; 

    #为FastCGI缓存指定一个路径，目录结构等级，关键字区域存储时间和非活动删除时间。
    #fastcgi_cache_path /clouddisk/attach/openresty/fastcgi_cache levels=1:2 keys_zone=cache_php:64m inactive=5m max_size=10g;  

    #gzip模块设置
    gzip on; #开启gzip压缩输出
    gzip_disable 'msie6'; #为指定的客户端禁用gzip功能。我们设置成IE6或者更低版本以使我们的方案能够广泛兼容。
    gzip_proxied any; #允许或者禁止压缩基于请求和响应的响应流。我们设置为any，意味着将会压缩所有的请求。
    gzip_min_length 1k; #最小压缩文件大小
    gzip_buffers 16 8k; #压缩缓冲区
    gzip_http_version 1.0; #压缩版本（默认1.1，前端如果是squid2.5请使用1.0）
    gzip_comp_level 6; #压缩等级
    gzip_types text/plain 
               text/css 
               text/xml 
               text/javascript 
               application/json 
               application/javascript
               application/x-httpd-php 
               application/x-javascript 
               application/xml 
               application/xml+rss 
               image/jpeg 
               image/gif 
               image/png
               image/svg+xml;

    #设置需要压缩的数据格式
    gzip_vary on;

    #limit_conn_zone $binary_remote_addr zone=addr:10m; #开启限制IP连接数的时候需要使用
    #limit_conn_log_level info;

    #指定DNS服务器的地址
    #resolver 223.5.5.5 223.6.6.6 8.8.8.8;

    #定义一个名为 default 的线程池，拥有 32 个工作线程，任务队列容纳的最大请求数为 65536。一旦任务队列过载，NGINX日志会报错并拒绝这一请求
    #thread_pool default threads=32 max_queue=65536;

    # cache informations about file descriptors, frequently accessed files 
    # can boost performance, but you need to test those values 
    open_file_cache max=65536 inactive=10s; # 打开缓存的同时也指定了缓存最大数目，以及缓存的时间
    open_file_cache_valid 30s; #在open_file_cache中指定检测正确信息的间隔时间
    open_file_cache_min_uses 1; #定义了open_file_cache中指令参数不活动时间期间里最小的文件数
    open_file_cache_errors on; #指定了当搜索一个文件时是否缓存错误信息，也包括再次给配置中添加文件

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }

    # another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

    # HTTPS server
    #
    #server {
    #    listen       443 ssl;
    #    server_name  localhost;

    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_cache    shared:SSL:1m;
    #    ssl_session_timeout  5m;

    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers  on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}
}

EOF
    
        local TMP_ORST_SETUP_NGX_CONF_WORKER_RLIMIT_NOFILE=$(($(ulimit -n)/4))
        sed -i "s@^worker_rlimit_nofile.*@worker_rlimit_nofile ${TMP_ORST_SETUP_NGX_CONF_WORKER_RLIMIT_NOFILE};@g" ${TMP_ORST_SETUP_NGX_CONF_PATH}
    fi
    
    ##########################################################################################
    # 指向luajit到环境变量
	local TMP_ORST_SETUP_LJ_DIR=`dirname ${TMP_ORST_SETUP_DIR}`/luajit
    if [ ! -d "${TMP_ORST_SETUP_LJ_DIR}" ]; then
        ln -sf ${TMP_ORST_SETUP_DIR}/luajit ${TMP_ORST_SETUP_LJ_DIR}
    fi
    
    if [ -z "${LUAJIT_HOME}" ] || [ ! -f "/usr/bin/luajit" ] || [ ! -f "/usr/local/bin/luajit" ]; then
        echo "LUAJIT_HOME=${TMP_ORST_SETUP_LJ_DIR}" >> /etc/profile
        echo "LUALIB_HOME=${TMP_ORST_SETUP_DIR}/lualib" >> /etc/profile
        echo 'LUAJIT_LIB=${LUAJIT_HOME}/lib' >> /etc/profile
        echo 'LUAJIT_INC=${LUAJIT_HOME}/include/luajit-2.1' >> /etc/profile
	    echo 'PATH=$LUAJIT_HOME/bin:$PATH' >> /etc/profile
    fi

    ##########################################################################################
	echo 'export PATH' >> /etc/profile

    # 重新加载profile文件
	source /etc/profile

    nginx -v
    luajit -v

	return $?
}

##########################################################################################################

# 4-启动软件
function boot_openresty()
{
	local TMP_ORST_SETUP_DIR=${1}

	cd ${TMP_ORST_SETUP_DIR}
	
	# 验证安装
    openresty -V

	# 启动状态检测
	openresty -t

	# 授权iptables端口访问
	echo_soft_port ${TMP_ORST_SETUP_HTTP_PORT}
	echo_soft_port ${TMP_ORST_SETUP_HTTPS_PORT}
    
    # 生成web授权访问脚本
    echo_web_service_init_scripts "openresty${LOCAL_ID}" "openresty${LOCAL_ID}-webui.${SYS_DOMAIN}" ${TMP_ORST_SETUP_HTTP_PORT} "${LOCAL_HOST}" "" "${LOCAL_HOST}"

	return $?
}

##########################################################################################################

# 下载驱动/插件
function down_plugin_openresty()
{
	return $?
}

# 安装驱动/插件
function setup_plugin_openresty()
{
	cd ${__DIR}
	
    source scripts/web/openresty_frame.sh

    source scripts/tools/luarocks.sh

	return $?
}

##########################################################################################################

# x2-执行步骤
function exec_step_openresty()
{
	local TMP_ORST_SETUP_DIR=${1}
	local TMP_ORST_CURRENT_DIR=`pwd`
    
	set_env_openresty "${TMP_ORST_SETUP_DIR}"

	setup_openresty "${TMP_ORST_SETUP_DIR}" "${TMP_ORST_CURRENT_DIR}"

	conf_openresty "${TMP_ORST_SETUP_DIR}"
        
    rouse_nginx "${TMP_ORST_SETUP_DIR}"

    setup_plugin_openresty "${TMP_ORST_SETUP_DIR}"

	boot_openresty "${TMP_ORST_SETUP_DIR}"

	return $?
}

##########################################################################################################

# x1-下载软件
function down_openresty()
{
	local TMP_ORST_SETUP_OFFICIAL_STABLE_VERS=`curl -s https://openresty.org/en/download.html | egrep -o "OpenResty .+ Released" | awk NR==1 | awk -F' ' '{print $2}'`
	echo "OpenResty: The newer stable version is ${TMP_ORST_SETUP_OFFICIAL_STABLE_VERS}"
    
    local TMP_ORST_SETUP_NEWER="${TMP_ORST_SETUP_OFFICIAL_STABLE_VERS}"
	exec_text_format "TMP_ORST_SETUP_NEWER" "https://openresty.org/download/openresty-%s.tar.gz"
    setup_soft_wget "openresty" "${TMP_ORST_SETUP_NEWER}" "exec_step_openresty"

	return $?
}

##########################################################################################################

#安装主体
setup_soft_basic "OpenResty" "down_openresty"