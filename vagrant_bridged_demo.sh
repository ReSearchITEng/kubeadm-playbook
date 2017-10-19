#!/usr/bin/env sh
set -e
#set -v
###
# This script mainly removes NAT from adaptor 1, and replace it with bridged for all machines
# If required, change the interface in the line below or pass as a parameter: --bridged_adapter
HOST_BRIDGED_INTERFACE=`ip route | grep default | head -1 | cut -d" " -f5`
# This is the same interface you may want to set in the Vagrantfile (or prompting you for)
# This entire script works only with virtualbox provider
###

# Optionally, when started with params like reset or init, it also does vagrant up, etc.
while [ $# -gt 0 ]; do
 case $1 in
  --full) 
    vagrant destroy -f || true
    vagrant up
    shift
  ;;
  --bridged_adapter)
    HOST_BRIDGED_INTERFACE=$2
    shift
    shift
  ;;
  --restart)
    ACTIONS=restart
    shift
  ;;
  --regenerate_config)
    ACTIONS=regenerate_config
    shift
  ;;
 esac
done

# How to start
VAGRANT_LOG=info # debug,info,warn,error
#vagrant up

if [ "${ACTIONS}x" != "regenerate_configx" ];then
 ###  Stop all machines for reconfiguration and/or restart, but not when we only want to regenerate config
 for runningVagrM in $(vagrant status | grep 'running (virtualbox)' | cut -d" " -f1); do
   vagrant halt $runningVagrM
 done

 ### Get list of all already powered off machines:
 filter_machines_offvagm=$(vagrant status | grep 'poweroff (virtualbox)' | cut -d" " -f1)

 if [ "${filter_machines_offvagm}x" = "x" ]; then
   echo "There is no machine to manage, exit now"
   exit 1 # && error_now
 fi

 ### Get list of machines created for local Vagrantfile in the current directory
 filter_machines_local_directory=$(basename `pwd`)  # note: cannot run it from /

 ### If the only request is restart, do it and exit
 if [ "${ACTIONS}" = "restartx" ];then
  echo "### Restart VMs"
  for vagrantM in ${filter_machines_offvagm}; do
   for vboxM in $(VBoxManage list vms | grep -v inaccessible | grep $vagrantM | grep $filter_machines_local_directory | cut -d'"' -f2  ); do
    VBoxManage startvm $vboxM --type headless  # DO NOT USE 'vagrant up', use VBoxManage startvm command
   done
  done
  vagrant status
  echo "Start vm triggered (via VBoxManage startvm). Once up, proceed with login using ssh -F ssh_config <host>; to check status use: vagrant status"
  exit 0
 fi

 ###
 echo "### Reconfigure the interfaces, disabling the NAT and making first interface bridged with "
 #set -vx
 for vagrantM in ${filter_machines_offvagm}; do
  for vboxM in $(VBoxManage list vms | grep -v inaccessible | grep $vagrantM | grep $filter_machines_local_directory | cut -d'"' -f2  ); do
    #VBoxManage showvminfo $M | grep -i nic    #"--machinereadable"
    VBoxManage modifyvm $vboxM --nic1 none --nic2 none --nic3 none --nic4 none --nic5 none --nic6 none --nic7 none --nic8 none 
    VBoxManage modifyvm $vboxM --nic1 bridged --bridgeadapter1 $HOST_BRIDGED_INTERFACE --nictype1 82540EM --macaddress1 auto
    #VBoxManage modifyvm $vboxM --nic2 nat --nictype2 82540EM --macaddress2 auto --natnet2 "10.0.2.0/24" --natpf2 "ssh,tcp,127.0.0.1,2222,,22" --natdnsproxy2 off --natdnshostresolver2 off # This is optional
    VBoxManage startvm $vboxM --type headless  # DO NOT USE 'vagrant up', use VBoxManage startvm command
  done
 done

 ###
 echo "  Machines were reconfigured and restarted. This is the vagrant status for virtuabox machines:"
 vagrant status | grep '(virtualbox)'

fi # Up to here we did actions when if [ "${ACTIONS}" != "regenerate_configx" ]

###
echo "### Generating the list of machines which are up:"
all_runningVagrMs=$(vagrant status | grep 'running (virtualbox)' | cut -d" " -f1)
echo "   List of machines: $all_runningVagrMs" | tr '\n' ' ' 
echo ""

### 
echo "### Creating list of machines with FQDN"
runningVagrM_FQDN=""
for runningVagrM in $all_runningVagrMs ; do
  runningVagrM_FQDN="${runningVagrM_FQDN} `ping -c 1 ${runningVagrM} | head -1 |cut -d " " -f2`"
done
echo "  List of FQDN for the vagrant machines: $runningVagrM_FQDN"

###
echo "### (re)Generating a ssh_config to be used by ssh (partially reusing vagrant generated ssh keys and config)"
rm -f ssh_config
for runningVagrM in $all_runningVagrMs ; do
  vagrant ssh-config $runningVagrM | sed "s|^Host .*|Host ${runningVagrM}\*|g" | sed "/^ *HostName .*/d" | sed "s|^ *Port .*|  Port 22|g" | sed "s|User vagrant|User root|g" >>ssh_config
done

###
#When below is enabled, ansible won't be able to run
#echo "### update ~vagrant/.ssh/authorized_keys inside each machine to automatically switch to root user (instead of vagrant) "
#set -vx
#for runningVagrM in $all_runningVagrMs ; do
#  ssh -F ./ssh_config $runningVagrM sed -i \'s#^ssh-#command=\"sudo -iu root\" ssh-#g\' ~vagrant/.ssh/authorized_keys
#done
#set +vx

echo "  To ssh into any of the machines, run like this: "
echo ""
#for M in ${all_runningVagrMs} ; do
for M in ${runningVagrM_FQDN} ; do
  echo "ssh -F ./ssh_config $M "
done
echo

###
echo "### Creating an ./ansible.cfg to based on the above ssh_config file and some more options, for ansible to be able to login "
cat << EOF >ansible.cfg
[defaults]
#remote_user=vagrant
become=true
become_method=sudo

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -F ./ssh_config 
EOF
echo "  a local ./ansible.cfg has been generated with success"
echo

###
echo "### Generating (guessing) inventory file based on host names (master must have word master in its name)"
echo "[master]" > hosts
#echo $all_runningVagrMs | tr ' ' '\n' | grep "master" >> hosts
echo $runningVagrM_FQDN | tr ' ' '\n' | grep "master" >> hosts
echo "[node]" >> hosts
#echo $all_runningVagrMs | tr ' ' '\n' | grep -v "master" >> hosts
echo $runningVagrM_FQDN | tr ' ' '\n' | grep -v "master" >> hosts
echo
echo "  the prepared inventory (./hosts file) looks like this:"
cat hosts

echo -e "You may proceed reviewing configuration with:\n vi group_vars/all \n and then run ansible playbooks like site.yml \n ansible-playbook -i hosts -v site.yml "


