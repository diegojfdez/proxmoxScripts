#!/usr/bin/env bash

# Will try to add to community-scripts ORG
# Author: DJFR
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Usage
# To use the PVE Group Users Add script, run the command below **only** in the Proxmox VE Shell. This script is intended for managing or enhancing the host system directly.
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/create-groups.sh)"

function header_info {
  clear
  cat <<"EOF"
    ____                                          ______                          __  __                       ___       __    ___ __  _           
   / __ \_________  _  ______ ___  ____  _  __   / ____/________  __  ______     / / / /_______  __________   /   | ____/ /___/ (_) /_(_)___  ____ 
  / /_/ / ___/ __ \| |/_/ __ `__ \/ __ \| |/_/  / / __/ ___/ __ \/ / / / __ \   / / / / ___/ _ \/ ___/ ___/  / /| |/ __  / __  / / __/ / __ \/ __ \
 / ____/ /  / /_/ />  </ / / / / / /_/ />  <   / /_/ / /  / /_/ / /_/ / /_/ /  / /_/ (__  )  __/ /  (__  )  / ___ / /_/ / /_/ / / /_/ / /_/ / / / /
/_/   /_/   \____/_/|_/_/ /_/ /_/\____/_/|_|   \____/_/   \____/\__,_/ .___/   \____/____/\___/_/  /____/  /_/  |_\__,_/\__,_/_/\__/_/\____/_/ /_/ 
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
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "group-users-add" "pve"

header_info
echo "Loading..."
#whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Group Users Addition" --yesno "This will add PVE Users to Groups. Proceed?" 10 58

#NODE=$(hostname)
DOMAIN='institutodh.net'

# CSV file format
# "Pupil","ID/Passaport","Unit"
# "Surname1 Surname2, Name1 Name2","ID","GROUP"
inputFile=${1:-"RegAlum.csv"}
inputFileTrans="RegAlumT.csv"

# Transliteration: Remove accented characters, ñs and so the like from the CSV file
iconv -c -t ASCII//TRANSLIT -f ISO-8859-1  $inputFile > $inputFileTrans

# Extract unit
unit=$(tail -1 $inputFileTrans | sed  's/\"\,\"/\"\;\"/'g | awk -F';' '{print $3}'| sed 's/[^[:alnum:]]\+//g'| sed -E 's/([[:digit:]])o/\1/')
#echo $unit


groups=$(pveum group list --output-format text --noborder --noheader|awk '{print $1}')
poolIds=$(pveum pool list --output-format text --noborder --noheader | awk '{print $1}')
pveUsers=$(pveum user list --output-format text --noborder --noheader | awk '{print $1}')

# Test if group exists
if [ -z $(echo $groups | grep -F -w -o "$unit") ]; then
  echo -e "${BL}[Error]${YW} Group \n \"$unit\"\n not found...${CL}"
  exit 127 # Soon replace for group creation
fi

# Extract IDs and Student Names
students=$(tail +2 $inputFileTrans | sed  's/\"\,\"/\"\;\"/'g | awk -F';' '{print $2";"$1}' | tr -d '\"')
# echo $students

# Loop students to generate various fields for pveum user and pvem pool
i=0
while read -r student; do
  id=$(echo $student | awk -F';' '{print $1}')

  #Get IDs
  IDs[$i]=$id
  #echo ${IDs[$i]}
  
  #Get Student Names
  aStudentNames[$i]=$(echo -n $student | awk -F';' '{print $2}') 
#  echo ${aStudentNames[$i]}
  # Generate userid from surnames, first name and ID
  username=$(echo -n ${aStudentNames[$i]} | tr '[:upper:]' '[:lower:]' \
                | sed -E 's/^([a-z].*) ([a-z])[a-z]*?, (([a-z])[a-z]*)[ ]?(([a-z])[a-z]*)?/\4\6\1\2/')
  userids[$i]=$(echo -n "$username$(echo -n ${IDs[$i]} | cut -c6-8)@pve")
 # echo ${userids[$i]}

  # Fullfil Lastnames
  lastNames[$i]=$(echo -n ${aStudentNames[$i]} | cut -d',' -f1)
 # echo ${lastNames[$i]}

  # Fullfil FirstNames
  firstNames[$i]=$(echo -n ${aStudentNames[$i]} | cut -d',' -f2 | cut -c2-)
#  echo ${firstNames[$i]}

  # Fullfil emails
  emails[$i]=$(echo -n "$(echo -n ${userids[$i]} | cut -d'@' -f1)@$DOMAIN")
  #cut  -d'@' -f1 
#  echo ${emails[$i]}

  # Fullfil User's pool comments
  poolUserComments[$i]="${aStudentNames[$i]} pool"
  #echo ${poolUserComments[$i]}

  let i=i+1
done <<<"$students"


# Fullfil User comments
userComments="$unit Student"
#echo $userComments
# Account Expiration = now() + 10 months (26298000 seconds)
expiration=$(echo "$(date +"%s")+26298000"|bc)
#echo $expiration


# Traverse students parallel arrays to create users, ACLs and pools
echo -e "${BL}[Info]${GN} Now we wel start adding user to Group $unit...${CL}"
for j in ${!userids[@]} ;do
  # Test if user exists
  if [ -z $(echo $pveUsers | grep -F -w -o "${userids[$j]}") ]; then
    # create new user
    echo -e "${BL}[Info]${GN} Creating user ${userids[$j]}...${CL}"
    pveum user add ${userids[$j]} \
          --comment "$userComments" \
          --email "${emails[$j]}" \
          --expire $expiration \
          --firstname "${firstNames[$j]}" \
          --lastname "${lastNames[$j]}" \
          --groups "$unit" \
          --password "${IDs[$j]}"
    echo -e "${BL}[Info]${GN} User ${userids[j]} created.${CL}"
    poolName=$(echo "${userids[$j]}"|cut -d'@' -f1)
    if [ -z $(echo $poolIds | grep -F -w -o "$poolName") ]; then
      # create new pool for that user
      echo -e "${BL}[Info]${GN} Creating pool $poolName...${CL}"
      pveum pool add $poolName \
            --comment "${poolUserComments[$j]}"
      echo -e "${BL}[Info]${GN} Pool $poolName created.${CL}" 
    else
      # Skip creation
      echo -e "${BL}[Warning]${YW} Pool ${userids[$j]} already exists...${CL}"
    fi

    # create ACL
    echo -e "${BL}[Info]${GN} Creating ACL for ${userids[$j]}...${CL}"
    pveum acl modify /pool/$poolName \
          --users ${userids[$j]} \
          --roles "PVEPoolUser,PVEVMAdmin"
    echo -e "${BL}[Info]${GN} ACL ${userids[j]} created.${CL}"
  else
    # Skip creation
    echo -e "${BL}[Warning]${YW} User ${userids[$j]} already exists...${CL}"
  fi
  #sleep .1
done

sleep 2 
header_info
echo -e "${GN}Addition process completed.${CL}\n"
