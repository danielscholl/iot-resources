#!/usr/bin/env bash
#
#  Purpose: Create a Resource Group with a KeyVault, IoT Hub and DPS
#  Usage:
#    provision.sh


###############################
## ARGUMENT INPUT            ##
###############################

usage() { echo "Usage: provision.sh " 1>&2; exit 1; }

if [ -f ./.envrc ]; then source ./.envrc; fi

if [ -z $AZURE_LOCATION ]; then
  AZURE_LOCATION="eastus"
fi

if [ -z $AZURE_GROUP ]; then
  AZURE_GROUP="iot-testing"
fi

if [ -z $ORGANIZATION ]; then
  ORGANIZATION="testonly"
fi

if [ -z $ROOT_CA_PASSWORD ]; then
  ROOT_CA_PASSWORD="azure@rootca"
fi

if [ -z $INT_CA_PASSWORD ]; then
  INT_CA_PASSWORD="azure@azure@intermediateca"
fi

USER_ID=$(az ad user show \
        --upn-or-object-id $(az account show --query user.name -otsv) \
        --query objectId -otsv)


##############################
## Deploy ARM Resources     ##
##############################
printf "\n"
tput setaf 2; echo "Deploying the ARM Templates" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0
if [ -f ./params.json ]; then PARAMS="params.json"; else PARAMS="azuredeploy.parameters.json"; fi

cat > azuredeploy.parameters.json << EOF2
{
  "\$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminUserName": {
      "value": "$(whoami)"
    },
    "sshKeyData": {
      "value": "$(< ~/.ssh/id_rsa.pub)"
    },
    "customData": {
      "value": "$(openssl base64 -in ./cloud-init.txt |tr -d '\n')"
    }
  }
}
EOF2

az deployment create --template-file azuredeploy.json  \
  --location $AZURE_LOCATION \
  --parameters azuredeploy.parameters.json \
  --parameters userObjectId=$USER_ID group=$AZURE_GROUP \
  -oyaml

rm azuredeploy.parameters.json

##############################
## Deploy .envrc File       ##
##############################
printf "\n"
tput setaf 2; echo "Creating the Environment File .envrc" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0

VAULT=$(az keyvault list --resource-group $AZURE_GROUP --query [].name -otsv)
HUB=$(az iot hub list --resource-group $AZURE_GROUP --query [].name -otsv)
DPS=$(az iot dps list --resource-group $AZURE_GROUP --query [].name -otsv)
DPS_GROUP=$AZURE_GROUP

cat > .envrc << EOF
# Azure Resources
export VAULT="${VAULT}"
export HUB="${HUB}"
export DPS="${DPS}"
export DPS_GROUP="${DPS_GROUP}"

# Certificate Authority
export ORGANIZATION="testonly"
export ROOT_CA_PASSWORD="azure@rootca"
export INT_CA_PASSWORD="azure@intermediateca"
EOF
