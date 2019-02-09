# iot-x509-testing

The purpose of this solution is to be able to test x509 certificates with self 509 certs signed by an Intermediate CA.  It uses the base of the scripts provided in the azure-iot-sdk which is a solution not recommended to be used in a production scenario and for testing purposes only.


__PreRequisites__

Requires the use of [direnv](https://direnv.net/).

Requires the use of [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).


## Provision the Azure Resources

This script will generate the following resources in Azure.

1. Key Vault

1. IoT Hub

1. Device Provisioning Service

```bash
# Provision the ARM Resources
./provision.sh
```

The script creates an .envrc file to set environment variables used in creating the x509 certs.

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

> The default ORGANIZATION name is `testonly`.  These files have the reference to the organization.
  - .envrc
  - root_ca.dnf
  - intermediate_ca.dnf


## Creating and upload the Root CA and Intermediate Certificates

This script initializes a Root and Intermediate CA for use.

1. Creates x509 Certificates and Authorities in `./src/pki`

1. Upload the Certificates, Keys, and Passwords used to the KeyVault.

1. Uploads and Validates the Root and Intermediate CA certificates to the IoT Hub.

1. Uploads and Validates the Root and Intermediate CA certificates to the IoT DPS.

```bash
# Initializes a Root and Intermediate CA for use.
./init-ca.sh
```

## Creating and uploading Device Certificates

This script creates device certificates for use.

1. Creates an iot hub identity using a self signed certificate.

1. Creates device certificates signed by the Intermediate CA

1. Creates edge certificates signed by the Intermediate CA

1. Creates leaf certificates signed by the Intermediate CA

```bash
# Usage         <type>  <name>
./device-cert   self    self-signed-device
./device-cert   device  my-device
./device-cert   edge    my-edge
./device-cert   leaf    my-leaf
```

### Current Issue List

DPS Issues
  - Creating Enrollment Groups

-----------------------------------------------------------------

### Working Notes

### Creating Self Signed Device Certificates

```bash
DEVICE="cli-device-test"
mkdir src/self

# Create a Device with x509 Self Signed by Hub
az iot hub device-identity create \
  --hub-name $HUB \
  --device-id $DEVICE \
  --auth-method x509_thumbprint \
  --output-dir src/self \
  --valid-days 10

# Store the Self Signed Certificate in KeyVault
cat "./src/self/${DEVICE}-cert.pem" \
  "./src/self/${DEVICE}-key.pem" \
  > "./src/self/${DEVICE}.certwithkey.pem"

az keyvault certificate import \
  --vault-name $VAULT \
  --name ${DEVICE} \
  --file "src/self/${DEVICE}.certwithkey.pem"
```

### Creating Intermediate CA Signed Device Certificates

```bash
DEVICE="DirectDevice"

# Create a Device Certificate signed by the Intermediate CA
./src/generate.sh device $DEVICE

# Create a Full Chain Certificate
cat "./src/pki/certs/$DEVICE.cert.pem" \
  "./src/pki/certs/$ORGANIZATION.intermediate.cert.pem" \
  "./src/pki/certs/$ORGANIZATION.root.ca.cert.pem" \
  > "./src/pki/certs/$DEVICE-chain.cert.pem"

# Store the Edge Certificate in KeyVault
az keyvault certificate import \
  --vault-name $VAULT \
  --name ${DEVICE} \
  --file "./src/pki/certs_pfx/${DEVICE}.cert.pfx"
```

### Creating Intermediate CA Signed Edge Device Certificates

```bash
# Create Edge Device Certificate
DEVICE="edge-ubuntu"
./src/generate.sh edge $DEVICE

# Create a Full Chain Certificate
cat "./src/pki/certs/$DEVICE.cert.pem" \
  "./src/pki/certs/$ORGANIZATION.intermediate.cert.pem" \
  "./src/pki/certs/$ORGANIZATION.root.ca.cert.pem" \
  > "./src/pki/certs/$DEVICE-chain.cert.pem"

# Store the Edge Certificate in KeyVault
az keyvault certificate import \
  --vault-name $VAULT \
  --name ${DEVICE} \
  --file "./src/pki/certs_pfx/${DEVICE}.cert.pfx"


# Copy Edge Certificate to Edge Server
EDGE_HOST="edge-ubuntu"
scp ./certs/$ORGANIZATION.root.ca.cert.pem $EDGE_HOST:~/$ORGANIZATION.root.ca.cert.pem
scp ./certs/$NAME.cert.pem $EDGE_HOST:~/$NAME-chain.cert.pem
scp ./private/$NAME.key.pem $EDGE_HOST:~/$NAME.key.pem
```

### Creating Intermediate CA Signed Edge Device Certificates


```bash
# Create Edge Device Certificate
DEVICE="leaf-device"
./src/generate.sh leaf $DEVICE

# Create a Full Chain Certificate
cat "./src/pki/certs/$DEVICE.cert.pem" \
  "./src/pki/certs/$ORGANIZATION.intermediate.cert.pem" \
  "./src/pki/certs/$ORGANIZATION.root.ca.cert.pem" \
  > "./src/pki/certs/$DEVICE-chain.cert.pem"

# Store the Edge Certificate in KeyVault
az keyvault certificate import \
  --vault-name $VAULT \
  --name ${DEVICE} \
  --file "./src/pki/certs_pfx/${DEVICE}.cert.pfx"
```
