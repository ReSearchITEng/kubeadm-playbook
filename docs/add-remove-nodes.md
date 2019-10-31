# Adding nodes (either secondary-masters or infra or compute)
It's important to understand that both secondary-masters and nodes are treated the same.
E.g. Adding secondary-masters to existing cluster - it runs the same flow it's actually working even when defined from first run: it does initially the primary-master, and then adds all those in the [secondary-masters]
the steps to add (either additional master or additional compute nodes)

Here are the steps to be performed to add nodes post install:
1. prepare the hosts file and make sure:
a. it has the [primary-master] defined
b. in the other groups it has **ONLY** the machines you want to add (either masters under the [secondary-masters] or nodes under [nodes]
2. run: `ansible-playbook -i hosts site.yml --tags node`

# Removing nodes:
To remove a node, do similarly:
1. Put in the inventory (hosts file), under [nodes] group only the machines you wish to reset(remove) as well as populate the [primary-master] with the proper primary-master machine.  
2. `ansible-playbook -i hosts site.yml --tags node`

Note: the primary-master won't be touched, but it's required in order to properly drain the nodes before reset).

# Removig secondary-masters:
For safety reasons, currently it was decided that only nodes can be removed, while any [master] (being it primary-master or secondary-masters ) won't be automatically removed.    
If you want to remove a machine that is secondary-master, you have to **move** it under [nodes] group, (and remove it from the [secondary-masters] group) - and follow the "Removing nodes" steps above.
