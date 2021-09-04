#!/bin/bash
#------------------------------------------------
#      centos7 project env installscript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function set_environment()
{
    yum -y install socat conntrack
    
	return $?
}

function setup_kubeadm()
{
    cd $DOWN_DIR

    mkdir -pv rpms/kubernates/kubeadm
    cd rpms/kubernates/kubeadm

    echo "-----------------------------------------------------"
    echo "KubeAdm: System start find the newer official version"
    echo "-----------------------------------------------------"
	local TMP_KUBEADM_NEWER_VERS=`curl -s https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md#client-binaries-1 | grep "https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-" | awk -F'\"' '{print $2}' | awk -F'-' '{print $NF}' | sed 's@\.md@@g' | awk NR==1`
    local TMP_KUBEADM_NEWER_VERS_S_COUNT=`echo $TMP_KUBEADM_NEWER_VERS | awk -F'.' '{print NF-1}'`
    if [ $TMP_KUBEADM_NEWER_VERS_S_COUNT -lt 2 ]; then
        TMP_KUBEADM_NEWER_VERS="${TMP_KUBEADM_NEWER_VERS}.0"
    fi

    echo "KubeAdm: The newer official version is $TMP_KUBEADM_NEWER_VERS"
    echo "-----------------------------------------------------"
    echo "KubeAdm: System start find the fpm file from mirrors"

    local TMP_MIRRORS_URL="https://mirrors.aliyun.com/kubernetes/yum/pool/"

    #安装依赖
    set_url_list_newer_date_link_filename "TMP_CRI_TOOLS_NEWER_FILE_NAME" "$TMP_MIRRORS_URL" "cri-tools.*.$CPU_ARCHITECTURE"
    local TMP_CRI_TOOLS_NEWER_RPM_DOWN_URL="${TMP_MIRRORS_URL}${TMP_CRI_TOOLS_NEWER_FILE_NAME}"
    echo "CriTools: Rpm finded \"$TMP_CRI_TOOLS_NEWER_RPM_DOWN_URL\""
    while_wget "--content-disposition ${TMP_CRI_TOOLS_NEWER_RPM_DOWN_URL}" "rpm -ivh $TMP_CRI_TOOLS_NEWER_FILE_NAME"
 
    set_url_list_newer_date_link_filename "TMP_KUBELET_NEWER_FILE_NAME" "$TMP_MIRRORS_URL" "kubelet.*.$CPU_ARCHITECTURE"
    local TMP_KUBELET_NEWER_RPM_DOWN_URL="${TMP_MIRRORS_URL}${TMP_KUBELET_NEWER_FILE_NAME}"
    echo "KubeLet: Rpm finded \"$TMP_KUBELET_NEWER_RPM_DOWN_URL\""
    while_wget "--content-disposition $TMP_KUBELET_NEWER_RPM_DOWN_URL"
    
    set_url_list_newer_date_link_filename "TMP_KUBERNETES_CNI_NEWER_FILE_NAME" "$TMP_MIRRORS_URL" "kubernetes-cni.*.$CPU_ARCHITECTURE"
    local TMP_KUBERNETES_CNI_NEWER_RPM_DOWN_URL="${TMP_MIRRORS_URL}${TMP_KUBERNETES_CNI_NEWER_FILE_NAME}"
    echo "KubernetesCni: Rpm finded \"$TMP_KUBERNETES_CNI_NEWER_RPM_DOWN_URL\""
    while_wget "--content-disposition $TMP_KUBERNETES_CNI_NEWER_RPM_DOWN_URL"
    rpm -ivh --nodeps --force ${TMP_KUBELET_NEWER_FILE_NAME} ${TMP_KUBERNETES_CNI_NEWER_FILE_NAME}

    #原方式，但dl.k8s.io无法访问，故改成中科镜像使用rpm方式安装
    #local TMP_KUBEADM_DOWNLOAD_URL="https://dl.k8s.io/v$TMP_KUBEADM_NEWER_VERS/kubernetes-client-linux-amd64.tar.gz"
    set_url_list_newer_date_link_filename "TMP_KUBEADM_NEWER_RPM_FILE_NAME" "$TMP_MIRRORS_URL" "kubeadm-${TMP_KUBEADM_NEWER_VERS}\-[0-9]*\.$CPU_ARCHITECTURE"
    local TMP_KUBEADM_NEWER_RPM_DOWN_URL="${TMP_MIRRORS_URL}${TMP_KUBEADM_NEWER_RPM_FILE_NAME}"
    echo "KubeAdm: Rpm finded \"$TMP_KUBEADM_NEWER_RPM_DOWN_URL\""
    while_wget "--content-disposition $TMP_KUBEADM_NEWER_RPM_DOWN_URL" "rpm -ivh $TMP_KUBEADM_NEWER_RPM_FILE_NAME"
    echo "-----------------------------------------------------"

    # 开机启动kubelet
    systemctl enable --now kubelet


    kubeadm version
    
	return $?
}

function check_kubeadm()
{
    soft_rpm_check_action "kubeadm" "setup_kubeadm" "Kubeadm was installed"

	return $?
}

set_environment
setup_soft_basic "KubeAdm" "check_kubeadm"
