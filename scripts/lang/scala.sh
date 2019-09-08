#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function setup_scala()
{
	cd ..
	mv scala-2.11.12 $SETUP_DIR/scala

	echo "SCALA_HOME=$SETUP_DIR/scala" >> /etc/profile
	echo "SCALA_BIN=\$SCALA_HOME/bin" >> /etc/profile
	echo "PATH=\$SCALA_BIN:\$PATH" >> /etc/profile
	source /etc/profile

	scala -version

	return $?
}

function down_scala()
{
    setup_soft_wget "scala" "https://downloads.lightbend.com/scala/2.11.12/scala-2.11.12.tgz" "setup_scala"

	return $?
}

setup_soft_basic "Scala" "down_scala"
