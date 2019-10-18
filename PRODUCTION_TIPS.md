# When to use this chart
Run this helm chart only for:
- generating the cluster first time:
- Adding a new node, using these steps:
  1. create a new hosts file and populate values only for **primary-master** (which won't be touched) and the sections where new nodes to be joining the cluster
  (either compute under **[nodes]** or master(control plane) under **[secondary-masters]** ; All non-relevant groups shoud be empty)
  2. run the `ansible-playbook -i hosts site.yml --tags node` (note the **--tags node** )

# Certificates:
- certs will expire 1 year after installation. The good part is that every kubeadm upgrade, the certs are getting regenerated. 
So, if you upgrade the cluster at least once a year (which you should to keep up with security fixes at least), then you don't need to be concerned.

# Check security settings:
- https://www.stackrox.com/post/2019/09/12-kubernetes-configuration-best-practices/ (PRs based on this are welcome)

# Other usefull charts:
- https://github.com/planetlabs/draino/tree/master/helm/draino -> when node is not heathy, it's automatically cordoned and containers drained (Kubernetes Node Problem Detector and Cluster Autoscaler).
