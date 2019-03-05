import ptvsd
import netifaces
import subprocess, shlex
import pyroute2
import ping3

def setup(ip_addr):
    for link in netifaces.interfaces():
        for ip in netifaces.ifaddresses(link):
            addrs = netifaces.ifaddresses(link)[ip]
            for addr in addrs:
                if ip_addr == addr['addr']:
                    # Allow other computers to attach to ptvsd at this IP address and port.
                    ptvsd.enable_attach(address=(ip_addr, 3000), redirect_output=True)

                    # Pause the program until a remote debugger is attached
                    ptvsd.wait_for_attach()
                    return True
    return False

def check_system():
    command = 'sudo dmidecode -s system-product-name'
    output = subprocess.check_output(shlex.split(command))
    return output.decode('UTF-8').strip()

def check_available_ip():
    ip_range = ['192.168.0.2', '192.168.0.3', '192.168.0.4', '192.168.0.5']
    
    for ip in ip_range:
        r = ping3.ping(ip)

        if r == None:
            print('IP {} is available'.format(ip))
            return ip            
        else:
            print('There is a host with IP address {}'.format(ip))
            continue

    raise Exception('No IP address Available')

def setup_ip_addr(system_model):
    if system_model == 'PowerEdge R630':
        interface = 'enp3s0f1'
    elif system_model == 'PowerEdge R740xd':
        interface = 'enp175s0'

    temp_ip = '192.168.0.1'

    ipr = pyroute2.IPRoute()
    pr_index = ipr.link_lookup(ifname=interface, operstate='UP')
    if len(pr_index) != 1:
        raise Exception('No 100G interface with a connection found')
        
    ipr.addr('add', index=pr_index, address=temp_ip, mask=24)
    address = check_available_ip()

    ipr.addr('del', index=pr_index, address=temp_ip, mask=24)
    ipr.addr('add', index=pr_index, address=address, mask=24)
    print('100G interface is "{}". IP address is set to {}'.format(interface,address))

if __name__ == '__main__':    
    # setup('10.140.80.3')
    system_model = check_system()
    setup_ip_addr(system_model)
    
