#!/usr/bin/env sh
set -e
#set -v
###
# This script mainly removes NAT from adaptor 1, and replace it with bridged for all machines
# If required, change the interface in the line below or pass as a parameter: --bridged_adapter
HOST_BRIDGED_INTERFACE=`ip route | grep default | head -1 | cut -d" " -f5`
# This is the same interface you may want to set in the Vagrantfile (or prompting you for)
# This entire script works only with virtualbox provider
# The script also modifies storage controller from IDE to SATA, and moves the disk from IDE to the newly created SATA 
###

if [ $# -eq 0 ];then

cat <<EOF
Use any of these options:
--full # which does: vagrant destroy (if anything existed before), vagrant up (create machines),i vagrant halt (for config), fix bridged adaptor, start machines with VBoxManage startvm, generate ansible.cfg and hosts file (ansible inventory).
--bridged_adapter <host_adapter> | auto # which does:  vagrant halt (for config), fix bridged adaptor, change from IDE to SATA, start machines with VBoxManage startvm, generate ansible.cfg and hosts file (inventory).
--restart # which does only: vagrant halt and  start machines with VBoxManage startvm.
--regenerate_config # which only regenerates ansible.cfg and hosts file (ansible inventory)
NOTE: ONLY ONE OPTION AT A TIME
EOF

exit 1
fi


# Optionally, when started with params like reset or init, it also does vagrant up, etc.
while [ $# -gt 0 ]; do
 case $1 in
  --full) 
    vagrant destroy -f || true
    vagrant up
    shift
    break
  ;;
  --bridged_adapter)
    if [ "${2}x" != "autox" ]; then
      HOST_BRIDGED_INTERFACE=$2
    fi
    shift
    shift
    break
  ;;
  --restart)
    ACTIONS=restart
    shift
    break
  ;;
  --regenerate_config)
    ACTIONS=regenerate_config
    shift
    break
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
 if [ "${ACTIONS}x" = "restartx" ];then
  echo "### Restart VMs"
  for vagrantM in ${filter_machines_offvagm}; do
    #for vboxM in $(VBoxManage list vms | grep -v inaccessible | grep $vagrantM | grep $filter_machines_local_directory | cut -d'"' -f2  ); do
    for vboxMUUID in $(VBoxManage list vms | grep -v inaccessible | grep $vagrantM | grep $filter_machines_local_directory | cut -d'{' -f2 | tr -d '}' ); do #UsesUUID
      VBoxManage startvm $vboxMUUID --type headless  # DO NOT USE 'vagrant up', use VBoxManage startvm command
    done
  done
  vagrant status
  echo "Start vm triggered (via VBoxManage startvm). Once up, proceed with login using ssh -F ssh_config <host>; to check status use: vagrant status"
  exit 0
 fi

 ###
 echo "### Reconfiguring machines ${filter_machines_offvagm}"

 if [ "${HOST_BRIDGED_INTERFACE}x" = "x" ]; then
  HOST_BRIDGED_INTERFACE=`ip route | head -1 | cut -d" " -f5`
  echo "!WARNING!: There was no interface provided, and is no default interface on this machine. Going to use: $HOST_BRIDGED_INTERFACE"
 fi
 #set -vx
 for vagrantM in ${filter_machines_offvagm}; do
  vagrantM_nodot=$(echo $vagrantM| tr -d ".")
  #for vboxM in $(VBoxManage list vms | grep -v inaccessible | grep $vagrantM | grep $filter_machines_local_directory | cut -d'"' -f2  ); do #Uses names
  for vboxMUUID in $(VBoxManage list vms | grep -v inaccessible | grep $vagrantM_nodot | grep $filter_machines_local_directory | cut -d'{' -f2 | tr -d '}' ); do #UsesUUID
    echo "Modifying the interfaces, disabling the NAT and making first interface bridged with for vagrantM=$vagrantM (vboxMUUID=$vboxMUUID)"
    #### Change VM's network interfaces, NAT to bridged:

    #VBoxManage showvminfo $M | grep -i nic    #"--machinereadable"
    VBoxManage modifyvm $vboxMUUID --nic1 none --nic2 none --nic3 none --nic4 none --nic5 none --nic6 none --nic7 none --nic8 none 
    VBoxManage modifyvm $vboxMUUID --nic1 bridged --bridgeadapter1 $HOST_BRIDGED_INTERFACE --nictype1 virtio --macaddress1 auto
    #VBoxManage modifyvm $vboxMUUID --nic1 bridged --bridgeadapter1 $HOST_BRIDGED_INTERFACE --nictype1 Am79C973 --macaddress1 auto
    #VBoxManage modifyvm $vboxMUUID --nic1 bridged --bridgeadapter1 $HOST_BRIDGED_INTERFACE --nictype1 virtio --macaddress1 auto
    #VBoxManage modifyvm $vboxMUUID --nic1 bridged --bridgeadapter1 $HOST_BRIDGED_INTERFACE --nictype1 82540EM --macaddress1 auto
    #VBoxManage modifyvm $vboxMUUID --nic2 nat --nictype2 82540EM --macaddress2 auto --natnet2 "10.0.2.0/24" --natpf2 "ssh,tcp,127.0.0.1,2222,,22" --natdnsproxy2 off --natdnshostresolver2 off # This is optional

    #### (optional but recommended), change disk IDE TO SATA". Centos comes by default with unperformant controller: IDE (not SATA/SCSI/etc)
    echo "Modifying the controller from IDE to SATA for vagrantM=$vagrantM (vboxMUUID=$vboxMUUID)"
    # Get disk
    #IDE_VMDK_PATH=$(VBoxManage showvminfo --machinereadable $vboxMUUID | grep -i "IDE" | grep '\.vmdk' | cut -d '"' -f4)
    IDE_VMDK_ImageUUID=$(VBoxManage showvminfo --machinereadable $vboxMUUID | grep -i "IDE" | grep ImageUUID | cut -d '"' -f4)
    if [ "${IDE_VMDK_ImageUUID}x" != "x" ]; then
      echo "Changind disk from IDE to SATA for disk IDE_VMDK_ImageUUID=$IDE_VMDK_ImageUUID "
      VBoxManage storagectl $vboxMUUID --name "IDE Controller" --remove || true # remove IDE controller 
      VBoxManage storagectl $vboxMUUID --name "IDE" --remove || true # remove IDE controller 
      VBoxManage storagectl $vboxMUUID --name "SATA" --add sata --portcount 3 --hostiocache on --bootable on  # Add SATA controller
      VBoxManage storageattach $vboxMUUID --storagectl "SATA" --port 0 --type hdd --nonrotational on --medium $IDE_VMDK_ImageUUID  # Attach the previous disk to the new SATA controller
      #For SSD optionally add also: "--nonrotational on"

    fi

    #### Start the VM:
    VBoxManage startvm $vboxMUUID --type headless  # DO NOT USE 'vagrant up', use VBoxManage startvm command
  done
 done

 ###
 echo "  Machines were reconfigured and restarted. This is the vagrant status for virtuabox machines:"
 vagrant status | grep '(virtualbox)'

