"""
Proxmox Server Bridge Interfaces Generator

Inputs
- @1 Initial 2nd IP Byte
- @2  Final 2nd IP Byte
- @3 Number of students
- @4 Comment for Bridge Interface

Assumptions
- Bridge interface name will be vmbrXXYY

where XX is the 2nd IP byte
and YY is the student number

#2SMR Alumnos
 
+auto vmbrXXYY
+iface vmbr0601 inet static
+	address 10.6.1.1/24
+	bridge-ports none
+	bridge-stp off
+	bridge-fd 0
+#2SMR Alumnos

"""

import sys
#import datetime, os, time
#import hashlib

def main():
    
    iniIP = int(sys.argv[1])
    endIP = int(sys.argv[2])
    numberOfStudents = int(sys.argv[3])
    comment = sys.argv[4]
    
    for i in range(iniIP, endIP+1):
        ii = str(i).zfill(2)
        for j in range(numberOfStudents+1):
            jj=str(j).zfill(2)
            #print(f"# {comment}")
            print()
            print(f"auto vmbr{ii}{jj}")
            print(f"iface vmbr{ii}{jj} inet static")
            print(f"  address 10.{i}.{j}.1/24")
            print("  bridge-ports none")
            print("  bridge-stp off")
            print("  bridge-fd 0")
            print(f"# {comment}")
            print()

main()
