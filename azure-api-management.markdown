# Azure API Management

- [Overview](#overview)
- [Policies](#policies)
- [Client certificates](#client-certificates)


## Overview

- You can import APIs defined in Open API, WSDL, WADL, Azure Functions, API app, ...
- Each API consists of one or more operations
- APIs can be grouped in to Product, which is a scope for policies and subscriptions (*this is API subscription, not your Azure subscription*)
- You can use subscription keys to restrict access to the API, a key can be scoped to
  - all APIs
  - a Product
  - a specific API

Call an API with a subscription key:

```sh
curl --header "Ocp-Apim-Subscription-Key: <my-subscription-key>" https://myApiName.azure-api.net/api/cars

# or as a query parameter
curl https://myApiName.azure-api.net/api/path?subscription-key=<key string>
```

## Policies

- You can add policies to APIs to:
  - cache responses (either internal cache or external Redis cache)
  - transform documents and values (e.g JSON to XML)
  - set limits (rate limit by client IP or subscription key)
  - enforce security requirements
  - call webhooks for notification or audit
- Policies can be applied at four scoped:
  - All
  - Product
  - API
  - Operation

- Policies are defined as XML documents, example:

```xml
<policies>
    <inbound>
        <base />
        <check-header name="Authorization" failed-check-httpcode="401" failed-check-error-message="Not authorized" ignore-case="false">
        </check-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <json-to-xml apply="always" consider-accept-header="false" parse-date="false" />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

*`<base />` specifies when to run upper-level policies*


## Client certificates

You can configure an **inbound policy** to only allow clients passing trusted certificates.

You can check the following certificate properties:

- Certificate Authority (CA)
- Thumbprint
- Subject
- Expiration date

Ways to verify a certificate:

- Check if it's issued by a trusted CA (you can configure trusted CA in Azure)
- Self-issued certificate (check you know this certificate)

```sh
# generate certificate
pwd='Pa$$w0rd'
pfxFilePath='selfsigncert.pfx'
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out selfsigncert.crt -subj /CN=localhost

# convert certificate to PEM format for curl
openssl pkcs12 -export -out $pfxFilePath -inkey privateKey.key -in selfsigncert.crt -password pass:$pwd
openssl pkcs12 -in selfsigncert.pfx -out selfsigncert.pem -nodes

# get fingerprint
Fingerprint="$(openssl x509 -in selfsigncert.pem -noout -fingerprint)"
Fingerprint="${Fingerprint//:}"
echo ${Fingerprint#*=}
```

Add an inbound policy, which checks thumbprint of the certificate

```xml
<inbound>
    <choose>
        <when condition="@(context.Request.Certificate == null || context.Request.Certificate.Thumbprint != "desired-thumbprint")" >
            <return-response>
                <set-status code="403" reason="Invalid client certificate" />
            </return-response>
        </when>
    </choose>
    <base />
</inbound>
```

Call API with both a subscription key and a certificate:

```sh
curl -X GET https://myApiName.azure-api.net/api/Weather/53/-1 \
  -H 'Ocp-Apim-Subscription-Key: [subscription-key]' \
  --cert-type pem \
  --cert selfsigncert.pem
```
