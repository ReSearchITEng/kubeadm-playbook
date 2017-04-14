# kubeadm Ansible Playbook for Centos/RHEL 7

This is a simple playbook to wrap the following operations:

* Install the kubeadm repo
* Install docker, kubeadm, kubelet, kubernetes-cni, and kubectl
* Disable SELinux :disappointed:
* Set docker `--logging-driver=json-file`             (when the tag docker is not skipped)
* Set docker `--storage-driver=overlay`               (when the tag docker is not skipped)
* Set kubelet `--cgroup-driver=systemd`               (when the tag kubelet is not skipped)
* Optional: Configure an insecure registry for docker (when the tag docker is not skipped)
* Initialize the cluster on master with `kubeadm init`
* Install user specified pod network from `group_vars/all`
* Join the nodes to the cluster with 'kubeadm join`
* Sanity: checks if nodes are ready and if all pods are running

This has been tested with **RHEL&CentOS 7.3** and **Kubernetes v1.6.1**

# How To

```
git clone https://github.com/sjenning/kubeadm-playbook.git
cd kubeadm-playbook/
cp hosts.example hosts
vi hosts <add hosts>
group_vars
cp group_vars/all.example group_vars/all
vi group_vars/all <modify vars as needed>
ansible-playbook -i hosts site.yml [--skip-tags "docker,prepull_images,kubelet"]
```
