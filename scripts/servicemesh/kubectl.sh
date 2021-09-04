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

function setup_kubectl()
{
    cd $DOWN_DIR

    mkdir -pv rpms/kubernates/kubectl
    cd rpms/kubernates/kubectl

    echo "-----------------------------------------------------"
    echo "KubeCtl: System start find the newer official version"
    echo "-----------------------------------------------------"
	local TMP_KUBECTL_NEWER_VERS=`curl -s https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md#client-binaries-1 | grep "https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-" | awk -F'\"' '{print $2}' | awk -F'-' '{print $NF}' | sed 's@\.md@@g' | awk NR==1`
    local TMP_KUBECTL_NEWER_VERS_S_COUNT=`echo $TMP_KUBECTL_NEWER_VERS | awk -F'.' '{print NF-1}'`
    if [ $TMP_KUBECTL_NEWER_VERS_S_COUNT -lt 2 ]; then
        TMP_KUBECTL_NEWER_VERS="${TMP_KUBECTL_NEWER_VERS}.0"
    fi

    echo "KubeCtl: The newer official version is $TMP_KUBECTL_NEWER_VERS"
    echo "-----------------------------------------------------"
    echo "KubeCtl: System start find the fpm file from mirrors"

    #原方式，但dl.k8s.io无法访问，故改成中科镜像使用rpm方式安装
    #local TMP_KUBECTL_DOWNLOAD_URL="https://dl.k8s.io/v$TMP_KUBECTL_NEWER_VERS/kubernetes-client-linux-amd64.tar.gz"
    local TMP_KUBECTL_NEWER_RPM_FILE_NAME=`curl -s https://mirrors.aliyun.com/kubernetes/yum/pool/ | grep "kubectl-${TMP_KUBECTL_NEWER_VERS}\-[0-9]*\.x86_64\.rpm" | awk -F'\"' '{print $2}'`
    local TMP_KUBECTL_NEWER_RPM_DOWN_URL="https://mirrors.aliyun.com/kubernetes/yum/pool/$TMP_KUBECTL_NEWER_RPM_FILE_NAME"

    echo "KubeCtl: Rpm finded \"$TMP_KUBECTL_NEWER_RPM_DOWN_URL\""
    echo "-----------------------------------------------------"

    while_wget "--content-disposition $TMP_KUBECTL_NEWER_RPM_DOWN_URL" "rpm -ivh $TMP_KUBECTL_NEWER_RPM_FILE_NAME"

    kubectl version
    
	return $?
}

function check_kubectl()
{
    soft_rpm_check_action "kubectl" "setup_kubectl" "Kubectl was installed"

	return $?
}

set_environment
setup_soft_basic "KubeCtl" "check_kubectl"
