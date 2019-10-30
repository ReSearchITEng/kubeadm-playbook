# Adding nodes (either secondary-masters or infra or compute)
It's important to understand that both secondary-masters and nodes are treated the same.
E.g. Adding secondary-masters to existing cluster - it runs the same flow it's actually working even when defined from first run: it does initially the primary-master, and then adds all those in the [secondary-masters]
the steps to add (either additional master or additional compute nodes)

Here are the steps to be performed to add nodes post install:
1. prepare the hosts file and make sure:
a. it has the [primary-master] defined
b. in the other groups it has **ONLY** the machines you want to add (either masters under the [secondary-masters] or nodes under [nodes]
2. run: `ansible-playbook -i hosts site.yml --tags node`
