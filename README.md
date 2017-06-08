# kubeadm Ansible Playbook for Centos/RHEL 7
Ubuntu/debian should work also, but not tested.

This is a simple playbook to wrap the following operations:

* Install the kubeadm repo
* Install docker, kubeadm, kubelet, kubernetes-cni, and kubectl
* Disable SELinux :disappointed:    
~~Set docker `--logging-driver=json-file`             (when the tag docker is not skipped)~~     
~~Set docker `--storage-driver=overlay`               (when the tag docker is not skipped)~~     
* Set kubelet `--cgroup-driver=systemd`               (when the tag kubelet is not skipped)
* Optional: Configure an insecure registry for docker (when the tag docker is not skipped)
* Initialize the cluster on master with `kubeadm init`
* Install user specified pod network from `group_vars/all`
* Install kubernetes dashboard
* Install helm
* Install nginx ingress controller via helm (control via `group_vars/all`)
* Planned: Install prometheus via ~~Helm~~ operator (control via `group_vars/all`)
* Join the nodes to the cluster with 'kubeadm join`
* Sanity: checks if nodes are ready and if all pods are running
* create ceph storage cluster using rook operator

NOTE: It does support **http_proxy** configuration cases. Simply update the your proxy in the group_vars/all.

This has been tested with **RHEL&CentOS 7.3** and **Kubernetes v1.6.1 & v1.6.2**

# How To

```
git clone https://github.com/ReSearchITEng/kubeadm-playbook.git
cd kubeadm-playbook/
cp hosts.example hosts
vi hosts <add hosts>
group_vars
cp group_vars/all.example group_vars/all
vi group_vars/all <modify vars as needed>
ansible-playbook -i hosts site.yml [--skip-tags "docker,prepull_images,kubelet"]
```

For load-ballancing, one may want to check also: https://github.com/kubernetes/contrib/tree/master/service-loadbalancer

PS: work based on sjenning/kubeadm-playbook

Similar k8s install on physical/vagrant/vms (byo) projects you may want to check:
- https://github.com/kubernetes/contrib/tree/master/ansible -> the official k8s ansible, but without kubeadm, therefore the processes will run on the nodes, not in docker containers
- https://github.com/apprenda/kismatic -> very big project by apprenda, it supports cluster upgrades, etc.

