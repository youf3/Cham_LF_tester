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

DTN_PORTS=(10001 10002 10003 10004 10005 10006 10007 10008)
duration=60

function test_conn {
	ssh  -o StrictHostKeyChecking=no cc@${1} exit
	if [ "$?" -ne "0" ]; then
	    echo "Cannot connect to $1"
	    exit 4
	fi
	
	echo "Connection to $1 was successful"	
}


function run_cl_sl {
    
    tmux kill-session -t "cham_dtn_tester" > /dev/null 2>&1
    tmux new-session -d -s "cham_dtn_tester" "iperf3 -c $1 -p $2 -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    #tmux set-option remain-on-exit on
    tmux set-window-option synchronize-panes on
    tmux split-window -v -t "cham_dtn_tester" "iperf3 -c $1 -p $3 -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux split-window -v -t "cham_dtn_tester" "iperf3 -c $1 -p $4 -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux split-window -v -t "cham_dtn_tester" "iperf3 -c $1 -p $5 -t ${duration}s;read -p \"Press enter to exit *(Note: you will lose the output)*\""
    tmux select-layout even-vertical
    tmux attach -t "cham_dtn_tester"
}

function run_server {
    echo "Testing connection to $1"
    test_conn $1
    
    tmux new-session -d -s "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -s -p $2"
    echo "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -s -p $2"
    tmux split-window -v -t "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -s -p $3"
    tmux split-window -v -t "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -s -p $4"
    tmux split-window -v -t "cham_dtn_server" "ssh -tt -o StrictHostKeyChecking=no cc@$1 iperf3 -s -p $5"
}


function main {
	echo "Starting server at $1 using ${DTN_PORTS[0]} ${DTN_PORTS[1]} ${DTN_PORTS[2]} ${DTN_PORTS[3]}"
	run_server "$1" "${DTN_PORTS[0]}" "${DTN_PORTS[1]}" "${DTN_PORTS[2]}" "${DTN_PORTS[3]}"
	sleep 1
	
	run_cl_sl "$1" "${DTN_PORTS[0]}" "${DTN_PORTS[1]}" "${DTN_PORTS[2]}" "${DTN_PORTS[3]}"

	echo "Stopping server" 
	#tmux kill-session -t "cham_dtn_server" 

}

main $@
