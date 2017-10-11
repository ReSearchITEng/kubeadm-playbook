# Update Status of the project: Stable

Link to project's github page: https://github.com/ReSearchITEng/kubeadm-playbook

# kubeadm based all in one kubernetes cluster installation Ansible Playbook
Tested on for Centos/RHEL 7.; Ubuntu/debian should work also, but not tested.

## Targets/pros&cons
Major difference from other projects: it uses kubeadm for all activities, and kubernetes is running in containers.
The project is for those who want to quickly create&recreate k8s cluster, with all production features:
- Ingresses
- Persistent storage (ceph or vsphere)

### PROS:
- quick (3-7 min) full cluster (re)installation
- all in one shop for a cluster which you can start working right away, without mastering the details
- applies fixes for quite few issues currently k8s installers have
- deploys plugins to all creation of dynamical persistent volumes via: vsphere, rook or self deployed NFS

### CONS:
- no HA: for now, kubeadm cannot install clusters with master/etcd HA (yet; but planned).
- during deployment requires internet access. Changes can be done to support situations when there is no internet. Should anyone be interested, I can give suggestions how.

## Prerequisites:
- ansible min. 2.1
- docker: machine(s) with properly set up and working docker daemon (with http_proxy, no_proxy,etc under /etc/sysconfig/docker when proxy is required)
- For a good experience, one should at least define a wildcard dns subdomain, to easily access the ingresses. The wildcard can pointed to the master (as it's quaranteed to exists)
- if one needs ceph(rook) persistent storage, disks or folders should be prepared and properly sized (e.g. /storage/rook)

## This playbook will:
* pre-sanity: docker sanity (soon)
* Install the kubeadm repo
* Install kubeadm, kubelet, kubernetes-cni, and kubectl
* Disable SELinux :disappointed: (current prerequisite of kubeadm)
* Set kubelet `--cgroup-driver=systemd`
* Reset activities (like kubeadm reset, unmount of `/var/lib/kubelet/*` mounts, ip link delete cbr0, cni0 , etc.) - important for reinstallations.
* Initialize the cluster on master with `kubeadm init`
* Install user specified pod network from `group_vars/all`
* Install kubernetes dashboard
* Install helm
* Install nginx ingress controller via helm (control via `group_vars/all`)
* Join the nodes to the cluster with 'kubeadm join'
* Planned: Install prometheus via ~~Helm~~ operator (control via `group_vars/all`)
* Sanity: checks if nodes are ready and if all pods are running
* when enabled, it will create ceph storage cluster using rook operator
* when enabled, it will create vsphere persistent storage class and all required setup. Please fill in vcenter u/p/url,etc `group_vars/all`, and follow all initial steps there.

NOTE: It does support **http_proxy** configuration cases. Simply update the your proxy in the group_vars/all.
This has been tested with **RHEL&CentOS 7.3** and **Kubernetes v1.6.1 - 1.6.6 and 1.7.0**
For installing k8s v1.7 one must also use kubeadm 1.7 (kubeadm limitation)

If for any reason anyone needs to relax RBAC, they can do: 
```kubectl create -f https://github.com/ReSearchITEng/kubeadm-playbook/blob/master/allow-all-all-rbac.yml```

# How To

```shell
git clone https://github.com/ReSearchITEng/kubeadm-playbook.git
cd kubeadm-playbook/
cp hosts.example hosts
vi hosts <add hosts>
# Setul vars in group_vars
cp group_vars/all.example group_vars/all
vi group_vars/all <modify vars as needed>
ansible-playbook -i hosts site.yml [--skip-tags "docker,prepull_images,kubelet"]
```

If the wildcard DNS was properly set up ( *.k8s.cloud.corp.example.com pointing to master machine public IP), at this stage one should be able to see the dashboard at: http://dashboard.cloud.corp.example.com
For testing the Persistent volume, one may use/tune the files in the demo folder.
```shell
kubectl exec -it demo-pod -- bash -c "echo Hello DEMO >> /usr/share/nginx/html/index.html "
```
and check the http://pv.cloud.corp.example.com page.

For load-ballancing, one may want to check also:
- https://github.com/kubernetes/contrib/tree/master/service-loadbalancer
- https://github.com/cloudlabs/kube-router/wiki
- https://github.com/kubernetes/contrib/tree/master/keepalived-vip

PS: work inspired from: @sjenning - thanks. PRs & suggestions from: @carlosedp - Thanks.

Similar k8s install on physical/vagrant/vms (byo - on premises) projects you may want to check, but all below are without kubeadm (as opposed to this project)
- https://github.com/kubernetes/contrib/tree/master/ansible -> the official k8s ansible, but without kubeadm, therefore the processes will run on the nodes, not in docker containers
- https://github.com/apprenda/kismatic -> very big project by apprenda, it supports cluster upgrades, etc.
- https://github.com/kubernetes-incubator/kargo -> plans to use kubeadm in the future, for the activities kubeadm can do.

URL page of this project: https://researchiteng.github.io/kubeadm-playbook/


## USING with Vagrant 
For using vagrant on one or multiple machines with bridged interface (public_network and ports accessible) all machines must have 1st interface as the bridged interface (so k8s processes will bind automatically to it). For this, use this script: vagrant_bridged_demo.sh.

### Steps to start Vagrant deployment:
1. edit ./Vagrant file and set desired number of machines, sizing, etc.
2. run:
```shell
./vagrant_bridged_demo.sh --full [ --bridged_adapter <desired host interface> ] # bridged_adapter defaults to ip route | grep default | head -1 
```
After preparations (edit group_vars/all, etc.), run the ansible installation normally.

Using vagrant keeping NAT as 1st interface (usually with only one machine) was not tested and the Vagrantfile may requires some changes.
There was no focus on this option as it's more complicated to use afterwards: one must export the ports manually to access ingresses like dashboard from the browser, and usually does not support more than one machine.


Project on Github : https://github.com/ReSearchITEng/kubeadm-playbook
