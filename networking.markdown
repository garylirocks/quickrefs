# Networking


- [Network Layers](#network-layers)
- [Physical Layer](#physical-layer)
- [Link Layer](#link-layer)
- [Network Layer](#network-layer)
  - [ARP protocol](#arp-protocol)
- [Transport Layer](#transport-layer)
  - [Why transport layer?](#why-transport-layer)
  - [UDP](#udp)
  - [TCP](#tcp)
- [Application Layer](#application-layer)
- [Network devices](#network-devices)
  - [Hub vs. Switch vs. Router](#hub-vs-switch-vs-router)
- [Top down - from user's point of view](#top-down---from-users-point-of-view)
- [Routing overview](#routing-overview)
- [BGP](#bgp)
- [Refs](#refs)


## Network Layers

OSI 7 Layers

- Physical Layer
- Data Link Layer
- Network Layer
- Transport Layer
- Session Layer
- Presentation Layer
- Application Layer

Most important 5 layers:

![OSI-5-layers-structure.png](./images/network_OSI-5-layers-structure.png)

## Physical Layer

Send and receive `0` and `1`

## Link Layer

How to group `0` and `1`

`Ethernet` protocol:

Group `0` and `1` in `Frame`, every `Frame` has `Head` and `Data`

![frame-structure](./images/network_network-frame-structure.png)

- Head has fixed length: 18 bytes
- Data can be 46 ~ 1500 bytes

Head contains sender and receiver's addresses: `MAC`

![mac-address](./images/network_mac-address.png)

`MAC` is 6 bytes, every network card has a unique `MAC` address, the first 3 bytes are manufacturer identifier

Sender must know receiver's `MAC` address to send data -> `ARP` protocol

![ethernet-broadcasting](./images/network_ethernet-broadcasting.png)

**`broadcasting`**:

When a sender wants to send data, it broadcasts it to every one in the same network, each one who received the data compares the MAC address to its own to determine whether it is the specified receiver, so in the above image, when 1 sends message to 2, others (3, 4, 5) will receive the message too

_Note: a modern switch may cache each host's MAC address, so it only needs to send the data to that host, do not need to do broadcasting_

_This only works in a subnet, you can not put all the computers in the world in a single subnet, so this leads to Network Layer_

## Network Layer

![internet structure](./images/network_internet-structure.png)

Use `IP address` to determine which subnet a computer belongs to

IPv4: 4 bytes, `0.0.0.0` ~ `255.255.255.255`

Each IP address contains a subnet address and then host address

For example:

`172.16.254.1`, if the first 24 bit are for subnet address, the subnet mask is `255.255.255.0`, and it's in the same subnet with `172.16.254.2`

![ip-frame-structure](./images/network_ip-frame-structure.png)

IP packet structure, Head is 20 ~ 60 bytes, maximum length for whole frame is 65535 bytes

Put IP packet inside an ethernet frame, it looks like this:

![ip-frame-in-ethernet-frame](./images/network_ip-frame-in-ethernet-frame.png)

Because an Ethernet frame data's max length is 1500 bytes, so IP packet may need to split to several Ethernet frames before sending

### ARP protocol

When sending data, IP data is contained in Ethernet frame, so we must know the destination's IP address and MAC address before sending

Usually we already know the IP address (e.g. use DNS), but how do we get the MAC address?

If the destination is in:

- Different subnet

  The sender can not get the destination's MAC address, so it just send the data to gateway, let the gateway handle it

- Same subnet

  *Note: a host knows every other one's IP address in the same subnet by looking at its own IP address and the subnet mask*

  Send request to every host in the subnet, every receiver compares the IP address with its own, if matching, reply the sender with its MAC address

  Use 'ARP' protocol: use `FF:FF:FF:FF:FF:FF` as MAC address, put the destination's IP address in data section


## Transport Layer

### Why transport layer?

You can send and receive messages with IP and MAC address, so why add another layer ?

The reason is a host may have many programs (processes), all of them want to communicate with other hosts, we need a mechanism to determine which message is for which program.

So **port** is introduced, in fact, it's a number to differentiate different programs using the same network card

- Port is an integer between 0 ~ 65535, 0 ~ 1023 is for system, every user program can randomly pick up a port larger than 1023 to communicate with the server
- So Network Layer is for host to host, Transport Layer is for port to port
- In Unix, host + port is called **socket**

### UDP

Add sender and receiver's port in Head (8 bytes), UDP is not reliable

### TCP

TCP is reliable, the receiver need to send `ack` back to sender, so sender can confirm the message is received, if the sender do not get `ack` message, it can resend the message


## Application Layer

Protocols to specify format for different applications: HTTP, FTP, Email, ...


## Network devices

### Hub vs. Switch vs. Router

![Hub vs. Switch vs. Router](images/network_hub-vs-switch-vs-router.jpg)

|                                    | Hub                                                 | Switch                                                                                                            | Router                                                |
| ---------------------------------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Layer                              | Physical layer                                      | Data link layer                                                                                                   | Network layer                                         |
| Used in(LAN, MAN, WAN)             | LAN                                                 | LAN                                                                                                               | LAN, MAN, WAN                                         |
| Data Transmission form             | electrical signal or bits                           | frame & packet                                                                                                    | packet                                                |
| Function                           | A received frame is broadcasted to every other port | Keeps a record of MAC addresses each port connects to, so it only sends the frame to the port for the destination | Route packets between networks                        |
| Port                               | 4/12 ports                                          | multi-port, usually between 4 and 48                                                                              | 2/4/5/8 ports                                         |
| Transmission type                  | Frame flooding, unicast, multicast or broadcast     | First broadcast, then unicast and/or multicast depends on the need                                                | At Initial Level Broadcast then unicast and multicast |
| Device type                        | Non-intelligent device                              | Intelligent device                                                                                                | Intelligent device                                    |
| Transmission mode                  | Half duplex                                         | Half/Full duplex                                                                                                  | Full duplex                                           |
| Speed                              | 10Mbps                                              | 10/100Mbps, 1Gbps                                                                                                 | 1-100Mbps(wireless); 100Mbps-1Gbps(wired)             |
| Address used for data transmission | MAC address                                         | MAC address                                                                                                       | IP address                                            |


## Top down - from user's point of view

When you start using a new computer, somtimes you need to manually set up the following parameters to connect your computer to the network:

- IP address
- Subnet mask: to determine which subnet this computer belongs to
- Gateway IP address: to communicate with other subnets
- DNS: to get other computer's IP address

Sometimes you can get this setup automatically by **DHCP** protocol


## Routing overview

![Border and interior routers](images/network_routers-border-and-interior.png)

- Interior routers do not need to know AS numbers

Routing protocols

- Interior routing Protocols
  - Distance Vector: RIP, IGRP
  - Link State: OSPF, IS-IS
  - Hybrid: EIGRP
- Exterior routing protocols
  - Path Vector: BGP


## BGP

BGP runs over TCP (port 179)
- Sends keepalive message periodically to maintain the connection


BGP can also be used
- between ASes, called *eBGP*
- internally within an AS, called *iBGP*

![iBGP vs. eBGP](images/network_bgp-ibpg-ebgp.png)

Routing policy:

![Choose a path based on policy](images/network_bgp-multi-paths.png)

- When there are multiple paths to a destination, a router choose one based on policy (eg. shortest path, lowest cost, ...)

![No transit traffic](images/network_bgp-policy-isp.png)

- An ISP may not want to carry transit traffic between two other ISPs, so it can set up a policy to not carry traffic between them

![Forwording tables](images/network_bgp-forwarding-tables.png)


![Hot potato routing](images/network_bgp-hot-potato-routing.png)

**hot potato routing**: hand off the traffic as soon as possible, even though it may not be the shortest AS-path. *in the above diagram, 2d sends traffic for X to 2a because the OSPF link weights is less, even though the AS-path is longer*


## Refs

- [互联网协议入门 - 阮一峰](http://www.ruanyifeng.com/blog/2012/05/internet_protocol_suite_part_i.html)
- [互联网协议入门 2 - 阮一峰](http://www.ruanyifeng.com/blog/2012/06/internet_protocol_suite_part_ii.html)
