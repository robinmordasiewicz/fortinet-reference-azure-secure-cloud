#!/bin/bash
#

#if [[ `az deployment group list -g fortinet-secure-cloud-blueprints` ]];then
#  echo "delete"
#fi

#az deployment group show -g fortinet-secure-cloud-blueprints -n fortinet-secure-cloud-blueprints

`az group exists -n fortinet-secure-cloud-blueprint` && az deployment group delete -g fortinet-secure-cloud-blueprint -n fortinet-secure-cloud-blueprint || true
`az group exists -n fortinet-secure-cloud-blueprint` && az group delete --yes --name fortinet-secure-cloud-blueprint || true
