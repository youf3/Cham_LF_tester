# Cham_dtn_tester

This is a set of tools for testing high-speed transfers on Chameleon Cloud (https://www.chameleoncloud.org).

## Getting Started

To get started with the tool, use the following commands.

```
git clone --recursive https://github.com/youf3/Cham_dtn_tester.git
sudo ./install_dep.bash
make
sudo make install
```

## Setup server

A server is a receiver for transfer and optionally a network emulator.
You can set the network emulation by
```
sudo ./set_network_delay.bash -s
```

You need to set the following the variables in the "set_network_delay.bash"
```
nic=eno1 # network interface to use
delay=30 # network delay
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

# Cham_dtn_tester

This is a set of tools for testing high-speed transfers on Chameleon Cloud (https://www.chameleoncloud.org).

## Getting Started

To get started with the tool, use the following commands.

```
git clone --recursive https://github.com/youf3/Cham_dtn_tester.git
sudo ./install_dep.bash
make
sudo make install
```

## Setup server

Server is a receiver for transfer and optionally a network emulator.
You can set the network emulation by
```
sudo ./set_network_delay.bash -s
```

You need to set the following the variables in the "set_network_delay.bash"
```
nic=eno1 # network interface to use
delay=30 # network delay
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

