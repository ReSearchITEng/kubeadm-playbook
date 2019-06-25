#!/bin/sh
export KUBECONFIG=/etc/kubernetes/admin.conf
NeedRebootList=""
for h in $(kubectl get nodes | tail -n +2 | awk '{print $1}'); do
  uuid=$(kubectl describe node/$h | grep -i UUID | tr '[:upper:]' '[:lower:]' | awk '{print $3}')
  eval kubectl patch node $h -p \'{\"spec\":{\"providerID\":\"vsphere://${uuid}\"}}\' | grep 'no change' >/dev/null
  if [[ $? -gt 0 ]]; then
    kubectl delete node $h  # As per vmware support suggetion: delete node and restart kubelet (see code: https://github.com/kubernetes/kubernetes/blob/v1.14.1/pkg/cloudprovider/providers/vsphere/vsphere.go#L278 )
    NeedRebootList="$NeedRebootList $h"
  fi
done
if [[ -n $NeedRebootList ]]; then
  echo "$NeedRebootList" | tr ' ' '\n' | tail -n +2
fi
### NeedRebootList holds the list of machines where there was a change and requrie reboot (or maybe at least kubelet restart)

