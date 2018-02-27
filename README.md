# Cham_dtn_tester

This is a set of tools for testing high-speed transfers on Chameleon Cloud (https://www.chameleoncloud.org).

## Getting Started

To get started with the tool, you will need two nodes, namely server and tester, and a shared network between them.
You can use the following sample heat template to create nodes and the network.
https://gist.githubusercontent.com/youf3/dec5073e44ab0c808fcfe49602fab0f6/raw/c2d0e9526f8bd29821ca9629a60fb62b9cdfc84c/Cham_dtn_network.yaml

For both nodes, retrieve the testing tool using

```
git clone --recursive https://github.com/youf3/Cham_dtn_tester.git
sudo ./install_dep.bash
make
sudo make install
```

## Setup server

A server is a receiver in the transfer test and optionally a network emulator.
You can set the network emulation by
```
sudo ./set_network_delay.bash -s
```

You need to set the following the variables in the "set_network_delay.bash"
```
nic=eno1 # network interface to use
delay=30 # network delay in millisecond
jitter=3 # jitter in normal distribution
```

You can start the server with
```
./run_server.bash
```

After the test, you can unset the network emulation with

```
sudo ./set_network_delay.bash -u
```

## Run tester
You need to modify the variables in the "run_test.bash"
```
server_ip=192.168.1.11 #ip address of the server
```
