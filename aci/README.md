## Deploying to ACI

```bash
az container create --resource-group ${GROUP} --file deploy-$DEVICE.yaml -oyaml
az container delete --resource-group ${GROUP} --name $DEVICE --yes -oyaml
```
