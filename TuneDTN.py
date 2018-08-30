import time
import getpass
import subprocess
import shlex
import sys
import platform
import re

tcp_params = {
        'net.core.rmem_max' : 2147483647,
        'net.core.wmem_max' : 2147483647,
        'net.ipv4.tcp_rmem' : [4096, 87380, 2147483647],
        'net.ipv4.tcp_wmem' : [4096, 87380, 2147483647],
        'net.core.netdev_max_backlog' : 250000,
        'net.ipv4.tcp_no_metrics_save' : 1,
        'net.ipv4.tcp_mtu_probing' : 1,
        'net.core.default_qdisc' : 'fq'
        }

interfaces = ['enp33s0f0.2038']

def run_command(cmd, ignore_stderr = False):
    proc = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
                                stderr=subprocess.PIPE)
    try:
        outs, errs = proc.communicate(timeout=2)
    except subprocess.TimeoutExpired:
        if 'sudo: no tty present and no askpass program specified' in str(proc.stderr.readline(),'UTF-8'):
            print('To change system parameters, please input sudo password')
            password = getpass.getpass()    
            cmd = cmd.replace('sudo', 'sudo -S')
            proc = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
                                    stderr=subprocess.PIPE)
            outs, errs = proc.communicate(bytes(password + '\n', 'UTF-8'))
            errs = str(errs,'UTF-8').split('\n')
            for line in errs:
                if '[sudo] password for' in line:
                    errs.remove(line)
            errs = bytes(''.join(errs), 'UTF-8')
            
        elif proc.stderr.readline() == b'':
            outs, errs = proc.communicate()            
        else:
            outs, errs = proc.communicate()
        
    return [str(outs,'UTF-8'), str(errs,'UTF-8')]

def install_required_packages():
    global pyroute2
    global ethtool
    while True:
        try:        
            import pyroute2, ethtool
            break
        except ImportError:
            print('Installing required packages....')
            distro_name = platform.linux_distribution()[0]
            print(distro_name)
            if 'CentOS' in distro_name or 'Red Hat' in distro_name:
                command = 'sudo yum install -y libnl3-devel pkg-config pciutils'
                pip_cmd = 'pip'

            elif 'Ubuntu' in distro_name or 'Debian' in distro_name:
                command = 'sudo apt-get install -y libnl-3-dev libnl-route-3-dev python3-pip pkg-config python3-dev'
                pip_cmd = 'pip3'
            
            out, err = run_command(command)
            if err != '':
                print(err)
                return False
            print(out)
            print('install pip')
            command = 'sudo env "PATH=$PATH" {0} install setuptools wheel pyroute2 ethtool'.format(pip_cmd)
            print(command)
            out, err = run_command(command)
            # if err != b'':
            #     print('error:', err)
            #     #print(out)
            #     print('returning false')                    
            #     return False
            print('error:', err)
            print(out)
        time.sleep(1)
        
def test_password():
    command = 'sudo su'
    out, err = run_command(command)
    print(out, err)
    if 'incorrect password attempt' in err:
        return False
    return True
    
def get_phy_int(interface):
    ip = pyroute2.IPRoute()
    if len(ip.link_lookup(ifname=interface)) == 0 :
        return None
    link = ip.link("get", index=ip.link_lookup(ifname=interface)[0])[0]
    raw_link_id = list(filter(lambda x:x[0]=='IFLA_LINK', link['attrs']))
    if len(raw_link_id) == 1:
        #print('This is vlan, Checking raw interface..')
        raw_index = raw_link_id[0][1]
        raw_link = ip.link("get", index=raw_index)[0]
        phy_int=list(filter(lambda x:x[0]=='IFLA_IFNAME', raw_link['attrs']))[0][1]
        return phy_int
    else:
        return interface

def get_link_cap(pci_info):
    line = list(filter(lambda x:'LnkSta:' in x ,pci_info))[0]
    caps = list(filter(None, re.split('[:,\t]',line)))
    
    return caps[1], caps[2]
    
def get_mtu(interface):
    ip = pyroute2.IPRoute()
    if len(ip.link_lookup(ifname=interface)) == 0 :
        return None
    link = ip.link("get", index=ip.link_lookup(ifname=interface)[0])[0]
    MTU = int((list(filter(lambda x:x[0]=='IFLA_MTU', link['attrs'])))[0][1])
    return MTU
    
    
def tune_sysctl():
    print('Changing TCP buffer to 2GB')
    #conf_file = 'DTN.conf'
    #create_temp_file(conf_file, tcp_params)
    #command = 'sudo -S cp {0} /etc/sysctl.d/ ; sudo sysctl --system' # -S as it enables input from stdin
    command = ''
    for param in tcp_params:
        if isinstance(tcp_params[param], list):
            value = ' '.join(str(v) for v in tcp_params[param])
        else:
            value = tcp_params[param]
        command += 'sudo sysctl {0}=\'{1}\';'.format(param, value)
    outs, errs = run_command(command)
    if errs != '':
        print(errs)

def tune_fq(interface):
    print('Setting fq')
    phy_int = get_phy_int(interface)
    command = 'sudo tc qdisc add dev {} root fq'.format(phy_int)
    outs, errs = run_command(command)
    if errs != '':
        print(errs)
        
def tune_mtu(interface):
    print('Changing MTU to 9k')
    phy_int = get_phy_int(interface)
    command = 'sudo ip link set dev {0} mtu 9000'.format(phy_int)
    if phy_int != interface:        
        command += '; sudo ip link set dev {0} mtu 9000'.format(interface)
    run_command(command)

