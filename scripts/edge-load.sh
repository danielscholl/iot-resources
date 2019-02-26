#!/bin/bash
GROUP="aci-devices"
LOCATION="eastus"

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

  az group create --name $GROUP --location $LOCATION

  for i in $( ls ../aci/devices |grep  leaf ); do
    az container create --resource-group $GROUP --file ../aci/devices/${i} --no-wait  -oyaml
  done
fi
