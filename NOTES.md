# General Notes

## Issues

- IoT Hub cli commands require --hub-name only but DPS cli commands require --dps-name and --resource-group.  (Inconsistent)
- KeyVault errors out when attempting to upload either a PEM w/ Cert&Key or pcf file containing Cert&Key&Pwd
- DPS Register Enrollment Group cli command doesn't function and doc and help is out of sync and says different things

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



## Create a Device Identity with x509 Self Signed by Hub

```bash
Name="hub-509-1"

az iot hub device-identity create \
  --hub-name $HUB \
  --device-id $Name \
  --auth-method x509_thumbprint \
  --output-dir self_signed \
  --valid-days 10
```

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


```bash
# Create  a Device with x509 Self Signed by Hub
az iot hub device-identity create -n $HUB -d cli-device-509 --am x509_thumbprint --valid-days 10

az iot hub device-identity create -n $HUB -d cli-device-509 --am x509_thumbprint --output-dir self_signed

az iot hub device-identity create \
  --hub-name $HUB \
  --device-id $Name \
  --auth-method x509_thumbprint \
  --primary-thumbprint $Thumbprint \
  --secondary-thumbprint $Thumbprint

az iot hub device-identity create -n $HUB -d kv-device --am x509_thumbprint --ptp [Thumbprint 1] --stp [Thumbprint 2]
```
