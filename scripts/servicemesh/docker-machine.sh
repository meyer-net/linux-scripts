#!/bin/bash
#------------------------------------------------
#      centos7 project env installscript
#      copyright https://devops.oshit.com/
#      author: meyer.cheng
#------------------------------------------------

#临时区变量
local TMP_SETUP_DOCKER_MACHINE_DIR="$SETUP_DIR/docker-machine"
local TMP_SETUP_DOCKER_MACHINE_PATH="$TMP_SETUP_DOCKER_MACHINE_DIR/docker-machine"

function set_environment()
{
	return $?
}

function check_docker_machine()
{
    path_not_exists_action "$TMP_SETUP_DOCKER_MACHINE_DIR" "setup_docker_machine" "DockerMachine was installed"

    return $?
}

function setup_docker_machine()
{
    echo "-----------------------------------------------------------"
    echo "DockerMachine: System start find the newer official version"
    echo "-----------------------------------------------------------"
	local TMP_DOCKER_MACHINE_NEWER_VERS=`curl -s https://github.com/docker/machine/releases | grep "/docker/machine/releases/tag/" | sed 's/="[^"]*[><][^"]*"//g;s/<[^>]*>//g' | awk '{sub("^ *","");sub(" *$","");print}' | awk NR==1`
    echo "DockerMachine: The newer official version is $TMP_DOCKER_MACHINE_NEWER_VERS"
    echo "-----------------------------------------------------------"

    mkdir -pv $TMP_SETUP_DOCKER_MACHINE_DIR
    curl -L https://github.com/docker/machine/releases/download/${TMP_DOCKER_MACHINE_NEWER_VERS}/docker-machine-`uname -s`-`uname -m` > $TMP_SETUP_DOCKER_MACHINE_PATH

    chmod +x $TMP_SETUP_DOCKER_MACHINE_PATH
    
    ln -sf $TMP_SETUP_DOCKER_MACHINE_PATH /usr/local/bin/docker-machine

	return $?
}

set_environment
setup_soft_basic "DockerMachine" "check_docker_machine"
