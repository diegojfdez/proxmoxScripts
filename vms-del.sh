#!/usr/bin/env bash

# Will try to add to community-scripts ORG
# Author: DJFR
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Usage
# To use the PVE VMs Deletion script, run the command below **only** in the Proxmox VE Shell. This script is intended for managing or enhancing the host system directly.
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/create-groups.sh)"

function header_info {
  clear
  cat <<"EOF"
     ____                                          _    ____  ___        ____       __     __  _           
   / __ \_________  _  ______ ___  ____  _  __   | |  / /  |/  /____   / __ \___  / /__  / /_(_)___  ____ 
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/   | | / / /|_/ / ___/  / / / / _ \/ / _ \/ __/ / __ \/ __ \
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <     | |/ / /  / (__  )  / /_/ /  __/ /  __/ /_/ / /_/ / / / /
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|     |___/_/  /_/____/  /_____/\___/_/\___/\__/_/\____/_/ /_/                                                                                                           
EOF
}

spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while ps -p $pid >/dev/null; do
    printf " [%c]  " "$spinstr"
    spinstr=${spinstr#?}${spinstr%"${spinstr#?}"}
    sleep $delay
    printf "\r"
  done
  printf "    \r"
}

set -eEuo pipefail
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
TAB="  "
CM="${TAB}✔️${TAB}${CL}"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "vms-delete" "pve"



# $1 Optional student lowest VMs ID. Default 100000
# $2 Optional student highest VMs ID. Default 2000000
minMVID=${1:-100000}
maxVMID=${2:-2000000}

NODE=$(hostname)

header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE VMs Deletion" --yesno "This will erase all students not running VMs in $NODE. Proceed?" 10 58


vmsList=$(qm list | tail +2)

FORMAT="%-10s %-2s" # %-10s"

if [ -z "$vmsList" ]; then
  echo -e "${BL}[Info]${GN} No VMs on $NODE.${CL}"
  exit 0
fi

i=0
while read -r vm; do
  vmid=$(echo $vm | awk '{print $1}')
  vmState=$(echo $vm | awk '{print $3}')
  if [ "stopped" == "$vmState" ]; then 
    vms[$i]=$vmid
    let i=i+1
  elif [ "running" == "$vmState" ]; then 
    echo -e "${BL}[Info]${YW} VM $vmid IS RUNNING and thus WILL NOT BE DELETED ...${CL}"
    echo -e "${BL}[Info]${GN} Stopping it for a later try...${CL}"
    echo -e "qm stop ${vms[$i]} --skiplock 1"
  else
    echo -e "${BL}[Info]${YW} VM $vmid is in $vmState STATE and thus WILL NOT BE DELETED ...${CL}"
  fi
done <<<"$vmsList"

indexes="${!vms[@]}" 
if [ -z "$indexes" ]; then
  echo -e "${BL}[Info]${GN} No VMs STOPPED on $NODE.${CL}"
  exit 0
fi

for i in ${!vms[@]}; do
  # Will skip if ID is not in students range
  if [ ${vms[$i]} -ge $minCTID ] && [ ${vms[$i]} -le $maxCTID ]; then 
    echo -e "${BL}[Info]${GN} Deleting container ${cts[$i]}...${CL}"
    # -purge: removes from backup/replication/HA
    # -destroy-unreferenced-disks: cleans up orphaned disks matching VMID
    # Preproduction version (only print command)
    echo -e "qm destroy $vmid --purge 1 --destroy-unreferenced-disks 1"
    
    # Succeded?
    if [ $? -eq 0 ]; then
      echo -e "${BL}[Info]${GN} VM ${vms[$i]} deleted.${CL}"
    else
      echo -e "${BL}[Info]${YW} VM ${vms[$i]} WAS NOT deleted ...${CL}"
    fi
  else
    echo -e "${BL}[Info]${GN} VM ${vms[$i]} skipped.${CL}"
  fi
  sleep .2
done

exit
header_info
echo -e "${GN}Deletion process completed.${CL}\n"



