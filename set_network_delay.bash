#!/bin/bash

nic=eno1
delay=100
jitter=3


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
