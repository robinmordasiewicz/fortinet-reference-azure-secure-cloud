#!/bin/bash
#

az bicep upgrade
az group create --location CanadaCentral --name fortinet-secure-cloud-blueprint
az deployment group create --name fortinet-secure-cloud-blueprint --resource-group fortinet-secure-cloud-blueprint --template-file 000-main.bicep
az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm
az vm image terms accept --publisher fortinet --offer fortinet_fortiweb-vm_v5 --plan fortinet_fw-vm
az vm image terms accept --publisher fortinet --offer fortinet_fortigate-vm_v5 --plan fortinet_fg-vm_payg_2022
az vm image terms accept --publisher fortinet --offer fortinet_fortiweb-vm_v5 --plan fortinet_fw-vm_payg_v2
az deployment group show -g fortinet-secure-cloud-blueprint -n fortinet-secure-cloud-blueprint --query properties.outputs

#az deployment group delete  -g fortinet-secure-cloud-blueprint -n fortinet-secure-cloud-blueprint
#az group delete --yes --name fortinet-secure-cloud-blueprint
