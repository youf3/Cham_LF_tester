#!/bin/bash

detect_linux_distro() {
    if [ $(command -v lsb_release) ]; then
	DISTRO=$(lsb_release -is)
    elif [ -f /etc/os-release ]; then
	# extract 'foo' from NAME=foo, only on the line with NAME=foo
	DISTRO=$(sed -n -e 's/^NAME="\(.*\)\"/\1/p' /etc/os-release)
    elif [ -f /etc/centos-release ]; then
	DISTRO=CentOS
    else
	DISTRO=''
    fi
    echo $DISTRO
}

case $(detect_linux_distro) in
    Ubuntu)
	apt install -y wget
	;;
    CentOS)
	yum install -y wget
	;;
esac

 
