# Azure Key Vault

- [Keys](#keys)
  - [HSM](#hsm)
    - [Azure Dedicated HSM](#azure-dedicated-hsm)
  - [Bring your own key (BYOK)](#bring-your-own-key-byok)
- [Secrets](#secrets)
- [Certificate](#certificate)
  - [Certificate composition](#certificate-composition)
  - [Certificate Policy](#certificate-policy)
- [Permission models](#permission-models)
  - [Read a secret](#read-a-secret)
  - [Understanding built-in roles](#understanding-built-in-roles)
- [Recover](#recover)
- [Networking](#networking)
- [Vault authentication](#vault-authentication)
- [Replication and Backup](#replication-and-backup)
- [Best practices](#best-practices)
- [CLI](#cli)


## Keys

- Represented as JSON Web Key (JWK)
- Can store both symmetric and asymmetric keys
- Two types:
  - Soft keys: processed in software, but encrypted at rest by a system key in a HSM (Hardware Security Module)
  - Hard keys: processed in HSM
- Once generated or imported to a key vault, your app **NEVER** has direct access to the private keys, public keys could be retrieved
- A key pair could be used for operations like:
  - signing/verifying
  - key encryption/wrapping: protect another key, typically a symmetric **content encryption key (CEK)**
    - When the key in vault is symmetric, key wrapping is used
    - When the key in vault is asymmetric, key encryption is used
  - encryption/decryption
- Can be single instanced or be versioned (primary and secondary keys)
- You can configure a key rotation policy, which would rotate your keys automatically before expiration.
  - Some clients (such as Azure Storage) support querying for the latest version of a key, so you don't need to do anything on the client side.
- Scenarios: asymmetric master key of Microsoft Azure RMS, SQL Server TDE (Transparent Data Encryption), CLE.
  - The one saved in a key vault is usually a key-protecting key, it just encrypts another key (which encypts the data in storage account or SQL Server).

### HSM

Two offerings:

- Azure Dedicated HSM (not a fit for most customers)
- Azure Key Vault Managed HSM

#### Azure Dedicated HSM

- FIPS 140-2 Level 3 validated
- Can be provisioned:
  - As a pair for high availability
  - Across regions
- Uses Thales Luna 7 HSM model A790 appliances
- Configured and manged via Thales customer support portal
- Only the customer has administrative or application-level access to the device
  - After the customer accesses the device for the first time, and changes the password
  - Microsoft does maintain monitor-level access (not an admin role) for telemetry via serial port connection. This access covers hardware monitors such as temperature, power supply health, and fan health.
- Not a fit for most customers, need >= 5M USD annual Azure spending to qualify
- NOT integrated with Azure services which support CMK encryption, eg. Azure Storage, Azure SQL

### Bring your own key (BYOK)

This refers to importing a key from an on-prem HSM to an Azure key vault, steps:

1. Generate a Key Exchange Key (KEK) in Azure key vault
2. Download the public key of the KEK
3. Use HSM vendor provided BYOK tool - import the KEK public key, export the target key (protected by the KEK, usually as a `.byok` blob)
4. Import the protected target key to Azure key vault


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

Operatons on the secret and key:

- If the private key is exportable, you could retrieve the cert with the private key from the addressable secret.
- The addresssable key's operations are mapped from the *keyusage* field of the policy used to create the cert.
- When the certificate expires, its addressable key and secret become inoperable.

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

### Certificate Policy

Each certificate has a policy, including:

- X509 certificate properties: subject name, alternative names etc
- Key properties: key type, length, exportable etc
- Secret properties: content type of addressable secret
- **Lifetime Actions**: Contains lifetime actions for the Key Vault certificate. Each lifetime action contains:
  - Trigger, which specifies via days before expiry or lifetime span percentage.
  - Action, which specifies the action type: *emailContacts*, or *autoRenew*.
- Issuer: Contains the parameters about the certificate issuer to use to issue x509 certificates.
- Policy attributes: Contains attributes associated with the policy.


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

### Understanding built-in roles

| Built-in role                       | Permission model | Management or data plane | Can                                                         |
| ----------------------------------- | ---------------- | ------------------------ | ----------------------------------------------------------- |
| Key Vault Secrets User              | RBAC             | D                        | read secrets                                                |
| Key Vault Secrets Officer           | RBAC             | D                        | any action on secrets                                       |
| Key Vault Administrator             | RBAC             | D                        | all actions on secrets/keys/certs                           |
| Key Vault Data Access Administrator | RBAC             | M                        | assign data plane RBAC roles                                |
| Key Vault Contributor               | -                | M                        | no access to data plane values, can change permission model |
| Key Vault Reader                    | -                | M                        | no access to data plane values                              |


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
- The trusted services
  - Include Office 365 Exchange Online, Office 365 SharePoint Online, Azure compute, Azure Resource Manager, and Azure Backup
  - **NOT** include Logic Apps, Azure DevOps, etc
  - Still need to present a valid Microsoft Entra token, and must have permissions (configured as access policies) to perform the requested operation
- **Exception still applies** even if you choose "Disable public access"

Notes:

- *This only applies to the data plane, so you might be able to see a key vault in the Portal, but can NOT list the secrets in it*


## Vault authentication

Applications can access Key Vault in two ways:

- **User plus application access**. The application accesses Key Vault on behalf of a signed-in user. For example, Azure PowerShell and the Azure portal. User access is granted in two ways. They can either
  - access Key Vault from **any application**,
  - or they must use a **specific application** (referred to as compound identity).
- **Application-only access**. The application runs as a daemon service or background job. The application identity is granted access to the key vault.

For application-only access, you could use a service principal or a managed identity:

1. **Service principle**

    - You register your app as a service principle, and assign vault permissions to it;
    - The app uses its password or certificate to get an AAD authentication token;
    - Then the app can access Vault secrets using the token;
    - There is a *bootstrapping problem*, all your secrets are securely saved in the Vault, but you still need to keep a secret outside of the vault to access them;

2. **Managed identities** for Azure resources

    - When you enable managed identity on your web app, Azure activates a **separate token-granting REST service (IMDS service)** (the endpoint url is like: `http://169.254.169.254/metadata/identity/oauth2/token?api-version=...`) specifically for use by your app, your app request tokens from this service instead of directly from AAD.
    - Your app needs a secret to access this service, but that **secret is injected into your app's environment variables** by App Service when it starts up.
    - You don't need to manage or store the secret value, and nothing outside of your app can access this secret or the managed identity token service endpoint.
    - This registers your app in AAD for you, and will delete the registration if you delete the app or disable its managed identity;
    - Managed identities are free, and you can enable/disable it on an app at any time;


## Replication and Backup

Key Vault contents are natively replicated
  - within the region (allow failover to another datacenter)
  - and to the paired region (could be failed over to the paired region automatically)

Backup is not usually necessary, if you need to replicate/move a vault to other regions, you could back up then restore

- Backup/restore operation is at individual secret/key/cert level
  - you can't backup the whole vault as a whole
  - backup includes all previous versions of the object
- The backup is encrypted, can't be decrypted outside of Azure
- Backup can only be restored to a KV in the
  - same subscription
  - and in the same **geography/security boundary** (eg. backup from Australia East, restore at Australia Central, not US East)


## Best practices

- It's recommended to set up a **separate vault for each environment of each of your applications**, so if someone gained access to one of your vaults, the impact is limited;
- Don't read secrets from the vault everytime, you should cache secret values locally or load them into memory at startup time;
- Key Vault is not intended as storage for user passwords.


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
