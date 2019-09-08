#!/bin/bash
#------------------------------------------------
#      centos7 project env installscript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
	return $?
}

function check_docker()
{
    #对应删除
    #sudo yum remove docker-ce
    #sudo rm -rf /var/lib/docker
    soft_yum_check_action "docker" "setup_docker" "Docker was installed"

    return $?
}

function setup_docker()
{
    # 更新包，因为过长所以暂时不放环境设置中
    sudo yum -y update
    sudo yum makecache fast

    # 安装
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl start docker
    
    # 配置
    cat >/etc/docker/daemon.json<<EOF
{
        "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn", "http://hub-mirror.c.163.com", "https://registry.docker-cn.com"],
        "max-concurrent-downloads": 30
}
EOF

    #sed -i 's@"registry-mirrors": .*@"registry-mirrors": ["https://docker.mirrors.ustc.edu.cn", "hub-mirror.c.163.com", "https://registry.docker-cn.com"]@g' /etc/docker/daemon.json
    
    sudo systemctl restart docker
    sudo docker run hello-world
    sudo docker images

    rm -rf get-docker.sh


	return $?
}

set_environment
setup_soft_basic "Docker" "check_docker"
