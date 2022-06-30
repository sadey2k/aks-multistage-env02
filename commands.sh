## Commands using CLI ##

#################################################
## Variables ##
#################################################
TENANT_ID="375b0336-a057-4ecb-b117-e02bf5b9a1a9"
SUBSCRIPTION="c88c8f23-28fa-446c-9737-a0a749bb194f"
BACKEND_RG_NAME="sadey2k-backendRG"
STORAGE_ACCOUNT_NAME="sadey2ksa"
STORAGE_ACCOUNT_KEY=
CONTAINER_NAME="tfstate"
INFRA_RG_NAME="sadey2k-aksRG"
RESOURCE_GROUP_LOCATION="ukwest"
ACR_NAME="sadey2kacr"
KEYVAULT_NAME="sadey2kKV"
TAG="dev"
SPN_NAME="sadey2k-aks-sp"
CLUSTER_NAME="sadey2k-aks-cluster"

#################################################
## Additional commands ##
#################################################

## get tenant and subscription id 
az login

## get subscription id only
az account list -o table

#################################################
## Create resource groups ##
#################################################

## backend
az group create -n $BACKEND_RG_NAME -l $RESOURCE_GROUP_LOCATION

## infra
az group create -n $INFRA_RG_NAME -l $RESOURCE_GROUP_LOCATION --tags $TAG

#################################################
## Create key vault ##
#################################################

az keyvault create -n $KEYVAULT_NAME -g $INFRA_RG_NAME --tags $TAG

#################################################
## Create storage account ##
#################################################

az storage account create -n $STORAGE_ACCOUNT_NAME -g $BACKEND_RG_NAME --sku Standard_LRS --encryption-services blob --tags $TAG

# Add the storage account key as a secret in the key vault
az keyvault secret set --vault-name $KEYVAULT_NAME --name "backend-sa-access-key" --value $STORAGE_ACCOUNT_KEY

#################################################
## Create container ##
#################################################

az storage container create -n $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME  --account-key $STORAGE_ACCOUNT_KEY 

#################################################
## Create ACR ##
#################################################

az acr create -n $ACR_NAME -g $INFRA_RG_NAME --sku basic --tags $TAG


######################################################
## CREATE SERVICE PRINCIPLE
######################################################
# Create AKS service principal and add corresponding secrets to key vault

az ad sp create-for-rbac --name $SPN_NAME --skip-assignment 

AKS_CLIENT_ID=
AKS_CLIENT_SECRET=
az keyvault secret set --vault-name $KEYVAULT_NAME --name "aks-sp2-id" --value "$AKS_CLIENT_ID"
az keyvault secret set --vault-name $KEYVAULT_NAME --name "aks-sp2-secret" --value "$AKS_CLIENT_SECRET"

az role assignment create --role "Owner" --assignee $AKS_CLIENT_ID --resource-group $INFRA_RG_NAME

#az role assignment create --assignee "sadey2k-aks-sp" --scope /subcriptions/$SUBSCRIPTION --role Contributor

#################################################
## Create SSH key ##
#################################################

AKS_SSH_KEY_LOCATION=$HOME/.ssh/aks-prod-sshkeys/aksprodsshkey.pub
echo $AKS_SSH_KEY_LOCATION

## add ssh key to the key vault
az keyvault secret set --vault-name $KEYVAULT_NAME -n 'aks-ssh-keysecret' -f $AKS_SSH_KEY_LOCATION

# you want to authorize the application to decrypt and sign with keys in your vault, use the following command:
az keyvault set-policy --name $KEYVAULT_NAME --spn 5a8cc7d2-17df-4bf4-ad32-665c5ff54ccb --key-permissions decrypt sign

# To authorize the same application to read secrets in your vault, type the following command:
az keyvault set-policy --name $KEYVAULT_NAME --spn 5a8cc7d2-17df-4bf4-ad32-665c5ff54ccb --secret-permissions get

#pubkey=$HOME/.ssh/aks-prod-sshkeys/aksprodsshkey.pub
#az keyvault secret set --vault-name $KEYVAULT_NAME --name "aks-ssh-keysecret" --value "$AKS_CLIENT_ID"

#################################################
## Create Network ##
#################################################

