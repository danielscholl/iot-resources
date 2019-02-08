#!/usr/bin/env bash
#
#  Purpose: Generate Root and Intermediate CA then register to Hub and DPS
#  Usage:
#    init-ca.sh


function validate_cleanup()
{
  rm -f ./src/pki/private/${ORGANIZATION}-verify.key.pem
  rm -f ./src/pki/certs/${ORGANIZATION}-verify.cert.pem
  rm -f ./src/pki/certs_pfx/${ORGANIZATION}-verify.cert.pfx
  rm -f ./src/pki/csr/${ORGANIZATION}-verify.csr.pem
}


##############################
## Creating PKI CA Certs    ##
##############################
printf "\n"
tput setaf 2; echo "Generating Root and Intermediate Certificate Authorities" ; tput sgr0
tput setaf 3; echo "--------------------------------------------------------" ; tput sgr0

if [ ! -d src/pki ]; then mkdir src/pki; fi
./src/generate.sh ca


##############################
## Backup PKI to KeyVault   ##
##############################
printf "\n"
tput setaf 2; echo "Storing PKI in KeyVault" ; tput sgr0
tput setaf 3; echo "-----------------------" ; tput sgr0

# Store the Root CA Key Password in the Vault
az keyvault secret set \
  --vault-name $VAULT \
  --name "$ORGANIZATION-ROOT-CA-PASSWORD" \
  --value $ROOT_CA_PASSWORD \
  -ojson

# Store the Intermediate CA Key Password in the Vault
az keyvault secret set \
  --vault-name $VAULT \
  --name "$ORGANIZATION-INT-CA-PASSWORD" \
  --value $INT_CA_PASSWORD \
  -ojson

# Store the Root CA Private Key in the Vault
az keyvault key import \
  --vault-name $VAULT \
  --name "${ORGANIZATION}-root-ca-key" \
  --pem-password $ROOT_CA_PASSWORD \
  --pem-file "./src/pki/private/${ORGANIZATION}.root.ca.key.pem"

# Store the Intermediate CA Private Key in the Vault
az keyvault key import \
  --vault-name $VAULT \
  --name "${ORGANIZATION}-intermediate-key" \
  --pem-password $INT_CA_PASSWORD \
  --pem-file "./src/pki/private/${ORGANIZATION}.intermediate.key.pem"

tput setaf 5; echo "** KeyVault cli certificate import bugs prevent uploading certs to KV **" ; tput sgr0
##  BUGS DON"T ALLOW THIS YET   ##
# Store the Root CA Certificate in the Vault
# az keyvault certificate import \
#   --vault-name $VAULT \
#   --name "${ORGANIZATION}-root" \
#   --file "./src/pki/certs_pfx/${ORGANIZATION}.root.ca.pfx"

# Store the Intermediate CA Certificate in the Vault
# az keyvault certificate import \
#   --vault-name $VAULT \
#   --name "${ORGANIZATION}-root" \
#   --file "./src/pki/certs_pfx/${ORGANIZATION}.intermediate.pfx"




###############################
## Upload Root CA to IoT Hub ##
###############################
printf "\n"
tput setaf 2; echo "Uploding Root CA Certificate to IoT Hub" ; tput sgr0
tput setaf 3; echo "---------------------------------------" ; tput sgr0

# Upload the Certificates to IoT Hub
az iot hub certificate create \
  --name "${ORGANIZATION}-ca" \
  --hub-name $HUB \
  --path src/pki/certs/${ORGANIZATION}.root.ca.cert.pem -ojson

# Retrieve the Certificate ETAG
ETAG=$(az iot hub certificate show \
        --name "${ORGANIZATION}-ca" \
        --hub-name $HUB \
        --query etag -otsv)

# Generate a Verification Code for the Certificate
CODE=$(az iot hub certificate generate-verification-code \
                --name "${ORGANIZATION}-ca" \
                --hub-name $HUB \
                --etag $ETAG \
                --query properties.verificationCode -otsv)

# Generate a Verification Certificate signed by the Root CA to prove CA ownership
./src/generate.sh verify $CODE

# Retrieve the Certificate ETAG which changed when the Verification Code was generated
ETAG=$(az iot hub certificate show \
        --name "${ORGANIZATION}-ca" \
        --hub-name $HUB \
        --query etag -otsv)

# Verify the CA Certificate with the Validation Certificate
az iot hub certificate verify \
  --name "${ORGANIZATION}-ca" \
  --hub-name $HUB \
  --etag $ETAG \
  --path src/pki/certs/${ORGANIZATION}-verify.cert.pem -ojson

# Cleanup Here as generate.sh isn't doing this properly yet.  (Timing?)
validate_cleanup


#######################################
## Upload Intermediate CA to IoT Hub ##
#######################################
printf "\n"
tput setaf 2; echo "Uploding Intermediate CA Certificate to IoT Hub" ; tput sgr0
tput setaf 3; echo "-----------------------------------------------" ; tput sgr0

# Upload the Certificates to IoT Hub
az iot hub certificate create \
  --name "${ORGANIZATION}-intermediate" \
  --hub-name $HUB \
  --path src/pki/certs/${ORGANIZATION}.intermediate.cert.pem -ojson

# Retrieve the Certificate ETAG
ETAG=$(az iot hub certificate show \
        --name "${ORGANIZATION}-intermediate" \
        --hub-name $HUB \
        --query etag -otsv)

