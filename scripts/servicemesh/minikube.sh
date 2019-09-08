#!/bin/bash
#------------------------------------------------
#      centos7 project env installscript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------
# https://yq.aliyun.com/articles/221687
# https://www.jianshu.com/p/dc3504b70b96
# https://feisky.gitbooks.io/kubernetes/components/kubectl.html
# https://www.centos.bz/2018/01/%E4%BD%BF%E7%94%A8minikube%E5%9C%A8%E6%9C%AC%E6%9C%BA%E6%90%AD%E5%BB%BAkubernetes%E9%9B%86%E7%BE%A4/

function set_environment()
{
	cd $WORK_PATH

	source scripts/servicemesh/docker.sh
	source scripts/servicemesh/kubectl.sh
	source scripts/servicemesh/kubeadm.sh

	return $?
}

function setup_minikube()
{
    cd $DOWN_DIR

    mkdir -pv rpms/kubernates/minikube
    cd rpms/kubernates/minikube

    echo "------------------------------------------------------"
    echo "MiniKube: System start find the newer official version"
	local TMP_MINIKUBE_NEWER_VERSION=`curl -s https://github.com/kubernetes/minikube/releases | grep "/kubernetes/minikube/releases/tag/" | sed 's/="[^"]*[><][^"]*"//g;s/<[^>]*>//g' | awk '{sub("^ *","");sub(" *$","");print}' | awk NR==1`
    echo "MiniKube: The newer official version is ${green}${TMP_MINIKUBE_NEWER_VERSION}${reset}"
    echo "------------------------------------------------------"
    echo "MiniKube: System start find the rpm from github"
	local TMP_MINIKUBE_NEWER_VERSION_TRIM_V=`echo $TMP_MINIKUBE_NEWER_VERSION | sed "s@^v@@g"`
	local TMP_MINIKUBE_NEWER_RPM_FILE_NAME="minikube-${TMP_MINIKUBE_NEWER_VERSION_TRIM_V}.rpm"
	local TMP_MINIKUBE_NEWER_RPM_DOWN_URL="https://github.com/kubernetes/minikube/releases/download/${TMP_MINIKUBE_NEWER_VERSION}/${TMP_MINIKUBE_NEWER_RPM_FILE_NAME}"

    echo "MiniKube: rpm finded \"${green}${TMP_MINIKUBE_NEWER_RPM_DOWN_URL}${reset}\""
    echo "------------------------------------------------------"

    while_wget "--content-disposition $TMP_MINIKUBE_NEWER_RPM_DOWN_URL" "rpm -ivh $TMP_MINIKUBE_NEWER_RPM_FILE_NAME"

	#minikube start --registry-mirror=https://registry.docker-cn.com --vm-driver=none
	#以强制客户端模式，检测是否使用SS
	proxy_by_ss "client"

	#降低配置
	minikube config set memory 1024
	minikube config set cpus 2

	#代理可能存在网络慢的问题，无限重试
	while_exec "minikube start --registry-mirror=https://registry.docker-cn.com --vm-driver=none" "minikube status | grep -o \"Running\" | awk 'END{print NR}' | xargs -I {} [ {} -eq 3 ] && echo 1" "minikube delete && rm -rf ~/.minikube"

	minikube config view cpus
	minikube config view memory
	minikube version
	echo "--------------------------"

	minikube status
	echo "--------------------------------------------------------------------------------"

	kubectl cluster-info
	echo "---------------------------------------------------------------------------------------------------------------------------"

	kubectl get nodes
	echo "-------------------------------------------------"

	kubectl config use-context minikube
	echo "-------------------------------------------------"

	nohup minikube dashboard &
	echo ""

	local TMP_MINIKUBE_BOOT_PATH=$BOOT_DIR/minikube.sh
	echo "minikube status | grep -o \"Running\" | awk 'END{print NR}' | xargs -I {} [ {} -eq 3 ] && echo \"minikube was started\" || minikube start --vm-driver=none" > $TMP_MINIKUBE_BOOT_PATH
    echo_startup_config "minikube" "$HOME" "bash $TMP_MINIKUBE_BOOT_PATH" "$HOME"
    echo_startup_config "minikube_dashboard" "$HOME" "minikube dashboard" "$HOME" 999

	return $?
}

function check_minikube()
{
    soft_rpm_check_action "minikube" "setup_minikube" "Minikube was installed"

	return $?
}

set_environment
setup_soft_basic "MiniKube" "check_minikube"
