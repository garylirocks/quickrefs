# Azure Marketplace

- [Overview](#overview)
- [Programmatic deployment](#programmatic-deployment)

## Overview

## Programmatic deployment

- VM images
  - You need to accept legal terms first with `az vm image terms accept --publisher X --offer Y --plan Z`
  - Only need to do this once for a subscription

- SaaS offer
  - You can deploy if manually first, then visit the resource group deployment blade to get the ARM template and parameters
  - Then deploy the ARM template

    ```
    az group create --resource-group <ResourceGroupName> --location <Location>

    az deployment group create \
      --resource-group <Resource Group Name> \
      --template-file ./SaaS-ARM.json \
      --parameters name=<SaaS Resource Name> publisherId=<Publisher ID> offerId=<Product ID> planId=<Plan ID> termId=<termId> quantity=1 azureSubscriptionId=11111111-1111-1111-1111-11111111 autoRenew=true
    ```

- Azure Application

  - Three types:
    - Solution Template - free offerring, ARM template deployment
    - Packaged Application - free or paid, creates a `Microsoft.Solutions/applications` resource type, managed by customer
    - Managed Application - free or paid, creates a `Microsoft.Solutions/applications` resource type, managed by publisher

  - Like VM images, you could also agree the terms with `az vm image terms accept`
