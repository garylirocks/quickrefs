# Authentication and Authorization

## JWT

A token format

## OAuth 2

Refs:
- [An OAuth 2.0 introduction for beginners](https://itnext.io/an-oauth-2-0-introduction-for-beginners-6e386b19f7a9)
- [Okta - OAuth 2.0 and OpenID Connect (in plain English)](https://youtu.be/996OiexHze0)

### History

The simple way for user authentication is using cookies:

![Auth with cookies](images/auth_cookie.png)

If website A want to access your info stored in website B, it's used to be done in this way:

![Pre OAuth](images/auth_pre-oauth.png)

Then comes OAuth2, it's goal is to obtain an *access_token* to access protected resources, there are four flows:

![OAuth2 flows comparison](./images/oauth2_flows.png)

### Authorization Code Grant

- Suitable for web applications with server backend;
- The most secure, complete and complex flow;
- Usually the auth server returns a *refresh_token* along with the *access_token*;

![Authorization Code Flow Example](images/oauth2_auth-code-flow-example.png)
![Authorization Code Flow Code Example](images/oauth2_auth-code-flow-code-example.png)
![Authorization Code Grant Flow](images/oauth2_auth-code-grant-flow.png)

### Implicit Grant

- Suitable for SPA, static Javascript applications;
- The Authorization server returns the *access_token* directly;
- Take care to store the *access_token* properly;
- There is no *client_secret*;

![Implicit Flow Example](images/oauth2_implicit-flow-example.png)
![Implicit Grant](images/oauth2_implicit-grant-flow.png)


### Client Credential

- Suitable for microservices and APIS;
- No user interaction;
- Happens only on a server;

![Client Credential](images/oauth2_client-credential-flow.png)

### Password Grant

- Users enter their username and password in the client application;
- The application must be fully trusted;
- Mostly just for compatible with old systems;

![Password Grant](images/oauth2_password-grant-flow.png)

### OpenID Connect

**This is where confusion comes from: OAuth2 was intended for authorization, but people started to use it for authentication as well, to standardize this, OpenID Connect came up**

![OpenID Connect](images/oauth2_openid-connect.png)

OpenID Connect is only an addition on OAuth2, the overall data flow is the same:

![OpenID Auth code flow](images/oauth2_openid-auth-code-flow.png)

A few differences:

- You specify `openid` in the *scope*;
- Besides *access_token*, you get an *id_token* as well, which contains some basic info about the user;
  ![OpenID - ID token](images/oauth2_id-token-jwt.png)
- You can get more info about the user from a userinfo endpoint;
  ![OpenID - calling userinfo endpoint](images/oauth2_openid-userinfo-endpoint.png)


### How to choose

![How to choose](images/oauth2_choose-a-flow.png)

- Web application with server backend: Authorization code flow

  - Cookie is still used to keep the session;
  - *access_token* and *id_token* are stored in the session on server;

  ![Example - Web app](images/oauth2_example-web-app.png)

- Native mobile app: authorization code flow with PKCE

  - There is a package 'AppAuth' to handle most of the work;

  ![Example - Native mobile app](images/oauth2_example-native-mobile-app.png)

- Javascript app (SPA) with API backend: implicit flow

  - Tokens need to be stored properly;

  ![Example - SPA](images/oauth2_example-spa.png)

- Microservices and APIs: client credentials flow