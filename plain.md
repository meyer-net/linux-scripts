*1：优化脚本镜像地址，区分国内、海外。
*2：优化脚本执行路径，非必要在脚本目录下。
*3：/var/log 下的目录要做同权操作。
*4：优化除了VmWare类型的机器，都不再安装iptables
*5：重整mysql等安装。
*6：重整kafka
x7：elk自动引用java环境变量
== 修改为 set_if_equals
*nfs 
*rpcbind

默认检测系统配置文件22端口开放，如开放则修改为10022   /etc/ssh/sshd_config

VC-100：{
    OPTS：80+
    SVRS：101+
}

预留段：~49
源服务段：50~79
ESXI-C段：80~99
ESXI-S段：100~109
业服务段：110~149
PC电脑段：150~199
LNX机段：200~229
WIFI、DHCP段：230~254

kong-cashier：110    4c4g  50G
kong-backstage：111  4c4g  50G
kong-buffer：112     4c8g  50G

core-domain rco-cashier 120         4c16g  100G
core-context micro-security 121      4c16g  100G
core-infrastructure micro-leaf 122          4c16g  50G

core-robot erp-robot 123           4c32g  200G

cache—mq redis 125               8c32g  300G

dbm：130 4c8g  500G
dbs：131 4c8g  500G
bak：132 4c8g 500G

https://my.oschina.net/u/3625745/blog/3006581