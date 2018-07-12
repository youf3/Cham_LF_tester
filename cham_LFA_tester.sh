# Tests iperf3 between Chameleon and Starlight

# Copyright (C) <2018>  <Se-young Yu>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Prerequisite :
#   DTN stack is running on CC cloud with ssh key installed on every node
#   python-openstackclient, python-heatclient, python-blazarclient or pip to install them
#   tmux


#!/bin/bash

SL_DTN=10.100.100.9
SL_DTN_PORTS=(10001 10002 10003 10004 10005 10006 10007 10008)
duration=60

#OS_USERNAME_INPUT=
#OS_PASSWORD_INPUT=
#export OS_PROJECT_NAME=
#export OS_PROJECT_ID=

stack_name=""
tester_stack_name=""

function set_cc_site {

    if [ "$1" = "uc" ]; then
	export OS_AUTH_URL=https://chi.uc.chameleoncloud.org:5000/v3
	export OS_REGION_NAME="CHI@UC"
    elif [ "$1" = "tacc" ]; then
	export OS_AUTH_URL=https://chi.tacc.chameleoncloud.org:5000/v3
	export OS_REGION_NAME="CHI@TACC"	
    fi
}

function check_dependency {
    if ! heat --version > /dev/null || ! blazar --version > /dev/null; then
	echo "Installing openstack cli"
	echo "Please input sudo password"
	sudo pip install python-openstackclient python-heatclient python-blazarclient
    fi

    if [ "$?" -ne "0" ]; then
	echo "Cannot install openstack cli"
	exit 6
    fi
    

    if ! tmux -V > /dev/null; then
	echo "Installing tmux.."
	echo "Please input sudo password"
	if [[ $(head -n 1 /etc/os-release) =~ .*Ubuntu.* ]];then
            sudo apt install tmux
	elif [[ $(head -n 1 /etc/os-release) =~ .*CentOS.* ]];then
            sudo yum install tmux
	fi
	
	if [ "$?" -ne "0" ]; then
	    echo "Cannot install tmux"
	    exit 7
	fi
    fi
}

function set_auth {
    # In addition to the owning entity (tenant), OpenStack stores the entity
    # performing the action as the **user**.
    if [ "$OS_USERNAME_INPUT" == "" ]; then
	echo "Please enter your Chameleon Cloud username"
	read -r OS_USERNAME_INPUT    
    fi
    export OS_USERNAME=$OS_USERNAME_INPUT
    
    # With Keystone you pass the keystone password.
    if [ "$OS_PASSWORD_INPUT" == "" ]; then
	echo "Please enter your Chameleon Cloud Password as user $OS_USERNAME: " 
	read -sr OS_PASSWORD_INPUT
    fi 
    export OS_PASSWORD=$OS_PASSWORD_INPUT
    export OS_INTERFACE=public
    export OS_IDENTITY_API_VERSION=3
}

