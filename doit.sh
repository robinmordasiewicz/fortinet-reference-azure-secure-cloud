#!/bin/bash
#

#if [[ `az deployment group list -g fortinet-secure-cloud-blueprints` ]];then
#  echo "delete"
#fi

az deployment group show -g fortinet-secure-cloud-blueprints -n fortinet-secure-cloud-blueprints
