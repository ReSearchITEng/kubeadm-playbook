#!/usr/bin/env sh
set -e 
      # Ubuntu
      #sudo apt-get update
      #sudo apt-get install -y git docker #ansible

      # CentOS/RHEL
      #sudo yum install -y git docker ansible curl tar zip unzip
      #ssh-copy-id
      sudo yum install -y docker
      sudo sh -c 'echo EXTRA_STORAGE_OPTIONS=\"--storage-opt overlay2.override_kernel_check=true\">/etc/sysconfig/docker-storage-setup'
      sudo sh -c 'echo STORAGE_DRIVER=\"overlay2\" >>/etc/sysconfig/docker-storage-setup'
      sudo rm -f /etc/sysconfig/docker-storage || true
      sudo systemctl stop docker
      sudo systemctl start docker-storage-setup
      sudo systemctl restart docker
      #sudo chown vagrant /var/run/docker.sock # optional

