# iot-resources

The purpose of this solution is to be able to test x509 certificates using x509 certs signed by an Intermediate CA.  It uses the base script provided in the azure-iot-sdk but heavily modified which is a solution _not recommended_ to be used in a production scenario and used for testing purposes only.


__PreRequisites__

Requires the use of [direnv](https://direnv.net/).

Requires the use of [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).

Requires the use of [OpenSSL](https://www.openssl.org).

### Related Repositories

- [iot-resources](https://github.com/danielscholl/iot-resources)  - Deploying IoT Resources and x509 Management
- [iot-device-edge](https://github.com/danielscholl/iot-device-edge) - Simple Edge Testing
- [iot-device-js](https://github.com/danielscholl/iot-device-js) - Simple Device Testing
- [iot-control-js](https://github.com/danielscholl/iot-control-js) - Simple Control Testing

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


## Create and Upload the Root CA and Intermediate Certificates

This script initializes a Root and Intermediate CA for use.

1. Creates x509 Certificates and Authorities in `./src/pki`

1. Upload the Certificates, Keys, and Passwords used to the KeyVault.

1. Uploads and Validates the Root and Intermediate CA certificates to the IoT Hub.

1. Uploads and Validates the Root and Intermediate CA certificates to the IoT DPS.

```bash
# Initializes a Root and Intermediate CA for use.
./init-ca.sh
```

## Creating and Storing Device Certificates

This script creates device certificates for use.

1. Creates an iot hub identity using a self signed certificate.

1. Creates device certificates signed by the Intermediate CA

1. Creates edge certificates signed by the Intermediate CA

1. Creates leaf certificates signed by the Intermediate CA

```bash
# Usage            <type>  <name>
./device-cert.sh   self    self-signed-device
./device-cert.sh   device  my-device
./device-cert.sh   edge    my-edge
./device-cert.sh   leaf    my-leaf
```


## Deploying to ACI

```bash
az container create --resource-group ${GROUP} --file aci/deploy-$DEVICE.yaml -oyaml
az container delete --resource-group ${GROUP} --name $DEVICE --yes -oyaml
```
### Current ToDo List

- Creating Enrollment Groups
