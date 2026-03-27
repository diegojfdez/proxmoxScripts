#!/usr/bin/env bash

# Will try to add to community-scripts ORG
# Author: DJFR
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Usage
# To use the PVE Containers Deletion script, run the command below **only** in the Proxmox VE Shell. This script is intended for managing or enhancing the host system directly.
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/create-groups.sh)"

function header_info {
  clear
  cat <<"EOF"
    ____                                          ______            __        _                         ____       __     __  _           
   / __ \_________  _  ______ ___  ____  _  __   / ____/___  ____  / /_____ _(_)___  ___  __________   / __ \___  / /__  / /_(_)___  ____ 
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  / /   / __ \/ __ \/ __/ __ `/ / __ \/ _ \/ ___/ ___/  / / / / _ \/ / _ \/ __/ / __ \/ __ \
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /___/ /_/ / / / / /_/ /_/ / / / / /  __/ /  (__  )  / /_/ /  __/ /  __/ /_/ / /_/ / / / /
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|   \____/\____/_/ /_/\__/\__,_/_/_/ /_/\___/_/  /____/  /_____/\___/_/\___/\__/_/\____/_/ /_/                                                                                                                                                                                                                                                                                                                                                                             
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "containers-delete" "pve"



# $1 Optional student lowest CT ID. Default 100000
# $2 Optional student highest CT ID. Default 2000000
minCTID=${1:-100000}
maxCTID=${2:-2000000}

NODE=$(hostname)

header_info
echo "Loading..."
whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Containers Deletion" --yesno "This will erase all students not running Containers in $NODE. Proceed?" 10 58


containersList=$(pct list 2>/dev/null|tail +2)
#poolIds=$(pveum pool list --output-format text --noborder --noheader | awk '{print $1}')

FORMAT="%-10s %-2s" # %-10s"

if [ -z "$containersList" ]; then
  echo -e "${BL}[Info]${GN} No containers on $NODE.${CL}"
  exit 0
fi

i=0
while read -r container; do
  ctid=$(echo $container | awk '{print $1}')
  ctState=$(echo $container | awk '{print $2}')
  if [ "stopped" == "$ctState" ]; then 
    cts[$i]=$ctid
    let i=i+1
  elif [ "running" == "$ctState" ]; then 
    echo -e "${BL}[Info]${YW} Container $ctid IS RUNNING and thus WILL NOT BE DELETED ...${CL}"
    echo -e "${BL}[Info]${GN} Stopping it for a later try...${CL}"
    echo -e "pct stop $ctid --skiplock 1"
  else
    echo -e "${BL}[Info]${YW} Container $ctid is in $ctState STATE and thus WILL NOT BE DELETED ...${CL}"
  fi
done <<<"$containersList"

indexes="${!cts[@]}" 
if [ -z "$indexes" ]; then
  echo -e "${BL}[Info]${GN} No containers STOPPED on $NODE.${CL}"
  exit 0
fi

for i in ${!cts[@]}; do
  # Will skip if ID is not in students range
  if [ ${cts[$i]} -ge $minCTID ] && [ ${cts[$i]} -le $maxCTID ]; then 
    echo -e "${BL}[Info]${GN} Deleting container ${cts[$i]}...${CL}"
    # Preproduction version (only print command)
    echo -e "pct destroy ${cts[$i]} --force 1 --purge 1"
    # TO-DO Succeded?
    if [ -n "1" ]; then
      echo -e "${BL}[Info]${GN} Container ${cts[$i]} deleted.${CL}"
    else
      echo -e "${BL}[Info]${YW} Container ${cts[$i]} WAS NOT deleted ...${CL}"
    fi
  else
    echo -e "${BL}[Info]${GN} Container ${cts[$i]} skipped.${CL}"
  fi
  sleep .2
done

header_info
echo -e "${GN}Deletion process completed.${CL}\n"
