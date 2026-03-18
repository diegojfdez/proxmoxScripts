#!/usr/bin/env bash

# Copyright (c) 2026-2030 community-scripts ORG
# Author: DJFR
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Usage
# To use the PVE Group Creation script, run the command below **only** in the Proxmox VE Shell. This script is intended for managing or enhancing the host system directly.
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/create-groups.sh)"

function header_info {
  clear
  cat <<"EOF"
    ____                                          ______                          __  __                       ____       __     __  _           
   / __ \_________  _  ______ ___  ____  _  __   / ____/________  __  ______     / / / /_______  __________   / __ \___  / /__  / /_(_)___  ____ 
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  / / __/ ___/ __ \/ / / / __ \   / / / / ___/ _ \/ ___/ ___/  / / / / _ \/ / _ \/ __/ / __ \/ __ \
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /_/ / /  / /_/ / /_/ / /_/ /  / /_/ (__  )  __/ /  (__  )  / /_/ /  __/ /  __/ /_/ / /_/ / / / /
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|   \____/_/   \____/\__,_/ .___/   \____/____/\___/_/  /____/  /_____/\___/_/\___/\__/_/\____/_/ /_/ 
                                                                    /_/                                                                          
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "group-users-delete" "pve"

header_info
echo "Loading..."
#whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Group Users Deletion" --yesno "This will erase PVE Group Users. Proceed?" 10 58


NODE=$(hostname)
#groups=$(pveum group list --output-format text --noborder --noheader | awk '{print $1}')
#description=$(pveum group list --output-format text --noborder --noheader | cut -c17-55)
#users=$(pveum group list --output-format text --noborder --noheader | cut -c57-)
groupUsers=$(pveum group list --output-format text --noborder --noheader | cut -c-16,57-)
poolIds=$(pveum pool list --output-format text --noborder --noheader | awk '{print $1}')
#if [ -z "$containers" ]; then
#  whiptail --title "Proxmox VE Group Management" --msgbox "No Groups available!" 10 60
#  exit 234
#fi

#menu_items=("ALL" "Manage All Groups" "OFF") # Add as first option
FORMAT="%-10s %-2s" # %-10s"

i=0
while read -r group; do
  groupid=$(echo $group | awk '{print $1}')
  groups[$i]=$groupid
  users[$i]=$(echo $group | awk '{print $2}') 
  someUsers=$(echo ${users[$i]} | cut -c-60 )
  formatted_line=$(printf "$FORMAT" "$groupid" "$someUsers")
  menu_items+=("$i" "$formatted_line" "OFF")
  let i=i+1
done <<<"$groupUsers"

CHOICES=$(whiptail --title "PVE Group Users Deletion" \
  --checklist "Select Group(s) to Delete its Users:" 25 100 13 \
  "${menu_items[@]}" 3>&2 2>&1 1>&3)

if [ -z "$CHOICES" ]; then
  whiptail --title "PVE Group User Deletion" \
    --msgbox "No groups selected!" 10 60
  exit 0
fi

selected_ids=$(echo "$CHOICES" | tr -d '"' | tr -s ' ' '\n')
echo "EL $selected_ids"

read -p "Try to delete users pools automatically? (Default: auto) m/a: " DELETE_MODE
DELETE_MODE=${DELETE_MODE:-a}

# If "ALL" is selected, override with all container IDs
#if echo "$selected_ids" | grep -q "^ALL$"; then
#  selected_ids=$(echo "$containers" | awk '{print $1}')
#fi

for gid in $selected_ids; do
  echo "Grupo $gid"
  echo ${groups[$gid]}
  echo ${users[$gid]}
  usersSel=$(echo ${users[$gid]} | tr -s ',' ' ')
  for userid in $usersSel; do
    echo -e "${BL}[Info]${GN} Deleting user $userid...${CL}"
    echo -e "pveum user delete $userid"
    if [[ "$DELETE_MODE" == "a" ]]; then
      poolID=$(echo $userid|cut -d'@' -f1)
      poolFound=$(echo $poolIds | grep -F -w -q "$poolID")
      if [ -z "$poolFound" ]; then
        echo -e "${BL}[Info]${GN} Found pool...${CL}"
        echo -e "pveum pool delete $poolID"
        echo -e "${BL}[Info]${GN} Pool $userid deleted.${CL}"
      else
        echo -e "${BL}[Info]${YW} Pool not found...${CL}"
      fi
    fi
    echo -e "${BL}[Info]${GN} User $userid deleted.${CL}"
    sleep .5
  done
done

exit

header_info
echo -e "${GN}Deletion process completed.${CL}\n"
