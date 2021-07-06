# 以下是 py 的执行安装范例
#!/usr/bin/python
# -*- coding: utf-8 -*-
# python version 2.7（一般服务器默认版本）
import os
import sys

# yum源设置
def set_yum():
	str_cmd = '''
sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo_bak`date +%Y%m%d`
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum makecache'''
	os.system(str_cmd)
  
# docker源设置
def set_docker():
	str_cmd = '''
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://registry.docker-cn.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker'''
	os.system(str_cmd)

if __name__ == '__main__':
	set_yum()
	set_docker()