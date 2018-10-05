#!/bin/sh
export KUBECONFIG=/etc/kubernetes/admin.conf
NeedRebootList=""
for h in $(kubectl get nodes | tail -n +2 | awk '{print $1}'); do
  uuid=$(kubectl describe node/$h | grep -i UUID | tr '[:upper:]' '[:lower:]' | awk '{print $3}')
  #eval kubectl patch node $h -p \'{\"spec\":{\"providerID\":\"vsphere://${uuid}\"}}\' | grep 'no change' >/dev/null
  eval kubectl patch node $h -p \'{\"spec\":{\"providerID\":\"vsphere://${uuid}\"}}\' | grep 'no changed' >/dev/null
  [[ $? -gt 0 ]] && NeedRebootList="$NeedRebootList $h"
done
[[ -n $NeedRebootList ]] && echo "$NeedRebootList" | tr ' ' '\n' | tail -n +2
#echo "You must reboot machines: $NeedRebootList"