#### Create Azure Virtual Network and subnet ####
AKS_VNET="aks-vnet"
AKS_VNET_ADDRESS_PREFIX="10.0.0.0/8"
AKS_VNET_SUBNET_DEFAULT="aks-subnet-default2"
AKS_VNET_SUBNET_DEFAULT_PREFIX="10.240.0.0/16"


#### Create Virtual Network & default Subnet ####
az network vnet create -g $INFRA_RG_NAME \
                       -n ${AKS_VNET} \
                       --address-prefix ${AKS_VNET_ADDRESS_PREFIX} \
                       --subnet-name ${AKS_VNET_SUBNET_DEFAULT} \
                       --subnet-prefix ${AKS_VNET_SUBNET_DEFAULT_PREFIX}



## Get Virtual Network default subnet id
AKS_VNET_SUBNET_DEFAULT_ID=$(az network vnet subnet show \
                           --resource-group $INFRA_RG_NAME \
                           --vnet-name ${AKS_VNET} \
                           --name ${AKS_VNET_SUBNET_DEFAULT} \
                           --query id \
                           -o tsv)
echo ${AKS_VNET_SUBNET_DEFAULT_ID}


#################################################
## Create Log Analytics Workspace ##
#################################################

AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace create -g ${INFRA_RG_NAME} -n aksprod-loganalytics-workspace1 --query id --output tsv)

echo $AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID

#################################################
## Create AKS ##
#################################################
az aks create --resource-group $INFRA_RG_NAME \
              --name ${CLUSTER_NAME} \
              --enable-managed-identity \
              --ssh-key-value  ${AKS_SSH_KEY_LOCATION} \
              --admin-username aksadmin1 \
              --node-count 1 \
              --enable-cluster-autoscaler \
              --min-count 1 \
              --max-count 10 \
              --network-plugin azure \
              --service-cidr 10.0.0.0/16 \
              --dns-service-ip 10.0.0.10 \
              --docker-bridge-address 172.17.0.1/16 \
              --service-principal $AKS_CLIENT_ID \
              --client-secret $AKS_CLIENT_SECRET \
              --node-osdisk-size 30 \
              --node-vm-size Standard_DS2_v2 \
              --enable-addons monitoring \
              --workspace-resource-id ${AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID} \
              --attach-acr $ACR_NAME

              --nodepool-labels nodepool-type=system nodepoolos=linux app=system-apps \
              --nodepool-name systempool \
              --nodepool-tags nodepool-type=system nodepoolos=linux app=system-apps \
              #--vnet-subnet-id $AKS_VNET_SUBNET_DEFAULT_ID \


az aks update -g $INFRA_RG_NAME -n ${CLUSTER_NAME} --attach-acr $ACR_NAME


az aks enable-addons --addon virtual-node \
    --resource-group $INFRA_RG_NAME \
    --name ${CLUSTER_NAME} \
    --workspace-resource-id ${AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID} 


#################################################
## Docker and ACR commands ##
#################################################
# Log into the ACR
az acr login --name skylinesacr92

# Build Docker image
docker build -t golangwebapi .

# Tag a Docker image
docker tag golangwebapi skylinesacr92.azurecr.io/go/webapi

# Push Docker image to ACR
docker push skylinesacr92.azurecr.io/go/webapi

# List container images
az acr repository list --name skylinesacr --output table

# AKS to ACR Authentication
az aks update -n skylines92 -g dev2 --generate-ssh-keys --attach-acr skylinesacr92

# Deploy the sample image from ACR to AKS
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx0-deployment
  labels:
    app: nginx0-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx0
  template:
    metadata:
      labels:
        app: nginx0
    spec:
      containers:
      - name: nginx
        image: <acr-name>.azurecr.io/nginx:v1
        ports:
        - containerPort: 80


kubectl apply -f acr-nginx.yaml

kubectl get pods



#################################################
## Yaml pipeline deployment using bash  ##
#################################################

trigger: none
# - main

pool:
  vmImage: ubuntu-latest

variables:
  acr_name: contosoteam7
  tag: 1.0.0-$(Build.BuildId)

steps:

- task: AzureCLI@2
  displayName: Docker Build & Push
  inputs:
    azureSubscription: 'spn-team7'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      docker build -t $(acr_name).azurecr.io/webapp:$(tag) app-dotnet
      az acr login -n $(acr_name)
      docker push $(acr_name).azurecr.io/webapp:$(tag)