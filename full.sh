#!/bin/bash

## Set the variables

resourcegroup=teamResources
aksname=deleteme-team4
location=northeurope
vnetName=vnet
subnetName=aks-subnet

# Create the Azure AD application
serverAppId=$(az ad app create \
    --display-name "${aksname}-server" \
    --identifier-uris "https://${aksname}-server" \
    --query appId -o tsv)

# Update the application group memebership claims
az ad app update --id $serverAppId --set groupMembershipClaims=All

# Create a service principal for the Azure AD application
az ad sp create --id $serverAppId

# Get the service principal secret
serverApplicationSecret=$(az ad sp credential reset \
    --name $serverAppId \
    --credential-description "AKSPassword" \
    --query password -o tsv)

# Add permissions for the Azure AD app to read directory data, sign in and read
# user profile, and read directory data
az ad app permission add \
    --id $serverAppId \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

# Grant permissions for the permissions assigned in the previous step
# You must be the Azure AD tenant admin for these steps to successfully complete
az ad app permission grant --id $serverAppId --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id  $serverAppId

# Create the Azure AD client application
clientAppId=$(az ad app create --display-name "${aksname}-client" --native-app --reply-urls "https://${aksname}-client" --query appId -o tsv)

# Create a service principal for the client application
az ad sp create --id $clientAppId

# Get the oAuth2 ID for the server app to allow authentication flow
oAuthPermissionId=$(az ad app show --id $serverAppId --query "oauth2Permissions[0].id" -o tsv)

# Assign permissions for the client and server applications to communicate with each other
az ad app permission add --id $clientAppId --api $serverAppId --api-permissions $oAuthPermissionId=Scope
az ad app permission grant --id $clientAppId --api $serverAppId

# Create a resource group the AKS cluster if it doesn't already exist
az group create --name $resourcegroup --location $location

# Create the service principal for the AKS cluster to use

az ad sp create --id $serverAppId
aksAppId=$(az ad app create \
    --display-name "${aksname}-aks" \
    --identifier-uris "https://${aksname}-aks" \
    --query appId -o tsv)

az ad sp create --id $aksAppId --skip-assignment

# Get the service principal secret
aksApplicationSecret=$(az ad sp credential reset \
    --name $aksAppId \
    --credential-description "AKSPassword" \
    --query password -o tsv)

# Get the Azure AD tenant ID to integrate with the AKS cluster
tenantId=$(az account show --query tenantId -o tsv)

# Get the subnetId
subnetId=$(az network vnet subnet show --resource-group $resourcegroup --vnet-name $vnetName --name $subnetName --query id --output tsv)

# Create the AKS cluster and provide all the Azure AD integration parameters
az aks create \
  --resource-group $resourcegroup \
  --name $aksname \
  --node-count 1 \
  --generate-ssh-keys \
  --aad-server-app-id $serverAppId \
  --aad-server-app-secret $serverApplicationSecret \
  --aad-client-app-id $clientAppId \
  --aad-tenant-id $tenantId


az aks create \
  --resource-group $resourcegroup \
  --name $aksname \
  --location $location \
  --node-count 3 \
  --generate-ssh-keys \
  --aad-server-app-id $serverAppId \
  --aad-server-app-secret $serverApplicationSecret \
  --aad-client-app-id $clientAppId \
  --aad-tenant-id $tenantId \
  --network-plugin azure \
  --service-cidr 10.0.0.0/16 \
  --dns-service-ip 10.0.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --vnet-subnet-id $subnetId  \
  --service-principal $aksAppId \
  --client-secret $aksApplicationSecret

exit 0
