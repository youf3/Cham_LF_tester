
all:
	cd fio;./configure;make
	cd iperf;./configure;make
	curl -o nuttcp.tar.bz2 http://nuttcp.net/nuttcp/nuttcp-8.1.4.tar.bz2;tar -xf nuttcp.tar.bz2;rm nuttcp.tar.bz2;cd nuttcp-8.1.4;make
	curl -o I2util-1.2.tar.gz http://software.internet2.edu/sources/I2util/I2util-1.2.tar.gz;tar -xf I2util-1.2.tar.gz;rm I2util-1.2.tar.gz;cd I2util-1.2;./configure;make
	cd bwctl;./configure;make


install:
	cd fio;make install
	cd iperf;make install
	cd nuttcp-8.1.4;cp nuttcp-8.1.4 /usr/local/bin/nuttcp
	cd I2util-1.2;make install
	cd bwctl; make install
	ldconfig

clean:
	cd fio;make clean
	cd iperf;make clean
	cd nuttcp-8.1.4;make clean
	rm /usr/local/bin/nuttcp
	cd I2util-1.2;make clean
	cd bwctl; make clean
