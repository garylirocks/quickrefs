# Microsoft Exchange

## Concepts

- **Contacts**: people outside your organization you'd like everyone to be able to find in Outlook
- **Shared mailbox**:
  - Corresponds to an Entra user, with sign-in blocked
  - Created in Exchange admin center, "Alias" (if specified) becomes the Entra user name
  - You should add "Read and manage (Full Access)" permission to users who need to access it
  - To access a shared mailbox, in Outlook, add the shared mailbox
  - Unlike a user mailbox, a shared mailbox usually does NOT need a license (unless you need some additional features)
- **Primary email address**
  - Could be different from the user name, could be on a non-default domain, eg. user name is `alice@domain.com`, primary email address could be `alice.smith@sub.domain.com`
  - For a user synced from on-prem AD, the primary email address is determined by the **`proxyAddresses`** attribute (overriding the `mail` attribute)

    `proxyAddresses` could have multiple values, `SMTP` value would be the primary email address, `smtp` values would be alias email addresses

    ```sh
    Get-ADUser alice -Properties proxyAddresses | Select -Expand proxyAddresses

    X500:/o=Exchange...
    smtp:alice@domain.mail.onmicrosoft.com
    smtp:alice@domain.com
    SMTP:alice.smith@sub.domain.com
    ```

    To update `SMTP`, do something like

    ```sh
    $user = Get-ADUser alice -Properties proxyAddresses
    $proxies = $user.proxyAddresses
    # Add new primary
    $proxies += "SMTP:alice.smith@new.sub.domain.com"
    Set-ADUser alice -Replace @{proxyAddresses=$proxies}
    ```
- Sharing:
  - **Organization relationship**:
    - allow users in each org to view calendar availability info (eg. to schedule meetings)
    - need to be set on both sides
    - with another Microsoft 365 / Office 365 organization, or with an Exchange-online organization
    - access settings (eg. free/busy, time, subject, and location) are maximum allowed, individual users can choose to share less (select a calendar, then configure sharing)
  - **Individual sharing**:
    - By default, all users can invite anyone with an email address to view their calendar
    - Individual sharing controls how your users share their calendars with people outside your organization
    - You can choose "All domains" or specified domains
    - After you create a new sharing policy, you need to go to target mailboxes and apply the policy to make it take effects
