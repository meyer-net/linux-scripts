*1：优化脚本镜像地址，区分国内、海外。
*2：优化脚本执行路径，非必要在脚本目录下。
*3：/var/log 下的目录要做同权操作。
*4：优化除了VmWare类型的机器，都不再安装iptables
*5：重整mysql等安装。
*6：重整kafka
x7：elk自动引用java环境变量
== 修改为 set_if_equals
nfs 
rpcbind