#!/usr/bin/env sh
set -e
set -v # for debug

###
# This script mainly removes NAT from adaptor 1, and replace it with bridged for all machines
# This works only if provider is virtualbox
###

# Optionally, when started with params like reset or init, it also does vagrant up, etc.
while [ $# -gt 0 ]; do
 case $1 in
  full)
    vagrant destroy -f || true
    vagrant up
    shift
  ;;
 esac
done

### Configuration:
# If required, change the interface in the line below:
HOST_BRIDGED_INTERFACE=`ip route | grep default | head -1 | cut -d" " -f5`

# How to start
VAGRANT_LOG=info # debug,info,warn,error
#vagrant up

###  Stop all machines for reconfiguration:
for runningVagrM in $(vagrant status | grep 'running (virtualbox)' | cut -d" " -f1); do
  vagrant halt $runningVagrM
done


### Get list of all already powered off machines:
filter_machines_offvagm=$(vagrant status | grep 'poweroff (virtualbox)' | cut -d" " -f1)

[[ -z $filter_machines_offvagm ]] && echo "There is no machine to manage, exit now" && error_now

### Get list of machines created for local Vagrantfile in the current directory
filter_machines_local_directory=$(basename `pwd`)  # note: cannot run it from /

### Reconfigure the interfaces, disabling the NAT and making first interface bridged with
for M in $(VBoxManage list vms | grep -v inaccessible | grep $filter_machines_offvagm | grep $filter_machines_local_directory | cut -d'"' -f2  ); do
  #VBoxManage showvminfo $M | grep -i nic    #"--machinereadable" # for debug
  VBoxManage modifyvm $M --nic1 none --nic2 none --nic3 none --nic4 none --nic5 none --nic6 none --nic7 none --nic8 none
  VBoxManage modifyvm $M --nic1 bridged --bridgeadapter1 $HOST_BRIDGED_INTERFACE --nictype1 82540EM --macaddress1 auto
  #VBoxManage modifyvm $M --nic2 nat --nictype2 82540EM --macaddress2 auto --natnet2 "10.0.2.0/24" --natpf2 "ssh,tcp,127.0.0.1,2222,,22" --natdnsproxy2 off --natdnshostresolver2 off # This is optional, and not useful as vagrant always wants nat on 1st interface
  VBoxManage startvm $M --type headless  # DO NOT USE 'vagrant up', use VBoxManage startvm command
done
vagrant status

### Make ssh use the vagrant generated ssh keys
all_runningVagrMs=$(vagrant status | grep 'running (virtualbox)' | cut -d" " -f1)
rm -f ssh_config
for runningVagrM in $all_runningVagrMs ; do
  vagrant ssh-config $runningVagrM | sed "s|^ *HostName .*|  HostName $runningVagrM|g" | sed "s|^ *Port .*|  Port 22|g" >>local_ssh_config
done

echo -e "to ssh into any of the machines ($all_runningVagrMs), run like this: \n ssh -f ./ssh_config $runningVagrM "

### Create an ansible.cfg to use the above file and some more options
cat << EOF >ansible.cfg
[defaults]
remote_user=vagrant
become=true
become_method=sudo

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -F ./ssh_config
EOF

### Generate (guess) inventory file based on host names (master must have wokrd master in it)
echo "[master]" > hosts
echo $all_runningVagrMs | grep "master" >> hosts
echo "[node]" >> hosts
echo $all_runningVagrMs | grep -v "master" >> hosts