def tune_cpu_governer():
    print('Setting CPU Governor to Performance')
    command = 'sudo sh -c \'echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor\''
    outs, errs = run_command(command)
    if errs != '':
        print(errs)

def tune_mellanox(interface):    
    print('Tunning Mellanox card')
    phy_int = get_phy_int(interface)
    bus = ethtool.get_businfo(phy_int)
    
    command = 'sudo setpci -s {0} 68.w'.format(bus)
    output, error = run_command(command)
    
    tempstr = list(output)
    tempstr[0] = '5'    
    maxredreq = ''.join(tempstr)    
        
    command = 'sudo setpci -s {0} 68.w={1}'.format(bus, maxredreq)
    output, error = run_command(command)
    
    if error != '':
        print(error)
        
    command = 'sudo mlnx_tune -p HIGH_THROUGHPUT'
    output, error = run_command(command, ignore_stderr= True)
    
    if error != '':
        print(error)
    print(output)
    
def tune_ring_buf(interface):
    print('Tunning ring param for ConnectX-5')
    phy_int = get_phy_int(interface)
    command = 'sudo ethtool -G {0} tx {1} rx {1}'.format(phy_int, 8192)
    output, error = run_command(command)
    
    if error != '':
        print(error)

import unittest

class TuningTest(unittest.TestCase):    
    
    @classmethod
    def setUpClass(cls):
        cls.interface = interface
        cls.phy_int = get_phy_int(cls.interface) 
        if cls.phy_int == None: raise Exception("There is no interface {0}".format(interface))
        cls.driver = ethtool.get_module(cls.phy_int)
        cls.bus = ethtool.get_businfo(cls.phy_int)
    
    def test_sysctl_value(self):
        for command in tcp_params:
            output, error = run_command('sysctl {0}'.format(command))
            if error == '':
                current_val = output.split()[-1]
                tune_param = tcp_params[command]
                #print(tune_param, type(tune_param))
                if isinstance(tune_param, int):
                    self.assertGreaterEqual(int(current_val), tune_param)
                elif isinstance(tune_param, list):
                    self.assertGreaterEqual(int(current_val), int(tune_param[-1]))
                elif isinstance(tune_param, str):
                    self.assertEqual(current_val, tune_param)
            else:
                print(error)
                self.fail(error)
                
    def test_fq(cls):        
        command = 'tc qdisc show dev {}'.format(cls.phy_int)
        output, error = run_command(command)
        if error != '':
            print(error)
            
        cls.assertIn('qdisc fq', output)
    
    def test_mtu(cls):        
        if cls.phy_int != cls.interface:
            cls.assertGreaterEqual(get_mtu(cls.interface), 9000)       
        cls.assertGreaterEqual(get_mtu(cls.phy_int), 9000)
        
    def test_cpu_governor(self):
        command = 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
        output, error = run_command(command)
        
        if error == '':
            governors = output.split('\n')[:-1]
            for govenor in governors:
                self.assertEqual(govenor,'performance')
        
        elif 'No such file or directory' in error : 
            self.skipTest('No CPU scaling governer found.')
        else: self.fail(error)
            
    def test_pci_speed(cls):
        command = 'sudo lspci -vvv -s {}'.format(cls.bus)
        output, error = run_command(command)
        
        if error == '':
            status = output.split('\n')
            #print(status)
            speed, width = get_link_cap(status)
            cls.assertEqual(speed, 'Speed 8GT/s')
            cls.assertEqual(width, ' Width x16')
        else:
            cls.fail(error)
       
    def test_meallnox_nic(cls):        
        if cls.phy_int == None : cls.fail('No interface {}'.format(cls.interface))
               
        if cls.driver != 'mlx5_core':  cls.skipTest('This is not Mellanox ConnectX-4 or X-5')            
        
        command = 'sudo setpci -s {0} 68.w'.format(cls.bus)
        output, error = run_command(command)
        print(output)
        cls.assertEqual(output[0], '5')
            
    def test_connectx_5(cls):              
        if cls.phy_int == None : cls.fail('No interface {}'.format(cls.interface))        
             
        if cls.driver != 'mlx5_core': cls.skipTest('This is not Mellanox ConnectX-4 or X-5')        
        
        command = 'lspci -s {0}'.format(cls.bus)
        output,error = run_command(command)        
        if '[ConnectX-5]' not in output: cls.skipTest('This is not ConnectX-5')
            
        ring_param = ethtool.get_ringparam(cls.phy_int)        
        cls.assertEqual(ring_param['rx_pending'], 8192)
        cls.assertEqual(ring_param['tx_pending'], 8192)

if __name__ == '__main__':
    
    if test_password():
        install_required_packages()
        
        for interface in interfaces:
             suite = unittest.TestLoader().loadTestsFromTestCase(TuningTest)
             test_result = unittest.TextTestRunner().run(suite)

             for failure in test_result.failures:
                 testname = failure[0].id().split(".")[-1]
                 if testname == 'test_sysctl_value':
                     tune_sysctl()
                 elif testname == 'test_fq':
                     tune_fq(interface)
                 elif testname == 'test_mtu':
                     tune_mtu(interface)
                 elif testname == 'test_cpu_governor':
                     tune_cpu_governer()
                 elif testname == 'test_meallnox_nic':
                     tune_mellanox(interface)
                 elif testname == 'test_connectx_5':
                     tune_ring_buf(interface)
                 elif testname == 'test_pci_speed':
                     print('Please check the PCI slot for {}'.format(interface))
                 print('Done')
    else:
        print('incorrect password. Quitting..')

