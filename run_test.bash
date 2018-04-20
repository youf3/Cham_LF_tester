#!/bin/bash
server_ip=192.168.1.11

mem_test(){
iperf3 -c $server_ip -Z -p 5001 -t30s
}

fio_test(){
fio --ioengine=posixaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=1M --iodepth=64 --size=4G --readwrite=read
fio --ioengine=posixaio --direct=1 --gtod_reduce=1 --name=test --filename=test --bs=1M --iodepth=64 --size=4G --readwrite=write
rm test
}

disk_test(){
    if [ ! -f data.dat ]; then
    echo "Generating test data"
    fio --thread --direct=1 --rw=read --norandommap --randrepeat=0 --bs=1M --numjobs=8 --ioengine=sync --runtime=30 --group_reporting --time_based --iodepth=32 --name=drive0 --size=10G --filename=data.dat
    fi

nuttcp -t -vv -i1 -sdz -p5002 -T30s $server_ip < data.dat
}

echo "Running mem-to-mem"
mem_test

echo -e "\nRunning disk read/write"
fio_test

echo -e "\nRunning disk-to-disk transfer"
disk_test
