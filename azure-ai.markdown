# Azure AI

- [Overview](#overview)
  - [Computer vision](#computer-vision)
- [Large Language Models (LLMs)](#large-language-models-llms)
  - [Prompt engineering](#prompt-engineering)
- [Responsible generative AI](#responsible-generative-ai)
- [Azure vs. Power Platform](#azure-vs-power-platform)
- [Azure AI services](#azure-ai-services)
- [AI Search](#ai-search)
- [Copilot studio](#copilot-studio)
  - [Knowledge sources](#knowledge-sources)
  - [Topics](#topics)
- [Azure AI Studio](#azure-ai-studio)
- [Azure AI Foundry](#azure-ai-foundry)
  - [AI Hub](#ai-hub)


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


## Large Language Models (LLMs)

- Based on transformer model

  - "transform" here means transforming source text/images to vectors
  - An *encoder* block that creates semantic representations of the training vocabulary
  - A *decoder* block that generates new language sequences

  ![Transformer model](./images/ai_transformer-model.png)

- Tokenization:
  - A token could be partial words, or combination of words and punctuation

- Embedding:
  - Vectors for the tokens, each element represents a feature of the token

    ```
    - 4 ("dog"): [10,3,2]
    - 8 ("cat"): [10,3,1]
    - 9 ("puppy"): [5,2,1]
    - 10 ("skateboard"): [-3,3,2]
    ```

- Attention:
  - A technique used to examine a sequence of text tokens and try to quantify the strength of the relationships between them


### Prompt engineering

![Prompt engineering](./images/ai_prompt-engineering.png)

Consider the following ways you can improve the response a generative AI assistant provides:

1. Start with a specific **goal** for what you want the assistant to do
1. Provide a **source** to ground the response in a specific scope of information
1. Add **context** to maximize response appropriateness and relevance
1. Set clear **expectations** for the response
1. **Iterate** based on previous prompts and responses to refine the result

In most cases, an agent doesn't just send your prompt as-is to the language model. Usually, your prompt is augmented with:

1. A **system message** that sets conditions and constraints for the language model behavior. For example, "You're a helpful assistant that responds in a cheerful, friendly manner." These system messages determine constraints and styles for the model's responses.
1. The conversation **history for the current session**, including past prompts and responses. The history enables you to refine the response iteratively while maintaining the context of the conversation.
1. The **current prompt** – potentially optimized by the agent to reword it appropriately for the model or to add more grounding data to scope the response.


## Responsible generative AI

- Identify potential harms
- Measure potential harms
- Mitigate potential harms (4 layers)
  - Model layer
    - Simpler model with lower risk
    - Fine-tune a foundational model
  - Safety system layer
    - Content filters to suppress prompts and responses
    - Abuse detection algorithms
  - Metaprompt and grounding layer
    - Metaprompt or system inputs that define behavioral parameters for the model
    - Add grounding data to input prompts
    - RAG (Retrieval Augmented Generation): retrieve contextual data from trusted data sources and include it in prompts
  - User experience layer
    - Documentations and guidelines
- Operate a responsible Gen-AI solution


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


## AI Search

- Built on Apache Lucene
- Data indexing process:
  - Data source
  - Indexer:
    - Document cracking: opens files and extracts content
    - Enrichment: by skillset, eg. OCR, text translation, image captioning, etc, enriched results could be saved in a knowledge store
  - Push to index

Querying:

- Supports simple and full Lucene query syntax
- Simple query example: `coffee (-"busy" + "wifi")`
- Example JSON query:

  ```json
  {
    "search": "locations:'Chicago'",
    "count": true
  }
  ```


## Copilot studio

For low-code or no-code usage

- Re-branded from Power Virtual Agents
- You can
  - extend Microsoft Copilot
    - The built agent could be published anywhere, like Microsoft 365 Copilot (Teams, SharePoint, Business Chat)
  - build custom copilot-like agents
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

For developers, allow full customization

Azure AI Foundry portal combines access to multiple Azure AI services and generative AI models into one user interface.
- Model catalog
- Prompt flow engineering
- Gen-AI model deployment, testing, and custom data integration capabilities of Azure OpenAI service
- Integration with Azure AI Services for speech, vision, language, etc

### AI Hub

- A collaborative workspace for AI development
- A resource in Azure
- Define assets that can be used across multiple projects
- Create members with different roles
- Manage compute instances
- Connections (to data sources, GitHub, etc)
- Policies (eg. automatic compute shutdown)
- A hub can host one or more projects
  - Projects are also resources in Azure

Supporting services:

- A **Storage account** in which the data for your AI projects is stored securely.
- A **Key vault** in which credentials used to access external resources and other sensitive values are secured.
- A **Container registry** to store Docker images used by your AI solutions.
- An **Application insights** resource to record usage and performance metrics.
- An **Azure OpenAI Service** resource that provides generative AI models for your applications.
