# What is included:
If the inventory has only [primary-master] section populated, it understands it's a one machine cluster (at least for now).
The playbook will do most of the settings accordingly.

# ingress with local binding
For ingress controller to listen to 127.*, you may want to use option 2 of the ingress controller defined in addons.yml

# Portable IP address:
Should you have this installation in a vm, and your IP address changes, you may want to make it "portable", so it does not depend on the ip address..

```
echo "make installation agnostic to ip address"
CURRENT_IP=`hostname -I | cut -d" " -f1`
sudo perl -p -i -e "s/${CURRENT_IP}/127.0.0.1/g" ` find /etc/kubernetes/ -type f \( -name \*.yaml -o -name \*.conf \) `
```

# add ingresses to hosts file
In such cases, most probably you don't have a wildcard dns either, so create similar entries in the /etc/hosts file.
(of course, these entries have to be in sync with the group_vars/all/network.yml (and, if you customized, eventually hosts/domains defined in addons.yml) .
# dns entries for ingresses. 
```
echo "127.0.1.2       dashboard.k8s.local.example.com prometheus.k8s.local.example.com grafana.k8s.corp.example.com" | sudo tee -a /etc/hosts >/dev/null
```

# compress image
In case you want to ship such a portable vm image with k8s inside, you may want to make it as small as possible before shutdown.

```
sudo systemctl stop kubelet || true
sudo systemctl disable kubelet || true
docker rmi -f $(docker images -q)
```

# If you want to temporary turn off your kubernetes (keep only its configuration), do:
```
sudo systemctl stop kubelet; sudo systemctl disable kubelet; docker ps | grep kube | cut -d" " -f1 | xargs docker stop ; docker ps | grep k8s | cut -d" " -f1 | xargs docker stop; docker ps
```

# To save space, you may want to also delete some or even all docker images which are not currently used:
`docker rmi $(docker images -q)`

# other tipcs:
you may want to do `sudo fstrim /`