# Generate a Verification Code for the Certificate
CODE=$(az iot hub certificate generate-verification-code \
                --name "${ORGANIZATION}-intermediate" \
                --hub-name $HUB \
                --etag $ETAG \
                --query properties.verificationCode -otsv)

# Generate a Verification Certificate signed by the Root CA to prove CA ownership
./src/generate.sh verify-intermediate $CODE

# Retrieve the Certificate ETAG which changed when the Verification Code was generated
ETAG=$(az iot hub certificate show \
        --name "${ORGANIZATION}-intermediate" \
        --hub-name $HUB \
        --query etag -otsv)

# Verify the CA Certificate with the Validation Certificate
az iot hub certificate verify \
  --name "${ORGANIZATION}-intermediate" \
  --hub-name $HUB \
  --etag $ETAG \
  --path src/pki/certs/${ORGANIZATION}-verify.cert.pem -ojson


# Cleanup Here as generate.sh isn't doing this properly yet.  (Timing?)
validate_cleanup


##############################
## Upload Root CA to DPS    ##
##############################
printf "\n"
tput setaf 2; echo "Uploding Root CA Certificate to DPS" ; tput sgr0
tput setaf 3; echo "-----------------------------------" ; tput sgr0

# Upload the Certificates to DPS
az iot dps certificate create \
  --name "${ORGANIZATION}-ca" \
  --resource-group $DPS_GROUP \
  --dps-name $DPS \
  --path src/pki/certs/${ORGANIZATION}.root.ca.cert.pem -ojson

# Retrieve the Certificate ETAG
ETAG=$(az iot dps certificate show \
        --name "${ORGANIZATION}-ca" \
        --resource-group $DPS_GROUP \
        --dps-name $DPS \
        --query etag -otsv)

# Generate a Verification Code for the Certificate
CODE=$(az iot dps certificate generate-verification-code \
                --name "${ORGANIZATION}-ca" \
                --dps-name $DPS \
                --resource-group $DPS_GROUP \
                --etag $ETAG \
                --query properties.verificationCode -otsv)

# Generate a Verification Certificate signed by the Root CA to prove CA ownership
./src/generate.sh verify $CODE

# Retrieve the Certificate ETAG which changed when the Verification Code was generated
ETAG=$(az iot dps certificate show \
        --name "${ORGANIZATION}-ca" \
        --dps-name $DPS \
        --resource-group $DPS_GROUP \
        --query etag -otsv)

# Verify the CA Certificate with the Validation Certificate
az iot dps certificate verify \
  --name "${ORGANIZATION}-ca" \
  --dps-name $DPS \
  --resource-group $DPS_GROUP \
  --etag $ETAG \
  --path src/pki/certs/${ORGANIZATION}-verify.cert.pem -ojson

# Cleanup Here as generate.sh isn't doing this properly yet.  (Timing?)
validate_cleanup


####################################
## Upload Intermediate CA to DPS  ##
####################################
printf "\n"
tput setaf 2; echo "Uploding Intermediate CA Certificate to DPS" ; tput sgr0
tput setaf 3; echo "-------------------------------------------" ; tput sgr0

# Upload the Certificates to DPS
az iot dps certificate create \
  --name "${ORGANIZATION}-intermediate" \
  --resource-group $DPS_GROUP \
  --dps-name $DPS \
  --path src/pki/certs/${ORGANIZATION}.intermediate.cert.pem -ojson

# Retrieve the Certificate ETAG
ETAG=$(az iot dps certificate show \
        --name "${ORGANIZATION}-intermediate" \
        --resource-group $DPS_GROUP \
        --dps-name $DPS \
        --query etag -otsv)

# Generate a Verification Code for the Certificate
CODE=$(az iot dps certificate generate-verification-code \
                --name "${ORGANIZATION}-intermediate" \
                --dps-name $DPS \
                --resource-group $DPS_GROUP \
                --etag $ETAG \
                --query properties.verificationCode -otsv)

# Generate a Verification Certificate signed by the Root CA to prove CA ownership
./src/generate.sh verify-intermediate $CODE

# Retrieve the Certificate ETAG which changed when the Verification Code was generated
ETAG=$(az iot dps certificate show \
        --name "${ORGANIZATION}-intermediate" \
        --dps-name $DPS \
        --resource-group $DPS_GROUP \
        --query etag -otsv)

# Verify the CA Certificate with the Validation Certificate
az iot dps certificate verify \
  --name "${ORGANIZATION}-intermediate" \
  --dps-name $DPS \
  --resource-group $DPS_GROUP \
  --etag $ETAG \
  --path src/pki/certs/${ORGANIZATION}-verify.cert.pem -ojson

# Cleanup Here as generate.sh isn't doing this properly yet.  (Timing?)
validate_cleanup


##############################
## Add DPS Enrollment Group ##
##############################
printf "\n"
tput setaf 2; echo "Create Enrollment Group for Root & Intermediate CA" ; tput sgr0
tput setaf 3; echo "--------------------------------------------------" ; tput sgr0

tput setaf 5; echo "** DPS cli enrollment-group bugs prevent creating enrollement group **" ; tput sgr0
##  BUGS DON"T ALLOW THIS YET   ##
# # Register the Enrollement Group
# az iot dps enrollment-group create \
#   --dps-name $DPS \
#   --resource-group $DPS_GROUP \
#   --enrollment-id "${ORGANIZATION}" \
#   --root-ca-name "${ORGANIZATION}-ca"
