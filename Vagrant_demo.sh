# How to start
vagrant up --parallel

### Make ssh use the vagrant generated ssh keys
for long_machine_path in .vagrant/machines/* ; do 
 machine=$(basename $long_machine_path) ; 
 key=$(echo .vagrant/machines/${machine}/*/private_key ) 
 if [ -r $key ]; then
   cat << EOF >local_ssh_config
Host $machine
     User vagrant
     IdentityFile `pwd`/$key
EOF
 fi

### Create an ansible.cfg to use the above file and some more options
cat << EOF >ansible.cfg
[defaults]
remote_user=vagrant
become=true

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s -F `pwd`/local_ssh_config
EOF

done

curl -SL https://github.com/ReSearchITEng/kubeadm-playbook/archive/master.tar.gz | tar xvz
cd kubeadm-playbook-master
### Generate (guess) inventory file based on hosts currently up
echo "[master]" > hosts
vagrant status | grep 'running (' | cut -d" " -f1 | grep "master" >> hosts
echo "" >> hosts
echo "[node]" >> hosts
vagrant status | grep 'running (' | cut -d" " -f1 | grep -v "master" >> hosts
echo "" >> hosts

cp group_vars/all.example group_vars/all
vi group_vars/all
ansible-playbook -i hosts -vv site.yml
