# Microsoft Defender

- [Defender for Containers](#defender-for-containers)
- [Defender for Cloud Apps](#defender-for-cloud-apps)
- [Defender for Identity](#defender-for-identity)


## Defender for Containers

- Only supports AKS clusters that use VMSS
- A Defender agent is deployed on each node as a DaemonSet
  - The agent is registered with a Log Analytics Workspace (LAW), a default LAW is created when you install the agent
  - The default LAW will be called `DefaultWorkspace-<sub-id>-<RegionShortCode>` in a RG named `DefaultResourceGroup-<RegionShortCode>`
  - You can also specify a custom LAW
- Security events that Microsoft Defender for Containers monitors include:
  - Exposed Kubernetes dashboards
  - Creation of high privileged roles
  - Creation of sensitive mounts
- Azure Policy for Kubernetes:
  - Installed as an add-on, monitors every API request
- Image vulnerability assessment
  - Pulls images from the registry and runs it in an isolated sandbox with
    - Qualys scanner
    - or Microsoft Defender Vulnerability Management (MDVM) scanner
  - Only scan images in ACR, AWS ECR, NOT Docker Hub, Microsoft Artifact Registry/Microsoft Container Registry and ARO built-in registry yet
- Run-time protection for Kubernetes nodes and clusters


## Defender for Cloud Apps

- Microsoft implementation of a CASB service
- Formerly known as Microsoft Cloud App Security (MCAS)

***CASB**: Cloud Access Security Broker, an on-prem or cloud-based security policy enforcement point that is placed between cloud service consumers and cloud service providers to combine and interject enterprise security policies as cloud-based resources are accessed.*

Features:

- Cloud discovery: discover cloud apps your organization is using
- Sanctioning and de-authorizing apps
- Use easy-to-deploy **app connectors** that take advantage of provider APIs, for visibility and governance of apps
- Use **Conditional Access App Control** to control over access and activities within your cloud apps

![Defender for Cloud Apps components](images/microsoft_defender-for-cloud-apps-architecture.png)


## Defender for Identity

- Formerly known as Azure Advanced Threat Protection (ATP)
- Uses on-prem AD signals, can be installed on Domain Controllers and AD FS servers

![Defender for Identity components](./images/microsoft_defender-for-identity.png)
