## Deploying to ACI

```bash
az container create --resource-group ${DPS_GROUP} --file deploy-$DEVICE.yaml -oyaml
az container delete --resource-group ${DPS_GROUP} --name $DEVICE --yes -oyaml
```
