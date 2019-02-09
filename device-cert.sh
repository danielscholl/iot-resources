#!/usr/bin/env bash
#
#  Purpose: Generate Device Certs and Store in Key Vault
#  Usage:
#    device-cert.sh <type> <name>


function create_chain()
{
  printf "\n"
  tput setaf 2; echo "Creating Chain Certificate" ; tput sgr0
  tput setaf 3; echo "--------------------------" ; tput sgr0

  # Concatinate the cert and pem to use as a chain
  cat "./src/pki/certs/$1.cert.pem" \
    "./src/pki/certs/$ORGANIZATION.intermediate.cert.pem" \
    "./src/pki/certs/$ORGANIZATION.root.ca.cert.pem" \
    > "./src/pki/certs/$1-chain.cert.pem"

  echo "    ./src/pki/certs/$1-chain.cert.pem"
}

function save_vault()
{
  printf "\n"
  tput setaf 2; echo "Saving to Vault" ; tput sgr0
  tput setaf 3; echo "---------------" ; tput sgr0

  # Import Certificate to the Key Vault
  az keyvault certificate import \
    --vault-name $VAULT \
    --name ${1} \
    --file "./src/pki/certs_pfx/${1}.cert.pfx" -oyaml
}

function generate_device_certificate()
{
  if [ $# -ne 1 ]; then
    echo "Usage: <subjectName>"
    exit 1
  fi

  ./src/generate.sh device $1
  create_chain $1
  save_vault $1

  # Create a Device Identity with a Self Signed x509
  az iot hub device-identity create \
    --hub-name $HUB \
    --device-id $1 \
    --auth-method x509_ca
    -oyaml
}

function generate_edge_certificate()
{
  if [ $# -ne 1 ]; then
    echo "Usage: <subjectName>"
    exit 1
  fi

  ./src/generate.sh edge $1
  create_chain $1
  save_vault $1
}

function generate_leaf_certificate()
{
  if [ $# -ne 1 ]; then
    echo "Usage: <subjectName>"
    exit 1
  fi

  ./src/generate.sh leaf $1
  create_chain $1
  save_vault $1
}

function generate_self_certificate()
{
  printf "\n"
  tput setaf 2; echo "Creating Device Identity" ; tput sgr0
  tput setaf 3; echo "------------------------" ; tput sgr0

  # Create a Device Identity with a Self Signed x509
  az iot hub device-identity create \
    --hub-name $HUB \
    --device-id $1 \
    --auth-method x509_thumbprint \
    --output-dir "./src/pki/self" \
    --valid-days 10 \
    -oyaml

  cat "./src/pki/self/${1}-cert.pem" \
    "./src/pki/self/${1}-key.pem" \
    > "./src/pki/self/${1}.certwithkey.pem"

  az keyvault certificate import \
    --vault-name $VAULT \
    --name ${1} \
    --file "./src/pki/self/${1}.certwithkey.pem" \
    -oyaml

  echo "    ./src/pki/self/${1}.certwithkey.pem"
}


if [ "${1}" == "device" ]; then
    generate_device_certificate "${2}"
elif [ "${1}" == "edge" ]; then
    generate_edge_certificate "${2}"
elif [ "${1}" == "leaf" ]; then
    generate_leaf_certificate "${2}"
elif [ "${1}" == "self" ]; then
    generate_self_certificate "${2}"
else
    echo "Usage: device <deviceName>  # Creates a new device certificate"
    echo "       edge   <deviceName>  # Creates a new edge device certificate"
    echo "       leaf   <deviceName>  # Creates a new edge leaf certificate"
    echo "       self   <deviceName>  # Creates a new self signed certificate"
    exit 1
fi
