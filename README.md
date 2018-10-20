# Update Status of the project: Stable
[kubeadm-playboook ansible project's code is on Github](https://github.com/ReSearchITEng/kubeadm-playbook)

# kubeadm based all in one kubernetes cluster installation (and addons) using Ansible
Tested on for all Centos/RHEL 7.2+ (ideally 7.4/7.5) and Ubuntu 16.04 (both with overlay2 and automatic docker_setup).    
Optionally, when docker_setup: True, this project will also setup the docker on the host if does not exist.     

## Targets/pros&cons
Kubeadm simplifies drastically the installation, so for BYO (vms,desktops,baremetal), complex projects like kubespray/kops are not required any longer. 
This project targets to get a fully working environment in matter of minutes on any hw: baremetal, vms (vsphere, virtualbox), etc.    
Major difference from other projects: it uses kubeadm for all activities, and kubernetes is running in containers.    
The project is for those who want to create&recreate k8s cluster using the official method (kubeadm), with all production features:
- Ingresses (via helm chart)
- Persistent storage (ceph or vsphere)
- dashboard (via helm chart)
- heapster (via helm chart)
- support proxy
- modular, clean code, supporting multiple activies by using ansible tags (e.g. add/reset a subgroup of nodes).
- suppoer multi master

### PROS:
- quick (3-7 min) full cluster installation
- all in one shop for a cluster which you can start working right away, without mastering the details
- applies fixes for quite few issues currently k8s installers have
- deploys plugins to all creation of dynamical persistent volumes via: vsphere, rook or self deployed NFS
- kubeadm is the only official tool specialized to install k8s

### CONS:
- during deployment requires internet access. Changes can be done to support situations when there is no internet. Should anyone be interested, I can give suggestions how (also see gluster project for hints).

## Prerequisites:
- ansible min. 2.3 (but higher is recommeneded. Tested on current 2.5)
- For a perfect experience, one should at least define a wildcard dns subdomain, to easily access the ingresses. The wildcard can pointed to the master (as it's quaranteed to exists).    
Note: dashboard will by default use the master machine, but also deploy under the provided domain (in parallel, only additional ingress rule)
- if docker_setup is True, it will also attempt to define your docker and set it up with overlay2 storage driver (one needs CentOS 7.4+)
- it will set required kernel modules (if desired)
- if one needs ceph(rook) persistent storage, disks or folders should be prepared and properly sized (e.g. /storage/rook)

## This playbook will:
* pre-sanity: docker sanity
* kernel modules (load & setup for every restart)
* Install ntp (to keep time in sync within cluster) (control via `group_vars/all`)
* Install the kubeadm repo
* Install kubeadm, kubelet, kubernetes-cni, and kubectl
* If desired, manipulate SELinux setting (control via `group_vars/all`)
* Set kubelet `--cgroup-driver=systemd` , swap-off, and many other settings required by kubelet to work (control via `group_vars/all`)  
* Reset activities (like kubeadm reset, unmount of `/var/lib/kubelet/*` mounts, ip link delete cbr0, cni0 , etc.) - important for reinstallations.
* Initialize the cluster on master with `kubeadm init`
* Install user specified pod network from `group_vars/all` (flannel, calico, weave, etc)
* Join the nodes to the cluster with 'kubeadm join' and full set of params.
* Install helm
* Install nginx ingress controller via helm (control via `group_vars/all`)
* Install kubernetes dashboard (via helm)
* Installs any listed helm charts in the config (via helm)
* Installs any yaml listed in the config
* Planned: Install prometheus via Helm (control via `group_vars/all`) -> prometheus operator helm chart is expected soon,
* Sanity: checks if nodes are ready and if all pods are running, and provides details of the cluster.
* when enabled, it will create ceph storage cluster using rook operator
* when enabled, it will create vsphere persistent storage class and all required setup. Please fill in vcenter u/p/url,etc `group_vars/all`, and follow all initial steps there.
* it will define a set of handy aliases 

NOTE: It does support **http_proxy** configuration cases. Simply update the your proxy in the group_vars/all.    
This has been tested with **RHEL&CentOS 7.3-7.5 and Ubuntu 16.04** and **Kubernetes v1.6.1 - v1.11.3**     
In general, keep the kube* tools at the same minor version with the desired k8s cluster. (e.g. For installing k8s v1.7 one must also use kubeadm 1.7 (kubeadm limitation).)    
FYI, higher kube* are usually supported with 1 minor version older cluster (e.g. kube[adm/ctl/let] 1.8.* accepts kubernetes cluster 1.7.*).

If for any reason anyone needs to relax RBAC, they can do: 
```kubectl create -f https://github.com/ReSearchITEng/kubeadm-playbook/blob/master/allow-all-all-rbac.yml```

# How To Use:

## Full cluster installation
```shell
git clone https://github.com/ReSearchITEng/kubeadm-playbook.git
cd kubeadm-playbook/
cp hosts.example hosts
vi hosts <add hosts>
# Setul vars in group_vars
vi group_vars/all/* <modify vars as needed>
ansible-playbook -i hosts site.yml [--skip-tags "docker,prepull_images,kubelet"]
```
If there are any issues, you may want to run only some of the steps, by choosing the appropriate tags to run.
Read the site.yml. Here are also some explanations of important steps:
- reset any previous cluster, delete etcd, cleanup network, etc.  (role/tag: reset)
- common section which prepares all machines (e.g. docker if required, kernel modules, etc) (role: common)
- install etcd  (role/tag: etcd) (requried only when you have HA only)
- install master (role/tag: master)
- install nodes  (role/tag: node)
- install network, helm, ingresses, (role/tag: post_deploy)

## Add manage (add/reinstall) only one node (or set of nodes):
- modify inventory (**hosts** file), and leave the master intact, but for nodes, keep *ONLY* the nodes to be managed (added/reset)
- ``` ansible-playbook -i hosts site.yml --tags node ```

## To remove a specific node (drain and afterwards kube reset, etc)
- modify inventory (**hosts** file), and leave the master intact, but for nodes, keep *ONLY* the nodes to be removed
- ``` ansible-playbook -i hosts site.yml --tags node_reset ```

## Other activities possible:
There are other operations possible against the cluster, look at the file: site.yml and decide. Few more examples of useful tags:
- "--tags reset" -> which resets the cluster in a safe matter (first removes all helm chars, then cleans all PVs/NFS, drains nodes, etc.)
- "--tags helm_reset" -> which removes all helm charts, and resets the helm.
- "--tags cluster_sanity" -> which does, of course, cluster_sanity and prints cluster details (no changes performed)

## Check the installation of dashboard
The output should have already presented the required info (or run again: `ansible-playbook -i hosts site.yml --tags cluster_sanity`).
The Dashboard is set on the master host, and, additionally, if it was set, also at something like: http://dashboard.cloud.corp.example.com  (depending on the configured selected domain entry), and if the wildcard DNS was properly set up *.k8s.cloud.corp.example.com pointing to master machine public IP).

e.g.  ``` curl -SLk 'http://k8s-master.example.com/#!/overview?namespace=_all' | grep browsehappy ```

For testing the Persistent volume, one may use/tune the files in the demo folder.
```shell
kubectl exec -it demo-pod -- bash -c "echo Hello TEST >> /usr/share/nginx/html/index.html "
```
and check the http://pv.cloud.corp.example.com page.

# load-ballancing
For LB, one may want to check also:

- github.com/cloudnativelabs/kube-router/wiki & https://github.com/cloudnativelabs/kube-router/blob/master/docs/kubeadm.md & https://github.com/cloudnativelabs/kube-router/blob/master/docs/how-it-works.md
- https://github.com/google/metallb/ (implements a LB type)
- https://github.com/kubernetes/contrib/tree/master/keepalived-vip (HA)
- https://github.com/kubernetes/contrib/tree/master/service-loadbalancer

# DEMO:
Installation demo k8s 1.7.8 on CentOS 7.4: [kubeadm ansible playbook install demo asciinema video](https://asciinema.org/a/Ii7NDu3eL9DsuM1fEFM9PMVTM)

## Vagrant 
For using vagrant on one or multiple machines with bridged interface (public_network and ports accessible) all machines must have 1st interface as the bridged interface (so k8s processes will bind automatically to it). For this, use this script: vagrant_bridged_demo.sh.

### Steps to start Vagrant deployment:
1. edit ./Vagrant file and set desired number of machines, sizing, etc.
2. run:
```shell
./vagrant_bridged_demo.sh --full [ --bridged_adapter <desired host interface|auto>  ] # bridged_adapter defaults to ip route | grep default | head -1 
```
After preparations (edit group_vars/all, etc.), run the ansible installation normally.

Using vagrant keeping NAT as 1st interface (usually with only one machine) was not tested and the Vagrantfile may requires some changes.
There was no focus on this option as it's more complicated to use afterwards: one must export the ports manually to access ingresses like dashboard from the browser, and usually does not support more than one machine.

# kubeadm-ha
While Kubeadm does not make multimaster (aka HA) setup easy (yet), thanks the comunity there we have it!
Starting our playbook for v1.11, we support master HA !
 Kubeadm will support ha OOB later -> as per https://github.com/kubernetes/kubeadm/issues/546; For now we do it using some work-arounds.
Our HA work is based on projects like: https://github.com/mbert/kubeadm2ha ( and https://github.com/sv01a/ansible-kubeadm-ha-cluster and/or github.com/cookeem/kubeadm-ha ).

# How does it compare to other projects:

## Kubeadm -> the official k8s installer (yet to be GA).

With kubeadm-playbook we are focus only kubeadm. 
**Pros:**
- as it's the official k8s installation tool 
- kubeadm is released with every k8s release, and you have a guarantee to be in sync with the official code. 
- self hosted deployment, making upgrades very smooth ; Here is a KubeCon talk presenting even more reasons to go with self-hosted k8s: https://www.youtube.com/watch?v=jIZ8NaR7msI

**Cons:**
- currenlty in beta (to be GA expected soon)
- no HA yet (expected in next release v1.10)

## Other k8s installers
Similar k8s install on physical/vagrant/vms (byo - on premises) projects you may want to check, but all below are without kubeadm (as opposed to this project)
- https://github.com/kubernetes/contrib/tree/master/ansible -> the official k8s ansible, but without kubeadm, therefore the processes will run on the nodes, not in docker containers
- https://github.com/dcj/ansible-kubeadm-cluster -> very simple cluster, does not (currently) have: ingresses, helm, addons, proxy support, vagrant support, persistent volumes, etc.
- https://github.com/apprenda/kismatic -> very big project by apprenda, it supports cluster upgrades
- https://github.com/kubernetes-incubator/kargo -> plans to use kubeadm in the future, for the activities kubeadm can do.
- https://github.com/gluster/gluster-kubernetes/blob/master/vagrant/ -> it's much more simple, no ingress, helm, addons, proxy support, and persistent volumes only using glusterfs. Entire project is only focused on CentOS.
- https://github.com/kubernetes-incubator/kubespray & https://github.com/kubernetes/kops (amazon) -> Neither of them use the official installtion tool: kubeadm, and that makes them heavy/big and require knowledge of "internals". 

PRs are accepted and welcome.

PS: work inspired from: @sjenning - and the master ha part from @mbert. PRs & suggestions from: @carlosedp - Thanks.
[URL page of kubeadm-playboook ansible project](https://researchiteng.github.io/kubeadm-playbook/)
[kubeadm-playboook ansible project's code is on Github](https://github.com/ReSearchITEng/kubeadm-playbook)

License: Public Domain 
