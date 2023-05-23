# SSL Certificate

- [File format](#file-format)
  - [Multiple certs in one file](#multiple-certs-in-one-file)
- [`openssl` command](#openssl-command)

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

## `openssl` command

```sh
# show certificate information
# if multiple cert in the `.pem` file, only info of the first one is shown
openssl x509 -in example.com.pem -text
```
