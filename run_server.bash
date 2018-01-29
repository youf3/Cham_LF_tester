#!/bin/bash

nuttcp -1 -p5002 -sdz > data.dat
iperf3 -s -p5001

#tmux new-session -d -s "server_instances" "nuttcp -1 -p5002 -sdz < data.dat; iperf3 -s -p5001"
#tmux set-option remain-on-exit on
#tmux attach -t "server_instances"

