# Azure Key Vault

- [Keys](#keys)
- [Secrets](#secrets)
- [Certificate](#certificate)
  - [Certificate composition](#certificate-composition)
- [Security](#security)
- [Vault authentication](#vault-authentication)
- [Best practices](#best-practices)
- [CLI](#cli)


## Keys

  - Such as asymmetric master key of Microsoft Azure RMS, SQL Server TDE (Transparent Data Encryption), CLE.
  - Once created or added to a key vault, your app **NEVER** has direct access to the keys
  - A key pair could be used for operations like: encryption/decryption, signing/verifying, wrapkey/unwrapkey
  - Can be single instanced or be versioned (primary and secondary keys)
  - There are hardware-protected and software-protected keys.

## Secrets

  - Name-value pair of strings
  - Can be passwords, SQL connection strings, etc
  - You app can retrive secrets through REST API
  - You could import a certificate to be a secret (*deprecated, use certificate service instead*)


## Certificate

- Create or import self-signed or CA-signed certificates
- When importing, you need a `.pfx`, or a `.pem` that includes the private key
- You could config a lifetime action: auto renew or email contacts
- Request and renew certificates through parternership with certificate authorities
- Certs could be renewed automatically if issued by a partner CA

### Certificate composition

![Certificate composition](./images/azure_certificate-composition.png)

When a certificate is created, key vault also creates an addressable key and secret with the same name.

For a cert version with this URL `https://kv-gary.vault.azure.net/certificates/cert-gary/123456789`, you would have its
  - key at  `https://kv-gary.vault.azure.net/keys/cert-gary/123456789`
  - secret at  `https://kv-gary.vault.azure.net/secrets/cert-gary/123456789`

If the private key is exportable, you could retrieve the cert with the private key from the addressable secret.

The addresssable key's operations are mapped from the *keyusage* field of the policy used to create the cert.

```sh
# download the public potion of the certificate
az keyvault certificate download \
    --file /path/to/cert.pfx \
    --vault-name VaultName \
    --name CertName \
    --encoding base64

# if the private key is exportable
# you could download the private key of a certificate
# using `az keyvault secret`
az keyvault secret download \
    --file /path/to/cert.pfx \
    --vault-name VaultName \
    --name CertName \
    --encoding base64

# convert .pfx to .pem, which would include both private key and certificate
openssl pkcs12 -in cert.pfx -passin pass: -out cert.pem -nodes
```


## Security

Two permission models:

- **Vault access policy**: for each individual vault, set permissions for users, groups, apps
- **RBAC**: access can be inherited, and can be more granular: set permissions on specific keys, secrets or certificates

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


## Best practices

- It's recommended to set up a **separate vault for each environment of each of your applications**, so if someone gained access to one of your vaults, the impace is limited;
- Don't read secrets from the vault everytime, you should cache secret values locally or load them into memory at startup time;


## CLI

```sh
az keyvault create \
    --name <your-unique-vault-name>

az keyvault secret set \
    --name password \
    --value TOP_SECRET \
    --vault-name <your-unique-vault-name>

# enable managed identity for an App Service app
az webapp identity assign \
    --resource-group <rg> \
    --name <app-name>

# grant key vault access policy
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
