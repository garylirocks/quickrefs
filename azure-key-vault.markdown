# Azure Key Vault

- [Keys](#keys)
- [Secrets](#secrets)
- [Certificate](#certificate)
  - [Certificate composition](#certificate-composition)
- [Permission models](#permission-models)
  - [Read a secret](#read-a-secret)
- [Recover](#recover)
- [Networking](#networking)
- [Vault authentication](#vault-authentication)
- [Replication](#replication)
- [Best practices](#best-practices)
- [CLI](#cli)


## Keys

  - Such as asymmetric master key of Microsoft Azure RMS, SQL Server TDE (Transparent Data Encryption), CLE.
    - The one saved in a key vault is usually a key-protecting key, it just encrypts another key (which encypts the data in storage account or SQL Server).
  - Once generated or imported to a key vault, your app **NEVER** has direct access to the private keys, public keys could be retrieved
  - A key pair could be used for operations like: encryption/decryption, signing/verifying, wrapkey/unwrapkey
  - Can be single instanced or be versioned (primary and secondary keys)
  - There are hardware-protected and software-protected keys.
  - You can configure a key rotation policy, which would rotate your keys automatically before expiration.
    - Some clients (such as Azure Storage) support querying for the latest version of a key, so you don't need to do anything on the client side.

## Secrets

  - Name-value pair of strings
  - Can be passwords, SQL connection strings, etc
  - **An SSH private key is like a password, should be saved as a "Secret", not as a "Key"**
  - You app can retrive secrets through REST API
  - You could import a certificate to be a secret (*deprecated, use certificate service instead*)


## Certificate

- Create or import self-signed or CA-signed certificates
- When importing, you need a `.pfx`, or a `.pem` that includes the private key
- You could config a **lifetime** action: auto renew or email contacts
- Request and renew certificates through parternership with certificate authorities
- Certs could be renewed automatically if issued by a partner CA

### Certificate composition

![Certificate composition](./images/azure_certificate-composition.png)

When a certificate is created, key vault also creates an addressable key and secret with the same name (**NOT visible in the Portal**).

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


## Permission models

Control plane permissions are always controlled by RBAC

For data plane, there are two models:

- **Vault access policy** (legacy):
  - assign secret/key/cert permissions for users/groups/apps
  - need to be configured for each individual key vault
  - *if a user has "Contributor" role over the vault, he can assign himself any access policy, this could be a security risk*
- **RBAC** (recommended):
  - access can be inherited, so you can assign at a higher level
  - can be granular as well: you could set permissions on specific keys, secrets or certificates

Three advanced access policy options:

- **Azure VM for deployment**: enables `Microsoft.Compute` resource provider to retrieve secrets when this key vault is referenced in resource creation, for example, when creating a VM
- **Azure Resource Manager for template deployment**: enables Azure Resource Manager to get secrets when this key vault is referenced in a template deployment
- **Azure Disk Encryption for volume encryption**

### Read a secret

To allow a service principal to retrieve value of a secret from key vault, you need to configure the access based on the permission model of the key vault:

- RBAC
  - "Key Vault Secrets User" role on the secret
  - "Key Vault Reader" role on the vault (only required by Terraform data block `azurerm_key_vault_secret`, not by AZ CLI)
- Vault access policy
  - "Get" on secrets
  - "Key Vault Reader" role on the vault (only required by Terraform data block `azurerm_key_vault_secret`, not by AZ CLI)


## Recover

After a vault is deleted, and before it's being purged (90 days by default), you can recover it.

- All the keys, secrets and certificates are recovered
- RBAC role assignments can't be recovered, you need to redo them


## Networking

Like storage accounts, you have options like:

- Allow public access from all networks
- Allow public access from specific virtual networks and IP addresses
- Disable public access

And there's an option for exception: "Allow trusted Microsoft services to bypass this firewall", see https://learn.microsoft.com/en-us/azure/key-vault/general/overview-vnet-service-endpoints#trusted-services
- This exception does not apply to logic apps
- **Exception still applies** even if you choose "Disable public access"


## Vault authentication

Vault uses AAD to authenticate users and apps:

1. Register your app as a service principle in AAD

    - you register your app as a service principle, and assign vault permissions to it;
    - the app uses its password or certificate to get an AAD authentication token;
    - then the app can access Vault secrets using the token;
    - there is a *bootstrapping problem*, all your secrets are securely saved in the Vault, but you still need to keep a secret outside of the vault to access them;

2. Managed identities for Azure resources

    When you enable managed identity on your web app, Azure activates a **separate token-granting REST service (IMDS service)** (the endpoint url is like: `http://169.254.169.254/metadata/identity/oauth2/token?api-version=...`) specifically for use by your app, your app request tokens from this service instead of directly from AAD. Your app needs a secret to access this service, but that **secret is injected into your app's environment variables** by App Service when it starts up. You don't need to manage or store the secret value, and nothing outside of your app can access this secret or the managed identity token service endpoint.

    - this registers your app in AAD for you, and will delete the registration if you delete the app or disable its managed identity;
    - managed identities are free, and you can enable/disable it on an app at any time;


## Replication

Key Vault contents are natively replicated
  - within the region (allow failover to another datacenter)
  - and to the paired region (allow failover in case of a region-wide failure)

To replicate/move it to other regions, you could back up then restore it

- Backup/restore operation is at individual secret/key/cert level
- The backup is encrypted
- Backup can only be restored to a KV in the
  - same subscription
  - and in the same **geography/security boundary** (eg. backup from Australia East, restore at Australia Central, not US East)




## Best practices

- It's recommended to set up a **separate vault for each environment of each of your applications**, so if someone gained access to one of your vaults, the impact is limited;
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
