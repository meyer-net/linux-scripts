#!/bin/bash
#------------------------------------------------
#      Centos7 Project Env InstallScript
#      copyright https://echat.oshit.com/
#      email: meyer_net@foxmail.com
#------------------------------------------------

function setup_java()
{
	cd ..
	mv jdk1.8.0_192 $JAVA_HOME

	echo "JAVA_HOME=$JAVA_HOME" >> /etc/profile
	echo "JRE_HOME=\$JAVA_HOME/jre" >> /etc/profile
	echo "CLASSPATH=\$JAVA_HOME/lib:\$JRE_HOME/lib" >> /etc/profile
	echo "JAVA_BIN=\$JAVA_HOME/bin" >> /etc/profile
	echo "PATH=\$JAVA_BIN:\$PATH" >> /etc/profile
	echo "export PATH JAVA_HOME JAVA_BIN JRE_HOME CLASSPATH" >> /etc/profile

	mkdir -pv /usr/lib/jvm
	ln -sf $JAVA_HOME /usr/lib/jvm/java-1.8.0

	groupadd javasys

	source /etc/profile

	java -version
	
	return $?
}

function setup_gradle()
{
	GRADLE_HOME=$SETUP_DIR/gradle

	cd ..
	mv gradle-4.10.3 $GRADLE_HOME

	echo "GRADLE_HOME=$GRADLE_HOME" >> /etc/profile
	echo "PATH=\$GRADLE_HOME/bin:\$PATH" >> /etc/profile
	echo "export PATH GRADLE_HOME" >> /etc/profile

	source /etc/profile

	gradle -version

	return $?
}

function setup_maven()
{
	yum -y install maven
	mvn -version

	return $?
}

function down_java()
{
	# http://dl.mycat.io/jdk-8u20-linux-x64.tar.gz
    setup_soft_wget "java" '--no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u192-b12/750e1c8617c5452694857ad95c3ee230/jdk-8u192-linux-x64.tar.gz' "setup_java"
    setup_soft_wget "gradle" "https://services.gradle.org/distributions/gradle-4.10.3-bin.zip" "setup_gradle"
	setup_maven
	
	return $?
}

setup_soft_basic "Java" "down_java"
