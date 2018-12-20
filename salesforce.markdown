Salesforce
==============
- [OAuth](#oauth)
    - [Endpoints](#endpoints)
    - [Tips](#tips)


## OAuth

### Endpoints

* For authorization: https://login.salesforce.com/services/oauth2/authorize
* For token requests: https://login.salesforce.com/services/oauth2/token
* For revoking OAuth tokens: https://login.salesforce.com/services/oauth2/revoke

replace `login.salesforce.com` with `test.salesforce.com` when testing with sandbox

### Tips

* The access token request's format should be in `application/x-www-form-urlencoded` ref: [Access Token Request](https://tools.ietf.org/html/rfc6749#section-4.1.3)




