# Ansible related errors:
### forks, number of open files
ERROR: "ERROR! A worker was found in a dead state"
REASON: this might appear if you have low limits of number of open files, and your number of hosts in inventory is big.     
Solution(s):        
- run this command before starting ansible: `ulimit -Sn $(ulimit -Hn)` to increase the softlimit up to the hard limit (which I suggest 16384 or more)    
- increase both soft limit and hardlimits (see links below)
- if `lsof | wc -l` is more than 1/2 of `ulimit -Sn`, you **may** want to reboot the control machine (from where you invoke ansible).(ideally reboot also the target machines if they were not restarted for very long time)    
- limit number of forks ansible uses, by using the -f1 parameter on the ansible.
Other related resources:
- https://github.com/ansible/ansible/issues/32554
- https://www.whatan00b.com/posts/debugging-a-segfault-from-ansible/
- https://stackoverflow.com/questions/21752067/counting-open-files-per-process
- https://www.tecmint.com/increase-set-open-file-limits-in-linux/
