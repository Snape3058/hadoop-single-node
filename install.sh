#!/bin/bash

# Description:
#	This script is used to install and config Hadoop automatically. In this
#	script, it will config hadoop node to single node mode.
#
# Author: alan snape
#
# Modifications:
# +-------------+-------------+----------------------------------------------+
# | Date        | Name        | Modification                                 |
# +-------------+-------------+----------------------------------------------+
# | 2015-09-08  | alan snape  | Start writing this script                    |
# | 2016-10-26  | alan snape  | Update script with JDK_VERSION variable      |
# +-------------+-------------+----------------------------------------------+
#

#### environment ####
JDK_VERSION=8
INSTALL_CMDS="apt -y install "
INSTALL_PKGS="vim build-essential openssh-server rsync openjdk-"$JDK_VERSION"-jre openjdk-"$JDK_VERSION"-jdk"

#### debug switch ####
debug=0

#### print to stdstream ####
function perro()
{
	>&2 echo -e "\033[01;31m[ERRO]:\033[0m $@"
}
function pwarn()
{
	>&2 echo -e "\033[01;33m[WARN]:\033[0m $@"
}
function pnote()
{
	echo -e "\033[01;32m[NOTE]:\033[0m $@"
}

#### root authentication ####
function rootChk()
{
	if (( 0 != $EUID )) && ((! $debug))
	then
		perro "Please run this script as root!"
		exit 1
	else
		pnote "root authenticated."
	fi
}

#### add user hadoop to sudo ####
function hadoopAdd()
{
	if (( $debug ))
	then
		pnote "add user hadoop"
	else
		if [ -z "`grep "hadoop" /etc/passwd`" ]
		then
			pnote "will create user 'hadoop'"
			useradd -m hadoop -s /bin/bash
			if (( $? ))
			then
				perro "error occurs when creating user 'hadoop', please refer to information above for more details."
				exit 1
			fi
		else
			pwarn "user 'hadoop' exists! Nothing will be done here"
		fi
		if [ -z "`grep "sudo" /etc/group | grep "hadoop"`" ]
		then
			pnote "will add user 'hadoop' to group 'sudo'"
			adduser hadoop sudo
			if (( $? ))
			then
				perro "error occurs when adding user 'hadoop' to group 'sudo', please refer to information above for more details."
				exit 1
			fi
		else
			pwarn "user 'hadoop' in group 'sudo', nothing will be done here"
		fi
	fi
}

#### install dependence ####
function depIns()
{
	execution="$INSTALL_CMDS $INSTALL_PKGS"
	if (( $debug ))
	then 
		pnote "$execution"
	else
		pnote "installing dependences"
		$execution
		if (( $? ))
		then
			perro "apt exits with $?, please check above output for more details."
			exit 1
		fi
	fi
}

#### download hadoop ####
function hadoopDow()
{
	execution="wget -c http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-2.7.1/hadoop-2.7.1.tar.gz"
#	down hadoop tarbool if not exists
	if [ ! -f "hadoop-2.7.1.tar.gz" ]
	then
		if (( $debug ))
		then
			pnote "$execution"
		else
			$execution
			if (( $? ))
			then
				perro "Download failed, please restart this program"
				exit 1
			fi
		fi
	else
		pnote "hadoop-2.7.1.tar.gz found!"
	fi
#	check md5sum of the hadoop tarball
	if (( $debug ))
	then
		pnote "check md5sum of the hadoop tarball"
	else
		if [ "`md5sum hadoop-2.7.1.tar.gz | awk '{print $1}'`" != "203e5b4daf1c5658c3386a32c4be5531" ]
		then
			perro "hash mismatch! please restart this program"
			rm "hadoop-2.7.1.tar.gz"
			exit 1
		fi
	fi
}

#### extract tarball and deploy ####
function hadoopDpl()
{
	execution="tar -xzf hadoop-2.7.1.tar.gz"
#	extraction
	if (( $debug ))
	then
		pnote "$execution"
	else
		pnote "extracting tarball..."
		$execution
		if (( $? ))
		then
			perro "Error occurs when extracting tarball, please refer to information above for more help."
			exit 1
		fi
	fi
#	config hadoop root directory
	pnote "config hadoop root directory"
	if (( ! $debug ))
	then
		if [ -d "/usr/local/hadoop" ]
		then
			pwarn "target directory '/usr/loca/hadoop' exists, will remove first."
			rm -rf /usr/local/hadoop
		fi
		if [ -d "hadoop-2.7.1" ]
		then
			chown -R hadoop:hadoop hadoop-2.7.1 && mv hadoop-2.7.1 /usr/local/hadoop
			if (( $? ))
			then
				perro "Error occurs when configuring hadoop root directory, please refer to information above for more help."
				exit 1
			fi
		fi
	fi
}

#### config hadoop ####
function hadoopCfg()
{
	pnote "change directory to /usr/local/hadoop"
	if (( ! $debug ))
	then
		cd /usr/local/hadoop
	fi
	pnote "edit hadoop-env.sh"
	if (( ! $debug ))
	then
		sed -i 's:export JAVA_HOME=${JAVA_HOME}:export JAVA_HOME="/usr/lib/jvm/java-'$JDK_VERSION'-openjdk-amd64":g' etc/hadoop/hadoop-env.sh
	fi
	pnote "edit core-site.xml"
	if (( ! $debug ))
	then
		if [ "`sed -n "20p" etc/hadoop/core-site.xml`"x = "</configuration>"x ]
		then
			sed -i "20i     <property>\n        <name>hadoop.tmp.dir</name>\n        <value>file:/usr/local/hadoop/tmp</value>\n        <description>Abase for other temporary directories.</description>\n    </property>\n    <property>\n        <name>fs.defaultFS</name>\n        <value>hdfs://localhost:9000</value>\n    </property>\n" etc/hadoop/core-site.xml
		fi
	fi
	pnote "edit hdfs-site.xml"
	if (( ! $debug ))
	then
		if [ "`sed -n "21p" etc/hadoop/hdfs-site.xml`"x = "</configuration>"x ]
		then 
			sed -i "21i    <property>\n        <name>dfs.replication</name>\n        <value>1</value>\n    </property>\n    <property>\n        <name>dfs.namenode.name.dir</name>\n        <value>file:/usr/local/hadoop/tmp/dfs/name</value>\n    </property>\n    <property>\n        <name>dfs.datanode.data.dir</name>\n        <value>file:/usr/local/hadoop/tmp/dfs/data</value>\n    </property>\n" etc/hadoop/hdfs-site.xml
		fi
	fi
	pnote "edit /etc/bash.bashrc"
	if (( ! $debug ))
	then
		if [ -z "`grep 'PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin' /etc/bash.bashrc`" ]
		then
			echo 'PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin' >> /etc/bash.bashrc
			export PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin
		fi
	fi
}

#### main process ####
function main()
{
#	check debug mode
	if [ "$@"x == "debug"x ]
	then 
		pnote "In debug mode, nothing will be done really."
		debug=1
	fi
#	check for root privilege
	rootChk
#	add hadoop user
	hadoopAdd
#	install dependence
	depIns
#	download hadoop tarball
	hadoopDow
#	extract tarball and deploy
	hadoopDpl
#	config hadoop
	hadoopCfg
#	finished
	pnote "done."
	return 0
}

main $@
exit $?

