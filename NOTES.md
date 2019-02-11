# General Notes

## Issues

- IoT Hub cli commands require --hub-name only but DPS cli commands require --dps-name and --resource-group.  (Inconsistent)
- DPS Register Enrollment Group cli command doesn't function and doc and help is out of sync and says different things


## Create DPS Enrollment Group

```bash
GROUP="iot-x509-testing"
DPS="$(az iot dps list --resource-group $GROUP --query [].name -otsv)"

az iot dps enrollment-group create \
  --enrollment-id 'testonly-ca' \
  --resource-group $GROUP \
  --dps-name $DPS \
  --ca-name 'testonly-ca'

```

## Create Certs with Key Vault

```bash
Name="kv-cert-1"

# Create a Certificate from Key Vault
az keyvault certificate create --name $Name \
    --vault-name $VAULT \
    --policy "$(az keyvault certificate get-default-policy -o json)"

# Download Certificate and get Fingerprint
az keyvault certificate download --name $Name \
    --vault-name $VAULT \
    --file "self_signed/$Name.pem"

# Get Fingerprint from a certificate
Thumbprint=$(openssl x509 -in "self_signed/$Name.pem" \
    -inform PEM \
    -noout -sha1 -fingerprint | cut -d = -f 2 | tr -d \:)
```



