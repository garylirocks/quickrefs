# Azure messaging services

- [Overview](#overview)
- [Messages vs. Events](#messages-vs-events)
- [Service bus](#service-bus)
  - [Queue](#queue)
  - [Topic](#topic)
- [Storage Queues](#storage-queues)
- [Event Grid](#event-grid)
- [Event Hub](#event-hub)


## Overview


## Messages vs. Events

Messages:
  - Generally contains the raw data itself (e.g. raw file data to be stored)
  - Sender and receiver are often coupled by a strict data contract
  - Overall integrity of the application rely on messages being received

Events:
  - Lightweight notification of a condition or a state change
  - Usually have meta data of the event but not the data that triggered the event (e.g. a file was created, but not the actual file data)
  - Most often used for broadcast communications, have a large number of subscribers for each publisher
  - Publisher has no expectation about how the event is handled
  - Can be discrete or part of series

| Service     | Type                          | Purpose                             | When to use                              |
| ----------- | ----------------------------- | ----------------------------------- | ---------------------------------------- |
| Service Bus | Message                       | **High-value enterprise** messaging | Order processing, financial transactions |
| Event Grid  | Event distribution (discrete) | Reactive programming                | React to status change                   |
| Event Hubs  | Event streaming (series)      | Big data pipeline                   | Telemetry and distributed data streaming |

## Service bus

- Intended for traditional enterprise applications, which require transactions, ordering, duplicate detection, and instantaneous consistency.

- Is a brokered messaging system, stores messages in a "broker" (e.g. a queue) until the consuming party is ready.

### Queue

![Service Bus Queue](./images/azure_service-bus-queue.png)

Storage queues are simpler to use but less sophisticated and flexible than Service Bus queues:

| Feature                          | Service Bus Queues                                        | Storage Queues |
| -------------------------------- | --------------------------------------------------------- | -------------- |
| Message size                     | 256KB(std tier) / 1MB (premium tier)                      | 64KB           |
| Queue size                       | 80 GB                                                     | unlimited      |
| Delivery                         | at-least-once or at-most-once                             | -              |
| Guarantee                        | FIFO guarantee                                            | -              |
| Transaction                      | Yes                                                       | No             |
| Role-based security              | Yes                                                       | No             |
| Queue polling on destination end | Not required (could use a long-polling receive operation) | Yes            |
| Log                              | -                                                         | Yes            |

### Topic

Unlike a queue, a topic supports multiple receivers

![Service Bus Topic](./images/azure_service-bus-topic.png)

Receivers do not need to poll the topic

Three filter conditions:

- Boolean filters
- SQL filters: use SQL-like conditional expressions
- Correlation Filters: matches against messages properties, more efficient than SQL filters

All filters evaluate message properties, not message body.

## Storage Queues

![storage queue message flow](images/azure_storage-queue-message-flow.png)

- `get` and `delete` are separate operations, this ensures the *at-least-once delivery*, in case there is a failure in the receiver, after receiver gets a message, the message remains in the queue but is invisible for 30 seconds, after that if not deleted, it becomes visible again and another instance of the receive can process it


## Event Grid

- Designed to react to status changes
- Lets you integrate third-party tools to react to events without having to continually poll for event status


## Event Hub

Often used for a specific type of high-flow stream of communications used for analytics (often used with Stream Analytics)

- It's one of the options in "Diagnostic settings" for resource logs/metrics
- Event Hub can work with Event Grid, could be either event source or handler
