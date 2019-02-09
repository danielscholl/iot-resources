#!/usr/bin/env bash
#
#  Purpose: Removes all resources
#  Usage:
#    remove-all.sh


# Remove the Resource Group
printf "\n"
tput setaf 2; echo "Removing Azure Resource Group" ; tput sgr0
tput setaf 3; echo "-----------------------------" ; tput sgr0
az group delete \
  --name $DPS_GROUP \
  --yes \
  --no-wait


# Remove the Private Key Folder
printf "\n"
tput setaf 2; echo "Removing Localhost Certificate Store" ; tput sgr0
tput setaf 3; echo "------------------------------------" ; tput sgr0
rm -rf "./src/pki"


# Remove the Environment File
printf "\n"
tput setaf 2; echo "Removing environment file" ; tput sgr0
tput setaf 3; echo "-------------------------" ; tput sgr0
rm .envrc
