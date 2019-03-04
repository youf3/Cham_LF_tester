#!/bin/bash

nic=$1
delay=$2
jitter=3

if [ -z $nic ]
then
    echo "Please provide 100G interface name"
    echo "e.g.) ./set_network_delay.bash enp175s0"
    exit
fi

if [ -z $delay ]
then
    delay=100
fi



if [ "$EUID" -ne 0 ]
then echo "Please run as root"
     exit
fi

tc qdisc del dev $nic root

if [[ $# -gt 0 ]]
then
    key="$1"
    case $key in
	-s|--set)
	    tc qdisc add dev $nic root netem delay ${delay}ms ${jitter}ms distribution normal
	    ;;
	-u|--unset)
	    tc qdisc add dev $nic root fq
	    ;;
    esac
else
    echo "Usage : set_network_delay [-s|-u]"
fi
