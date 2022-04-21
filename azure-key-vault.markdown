# Azure Key Vault

- [Concepts](#concepts)
- [Usage](#usage)
- [Security](#security)
- [Vault authentication](#vault-authentication)
- [Example](#example)
- [Best practices](#best-practices)

## Concepts

- Secrets

  - Name-value pair of strings
  - Can be passwords, SQL connection strings, etc
  - You app can retrive secrets through REST API

- Keys

  - Such as asymmetric master key of Microsoft Azure RMS, SQL Server TDE (Transparent Data Encryption), CLE.
  - Once created or added to a key vault, your app **NEVER** has direct access to the keys.
  - Can be single instanced or be versioned (primary and secondary keys)
  - There are hardware-protected and software-protected keys.

## Usage

- Secrets management
- Key management
  - Encryption keys
  - Azure services such as App Service integrate directly with Key Vault
- Certificate management
  - Provision, manage and deploy SSL/TLS certificate;
  - Request and renew certificates through parternership with certificate authorities

## Security

Two permission models:

- **Vault access policy**: for each individual vault, set permissions for users, groups, apps
- **RBAC**

You could also enable access for:

- **Azure VM for deployment**: enables Microsoft.Compute resource provider to retrieve secrets when this key vault is referenced in resource creation, for example, when creating a VM
- **Azure Resource Manager for template deployment**: enables Azure Resource Manager to get secrets when this key vault is referenced in a template deployment
- **Azure Disk Encryption for volume encryption**

## Vault authentication

Vault uses AAD to authenticate users and apps:

1. Register your app as a service principle in AAD

    - you register your app as a service principle, and assign vault permissions to it;
    - the app uses its password or certificate to get an AAD authentication token;
    - then the app can access Vault secrets using the token;
    - there is a *bootstrapping problem*, all your secrets are securely saved in the Vault, but you still need to keep a secret outside of the vault to access them;

2. Managed identities for Azure resources

    When you enable managed identity on your web app, Azure activates a **separate token-granting REST service** specifically for use by your app, your app request tokens from this service instead of directly from AAD. Your app needs a secret to access this service, but that **secret is injected into your app's environment variables** by App Service when it starts up. You don't need to manage or store the secret value, and nothing outside of your app can access this secret or the managed identity token service endpoint.

    - this registers your app in AAD for you, and will delete the registration if you delete the app or disable its managed identity;
    - managed identities are free, and you can enable/disable it on an app at any time;

## Example

```sh
az keyvault create \
    --name <your-unique-vault-name>

az keyvault secret set \
    --name password \
    --value TOP_SECRET \
    --vault-name <your-unique-vault-name>

# enable managed identity for a App Service app and grant vault access
az webapp identity assign \
    --resource-group <rg> \
    --name <app-name>

az keyvault set-policy \
    --secret-permissions get list \
    --name <vault-name> \
    --object-id <managed-identity-principleid-from-last-step>
```

In Node, Azure provides packages to access Vault secrets:

- `azure-keyvault`:
  - `KeyVaultClient.getSecret`: to read a secret;
  - `KeyVaultClient.getSecrets`: get a list of all secrets;
- `ms-rest-azure` authenticate to Azure:
  - `loginWithAppServiceMSI` login using managed identity credentials available via your environment variables;
  - `loginWithServicePrincipalSecret` login using your service principle secret;

## Best practices

- It's recommended to set up a **separate vault for each environment of each of your applications**, so if someone gained access to one of your vaults, the impace is limited;
- Don't read secrets from the vault everytime, you should cache secret values locally or load them into memory at startup time;