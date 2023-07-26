# SSL Certificate

- [File format](#file-format)
  - [Multiple certs in one file](#multiple-certs-in-one-file)
  - [Private keys](#private-keys)
- [Certificates](#certificates)
  - [Certificate information](#certificate-information)
  - [Convert `.pfx` to `.pem`](#convert-pfx-to-pem)
  - [Add a CA certificate to Linux system](#add-a-ca-certificate-to-linux-system)
- [Self-signed SSL certs](#self-signed-ssl-certs)
- [Digest/hash](#digesthash)
- [Encryption](#encryption)
  - [With a symmetric key](#with-a-symmetric-key)
  - [With a pair of public/private keys](#with-a-pair-of-publicprivate-keys)

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
- *A `.cer` could be in binary or ASCII format*

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

### Private keys

Encrypted

```
-----BEGIN ENCRYPTED PRIVATE KEY-----
// encrypted private key
-----END ENCRYPTED PRIVATE KEY-----
```

Not encrypted

```
-----BEGIN RSA PRIVATE KEY-----
// private key
-----END RSA PRIVATE KEY-----
```


## Certificates

### Certificate information

```sh
# if multiple cert in the `.pem` file, only info of the first one is shown
openssl x509 -in example.com.pem -text

# output selected fields only
openssl x509 -in example.com.pem -noout -issuer -subject -dates -fingerprint -ext subjectAltName
```

Get certificate info of an HTTPS site

```sh
# the `-servername` option is required for SNI
openssl s_client \
        -showcerts \
        -verify_quiet \
        -servername example.com \
        -connect example.com:443 </dev/null \
        | openssl x509 -noout -issuer -subject -dates -fingerprint -ext subjectAltName
```

### Convert `.pfx` to `.pem`

```sh
# will prompt for password if there is one
# `-nodes` means "Don't encrypt the private key"
openssl pkcs12 -in cert.pfx -out cert.pem -nodes

# don't output the private key
openssl pkcs12 -in cert.pfx -out cert.pem -nodes -nokeys
```

### Add a CA certificate to Linux system

```sh
sudo cp new-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
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


## Digest/hash

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


## Encryption

### With a symmetric key

```sh
# will prompt for the password
openssl enc -e -aes256 -iter 1000 -in secret.txt -out secret.enc
openssl enc -d -aes256 -iter 1000 -in secret.enc -out secret.decrypted.txt
```

### With a pair of public/private keys

```sh
echo "hello world" > secret.txt

# generate private and public keys
openssl genrsa -aes256 -out gary_private.pem 2048
openssl rsa -in gary_private.pem -pubout > gary_public.pem

# encrypt, then decrypt
openssl rsautl -encrypt -inkey gary_public.pem -pubin -in secret.txt -out secret.enc
openssl rsautl -decrypt -inkey gary_private.pem -in secret.enc > secret.dycrypted.txt

cat secret.dycrypted.txt
```
