# Azure Relay

- [Overview](#overview)
- [Basic flow](#basic-flow)
- [Architecture](#architecture)
- [Example](#example)


## Overview

Enables you to securely expose on-prem service to the public cloud (or another on-prem environment).

- The on-prem service doesn't need any inbound ports open on the firewall
- Comparing to VPN
  - it can be scoped to a single application endpoint on a single machine
  - not intrusive

Two features:

- **Hybrid Connections** - open standard web sockets, supports both WebSocket and HTTP protocols
- **WCF Relays** - legacy, Windows Communication Foundation (WCF) for remote procedure calls (RPC)


## Basic flow

1. On-prem service connects to the relay service through an outbound port
2. It creates a bi-directional socket for communication tied to a paricular address
3. The client can then communicate with the on-prem service by sending traffic to the relay service
4. The relay service then relays data to the on-prem service via the bi-directional socket dedicated to the client


## Architecture

![Process flow](images/azure_relay-process-flow.svg)


## Example

An implementation of [this tutorial](https://learn.microsoft.com/en-us/azure/azure-relay/relay-hybrid-connections-node-get-started) can be found at https://github.com/garylirocks/azure-relay-demo
