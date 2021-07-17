#!/bin/bash

cd ~/work/
mv -f ./kubeadm-playbook ./kubeadm-playbook.old || true
sudo cp -rp ~researchiteng/git/kubeadm-playbook .
sudo chown -R `id -u`:`id -g` ./kubeadm-playbook
cd ./kubeadm-playbook
cp -p .././kubeadm-playbook.old/hosts .
sed -i 's/myk8s.corp.example.com/ap/' group_vars/all/network.yml
sudo kubeadm reset -f
ansible-playbook -i hosts site.yml
sudo cp -pf /etc/kubernetes/admin.conf ~/.kube/config
sudo chown -R `id -u`:`id -g` ~/.kube/config