fi # Up to here we did actions when if [ "${ACTIONS}" != "regenerate_configx" ]

###
echo "### Generating the list of machines which are up:"
all_runningVagrMs=$(vagrant status | grep 'running (virtualbox)' | cut -d" " -f1)
echo "   List of already started machines: $all_runningVagrMs" | tr '\n' ' ' 
echo ""

###
echo "### (re)Generating a ssh_config to be used by ssh (partially reusing vagrant generated ssh keys and config)"
rm -f ssh_config
for runningVagrM in $all_runningVagrMs ; do
  vagrant ssh-config $runningVagrM | sed "s|^Host .*|Host ${runningVagrM}\*|g" | sed "/^ *HostName .*/d" | sed "s|^ *Port .*|  Port 22|g" | sed "s|^ *User .*|  User root|g" >>ssh_config
done

###
#When below is enabled, ansible won't be able to run
#echo "### update ~vagrant/.ssh/authorized_keys inside each machine to automatically switch to root user (instead of vagrant) "
#set -vx
#for runningVagrM in $all_runningVagrMs ; do
#  ssh -F ./ssh_config $runningVagrM sed -i \'s#^ssh-#command=\"sudo -iu root\" ssh-#g\' ~vagrant/.ssh/authorized_keys
#done
#set +vx

### 
echo "### Creating list of machines with FQDN"
runningVagrM_FQDN=""
for runningVagrM in $all_runningVagrMs ; do
  runningVagrM_FQDN="${runningVagrM_FQDN} `ping -c 1 ${runningVagrM} | head -1 |cut -d " " -f2`"
done
echo "  List of FQDN for the vagrant machines: $runningVagrM_FQDN"

###
number_hosts_nonfqdn=`echo $all_runningVagrMs | wc -l`
number_hosts_fqdn=`echo $runningVagrM_FQDN | wc -l`

if [ $number_hosts_nonfqdn -ne $number_hosts_fqdn ]; then
  echo "!WARNING!: FQDN is not properly set. Trying without..."
  use_FQDN=0
  all_runningVagrMs_postfqdn=$all_runningVagrMs
else
  use_FQDN=1
  all_runningVagrMs_postfqdn=$runningVagrM_FQDN
fi

echo "  To ssh into any of the machines, run like this: "
echo ""
#for M in ${all_runningVagrMs} ; do
for M in ${all_runningVagrMs_postfqdn} ; do
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
stdout_callback = debug

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -F ./ssh_config 
pipelining = True
EOF

echo "  a local ./ansible.cfg has been generated with success. Contents:"
cat ansible.cfg
echo

###
echo "### Generating (guessing) inventory file based on host names (master must have word master in its name)"
echo "[master]" > hosts
#echo $all_runningVagrMs | tr ' ' '\n' | grep "master" >> hosts
echo $all_runningVagrMs_postfqdn | tr ' ' '\n' | grep "master" >> hosts
echo "[node]" >> hosts
#echo $all_runningVagrMs | tr ' ' '\n' | grep -v "master" >> hosts
echo $all_runningVagrMs_postfqdn | tr ' ' '\n' | grep -v "master" >> hosts
number_nodes=$( echo $all_runningVagrMs_postfqdn | tr ' ' '\n' | grep -v "master" | wc -l )
if [ $number_nodes -lt 1 ]; then
  echo "no nodes were detected, so master will be also a node"
  echo $all_runningVagrMs_postfqdn | tr ' ' '\n' | grep "master" >> hosts
fi

echo
echo "### The autogenerated inventory (./hosts file) looks like this:"
cat hosts

cat <<EOF

### Vagrant should be up.
   You may now proceed wth reviewing configuration:
       vi group_vars/all 
   and then run ansible playbooks like site.yml 
       ansible-playbook -i hosts -v site.ym"
EOF


