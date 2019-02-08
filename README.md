# iot-x509-testing

The purpose of this solution is to be able to test x509 certificates with self 509 certs signed by an Intermediate CA.  It uses the base of the scripts provided in the azure-iot-sdk which is a solution not recommended to be used in a production scenario and for testing purposes only.


__PreRequisites__

Requires the use of [direnv](https://direnv.net/).
Requires the use of Azure CLI


## Provision the Azure Resources

This script will generate the following resources in Azure.

1. Key Vault

1. IoT Hub

1. Device Provisioning Service

```bash
./provision.sh
```

The script also will create a .envrc file that is then used in the next step.

```bash
# Azure Resources
export VAULT="<key_vault>"
export HUB="<iot_hub>"
export DPS="<iot_dps>"
export DPS_GROUP="<resource_group>"

# Certificate Authority
export ORGANIZATION="<organization>"
export ROOT_CA_PASSWORD="<password>"
export INT_CA_PASSWORD="<password>"
```

> The default ORGANIZATION is `testonly` if you wish to change this you must modify the following:
  - .envrc
  - root_ca.dnf
  - intermediate_ca.dnf

## Creating and upload the Root CA and Intermediate Certificates

This script will create a Root and an Intermediate CA located in src/pki then perform the following actions.

1. Upload the Certificates, Keys, and Passwords used to the KeyVault.

1. Upload the Root and Intermediate CA certificates to the IoT Hub and validate them.

1. Upload the Root and Intermediate CA certificates to the IoT DPS and validate them.

```bash
./init-ca.sh
```

### Current Issue List

KeyVault Issues
  - [PEM Import Support](https://github.com/MicrosoftDocs/azure-docs/issues/23558)
  - [PFX Import Support](https://github.com/MicrosoftDocs/azure-docs/issues/16543)

DPS Issues
  - Creating Enrollment Groups

-----------------------------------------------------------------

### Working Notes

#### Storing CA Certificates and Private Keys in a Vault


```bash
# Option 1 -- Import PEM with private key
cat "./src/pki/certs/${ORGANIZATION}.root.ca.cert.pem" "./src/pki/private/${ORGANIZATION}.root.ca.key.pem" > "./src/pki/private/${ORGANIZATION}.root.ca.certwithkey.pem"

az keyvault certificate import \
  --vault-name $VAULT \
  --name "${ORGANIZATION}-root" \
  --file "./src/pki/private/${ORGANIZATION}.root.ca.certwithkey.pem"

# Option 1 Result
PEM is in unexpected format

# Option 2 - Import PFX certificate
az keyvault certificate import \
  --vault-name $VAULT \
  --name "${ORGANIZATION}-root" \
  --file "./src/pki/certs_pfx/${ORGANIZATION}.root.ca.cert.pfx"

# Option 2 Result
We could not parse the provided certificate as .pem or .pfx. Please verify the certificate with OpenSSL.
```

### Creating Device Certificates

```bash
# Creating a Edge Device Certificates
NAME="edge-ubuntu"
./generate.sh edge $NAME
cat ./certs/$NAME.cert.pem ./certs/$ORGANIZATION.intermediate.cert.pem ./certs/$ORGANIZATION.root.ca.cert.pem > ./certs/$NAME-chain.cert.pem

az keyvault certificate import --vault-name $VAULT --file "./certs_pfx/${NAME}.cert.pfx" --name $NAME --password $PASSWORD
az keyvault key import --vault-name $VAULT --pem-file "./private/${NAME}.key.pem" --name "${NAME}-key"

scp ./certs/$ORGANIZATION.root.ca.cert.pem $NAME:~/$ORGANIZATION.root.ca.cert.pem
scp ./certs/$NAME.cert.pem $NAME:~/$NAME-chain.cert.pem
scp ./private/$NAME.key.pem $NAME:~/$NAME.key.pem


# Creating a Edge Device Certificates
NAME="edge-windows"
./generate.sh edge $NAME
cat ./certs/$NAME.cert.pem ./certs/$ORGANIZATION.intermediate.cert.pem ./certs/$ORGANIZATION.root.ca.cert.pem > ./certs/$NAME-chain.cert.pem

az keyvault certificate import --vault-name $VAULT --file "certs_pfx/${NAME}.cert.pfx" --name $NAME --password $PASSWORD
az keyvault key import --vault-name $VAULT --pem-file "./private/${NAME}.key.pem" --name "${NAME}-key"



# Creating a Device Certificates
NAME="DirectDevice"
./generate.sh device $NAME
cat ./certs/$NAME.cert.pem ./certs/$ORGANIZATION.intermediate.cert.pem ./certs/$ORGANIZATION.root.ca.cert.pem > ./certs/$NAME-chain.cert.pem

az keyvault certificate import --vault-name $VAULT --file "certs_pfx/${NAME}.cert.pfx" --name $NAME --password $PASSWORD
az keyvault key import --vault-name $VAULT --pem-file "./private/${NAME}.key.pem" --name "${NAME}-key"
```

### Creating Self Signed Device Certificates

```bash
DEVICE="cli-device-509"

# Create  a Device with x509 Self Signed by Hub
az iot hub device-identity create -n $HUB -d $DEVICE --am x509_thumbprint --valid-days 10

az iot hub device-identity create -n $HUB -d $DEVICE --am x509_thumbprint --output-dir self_signed

az iot hub device-identity create \
  --hub-name $HUB \
  --device-id $DEVICE \
  --auth-method x509_thumbprint \
  --primary-thumbprint $Thumbprint \
  --secondary-thumbprint $Thumbprint

az iot hub device-identity create -n $HUB -d kv-device --am x509_thumbprint --ptp [Thumbprint 1] --stp [Thumbprint 2]
```
