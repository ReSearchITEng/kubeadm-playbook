# When to use this chart
Run this helm chart only for:
- generating the cluster first time:
- Adding a new node, using these steps:
  1. create a new hosts file and populate values only for **primary-master** (which won't be touched) and the sections where new nodes to be joining the cluster
  (either compute under **[nodes]** or master(control plane) under **[secondary-masters]** ; All non-relevant groups shoud be empty)
  2. run the `ansible-playbook -i hosts site.yml --tags node` (note the **--tags node** )

# Use conventions
Besides "master" role, it's suggested to use also "infra" role (by specifying `label=node-role.kubernetes.io/infra=` in the hosts file).
Machines marked as infra usually hold Prometheus, nginx ingress controllers, grafana, EFK, etc...  
Usually there should be min. 3 master nodes and min 3 infra nodes ( compute (aka worker) nodes -> as many as required by the actual workload of the cluster).

# Secure Dashboard
- from addons.yaml, remove "--set enableInsecureLogin=True --set enableSkipLogin=True"
- also you may want to review the dashboard service account perms you desire  

# Heads-up
When you have master-ha, the cluster can function properly when there are up at least 1/2 + 1 masters (so the quorum will function). If you have 3 masters, you must have at least 2 masters up for the cluster function.
FYI: the good part is that the workload of a k8s cluster will continue to serve everything even without any master running, BUT, if any pod crashes, or there are any activities that need masters up, those won't be done till masters are up again.

# Certificates:
- certs will expire 1 year after installation. The good part is that every kubeadm upgrade, the certs are getting regenerated. 
So, if you upgrade the cluster at least once a year (which you should to keep up with security fixes at least), then you don't need to be concerned.

# Check security settings:
- https://www.stackrox.com/post/2019/09/12-kubernetes-configuration-best-practices/ (PRs based on this are welcome)
- https://kubernetes.io/docs/tasks/administer-cluster/securing-a-cluster/
- secure using: https://github.com/nirmata/kyverno/blob/master/samples/README.md
- test using: https://github.com/aquasecurity/kube-bench

# Other usefull charts:
- https://github.com/planetlabs/draino/tree/master/helm/draino -> when node is not heathy, it's automatically cordoned and containers drained (Kubernetes Node Problem Detector and Cluster Autoscaler).
- Use Public IP Address from a cloud vendor, simulating a LoadBalancer: https://github.com/inlets/inlets-operator

# Debian - package hold
make sure k8s tools are not upgraded by mistake (do it post ansible)
```
sudo apt-mark hold kubectl kubelet kubeadm kubernetes-cni cri-tools
```
allow k8s tools to be upgraded (do it when upgrade is desired)
```
sudo apt-mark unhold kubectl kubelet kubeadm kubernetes-cni cri-tools
```

