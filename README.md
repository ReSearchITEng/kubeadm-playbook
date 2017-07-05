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
- deploys plugins to all creation of dynamica persistent volumes via: vsphere, rook or self deployed NFS

### CONS:
- no HA: for now, kubeadm cannot install clusters with master/etcd HA.
- during deployment requires internet access. Changes can be done to support situations when there is no internet. Should anyone be interested, I can give suggestions how.

## Prerequisites:
- machine(s) with properly set up and working docker daemon (with http_proxy, no_proxy,etc under /etc/sysconfig/docker when proxy is required)
- For a good experience, one should at least define a wildcard dns subdomain, to easily access the ingresses. The wildcard can pointed to the master (as it's quaranteed to exists)
- if one needs ceph(rook) persistent storage, disks or folders should be prepared and properly sized (e.g. /storage/rook)

## This playbook will:

* Install the kubeadm repo
* Install ~~docker,~~~ kubeadm, kubelet, kubernetes-cni, and kubectl
~~Set docker `--logging-driver=json-file`             (when the tag docker is not skipped)~~
~~Set docker `--storage-driver=overlay`               (when the tag docker is not skipped)~~
* Disable SELinux :disappointed:    (prerequisite of kubeadm)
* Set kubelet `--cgroup-driver=systemd`
~~* Optional: Configure an insecure registry for docker (when the tag docker is not skipped)~~
* Initialize the cluster on master with `kubeadm init`
* Install user specified pod network from `group_vars/all`
* Install kubernetes dashboard
* Install helm
* Install nginx ingress controller via helm (control via `group_vars/all`)
  NOTE: nginx ingress is not yet RBAC ready, and we currently have to use: https://github.com/ReSearchITEng/kubeadm-playbook/blob/master/allow-all-all-rbac.yml.
* Join the nodes to the cluster with 'kubeadm join'
* Planned: Install prometheus via ~~Helm~~ operator (control via `group_vars/all`)
* Sanity: checks if nodes are ready and if all pods are running
* create ceph storage cluster using rook operator
* create vsphere persistent storage class and all required setup. Please fill in vcenter u/p/url,etc `group_vars/all`, and follow all initial steps there.

NOTE: It does support **http_proxy** configuration cases. Simply update the your proxy in the group_vars/all.

This has been tested with **RHEL&CentOS 7.3** and **Kubernetes v1.6.1 - 1.6.6**
For installing k8s 1.7 one must also use kubeadm 1.7 (known kubeadm limitation)

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

If the wildcard DNS was properly set up ( *.k8s.cloud.corp.example.com pointing to master machine public IP), at this stage one should be able to see the dashboard at: http://dashboard.cloud.corp.example.com
For testing the Persistent volume, one may use/tune the files in the demo folder.
```
kubectl exec -it demo-pod -- bash -c "echo Hello DEMO >> /usr/share/nginx/html/index.html "
```
and check the http://pv.cloud.corp.example.com page.

For load-ballancing, one may want to check also:
- https://github.com/kubernetes/contrib/tree/master/service-loadbalancer
- https://github.com/cloudlabs/kube-router/wiki
- https://github.com/kubernetes/contrib/tree/master/keepalived-vip

PS: work inspired from: @sjenning

Similar k8s install on physical/vagrant/vms (byo - on premises) projects you may want to check, but all below are without kubeadm (as opposed to this project)
- https://github.com/kubernetes/contrib/tree/master/ansible -> the official k8s ansible, but without kubeadm, therefore the processes will run on the nodes, not in docker containers
- https://github.com/apprenda/kismatic -> very big project by apprenda, it supports cluster upgrades, etc.
- https://github.com/kubernetes-incubator/kargo -> plans to use kubeadm in the future, for the activities kubeadm can do.

URL page of this project: https://researchiteng.github.io/kubeadm-playbook/
