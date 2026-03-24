# proxmoxScripts
Various Shell scripts to manage Bridges, Users, Groups and Pools in Proxmox VE.

### Scripts description

**group-users-del.sh**: An interactive administration utility designed to facilitate the bulk removal of users within specific Proxmox VE groups. The script enumerates existing PVE groups and their constituent members, allowing for targeted selection and deletion. Additionally, it provides an optional routine to decommission associated resource pools tied to the selected user accounts.

**group-users-add.sh** The script ensures the target Security Group exists within the PVE realm. It then iterates through a defined user list in CSV format, creating accounts with standardized credentials and assigning them to the centralized group.
For every user created, the script automatically generates a dedicated Resource Pool. It applies Access Control Lists (ACLs) to the newly created pools, granting the specific user administrative roles PVEVMAdmin and PVEPoolUser.
