#!/usr/bin/env sh
set -e 
      # Ubuntu
      #sudo apt-get update
      #sudo apt-get install -y git docker #ansible

      # CentOS/RHEL
      #sudo yum install -y git docker ansible curl tar zip unzip
      #ssh-copy-id
      sudo yum install -y docker iptables-services 
      sudo sh -c 'echo EXTRA_STORAGE_OPTIONS=\"--storage-opt overlay2.override_kernel_check=true\">/etc/sysconfig/docker-storage-setup'
      sudo sh -c 'echo STORAGE_DRIVER=\"overlay2\" >>/etc/sysconfig/docker-storage-setup'
      sudo rm -f /etc/sysconfig/docker-storage || true

# Firewalld (and selinux) do not play well with k8s (and especially with kubeadm). 
# NOTE: A machine reboot may be required if SELinux was enforced previously
systemctl stop firewalld || true
systemctl disable firewalld || true
systemctl mask firewalld || true
systemctl start iptables
systemctl enable iptables
systemctl unmask iptables

      sudo systemctl stop docker
      sudo systemctl start docker-storage-setup
      sudo systemctl restart docker
      sudo systemctl enable docker
      #sudo chown vagrant /var/run/docker.sock # optional

# SET Default Policies to ACCEPT
iptables -P FORWARD ACCEPT
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# Remove the Default REJECT rules, so it will hit the default Policy
iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited
iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited

# If someone wants to enable only some ports (there will be many, and most of them dynamic), here is a start: 6443 (k8s api), 10250, etc. (maybe both tcp and udp...)
#sudo iptables -I INPUT -p tcp --dport 6443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
#sudo iptables -I OUTPUT -p tcp --sport 6443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# DEBUG LIVE WITH:
# watch -n1 iptables -vnL
