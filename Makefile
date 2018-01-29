
all:
	cd fio;./configure;make
	cd iperf;./configure;make
	curl -o nuttcp.tar.bz2 http://nuttcp.net/nuttcp/nuttcp-8.1.4.tar.bz2;tar -xf nuttcp.tar.bz2;rm nuttcp.tar.bz2;cd nuttcp-8.1.4;make

install:
	cd fio;make install
	cd iperf;make install
	cd nuttcp-8.1.4;cp nuttcp-8.1.4 /usr/local/bin/nuttcp
	ldconfig

clean:
	cd fio;make clean
	cd iperf;make clean
	cd nuttcp-8.1.4;make clean
	rm /usr/local/bin/nuttcp
