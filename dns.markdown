# DNS

- [`dig`](#dig)
- [`nslookup`](#nslookup)
- [`ipconfig`](#ipconfig)
- [`systemd-resolve`](#systemd-resolve)
- [Security](#security)
- [DNSSEC](#dnssec)
- [Windows Server DNS](#windows-server-dns)
- [Misc](#misc)


## `dig`

```sh
# query A records of example.com using server 8.8.8.8
dig @8.8.8.8 example.com

# get name server of a domain
dig example.com ns

# show friendly ttl
dig google.com +ttlunits
# google.com.             3m37s   IN      A       142.250.66.238
```

Reverse lookup (PTR)

```sh
dig -x 8.8.8.8
# 8.8.8.8.in-addr.arpa.   1621    IN      PTR     dns.google.
```

Get root server list

```sh
dig . ns

# ...
# ;; ANSWER SECTION:
# .                       49699   IN      NS      g.root-servers.net.
# .                       49699   IN      NS      k.root-servers.net.
# .                       49699   IN      NS      d.root-servers.net.
# ...
```

If you query a root server for a specific domain name, it returns the authoritative name servers for the TLD

```sh
dig @a.root-servers.net. google.com

# ...
# ;; AUTHORITY SECTION:
# com.                    172800  IN      NS      a.gtld-servers.net.
# com.                    172800  IN      NS      b.gtld-servers.net.
# com.                    172800  IN      NS      c.gtld-servers.net.
# com.                    172800  IN      NS      d.gtld-servers.net.
# ...
```


## `nslookup`

```sh
nslookup                                # enter interactive mode

> server 8.8.8.8                        # set default name server
Default server: 8.8.8.8
Address: 8.8.8.8#53

> google.com
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:               # this is non-authoritative
Name:   google.com
Address: 142.250.66.206

> server ns1.google.com                 # change the default name server
Default server: ns1.google.com
Address: 216.239.32.10#53
Default server: ns1.google.com
Address: 2001:4860:4802:32::a#53

> google.com
Server:         ns1.google.com
Address:        216.239.32.10#53

Name:   google.com                      # this is the authoritative answer, because you are querying the domain's name server directly
Address: 172.217.167.110

> set debug                             # turn on debugging
> google.com
# ------------
#     QUESTIONS:
#         google.com, type = A, class = IN
#     ANSWERS:
#     ->  google.com
#         internet address = 172.217.167.110
#         ...

> set type=aaaa                         # set the query type
> google.com
# ...
# ------------
# Non-authoritative answer:
# Name:   google.com
# Address: 2404:6800:4006:813::200e
```


## `ipconfig`

```powershell
# show cached DNS entries
ipconfig /displaydns
# or
Get-DnsClientCache
```

Clear local DNS cache

```powershell
ipconfig /flushdns

# renew IP address lease from DHCP server
ipconfig /renew
```


## `systemd-resolve`

- Find DNS configs on each network interface

  ```sh
  systemd-resolve --status

  # Global
  #           DNSSEC NTA: 10.in-addr.arpa
  #                       16.172.in-addr.arpa
  #                       ...
  # Link 2 (eth0)
  #       Current Scopes: DNS
  #        LLMNR setting: yes
  # MulticastDNS setting: no
  #       DNSSEC setting: no
  #     DNSSEC supported: no
  #          DNS Servers: 168.63.129.16
  #           DNS Domain: bkz3n5lfd3kufhikua4wl40kwg.px.internal.cloudapp.net
  ```

- Show statistics and clear local cache

  ```sh
  systemd-resolve --statistics
  # ...
  # Cache
  #   Current Cache Size: 6
  #           Cache Hits: 23
  #         Cache Misses: 67

  sudo systemd-resolve --flush-caches

  systemd-resolve --statistics
  # ...
  # Cache
  #   Current Cache Size: 0
  #           Cache Hits: 23
  #         Cache Misses: 69
  ```


## Security

- DNS over HTTPS (DoH)
- DNS over TLS (DoT)

## DNSSEC

Why: Security was not imbedded in the original DNS design, a DNS response could be spoofed, a resolver cannot easily verify its authenticity.

DNS record types for DNSSEC:

- **RRSIG (resource record signature)**: the signature for a record set
- **DNSKEY**: the public key to verify signatures in RRSIG records
- **DS (delegation signer)**: holds the name of a delegated zone, referencing a DNSKEY record in the sub-delegated zone
- **NSEC**
- **NSEC3**
- **NSEC3PARAM**

How:

- Every DNS zone has a public/private key pair
  - The *public key* is published in the zone itself for anyone to retrieve
- Signatures of the DNS zone data is generated
- DNS queries and responses themselves are not signed
- Any recursive resolver that looks up data in the zone also retrieves the zone's public key, which it uses to validate the authenticity ot the DNS data.
- Insures integrity, but not confidentiality or availability

Chain of trust:

- Effectively, the *public key* of each zone is signed by the private key of its parent zone
- The public key at the beginning of a chain of trust is called a *trust anchor*
- Most resolvers are configured with just one trust anchor: a set of public keys for the root zone
- The root zone and all gTLDs are already signed.
- Domain owners generate their own keys, and upload them to the domain-name registrar, which pushes the keys to the zone operator (e.g. Verisign for .com), who signs and publishes them in DNS


## Windows Server DNS

Some notes about Windows Server DNS

- Conditional Forwarders
  - If you have `company.com` in Forward Lookup Zones, and then if you want to add a conditional forwarder for a subzone `sub.company.com`, then you'll need to add a delegation for `sub.company.com` in `company.com` first. Does it matter whether the delegation and conditional forwarder is the same ? (haven't validated this, see https://techcommunity.microsoft.com/t5/windows-server-for-it-pro/dns-delegation-and-conditional-forwarder-for-the-same-domain/m-p/3717385)
- See [this diagram](./images/azure_dns-resolution.drawio.svg) for another quirky behavior of Windows Server DNS: if it gets from an upstream server a response containing a CNAME record, and it has an authoritative zone itself for the CNAME zone, then it overrides values in the upstream response
- If you have two Forward Lookup Zones:
  - `example.com` zone, with record `host1.sub` -> `1.1.1.1`, `host2.sub` -> `2.2.2.2`
  - `sub.example.com` zone, with record `host1` -> `10.10.10.10`

  When you query
  - `host1.sub.example.com`, it returns `10.10.10.10`
  - `host2.sub.example.com`, it returns null

  Meaning that the most specific zones take precedence, all queries for `*.sub.example.com` goes to the `sub.example.com` zone


## Misc

Public recursive DNS resovers:

```
# Google
8.8.8.8
8.8.4.4
```

```
# Cloudflare
# open
1.1.1.1
1.0.0.1

# block malware
1.1.1.2
1.0.0.2

# block malware and adult content
1.1.1.3
1.0.0.3
```
