/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                                                                                                 //
//  This Template File should NOT be MODIFIED - Please make all modifications via "MAIN.BICEP"                                     //
//                                                                                                                                 //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          PARAMETERS                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

param deploymentPrefix string
param location string
param adminUsername string
@secure()
param adminPassword string
param vnetNewOrExisting  string
param vnetName string
param subnet7Name string
param vnetResourceGroup string 
param subnet7Prefix string
param subnet7StartAddress string
param dvwaserialConsole string

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          VARIABLES                                                              //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

var vmName = '${deploymentPrefix}-DVWA'
var vmNicName = '${deploymentPrefix}-DVWA-NIC'
var vmNicId = ubuntuNic.id
var var_vnetName = ((vnetName == '') ? '${deploymentPrefix}-VNET' : vnetName)
var var_serialConsoleStorageAccountName = 'dvwa${uniqueString(resourceGroup().id)}'
var serialConsoleStorageAccountType = 'Standard_LRS'
var serialConsoleEnabled = ((dvwaserialConsole == 'yes') ? true : false)
var subnet7Id = ((vnetNewOrExisting == 'new') ? resourceId('Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet7Name) : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', var_vnetName, subnet7Name))
var sn7IPArray = split(subnet7Prefix, '.')
var sn7IPArray2 = string(int(sn7IPArray[2]))
var sn7IPArray1 = string(int(sn7IPArray[1]))
var sn7IPArray0 = string(int(sn7IPArray[0]))
var sn7IPStartAddress = split(subnet7StartAddress, '.')
var sn7IPUbuntu = '${sn7IPArray0}.${sn7IPArray1}.${sn7IPArray2}.${int(sn7IPStartAddress[3])}'
var vmCustomDataBody = '''
#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
#Wait for the repo 
echo "Waiting for repo to be reacheable"
curl --retry 20 -s -o /dev/null "https://download.docker.com/linux/centos/docker-ce.repo"
echo "Adding repo"
until dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
do
   dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo 
   sleep 2
done
dnf remove podman buildah
echo "Installing docker support"
until dnf -y install docker-ce docker-ce-cli containerd.io
do
    dnf -y install docker-ce docker-ce-cli containerd.io
    sleep 2
done
systemctl start docker.service
systemctl enable docker.service
#Wait for Internet access through the FGT by testing the docker regsitry
echo "Waiting for docker registry to be reacheable"
curl --retry 20 -s -o /dev/null "https://index.docker.io/v2/"
echo "installing dvwa docker container"
until docker run --restart=always --name dvwa -d -p 80:80 vulnerables/web-dvwa
do
    docker pull vulnerables/web-dvwa
    sleep 2
done
'''

var vmCustomData = base64(vmCustomDataBody)

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                 //
//                                                          RESOURCES                                                              //
//                                                                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

resource ubuntuNic 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: vmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sn7IPUbuntu
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnet7Id
          }
        }
      }
    ]
  }
}


resource ubuntuVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  plan: {
    name: '8-gen2'
    publisher: 'almalinux'
    product: 'almalinux'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_F2s_v2'
    }
    osProfile: {
      computerName: 'DVWA'
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: vmCustomData
    }
    storageProfile: {
      imageReference: {
        publisher: 'almalinux'
        offer: 'almalinux'
        sku: '8-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNicId
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: serialConsoleEnabled
        storageUri: ((dvwaserialConsole == 'yes') ? reference(var_serialConsoleStorageAccountName, '2021-08-01').primaryEndpoints.blob : null)
      }
    }
  }
}

resource serialConsoleStorageAccountName 'Microsoft.Storage/storageAccounts@2021-02-01' = if (dvwaserialConsole == 'yes') {
  name: var_serialConsoleStorageAccountName
  location: location
  kind: 'Storage'
  sku: {
    name: serialConsoleStorageAccountType
  }
}

output dvwaPrivateIP string = sn7IPUbuntu
