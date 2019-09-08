
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
minikube version
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
kubectl version

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
mkdir $HOME/.kube || true
touch $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config



base=https://github.com/docker/machine/releases/download/v0.16.0 &&
  curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
  sudo install /tmp/docker-machine /usr/local/bin/docker-machine

minikube -version
--yum -y install docker

rm -rf ~/.minikube

vim /etc/yum.repos.d/virtualbox.repo

yum install gcc make kernel-headers kernel-devel
yum -y install VirtualBox-5.2
minikube start --registry-mirror=https://registry.docker-cn.com
sudo /sbin/rcvboxdrv setup
minikube start --registry-mirror=https://registry.docker-cn.com


wget -O - https://raw.githubusercontent.com/XiaoMi/naftis/master/tool/getlatest.sh | bash



http://blog.gezhiqiang.com/2017/08/04/minikube/
http://blog.51cto.com/purplegrape/2315451