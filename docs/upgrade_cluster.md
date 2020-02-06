Kubeadm upgrade is pretty clear and simple, there is no need for much automation around it.
Mainly run in a loop across all the machines (start with masters):
https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/#upgrading-control-plane-nodes

Upgrade only a version at a time (don't jump major versions).
(ideally get familiar with the process on another machine before)

PS:
The concept of "primary master" is there only part of the install flow, to denote where will be the first set of commands and where we'll run commands like: get join tokens, etc.
The cluster as such does not have/need such a concept.
