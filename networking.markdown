# Networking

[互联网协议入门 - 阮一峰](http://www.ruanyifeng.com/blog/2012/05/internet_protocol_suite_part_i.html)
[互联网协议入门 2 - 阮一峰](http://www.ruanyifeng.com/blog/2012/06/internet_protocol_suite_part_ii.html)

## Network Layers

OSI 7 Layers

- Physical Layer
- Data Link Layer
- Network Layer
- Transport Layer
- Session Layer
- Presentation Layer
- Application Layer

most important 5 layers:

![OSI-5-layers-structure.png](./images/network_OSI-5-layers-structure.png)

## Physical Layer

send and receive `0` and `1`

## Link Layer

how to group `0` and `1`

`Ethernet` Protocal:

group `0` and `1` in `Frame`, every `Frame` has `Head` and `Data`

![frame-structure](./images/network_network-frame-structure.png)

- Head has fixed length: 18 bytes
- Data can be 46 ~ 1500 bytes

Head contains sender and receiver's addresses: `MAC`

![mac-address](./images/network_mac-address.png)

`MAC` is 6 bytes, every network card has a unique `MAC` address, the first 3 bytes are manufacturer identifier

sender must know reciever's `MAC` address to send data -> `ARP` protocal

![ethernet-broadcasting](./images/network_ethernet-broadcasting.png)

**`broadcasting`**:

when a sender want to send data, it broadcasts it to every one in the same network, each one who received the data compares the MAC address to its own to determine whether it is the specified receiver, so in the above image, when 1 sends message to 2, others (3, 4, 5) will receive the message too

_Note: a modern switcher may cache each host's MAC address, so it only needs to send the data to that host, do not need to do broadcasting_

_this only works in a subnet, you can not put all the computers in the world in a single subnet, so this leads to Network Layer_

## Network Layer

![internet structure](./images/network_internet-structure.png)

use `IP address` to determine which subnet a computer belongs to

IPv4: 4 bytes, `0.0.0.0` ~ `255.255.255.255`

each IP address contains a subnet address and then host address

for example:

`172.16.254.1`, if the first 24 bit are for subnet address, the subnet mask is `255.255.255.0`, and it's in the same subnet with `172.16.254.2`

![ip-frame-structure](./images/network_ip-frame-structure.png)

IP packet sturcture, Head is 20 ~ 60 bytes, maximum length for whole frame is 65535 bytes

put IP packet inside an ethernet frame, it looks like this

![ip-frame-in-ethernet-frame](./images/network_ip-frame-in-ethernet-frame.png)

because an Ethernet frame data's max length is 1500 bytes, so IP packet may need to split to several Ethernet frames before sending

**ARP protocal**

when sending data, IP data is contained in Ethernet frame, so we must know the destination's IP address and MAC address before sending

usually we already know the IP address (e.g. use DNS), but how do we get the MAC address?

If the destination is in:

- different subnet

  the sender can not get the destination's MAC address, so it just send the data to gateway, let the gateway handle it

- same subnet

  use 'ARP' protcal: use 'FF:FF:FF:FF:FF:FF' as MAC address, put the destination's IP address in data section

  send data to every host in the subnet, every receiver compares the IP address with its own, if matching, reply the sender with its MAC address

*Note: a host knows every other one's IP address in the same subnet by looking at its own IP address and the subnet mask*

## Transport Layer

### why transport layer?

you can send and receive messages with IP and MAC address, so why add another layer ?

the reason is a host may have many programs (processes), all of them want to communicate with other host, we need a mechanism to determine which message is for which program.

so **port** is introduced, in fact it's a number to differentiate different programs using the same network card

port is an integer between 0 ~ 65535, 0 ~ 1023 is for system, every user program can randomly pick up a port larger than 1023 to communicate with the server

so Network Layer is for host to host, Transport Layer is for port to port

in Unix, host + port is called **socket**

## UDP

add sender and receiver's port in Head (8 bytes), UDP is not reliable

## TCP

TCP is reliable, the receiver need to send `ack` back to sender, so sender can confirm the message is received, if the sender do not get `ack` message, it can resend the message

## Application Layer

protocals to specify format for different applications: HTTP, FTP, Email, ...

## top down - from user's point of view

when you start using a new computer, somtimes you need to manually set up the following parameters to connncet your computer to the network:

- IP address
- subnet mask: to determine which subnet this computer belongs to
- gateway IP address: to communicate with other subnets
- DNS: to get other computer's IP address

sometimes you can get this setup automatically by **DHCP** protocal
