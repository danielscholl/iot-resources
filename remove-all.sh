#!/usr/bin/env bash
#
#  Purpose: Removes all resources
#  Usage:
#    remove-all.sh

###############################
## ARGUMENT INPUT            ##
###############################

usage() { echo "Usage: remove-all.sh " 1>&2; exit 1; }

if [ -f ./.envrc ]; then source ./.envrc; fi

if [ ! -z $1 ]; then PREFIX=$1; fi
if [ -z $PREFIX ]; then
  PREFIX="pp"
fi

printf "\n"
tput setaf 2; echo "Defining the Resource Group" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0
AZURE_GROUP="$PREFIX-resources"
tput setaf 3; echo "Resource Group = $AZURE_GROUP"

# Remove the Resource Group
printf "\n"
tput setaf 2; echo "Removing Azure Resource Group" ; tput sgr0
tput setaf 3; echo "-----------------------------" ; tput sgr0
az deployment delete \
--name iot-resources \
--no-wait \
-oyaml

az group delete \
  --name $AZURE_GROUP \
  --yes \
  --no-wait


# Remove the Private Key Folder
printf "\n"
tput setaf 2; echo "Removing Localhost Certificate Store" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0
rm -rf ./src/pki

# Remove ACI Deployments
printf "\n"
tput setaf 2; echo "Removing Localhost Certificate Store" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0
rm -f ./aci/*.yaml


# Remove the Environment File
printf "\n"
tput setaf 2; echo "Removing environment file" ; tput sgr0
tput setaf 3; echo "-------------------------" ; tput sgr0
rm .envrc
