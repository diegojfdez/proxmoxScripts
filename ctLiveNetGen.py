"""
Proxmox Server ct-live-network Network Config Generator

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
import datetime
import time
#import hashlib

def generate_mac():
    """
    Generates the last 3 MAC address octets based on the current number of
    milliseconds since the Unix epoch (January 1, 1970, UTC).

    This method is highly unlikely to produce collisions as the timestamp
    is a continuously incrementing value.

    Returns:
        str: A string in 'aa:bb:cc' format representing the last three
             octets of the millisecond timestamp.
    """
    # Get the current time in milliseconds since the epoch
    ns_since_epoch =time.time_ns()
    # Take the last 3 octets (24 bits) of the timestamp value
    # This is equivalent to taking the last 6 hexadecimal digits
    last_three_octets = ns_since_epoch & 0xFFFFFF

    # Convert the value to a 6-digit hexadecimal string, padded with leading zeros
    hex_string = f'{last_three_octets:06X}'

    # Split the string into three pairs and format with colons
    aa = hex_string[0:2]
    bb = hex_string[2:4]
    cc = hex_string[4:6]

    return f'{aa}:{bb}:{cc}'

def main():
    netID = 1
    iniIP = int(sys.argv[1])
    endIP = int(sys.argv[2])
    numberOfStudents = int(sys.argv[3])
#    comment = sys.argv[4]
    for i in range(iniIP, endIP+1):
        ii = str(i).zfill(2)
        for j in range(numberOfStudents+1):
            jj = str(j).zfill(2)
            mac = generate_mac()
            #print(f"# {comment}")
            print(f"net{netID}: name=net{ii}{jj},bridge=vmbr{ii}{jj},firewall=0,hwaddr=BC:24:11:{mac},ip=10.{i}.{j}.2/24,type=veth")
            netID += 1

main()
