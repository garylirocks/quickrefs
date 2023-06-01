# DNS

- [`dig`](#dig)
- [`nslookup`](#nslookup)
- [`ipconfig`](#ipconfig)
- [`systemd-resolve`](#systemd-resolve)


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
