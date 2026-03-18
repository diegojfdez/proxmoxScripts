"""
DHCP server Interfaces Generator

Inputs
- @1 Initial 2nd IP Byte
- @2  Final 2nd IP Byte
- @3 Number of students

Assumptions
- Bridge interface name will be vmbrXXYY

where XX is the 2nd IP byte
and YY is the student number


"""

import sys
#import datetime, os, time
#import hashlib

def main():
    
    iniIP = int(sys.argv[1])
    endIP = int(sys.argv[2])
    numberOfStudents = int(sys.argv[3])
    
    for i in range(iniIP, endIP+1):
        i = str(i).zfill(2)
        for j in range(numberOfStudents+1):
            j=str(j).zfill(2)
            print(f"vmbr{i}{j}", end=" ")
    print()
            

main()
