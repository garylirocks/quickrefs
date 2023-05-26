# SSL Certificate

- [File format](#file-format)
  - [Multiple certs in one file](#multiple-certs-in-one-file)
- [`openssl` commands](#openssl-commands)
- [Self-signed SSL certs](#self-signed-ssl-certs)

## File format

Different CAs and servers may issue or require X.509 certificates in different formats, the most common encoding formats and extensions are:

- Base64 (ASCII)
  - PEM (privacy-enhanced mail)
    - Extensions: `.pem`, `.cer`, `.crt`, `.ca-bundle`, `.key`
    - Can contain both certificates and private keys
    - Can be single certificate or the whole certificate chain
    - Delimiter lines are:
      - `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`
      - `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----`
  - P7B/PKCS#7
    - Extensions: `.p7b`, `.p7c`
    - Can only contain certificates, **NOT** private keys
    - Can be single certificate or the whole certificate chain
    - Commonly used by Windows and Java Tomcat servers
    - Delimiter lines are `-----BEGIN PKCS7-----` and `-----END PKCS7-----`
- Binary
  - DER (Distinguished Encoding Rules)
    - Extensions: `.der`, `.cer`
    - Binary form of PEM-formatted certificates
    - Can include certificates and private keys
    - Most commonly used in Java-based platforms
  - PFX/P12/PKCS#12 (Personal Information Exchange)
    - Extensions: `.pfx`, `.p12`
    - A single archive file that **contains the entire certificate chain plus the matching private key**, the key *could be password protected*. Essentially it is everything that a server needs, so often used for import/export.
    - Typically used on Windows platforms

Notes:

- A Base64 encoded cert contains the same content, extensions like `.pem`, `.cer` and `.crt` are interchangeable
- *A `.cer` could be binary or ASCII*

See: https://comodosslstore.com/resources/a-ssl-certificate-file-extension-explanation-pem-pkcs7-der-and-pkcs12/

### Multiple certs in one file

A file could contain the whole certificate chain, like

```
-----BEGIN CERTIFICATE-----
// primary or end certificate
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
// intermediate certificate
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
// root certificate
-----END CERTIFICATE-----
```

## `openssl` commands

- show certificate information

  ```sh
  # if multiple cert in the `.pem` file, only info of the first one is shown
  openssl x509 -in example.com.pem -text

  # output selected fields only
  openssl x509 -in example.com.pem -noout -dates -subject -issuer -ext subjectAltName
  ```

- Get certificate info of an HTTPS site

  ```sh
  # the `-servername` option is required for SNI
  openssl s_client \
          -showcerts \
          -servername example.com \
          -connect example.com:443 </dev/null \
          | openssl x509 -noout -dates -subject -issuer -ext subjectAltName
  ```

- Generate digest/hash

  ```sh
  openssl md4 temp.txt
  MD4(temp.txt)= b5227179...

  openssl sha512 temp.txt
  SHA512(temp.txt)= ecacf0e610...
  ```

- Generate random strings

  ```sh
  # 5 character string (5 bytes, 10 hex chars)
  openssl rand -hex 5
  # cf2a039a47
  ```

## Self-signed SSL certs

```sh
# Create CA cert and key

# Generate private key
openssl genrsa -des3 -out gary_ca.key 2048

# Generate root certificate
openssl req -x509 -new -nodes -key gary_ca.key -sha256 -days 825 -out gary_ca.pem
```

```sh
# Create self-signed cert

NAME=$1 # 'localhost' or 'gary.local', or '*.gary.local"

# Generate a private key
openssl genrsa -out $NAME.key 2048

# Create a certificate-signing request
openssl req -new -key $NAME.key -out $NAME.csr

# Create a config file for the extensions
cat > $NAME.ext <<-EOF
	authorityKeyIdentifier=keyid,issuer
	basicConstraints=CA:FALSE
	keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
	subjectAltName = @alt_names
	[alt_names]
	DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
	EOF

# Create the signed certificate
openssl x509 -req \
  -CA gary_ca.pem \
  -CAkey gary_ca.key \
  -CAcreateserial \
  -days 825 \
  -sha256 \
  -in $NAME.csr \
  -extfile $NAME.ext \
  -out $NAME.crt
```

If you want to create a wildcard certificate, use `*.gary.local` as `$NAME`, and use it when prompted for `CN` (it needs to be a properly-structured domain, something like `*.local` is not working in Chrome)
