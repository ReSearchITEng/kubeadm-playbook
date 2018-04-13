Examples of popular helm charts with their relevant params.
Tested in k8s 10, helm 2.8.2, with persistent volumes and proxy.

# Test k8s deployment with:
## Wordpress
```
export K8SMASTER=$(hostname -s)
helm delete --purge wordpress || true
helm install --name wordpress --namespace default \
--set wordpressUsername=admin,wordpressPassword=password \
--set persistence.size=200Mi \
--set mariadb.mariadbRootPassword=secretpassword,mariadb.persistence.size=400Mi \
--set ingress.enabled=true,ingress.hosts[0].name="wordpress.${K8SMASTER}.k8singress.example.com" \
stable/wordpress
```

# DBs
## mysql
```
export K8SMASTER=$(hostname -s)
helm delete --purge mysql || true
helm install --namespace default --name mysql \
--set mysqlRootPassword=secretpassword,mysqlUser=my-user,mysqlPassword=my-password,mysqlDatabase=my-database,persistence.size=400Mi \
stable/mysql
```

## MongoDB
```
export K8SMASTER=$(hostname -s)
helm delete --purge mongodb || true
helm install --name mongodb --namespace mongodb \
--set mongodbRootPassword=secretpassword,mongodbUsername=my-user,mongodbPassword=my-password,mongodbDatabase=my-database \
--set persistence.enabled=True,persistence.size=500Mi \
stable/mongodb
```

## PostgreSQL
```
export K8SMASTER=$(hostname -s)
helm delete --purge postgresql || true
helm install --name postgresql --namespace default \
--set postgresUser=my-user,postgresPassword=secretpassword,postgresDatabase=my-database \
--set persistence.enabled=True,persistence.size=300Mi \
stable/postgresql
```

# Monitoring
## Prometheus
```
export K8SMASTER=$(hostname -s)
helm delete --purge prometheus || true
helm install --name prometheus --namespace infra \
--set rbac.create=True \
--set alertmanager.ingress.enabled=True,alertmanager.ingress.hosts[0]=alertmanager.${K8SMASTER}.k8singress.example.com \
--set alertmanager.persistentVolume.enabled=true,alertmanager.persistentVolume.size=300Mi \
--set server.ingress.enabled=True,server.ingress.hosts[0]=prometheus.${K8SMASTER}.k8singress.example.com \
--set server.persistentVolume.enabled=True,server.persistentVolume.size=400Mi \
--set pushgateway.ingress.enabled=True,pushgateway.ingress.hosts[0]=pushgateway.${K8SMASTER}.k8singress.example.com \
stable/prometheus 
```

## Grafana (resource intensive/cron jobs)
```
export K8SMASTER=$(hostname -s)
helm delete --purge grafana || true
helm install --name grafana --namespace infra \
--set adminPassword=my-password \
--set persistence.enabled=True,persistence.size=200Mi,persistence.accessModes[0]=ReadWriteOnce \
--set ingress.enabled=True,ingress.hosts[0]=grafana.${K8SMASTER}.k8singress.example.com \
--set datasources.datasources\\.yaml.apiVersion=1 \
--set datasources.datasources\\.yaml.datasources[0].name=prometheus \
--set datasources.datasources\\.yaml.datasources[0].type=prometheus \
--set datasources.datasources\\.yaml.datasources[0].url="http://prometheus-server.infra.svc.cluster.local" \
--set datasources.datasources\\.yaml.datasources[0].isDefault=true \
--set datasources.datasources\\.yaml.datasources[0].access=proxy \
--set datasources.datasources\\.yaml.datasources[1].name=prometheus_direct \
--set datasources.datasources\\.yaml.datasources[1].type=prometheus \
--set datasources.datasources\\.yaml.datasources[1].url="http://prometheus.${K8SMASTER}.k8singress.example.com" \
--set datasources.datasources\\.yaml.datasources[1].isDefault=false \
--set datasources.datasources\\.yaml.datasources[1].access=direct \
stable/grafana 
```

