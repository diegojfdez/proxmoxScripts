"""
DHCP server conf Generator

Inputs
- @1 Initial 2nd IP Byte
- @2  Final 2nd IP Byte
- @3 Number of students

Assumptions
- .1 will be GW IP
- DNS will be 172.16.200.1


subnet 10.X.Y.0 netmask 255.255.255.0 {
  range 10.X.Y.100 10.X.Y.254;
  option domain-name-servers 172.16.200.1;
  option domain-name "institutodh.net";
  option routers 10.X.Y.1
  default-lease-time 86400;
  max-lease-time 86400;
}

"""

import sys
#import datetime, os, time
#import hashlib

def main():
    print ('argument list', sys.argv)
    iniIP = int(sys.argv[1])
    endIP = int(sys.argv[2])
    numberOfStudents = int(sys.argv[3])
    
    for i in range(iniIP, endIP+1):
        for j in range(numberOfStudents+1):
            print(f"subnet 10.{i}.{j}.0 netmask 255.255.255.0 {{")
            print(f"  range 10.{i}.{j}.100 10.{i}.{j}.254;")
            print("""  option domain-name-servers 172.16.200.1;""")
            print('  option domain-name "institutodh.net";')
            print(f"  option routers 10.{i}.{j}.1;")
            print("default-lease-time 86400;")
            print("max-lease-time 86400; }")


main()
