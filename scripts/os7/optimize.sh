#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function check_sets()
{
	path_not_exits_action "${SETUP_DIR}/sys_seted" "optimize_system"

	return $?
}

function optimize_system()
{
	#安装CJSON时用
	##默认会检测不到lua.h
	#net.ipv4.tcp_max_tw_buckets参数用来设定timewait的数量，默认是180000，这里设为6000。
	#net.ipv4.ip_local_port_range选项用来设定允许系统打开的端口范围。
	#net.ipv4.tcp_tw_recycle选项用于设置启用timewait快速回收。
	#net.ipv4.tcp_tw_reuse选项用于设置开启重用，允许将TIME-WAIT sockets重新用于新的TCP连接。
	#net.ipv4.tcp_syncookies选项用于设置开启SYN Cookies，当出现SYN等待队列溢出时，启用cookies进行处理。
	#net.core.somaxconn选项默认值是128， 这个参数用于调节系统同时发起的tcp连接数，在高并发的请求中，默认的值可能会导致链接超时或者重传，因此，需要结合并发请求数来调节此值。
	#net.core.netdev_max_backlog选项表示当每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许发送到队列的数据包的最大数目。
	#net.ipv4.tcp_max_orphans选项用于设定系统中最多有多少个TCP套接字不被关联到任何一个用户文件句柄上。如果超过这个数字，孤立连接将立即被复位并打印出警告信息。这个限制只是为了防止简单的DoS攻击。不能过分依靠这个限制甚至人为减小这个值，更多的情况是增加这个值。
	#net.ipv4.tcp_max_syn_backlog选项用于记录那些尚未收到客户端确认信息的连接请求的最大值。对于有128MB内存的系统而言，此参数的默认值是1024，对小内存的系统则是128。
	#net.ipv4.tcp_synack_retries参数的值决定了内核放弃连接之前发送SYN+ACK包的数量。
	#net.ipv4.tcp_syn_retries选项表示在内核放弃建立连接之前发送SYN包的数量。
	#net.ipv4.tcp_fin_timeout选项决定了套接字保持在FIN-WAIT-2状态的时间。默认值是60秒。正确设置这个值非常重要，有时候即使一个负载很小的Web服务器，也会出现因为大量的死套接字而产生内存溢出的风险。
	#net.ipv4.tcp_keepalive_time选项表示当keepalive启用的时候，TCP发送keepalive消息的频度。默认值是2（单位是小时）。

	#优化LINUX内核
	cat >>/etc/sysctl.conf<<EOF
# max open files
fs.file-max = 1024000

# max read buffer
net.core.rmem_max = 67108864

# max write buffer
net.core.wmem_max = 67108864

# default read buffer
net.core.rmem_default = 65536

# default write buffer
net.core.wmem_default = 65536

# max processor input queue
net.core.netdev_max_backlog = 4096

# max backlog
net.core.somaxconn = 4096

# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1

# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1

# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0

# short FIN timeout
net.ipv4.tcp_fin_timeout = 30

# short keepalive time
net.ipv4.tcp_keepalive_time = 1200

# outbound port range
net.ipv4.ip_local_port_range = 10000 65000

# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096

# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000

# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864

# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864

# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

# for high-latency network
net.ipv4.tcp_congestion_control = hybla

# forward ivp4
net.ipv4.ip_forward = 1

vm.swappiness = 0

net.ipv4.neigh.default.gc_stale_time=120

net.ipv4.conf.all.arp_announce=2

net.ipv4.tcp_synack_retries = 2

net.ipv6.conf.all.disable_ipv6 = 1

net.ipv4.conf.default.accept_source_route = 0

net.ipv4.tcp_sack = 1

net.ipv4.tcp_window_scaling = 1

net.ipv4.tcp_max_orphans = 3276800

net.ipv4.tcp_timestamps = 0

net.ipv4.tcp_syn_retries = 1

net.ipv4.tcp_mem = 94500000 915000000 927000000

kernel.sysrq = 0

kernel.core_uses_pid = 1

kernel.msgmnb = 65536

kernel.msgmax = 65536

kernel.shmmax = 68719476736

kernel.shmall = 4294967296

vm.max_map_count = 262144
EOF

	#echo "ulimit -SHn 65536" >> /etc/rc.local
	echo "ulimit -SHn 65536" >> /etc/profile

	#单个用户可用的最大进程数量(软限制)
	echo "* soft nofile 65536" >> /etc/security/limits.conf

	#单个用户可用的最大进程数量(硬限制)
	echo "* hard nofile 65536" >> /etc/security/limits.conf

	#单个用户可打开的最大文件描述符数量(软限制)
	echo "* soft nproc 65536" >> /etc/security/limits.conf

	#单个用户可打开的最大文件描述符数量(硬限制)
	echo "* hard nproc 65536" >> /etc/security/limits.conf

	sysctl -p

	#表示已设置优化
	echo "" >> $SETUP_DIR/sys_seted
	
    return $?
}

setup_soft_basic "Optimize System" "check_sets"