# Others
## chartmuseum
TBD: The chart does not provide a way to add proxy curently
```
export K8SMASTER=$(hostname -s)
helm delete --purge chartmuseum || true
helm install --name chartmuseum --namespace infra \
--set persistence.enabled=True,persistence.storageClass="",persistence.size=100Mi \
--set ingress.enabled=True \
--set ingress.hosts.chartmuseum\\.${K8SMASTER}\\.k8singress\\.example\\.com[0]="/charts" \
--set ingress.hosts.chartmuseum\\.${K8SMASTER}\\.k8singress\\.example\\.com[1]="/index.yaml" \
--set ingress.hosts.chartmuseum\\.${K8SMASTER}\\.k8singress\\.example\\.com[2]="/index.yml" \
stable/chartmuseum

#### Optionally, install the binary on the unix side to interact with it:
curl -LO https://s3.amazonaws.com/chartmuseum/release/latest/bin/linux/amd64/chartmuseum && chmod +x ./chartmuseum && mv ./chartmuseum /usr/local/bin
```

## Monocular
TBD: The chart does not provide a way to add proxy curently
```
export K8SMASTER=$(hostname -s)
helm delete --purge monocular || true
helm repo add monocular https://kubernetes-helm.github.io/monocular
helm install --name monocular --namespace infra \
--set ingress.enabled=True,ingress.hosts[0]="monocular.${K8SMASTER}.k8singress.example.com" \
--set mongodb.persistence.enabled=True,mongodb.persistence.size=400Mi \
monocular/monocular
```

# CI/CD
## Jenkins
```
export K8SMASTER=$(hostname -s)
helm delete --purge jenkins || true
helm install --name jenkins --namespace infra \
--set rbac.install=true \
--set Master.InstallPlugins[0]="kubernetes:1.5.1" \
--set Master.InstallPlugins[1]="credentials-binding:1.16" \
--set Master.InstallPlugins[2]="git:3.8.0" \
--set Master.InstallPlugins[3]="workflow-job:2.18" \
--set Master.InstallPlugins[4]="workflow-aggregator:2.5" \
--set Master.InitContainerEnv[0].name=http_proxy,Master.InitContainerEnv[0].value='http://proxy.corp.example.com:8080' \
--set Master.InitContainerEnv[1].name=https_proxy,Master.InitContainerEnv[1].value='http://proxy.corp.example.com:8080' \
--set Master.InitContainerEnv[2].name=no_proxy,Master.InitContainerEnv[2].value='localhost\,.svc\,.local\,.example.com' \
--set Master.ContainerEnv[0].name=http_proxy,Master.ContainerEnv[0].value='http://proxy.corp.example.com:8080' \
--set Master.ContainerEnv[1].name=https_proxy,Master.ContainerEnv[1].value='http://proxy.corp.example.com:8080' \
--set Master.ContainerEnv[2].name=no_proxy,Master.ContainerEnv[2].value='localhost\,.svc\,.local\,.example.com' \
--set Master.JavaOpts="-Dhttp.proxyHost=proxy.corp.example.com -Dhttp.proxyPort=8080 -Dhttps.proxyHost=proxy.corp.example.com -Dhttps.proxyPort=8080 -Dhttp.nonProxyHosts='localhost|*.example.com|*.local|*.svc' -Dhttps.nonProxyHosts='localhost|*.example.com|*.local|*.svc' " \
--set Master.ServiceType=ClusterIP \
--set Master.HostName=jenkins.${K8SMASTER}.k8singress.example.com \
--set Persistence.Enabled=True \
--set Persistence.Size=1Gi \
stable/jenkins
echo "Find admin password is:"
printf $(kubectl get secret --namespace infra jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

## Nexus
TBD: The chart does not provide a way to add proxy at deploy time (as of now)
```
export K8SMASTER=$(hostname -s)
helm delete --purge nexus || true
helm install --name nexus --namespace infra \
--set docker.enabled=True,docker.host=myregistry.${K8SMASTER}.k8singress.example.com,docker.port=5000 \
--set persistence.enabled=True,persistence.size=1Gi \
--set service.type=ClusterIP \
--set ingress.enabled=True,ingress.hosts[0]="nexus.${K8SMASTER}.k8singress.example.com" \
stable/sonatype-nexus
```

# Notes:
All sizes are at min.
If proxy is not required, remove the relevant lines 
