#!/bin/bash

resourcegroup=teamResources
aksname=openhack-team4
location=northeurope

serverApplicationId=1595b08d-88ac-406d-9466-374e73e66f87
serverApplicationSecret=e8888960-63f3-4383-a362-e7e19f464e47
clientApplicationId=339ad7e7-fc7e-4cca-b440-b8ed9bcee19a
tenantId=01228752-91ea-4355-9ec3-45574aa23dcb
 
subnetId=$(az network vnet subnet show --name aks-subnet --vnet-name vnet -g $resourcegroup --query id --output tsv)



az ad sp create-for-rbac --name "http://$aksname" --skip-assignment 
