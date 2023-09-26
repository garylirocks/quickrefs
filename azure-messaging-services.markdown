# Azure messaging services

- [Overview](#overview)
- [Messages vs. Events](#messages-vs-events)
- [Service bus](#service-bus)
  - [Queue](#queue)
  - [Topic](#topic)
- [Storage Queues](#storage-queues)
- [Event Grid](#event-grid)
  - [Events](#events)
  - [Topics](#topics)
  - [Subscriptions](#subscriptions)
  - [Event handlers](#event-handlers)
    - [Webbook validation](#webbook-validation)
  - [Event delivery](#event-delivery)
  - [RBAC](#rbac)
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

![Event Grid sources and handlers](images/azure_event-grid-sources-handlers.png)

- Designed to react to status changes
- Lets you integrate third-party tools to react to events without having to continually poll for event status

Sources:

- Built-in support for events coming form Azure services, like blob storage and resource groups.
- Support for your own events, using custom topics.

### Events

Transmission:

- Event sources send events in an array, which can have several event objects.
- Event Grid sends events to subscribers in an array that has a single event.

Size limits:

- An event array from sources can be up to 1MB.
- A single event's size up to 64KB is covered by GA SLA.
  - Up to 1MB is in preview
  - Over 64KB are charged in 64-KB increments

Event schema:

- Azure Event Grid supports two types of event schemas: Event Grid event schema and Cloud event schema.
- Events consist of a set of four required string properties. The properties are common to all events from any publisher.
- Schema of `data` is specific to each publisher.
- `subject` is a path like structure,
  - eg. A blob added event could have a `subject` field like `/blobServices/default/containers/<container-name>/blobs/<file>`
  - A subscription could filter based on subject pattern

```json
[
  {
    "topic": string,
    "subject": string,
    "id": string,
    "eventType": string,
    "eventTime": string,
    "data":{
      object-unique-to-each-publisher
    },
    "dataVersion": string,
    "metadataVersion": string
  }
]
```

**CloudEvents** is an open specification for describing event data. Can be used for both input and output of events.

Example:

```json
{
  "specversion": "1.0",
  "type": "Microsoft.Storage.BlobCreated",
  "source": "/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.Storage/storageAccounts/{storage-account}",
  "id": "9aeb0fdf-c01e-0131-0922-9eb54906e209",
  "time": "2019-11-18T15:13:39.4589254Z",
  "subject": "blobServices/default/containers/{storage-container}/blobs/{new-file}",
  "dataschema": "#",
  "data": {
    "api": "PutBlockList",
    "clientRequestId": "4c5dd7fb-2c48-4a27-bb30-5361b5de920a",
    "requestId": "9aeb0fdf-c01e-0131-0922-9eb549000000",
    "eTag": "0x8D76C39E4407333",
    "contentType": "image/png",
    "contentLength": 30699,
    "blobType": "BlockBlob",
    "url": "https://gridtesting.blob.core.windows.net/testcontainer/{new-file}",
    "sequencer": "000000000000000000000000000099240000000000c41c18",
    "storageDiagnostics": {
      "batchId": "681fe319-3006-00a8-0022-9e7cde000000"
    }
  }
}
```

### Topics

A topic is an endpoint where the source sends events. The publisher creates topic, and decides whether an event source needs one or more topics.

Two types of topics in Event Grid:

- System topics
  - Built-in topics provided by Azure services
  - You don't see them in your subscription
  - As long as you have access a resource, you can subscribe to its events
- Custom topics
  - Application and third-party topics
  - You can only see them When you create or are assigned access to a custom topic

### Subscriptions

- You provide an endpoint for handling the event.
- You can set an expiration for the subscriptions if you only need it for a limited time.
- You can filter the events
  - By event type

    ```json
    "filter": {
      "includedEventTypes": [
        "Microsoft.Resources.ResourceWriteFailure",
        "Microsoft.Resources.ResourceWriteSuccess"
      ]
    }
    ```

  - By subject

    ```json
    "filter": {
      "subjectBeginsWith": "/blobServices/default/containers/mycontainer/log",
      "subjectEndsWith": ".jpg"
    }
    ```

  - Advanced filtering

    ```json
    "filter": {
      "advancedFilters": [
        {
          "operatorType": "NumberGreaterThanOrEquals",
          "key": "Data.Key1",
          "value": 5
        },
        {
          "operatorType": "StringContains",
          "key": "Subject",
          "values": ["container1", "container2"]
        }
      ]
    }
    ```


### Event handlers

A handler could be a supported Azure service or a custom HTTP webhook.

Supported Azure services:
- Azure Function
- Logic App
- Event hubs, Storage Queues
- Azure Function
- etc.

#### Webbook validation

You need to prove you own the webhook endpoint.

- For these Azure Services, the validation is done automatically:
  - Azure Functions with Event Grid trigger
  - Logic Apps wth Event Grid Connector
  - Azure Automation via webhook

- For custom HTTP webhook, when setting up a subscription, a validatation event is sent to your endpoint, the data field contains a `validationCode` property, two ways to validate the endpoint:
  - Synchronous handshake: the endpoint returns the `validationCode` in response
  - Asynchronous handshake:
    - For API version `2018-05-01-preview` or later, data field contains a `validationUrl` property
    - Send a `GET` request to the URL (using a REST client or a browser) within 5 minutes

### Event delivery

- Event Grid provides durable delivery, it tries to deliver each event at least once for each matching subscription immediately.
- By default, Event Grid delivers one event at a time to the subscriber, the palyload is an array with **a single event**.
- Delivery **order is not guaranteed**, subscribers may receive them out of order.

What counts as a **successful delivery**:
- Azure service handlers: processed successfully (eg. Storage Queue successfully process the message push to the queue)
- HTTP webhook: until the handler returns a status code of `200 - OK`

When an **delivery fails**, Event Grid will either:

- retry the delivery (based on error codes)
- dead-letter the event (need to be configured for an endpoint)
- drop the event

**Retry policy** for an subscription:

- Max number of attempts (1-30)
- Event time-to-live (1-1440 minutes)

**Output batching**, to improve performance, could be configured per subscripton:

- Max events per batch (1-5000)
- Preferred batch size in kilobytes

**Delayed delivery**: If an endpoint seems not healthy, Event Grid will delay new deliveries and retries to that endpoint

**Dead-lettering**
- Must be turned on per subscription
- You need to specify a storage account container to store the undelivered events
- When `400 Bad Request` or `413 Request Entity Too Large` is received, the event is scheduled for dead-lettering immediately
- If dead-lettering fails, the event is dropped

**Custom HTTP headers**
- You can set up to 10 custom HTTP headers
- Works with the following handlers:
  - Webhooks
  - Azure Service Bus topics and queues
  - Azure Event Hubs
  - Relay Hybrid Connections

### RBAC

Built-in roles:

- Event Grid Subscription Reader: read subscriptions
- Event Grid Subscription Contributor: manage subscriptons
- Event Grid Data Sender: send events to Event Grid topics
- Event Grid Contributor: create an manage Event Grid resources

To create a subscription, you need permissions:
- `Microsoft.EventGrid/EventSubscriptions/Write` on the topic:
  - System topics, the Azure resource `/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/{resource-provider}/{resource-type}/{resource-name}`
  - Custom topics, the Event Grid topic `/subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.EventGrid/topics/{topic-name}`
- If the event handler is an Azure service, you need **write access** to it


## Event Hub

Often used for a specific type of high-flow stream of communications used for analytics (often used with Stream Analytics)

- It's one of the options in "Diagnostic settings" for resource logs/metrics
- Event Hub can work with Event Grid, could be either event source or handler
