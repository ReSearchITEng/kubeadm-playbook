# What is included:
If the inventory has only [primary-master] section populated, it understands it's a one machine cluster (at least for now).
The playbook will do most of the settings accordingly.

# no auth dashboard
If you want a quick dashboard without any auth, you may want to use k8s 1.15, and use the older dashboard in addons.yml, replacing the dashboard defined there, with this:
```
    - { name: dashboard, repo: stable/kubernetes-dashboard, options: '--set rbac.create=True,ingress.enabled=True,ingress.hosts[0]={{groups["primary-master"][0]}},ingress.hosts[1]=dashboard.{{ custom.networking.dnsDomain }},image.tag=v1.8.3 --version=0.5.3' }
```

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

# other tipcs:
you may want to do `sudo fstrim /`
