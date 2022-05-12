#!/bin/sh
# There is no bash on ESXi, only sh (but not a real sh, just busybox).
# Determine the latest ESXi update here:
# https://esxi-patches.v-front.de/

# SSH and Shell are enabled by default on Equinix Metal ESXi servers

echo "Enabling swap"
# Swap must be enabled on the datastore. Otherwise, the upgrade may fail with a "no space left" error.
esxcli sched swap system set --datastore-enabled true
esxcli sched swap system set --datastore-name datastore1

# Update to your specified version of ESXi in the variables.tf file
vim-cmd /hostsvc/maintenance_mode_enter

esxcli network firewall ruleset set -e true -r httpClient

echo "Getting update file and updating"
# The variable esxi_update_filename is in the variables.tf file
esxcli software profile update -d https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml -p ${esxi_update_filename}

esxcli network firewall ruleset set -e false -r httpClient

vim-cmd /hostsvc/maintenance_mode_exit

reboot