function set_project {
  
    if [ "$OS_PROJECT_NAME" == ""  ]; then
	projects=($(openstack project list|gawk -F'| ' 'NF > 1 {print $4 " " $2}'))

	if [ "$projects" == "" ]; then
	    echo "Incorrect password"
	    exit 6
	fi
	
	size=($(expr ${#projects[@]} / 2))
	
	echo "Please choose the project you are using for stack $stack_name"
	for (( i=1; i<size+1; i++  )); do
	    index=($(expr $i \* 2 - 1))
	    echo $i: ${projects[index]}
	done
	
    fi
    
    read -r project_num
    project_number=($(expr $project_num \* 2 - 1))

    if [ "${projects[$project_number]}" == "" ] ; then
	echo "Project $project_num does not exist"
	exit 5
    fi    
    
    export OS_PROJECT_NAME=${projects[$project_number]}
    export OS_PROJECT_ID=${projects[$project_number+1]}
}


function get_ip {
    ips=($(openstack stack show $1 | gawk '/output_value:/{flag=1} ; / links|description /{flag=0} flag' | cut -f 3 -d "|"))
    if [ "${#ips[@]}" -eq 32 ] && [ "${ips[1]}" != "''" ] && [ "${ips[27]}" != "''" ];then
	echo -e ${ips[1]} "\n"${ips[27]} "\n"${ips[29]} "\n"${ips[31]}
    else
	exit 3
    fi
    
}

function test_conn {
    argv=($@)
    for (( j=0; j<4; j++ )); do
	#echo "Testing connection to ${argv[$j]}"
	ssh  -o StrictHostKeyChecking=no cc@${argv[j]} exit
	if [ "$?" -ne "0" ]; then
	    echo "Cannot connect to ${argv[j]}"
	    exit 4
	fi
	
	echo "Connection to ${argv[j]} was successful"	
    done    
}


function run_cl_sl {
    echo "Testing connection to DTN"
    test_conn $@
    
    tmux kill-session -t "cham_dtn_tester" > /dev/null 2>&1
    tmux new-session -d -s "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -c $5 -p ${6} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    #tmux set-option remain-on-exit on
    tmux set-window-option synchronize-panes on
    tmux split-window -v -t "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$2 iperf3 -c $5 -p ${7} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux split-window -v -t "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$3 iperf3 -c $5 -p ${8} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux split-window -v -t "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$4 iperf3 -c $5 -p ${9} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux select-layout even-vertical
    tmux attach -t "cham_dtn_tester"
}

function run_server {
    echo "Testing connection to DTN"
    test_conn $@
    
    tmux new-session -d -s "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -s"
    tmux split-window -v -t "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$2 iperf3 -s"
    tmux split-window -v -t "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$3 iperf3 -s"
    tmux split-window -v -t "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$4 iperf3 -s"
}

function run_cl {
    echo "Testing connection to DTN"
    test_conn $@
    
    tmux new-session -d -s "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -c ${5} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\" "
    #tmux set-option remain-on-exit on
    tmux set-window-option synchronize-panes on
    tmux split-window -v -t "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$2 iperf3 -c ${6} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux split-window -v -t "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$3 iperf3 -c ${7} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux split-window -v -t "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$4 iperf3 -c ${8} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux select-layout even-vertical
    tmux attach -t "cham_dtn_tester"
}

function run_cl_within {
    echo "Testing Connection within CC"

    tmux new-session -d -s "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -c ${2} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\" "
    tmux set-window-option synchronize-panes on
    tmux split-window -v -t "cham_dtn_tester" "ssh -tt -o StrictHostKeyChecking=no cc@$2 iperf3 -c ${3} -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux attach -t "cham_dtn_tester"
}

function main {
    if [ "$1" = "uc" ] || [ "$1" = "tacc" ] ; then
	set_cc_site $1
    else    
	echo "Please specify either uc or tacc as site name"
	echo "Usage : $0 {uc | tacc} {sl | cha}"
	exit 0
    fi

    if [ "$2" != "sl" ] && [ "$2" != "cha" ] && [ "$2" != "" ]; then
	echo "Please specify either sl or cha as testing site name"
	echo "Usage : $0 {uc | tacc} [sl | cha]"
	exit 1
    fi

    if [ -z "$stack_name" ] || [ -z "$tester_stack_name" ] ; then
	echo "Please set \$stack_name and \$tester_stack_name in the script."
	exit 8
    fi
    
    echo "Checking dependency"
    check_dependency

    echo "Checking Authentication"
    set_auth

    set_project

    echo "Getting IP from $1"
    cham_ip=($(get_ip "$stack_name"))
    echo "${cham_ip[@]}"
    if [ "$?" -ne "0" ]; then
	echo "cannot find IP from stack $stack_name in $1. Please check $stack_name is running in $1"
	exit 3
    fi

    if [ "$2" = "" ]; then
	echo "Running test within site cc@$1"
	tmux kill-session -t "cham_dtn_server"  > /dev/null 2>&1
	tmux kill-session -t "cham_dtn_tester"  > /dev/null 2>&1

	remote_ips=($(get_ip "$tester_stack_name"))
	echo "${remote_ips[@]}"
	echo "Starting server"
	run_server "${remote_ips[@]}"
	sleep 3
	
	run_cl "${cham_ip[@]}" "${remote_ips[@]}"

	echo "Stopping server" 
	tmux kill-session -t "cham_dtn_server" 
	
    elif [ "$2" = "sl" ]; then
	run_cl_sl "${cham_ip[@]}" "$SL_DTN" "${SL_DTN_PORTS[@]}"
    elif [ "$2" = "cha" ]; then 
	if [ "$1" = "tacc" ]; then
	    echo "Getting IP from uc"
	    set_cc_site "uc"
	    
    	    remote_ips=($(get_ip "$stack_name"))

   	    if [ "$?" -ne "0" ]; then
		echo "cannot find IP from stack $stack_name in uc. Please check $stack_name is running in uc"
		exit 3
   	    fi

	else
	    echo "Getting IP from tacc"
	    set_cc_site "tacc"
	    
    	    remote_ips=($(get_ip "$stack_name"))

   	    if [ "$?" -ne "0" ]; then
		echo "cannot find IP from stack $stack_name in tacc. Please check $stack_name is running in tacc"
		exit 3
   	    fi

	fi

	tmux kill-session -t "cham_dtn_server"  > /dev/null 2>&1
	tmux kill-session -t "cham_dtn_tester"  > /dev/null 2>&1

	echo "Starting server"
	run_server "${remote_ips[@]}"
	sleep 1
	
	run_cl "${cham_ip[@]}" "${remote_ips[@]}"

	echo "Stopping server" 
	tmux kill-session -t "cham_dtn_server" 
    fi
}

main $@
