
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

## Deployment stack

```sh
az stack sub create \
        --name "deployment-stack-test-rg" \
        --template-file resource-group.json \
        --deny-settings-mode denyWriteAndDelete \
        --deny-settings-apply-to-child-scopes \
        --location australiaeast

# use this to test whether you can create an NSG resource in the new RG
az deployment group create \
  --name "deployment-test-nsg" \
  --resource-group rg-gary-testing-001 \
  --template-file nsg.json
```
