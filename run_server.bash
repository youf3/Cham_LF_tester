#!/bin/bash

fio --ioengine=posixaio --direct=1 --gtod_reduce=1 --name=test --filename=/home/cc/data.dat --bs=1M --iodepth=64 --size=4G --readwrite=write
nuttcp -1 -p5002 -sdz > /home/cc/data.dat
iperf3 -s -p5001

#tmux new-session -d -s "server_instances" "nuttcp -1 -p5002 -sdz < data.dat; iperf3 -s -p5001"
#tmux set-option remain-on-exit on
#tmux attach -t "server_instances"

