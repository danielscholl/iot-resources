#!/usr/bin/env bash
#
#  Purpose: Generate Device Certs and Store in Key Vault
#  Usage:
#    device-cert.sh <type> <name>


function aci_deploy() {
  if [ $# -ne 1 ]; then
    echo "Usage: <subjectName>"
    exit 1
  fi

  printf "\n"
  tput setaf 2; echo "Creating ACI Deployment" ; tput sgr0
  tput setaf 3; echo "-----------------------" ; tput sgr0

  b64_cert=$(openssl base64 -in ./src/pki/certs/${1}-chain.cert.pem |tr -d '\n')
  b64_key=$(openssl base64 -in ./src/pki/private/${1}.key.pem |tr -d '\n')
  idScope=$(az iot dps list --resource-group $DPS_GROUP --query [0].properties.idScope -otsv)

  cat > ./aci/deploy-${1}.yaml << EOF
apiVersion: '2018-06-01'
location: eastus
name: $1
properties:
  containers:
  - name: $1
    properties:
      environmentVariables:
        - name: 'DEVICE'
          value: '${1}'
        - name: 'DPS_HOST'
          value: 'global.azure-devices-provisioning.net'
        - name: 'ID_SCOPE'
          value: '${idScope}'
      image: danielscholl/iot-device-js:latest
      ports: []
      resources:
        requests:
          cpu: 1.0
          memoryInGB: 1.5
      volumeMounts:
      - mountPath: /usr/src/app/cert
        name: certvolume
  osType: Linux
  restartPolicy: Always
  volumes:
  - name: certvolume
    secret:
      device-cert.pem: ${b64_cert}
      device-key.pem: ${b64_key}
tags: {}
type: Microsoft.ContainerInstance/containerGroups
EOF
  echo "    ./aci/deploy-${1}.yaml"
}

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
  if [ $# -lt 1 ]; then
    echo "Usage: device <deviceName>"
    exit 1
  fi

  ./src/generate.sh device $1
  create_chain $1
  save_vault $1

  # Create a Device Identity with a Self Signed x509
  az iot hub device-identity create \
    --hub-name $HUB \
    --device-id $1 \
    --auth-method x509_ca \
    -oyaml

    aci_deploy ${1}

    if [ ${2}="deploy" ]; then
      printf "\n"
      tput setaf 2; echo "Deploying Device to ACI" ; tput sgr0
      tput setaf 3; echo "--------------------------" ; tput sgr0
      az container create --resource-group ${DPS_GROUP} --file aci/deploy-${1}.yaml -oyaml
    fi
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
  if [ $# -ne 1 ]; then
    echo "Usage: <subjectName>"
    exit 1
  fi

  printf "\n"
  tput setaf 2; echo "Creating Device Identity" ; tput sgr0
  tput setaf 3; echo "------------------------" ; tput sgr0

  # Create a Device Identity with a Self Signed x509
  az iot hub device-identity create \
    --hub-name $HUB \
    --device-id $1 \
    --auth-method x509_thumbprint \
    --output-dir "./src/pki/self" \
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

  aci_deploy ${1}
}


if [ ${1} == "device" ]; then
    generate_device_certificate ${2} ${3}
elif [ ${1} == "edge" ]; then
    generate_edge_certificate ${2}
elif [ ${1} == "leaf" ]; then
    generate_leaf_certificate ${2}
elif [ ${1} == "self" ]; then
    generate_self_certificate ${2}
else
    echo "Usage: device <deviceName>  # Creates a new device certificate"
    echo "       edge   <deviceName>  # Creates a new edge device certificate"
    echo "       leaf   <deviceName>  # Creates a new edge leaf certificate"
    echo "       self   <deviceName>  # Creates a new self signed certificate"
    exit 1
fi
