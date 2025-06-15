# ActiveMQ


## Overview

## Concepts

```
[Connection]
   └── [Session]
         ├── [Producer] → [Address] → [Queue] → [Consumer]
         └── [Consumer]
```

- Address (Artemis only)
  - Can have multiple queues bound to it
  - Supports multicast, anycast, routing rules, and wildcards
  - Messages go from producers -> addresses -> queues -> consumers

- Queue
  - A queue is bound to an address
  - One address can route to multiple queues
  - Each message goes to one consumer only

- Workflow
  - Create a connection (using a broker URL)
  - Open a session(s)
  - Create producers/consumers/queues
  - Send/receive messages


### Example operations

```sh
artemis shell --user artemis --password artemis

# create queue and address
queue create --name queue-gary-001 --address address-gary-001
```


## Classic

- Version: 5.x
- You can send message to
  - a queue
  - or a topic
