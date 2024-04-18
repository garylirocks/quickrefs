
Example deployment script:

```sh
# deploy to a RG
az deployment group create \
  --name "deployment-test-storage-account" \
  --resource-group rg-gary-playground \
  --template-file storage-account.json
```

To update just some specified properties, new properties are merged to existing properties, use:

```sh
az deployment group create \
  --name "deployment-test-storage-account" \
  --resource-group rg-gary-playground \
  --template-file storage-account-properties-update.json
```
