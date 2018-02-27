# Cham_LF_tester

This is a set of tools for testing Large Flow transfers on Chameleon Cloud (https://www.chameleoncloud.org).

## Getting Started

To get started with the tool, you will need two nodes, namely server and tester, and a shared network between them.
You can use the following sample heat template to create nodes and the network.
https://gist.githubusercontent.com/youf3/dec5073e44ab0c808fcfe49602fab0f6/raw/1cc10f0ee6513b3af6299813e9c054c689e3ac2a/Cham_LF_network.yaml

Retrieve the testing tool on each node using the following command.

```
git clone --recursive https://github.com/youf3/Cham_LF_tester.git
sudo ./install_dep.bash
make
sudo make install
```

## Setup server

A server is a receiver in the transfer test and optionally a network emulator.
You can set the network emulation using the following command.
```
sudo ./set_network_delay.bash -s
```

You need to set the following the variables in the "set_network_delay.bash".
```
nic=eno1 # network interface to insert delay
delay=30 # network delay in millisecond
jitter=3 # noramlly distributed jitter in millisecond 
```

You can start the server with the following command.
```
./run_server.bash
```

After the test, you can unset the network emulation with the following command.

```
sudo ./set_network_delay.bash -u
```

## Run tester
You need to modify the variables in the "run_test.bash"
```
server_ip=192.168.1.11 #ip address of the server
```

Then run the test using the following command.
```
./run_test.bash
```
