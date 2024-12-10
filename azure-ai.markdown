# Azure AI

- [Overview](#overview)
  - [Computer vision](#computer-vision)
- [Azure vs. Power Platform](#azure-vs-power-platform)
- [Azure AI services](#azure-ai-services)
- [Copilot studio](#copilot-studio)
  - [Knowledge sources](#knowledge-sources)
  - [Topics](#topics)
- [Azure AI Studio](#azure-ai-studio)
- [Azure AI Foundry](#azure-ai-foundry)


## Overview

General usage pattern:

- Deploy resources in Azure
- Use an auth token to access the service's API endpoint

### Computer vision

![CNN model](./images/ai_computer-vision-cnn.png)

*CNN for image classification*

![Multi-modal model](./images/ai_computer-vision-multi-modal.png)

*Multi-modal model, capturing relations between natural language tokens and image features*

![Computer vision tasks](./images/ai_computer-vision-tasks.png)

*Usual computer vision tasks: Classification, object detection, tagging, ...*


## Azure vs. Power Platform

Some capabilities exist in both platforms

|             | Azure    | Power Platform |
| ----------- | -------- | -------------- |
| Usage       | Code     | Codeless       |
| Features    | More     |                |
| Cost        | Less     |                |
| Volume      | Higher   |                |
| Integration | Flexible |                |


## Azure AI services

You can often choose to deploy a single-service resource or a multi-service resource, considerations are:

- Single-service resource: only that service is required, or to track utilization and costs separately
- Multi-service resource:
  - Simplify administration and development
  - Single auth key and endpoint

Three principals:

- Ready to use:
  - Azure AI services use pre-built models, can be used without any modification
  - Some AI services can be customized to better fit specific requirements
- Accessible via APIs
- //TODO


|                                                             | Type                                   | Endpoint                             |
| ----------------------------------------------------------- | -------------------------------------- | ------------------------------------ |
| AI Services (kind: `AIServices`)                            | `Microsoft.CognitiveServices/accounts` | depending on service                 |
| Multi-service account (kind: `CognitiveServices`) (legacy?) | `Microsoft.CognitiveServices/accounts` | `<name>.cognitiveservices.azure.com` |


- AI Services
  - Portal (Azure AI Foundry): https://ai.azure.com
  - Organized by project
- Vision:
  - Portal (Vision Studio): https://portal.vision.cognitive.azure.com/
  - Vision Studio only works with "Multi-service account" resource, NOT "Azure AI Vision" resource
- Language:
  - Portal (Language Studio): https://language.cognitive.azure.com
  - Question and Answering:
    - You need a AI Search resource
    - You can create a knowledge base by adding a existing FAQ url, or adding questions and answers manually
    - You'll need to deploy the knowledge base, then call it via a URL, or through a bot
  - Conversational language understanding
    - Train computers to interpret text or voice controls
    - Concepts: intent, utterances, entities
    - Define intents ("switchOn", "switchOff" etc), then utterances ("switch on the light") for the intent, then label entities ("light", "door") in the utterance
- Speech
  - Text to speech and speech to text
  - Real-time or batch
- Translation
  - AI Translator: text-to-text, can translate to multiple target languages simultaneously
  - AI Speech: speech-to-text or speech-to-speech

## Copilot studio

- Re-branded from Power Virtual Agents
- You can
  - build a custom copilot
  - or extend a Microsoft Copilot
    - The built agent could be published anywhere, like Microsoft 365 Copilot (Teams, SharePoint, Business Chat)
- For none/low code usage, using natural language or a GUI

### Knowledge sources

You can connect it to your public websites or internal data (files, databases, etc)

### Topics

For certain specified phrases, you might want to control the response message or action, you can define a topic.

This is called *conversational orchestration*.


## Azure AI Studio

- You can pick models
- Integrate with other resources, like Azure Search for managing indexes


## Azure AI Foundry

Azure AI Foundry portal combines access to multiple Azure AI services and generative AI models into one user interface.
