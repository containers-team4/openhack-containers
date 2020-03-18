#!/bin/bash

resourcegroup=teamResources
aksname=openhack-team4
location=northeurope

serverApplicationId=1595b08d-88ac-406d-9466-374e73e66f87
serverApplicationSecret=e8888960-63f3-4383-a362-e7e19f464e47
clientApplicationId=339ad7e7-fc7e-4cca-b440-b8ed9bcee19a
tenantId=01228752-91ea-4355-9ec3-45574aa23dcb
 
subnetId=$(az network vnet subnet show --name aks-subnet --vnet-name vnet -g $resourcegroup --query id --output tsv)

## {
##   "appId": "f0b7845a-e719-4554-8398-df68bd0e8946",
##   "displayName": "openhack-team4",
##   "name": "http://openhack-team4",
##   "password": "6ff78d9c-58c0-4f6a-ab0f-4f92b31efa0d",
##   "tenant": "01228752-91ea-4355-9ec3-45574aa23dcb"
## }

az aks create \
  --resource-group $resourcegroup \
  --name $aksname \
  --location $location \
  --node-count 3 \
  --generate-ssh-keys \
  --aad-server-app-id $serverApplicationId \
  --aad-server-app-secret $serverApplicationSecret \
  --aad-client-app-id $clientApplicationId \
  --aad-tenant-id $tenantId \
  --network-plugin azure \
  --service-cidr 10.0.0.0/16 \
  --dns-service-ip 10.0.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --vnet-subnet-id $subnetId  \
  --service-principal f0b7845a-e719-4554-8398-df68bd0e8946 \
  --client-secret 6ff78d9c-58c0-4f6a-ab0f-4f92b31efa0d
