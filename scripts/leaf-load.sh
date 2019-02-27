#!/bin/bash
GROUP="aci-devices"
LOCATION="eastus"

function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (LOCATION) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az group show --name $1)
  if [ "$_result"  == "" ]
    then
      OUTPUT=$(az group create --name $1 \
        --location $2 \
        -oyaml)
    else
      tput setaf 3;  echo "Resource Group $1 already exists."; tput sgr0
    fi
}

if [ ! -z $CREATE ]; then
  printf "\n"
  tput setaf 2; echo "Creating the Deployments" ; tput sgr0
  tput setaf 3; echo "-----------------------" ; tput sgr0

  COUNT=1
  until [ $COUNT -gt $CREATE ]; do
    ./device-cert.sh leaf leaf$COUNT deploy
    let COUNT+=1
  done
fi

if [ ! -z $DEPLOY ]; then
  printf "\n"
  tput setaf 2; echo "Deploying the Devices" ; tput sgr0
  tput setaf 3; echo "-----------------------" ; tput sgr0

  CreateResourceGroup $GROUP $LOCATION
  #az group create --name $GROUP --location $LOCATION

  COUNT=1
  until [ $COUNT -gt $DEPLOY ]; do
    tput setaf 4; echo "---> Deploying: leaf${COUNT}"  ; tput sgr0
    az container create --resource-group $GROUP --file ./aci/deploy-leaf${COUNT}.yaml --no-wait  -oyaml
    let COUNT+=1
  done
fi
