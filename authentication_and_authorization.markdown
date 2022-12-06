# Authentication and Authorization

- [JWT](#jwt)
- [JWK](#jwk)
- [OAuth 2](#oauth-2)
  - [History](#history)
  - [Authorization Code Flow](#authorization-code-flow)
  - [PKCE extension](#pkce-extension)
  - [Implicit Flow (NOT SECURE)](#implicit-flow-not-secure)
  - [Client Credential](#client-credential)
  - [Password Flow](#password-flow)
  - [OpenID Connect](#openid-connect)
  - [How to choose](#how-to-choose)
- [SAML](#saml)

## JWT

JWT is a token format, containing three base64url encoded segments separated by period (`.`) character.

- The first segment represents the JOSE Header

  ```json
  {"kid":"1e9gdk7","alg":"RS256"}
  ```

    - `kid` is the key identifier, used to find a key in the JWK Set to verify the signature;
    - `alg` is the signature algorithm, `RS256` here represents RSASSA-PKCS-v1_5 using SHA-256;

- The second segment represents the claims in the token

  ```json
  {
    "iss": "http://server.example.com",
    "sub": "248289761001",
    "aud": "s6BhdRkqt3",
    "nonce": "n-0S6_WzA2Mj",
    "exp": 1311281970,
    "iat": 1311280970,
    "name": "Jane Doe",
    ...
  }
  ```

- The third segment represents the signature, created by signing the header and body using the specified algorithm

## JWK

A RSA key pair in JWK format looks like:

```json
{
  "e": "AQAB",
  "n": "3NFfKkp-P8PxG4wPN6DjB21TL2cEr7XjrZ_pzOiDUBe8SN...",
  "d": "XrS9qBnDA_45zqLHdAhg1rKg1tfMPsA4IiNP1z5x80v6yR...",
  "p": "_27qdcIybk4wJDsAVl1x7o10JWEc0-ha1sT5vpryOSXBcC...",
  "q": "3U7Lanpkcp2vyW50ZKfssoaEAKM6VyTL3xeEWm95ZRxo9P...",
  "dp": "sxaUAj5G13mwXSaU5PidUdERdsewy44kamIubAn8_D5Rc...",
  "dq": "UVn0ppiFMijLBLXIrXOZK-sMvRtDh-Mr2j9P1NqjekqeP...",
  "qi": "rpt-JQabYEQR5jFyix7LXiq5-LczWaxJEfyBCh17XcSKZ...",
  "kty": "RSA",
  "kid":"1e9gdk7",
  "use": "sig"
}
```

ONLY the public part should be published by an OAuth server for encoding/verification, usually as a JWK Set:

```json
{
  "keys": [
    {
      "e": "AQAB",
      "n": "xwQ72P9z9OYshiQ-n ...",
      "kty": "RSA",
      "kid": "r1LkbBo3925Rb2ZFFrKyU3MVex9T2817Kx0vbi6i_Kc",
      "use": "sig"
    },
    {
      "e": "AQAB",
      "n": "mXauIvyeUFA74P2vcmg ...",
      "kty": "RSA",
      "kid": "w5kPRdJWODnYjihMgqs0tHkKk-e5OxU4DnSCZDkF_h0",
      "use": "enc"
    }
  ]
}
```

## OAuth 2

Refs:

- [An OAuth 2.0 introduction for beginners](https://itnext.io/an-oauth-2-0-introduction-for-beginners-6e386b19f7a9)
- [Okta - OAuth 2.0 and OpenID Connect (in plain English)](https://youtu.be/996OiexHze0)
- [RFC 6749 - The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html#OfflineAccess)


### History

The simple way for user authentication is using cookies:

![Auth with cookies](images/auth_cookie.png)

If website A wants to access your info stored in website B, it's used to be done in this way:

![Pre OAuth](images/auth_pre-oauth.png)

Then comes **OAuth2**, if Yelp wants to access your Gmail account, it needs to register itself in Google as an app:

- Specify scopes, redirection url etc;
- Get a *client_id* and a *client_secret* ;

Its goal is to obtain an *access_token* to access protected resources

- OAuth2.0 does not specify the format of *access_token*, it's up to the implementation, it can be JWT, or something else;
- There are four flows:

  ![OAuth2 flows comparison](./images/oauth2_flows.png)

### Authorization Code Flow

- Suitable for web applications with server backend;
- The most secure, complete and complex flow;
- Usually the auth server returns a *refresh_token* along with the *access_token*;

![Authorization Code Flow Example](images/oauth2_auth-code-flow-example.png)
![Authorization Code Flow Code Example](images/oauth2_auth-code-flow-code-example.png)
![Authorization Code Grant Flow](images/oauth2_auth-code-grant-flow.png)


### PKCE extension

- PKCE: Proof Key for Code Exchange, an extension to the Authorization Code Flow;
- Created because native apps can't safely use a client secret, so it uses a dynamic secret generated on the client;
- Protects against authorization code stolen in transit;
- Doesn't solve the problem of storing access token and refresh token in the front-end, you still need good a Content Security Policy and be aware of any third-party libraries you are using;
- See:
  - [OAuth 2.0 Playground](https://www.oauth.com/playground/)
  - [Is the OAuth 2.0 Implicit Flow Dead? | Okta Developer][implicit-flow-dead]
  - [aaronpk/pkce-vanilla-js: A demonstration of the OAuth PKCE flow in plain JavaScript](https://github.com/aaronpk/pkce-vanilla-js)


- Steps:

  Generates Code Verifier and Code Challenge
  ```js
  // dummy code
  const code_verifier = getRandomString();
  const code_challenge = base64url(sha256(code_verifier));
  ```

  Redirect to auth server, send `code_challenge`:

  ```
  https://authorization-server.com/authorize?
       response_type=code
      &client_id=DQbPDZTDvFUy3G2C3z9Wp5tx
      &redirect_uri=https://www.oauth.com/playground/authorization-code-with-pkce.html
      &scope=photo+offline_access
      &state=zPw70UxYF_dLjn-D
      &code_challenge=a3jxgYEML02lNWk-OQB9aTLPPon5CBoAEdEE6eO12FM
      &code_challenge_method=S256
  ```

  Redirect back

  ```
  ?state=zPw70UxYF_dLjn-D&code=IbaAu5FBoJOkK5aeSvOA-wYhcbAN9jjDeEitijeRsUJyEt9V
  ```

  Exchange the code for token, use `code_verifier` here:

  ```
  POST https://authorization-server.com/token
    grant_type=authorization_code
    &client_id=DQbPDZTDvFUy3G2C3z9Wp5tx
    &redirect_uri=https://www.oauth.com/playground/authorization-code-with-pkce.html
    &code=IbaAu5FBoJOkK5aeSvOA-wYhcbAN9jjDeEitijeRsUJyEt9V
    &code_verifier=47LQewk2qOLVvz0AqV5kt_BBQB60WlImDdDj0AFrsLPRGu9n
  ```

  Get back result

  ```json
  {
    "token_type": "Bearer",
    "expires_in": 86400,
    "access_token": "4M2T7HkVKv-M5ouVL2HbBoTxtE7UuSdnJbWRqSRvv3Aji8cPjjtiFQiRNv5jefsY-vwtDPbS",
    "scope": "photo offline_access",
    "refresh_token": "jDBLg1iTwLG24380c9K5pzq3"
  }
  ```


### Implicit Flow (NOT SECURE)

- Suitable for SPA, static Javascript applications;
- The Authorization server returns the *access_token* directly;
- Take care to store the *access_token* properly;
- There is no *client_secret*;
- Doesn't return a refresh token (seen as too insecure), recommends short lifetime and limited scope;
- **NOT SECURE, DEPRECATED NOW**
  - It was a compromise, created due to browser limitations (JS couldn't do cross-origin post, which is required in the auth code flow)
  - Browsers, browser addons, third party JS libraries can get the access token in the url
  - see: [implicit-flow-dead]
- Current Best Practice is to replace this with Auth Code Flow with PKCE;

![Implicit Flow Example](images/oauth2_implicit-flow-example.png)
![Implicit Grant](images/oauth2_implicit-grant-flow.png)


### Client Credential

- Suitable for microservices and APIS;
- No user interaction;
- Happens only on a server;

![Client Credential](images/oauth2_client-credential-flow.png)

### Password Flow

- Users enter their username and password in the client application;
- The application must be fully trusted;
- Mostly just for compatible with old systems;

![Password Grant](images/oauth2_password-grant-flow.png)

### OpenID Connect

**This is where confusion comes from: OAuth2 was intended for authorization, but people started to use it for authentication as well, to standardize this, OpenID Connect came up**

![OpenID Connect](images/oauth2_openid-connect.png)

OpenID Connect is a simple identity layer on top of OAuth2, the overall data flow is the same:

![OpenID Auth code flow](images/oauth2_openid-auth-code-flow.png)

A few differences:

- The *scope* must contain `openid`;

- You always get an *id_token* in JWT format, *access_token* may or may not be a JWT;

  ![OpenID - ID token](images/oauth2_id-token-jwt.png)

- You can get more info about the user from a userinfo endpoint;

  ![OpenID - calling userinfo endpoint](images/oauth2_openid-userinfo-endpoint.png)


### How to choose

![How to choose](images/oauth2_choose-a-flow.png)

- Web application with server backend: Authorization code flow

  - Cookie is still used to keep the session;
  - *access_token* and *id_token* are stored in the session on server;
  - More secure:
    - Tokens are saved on the server;
    - Cookies can be limited to HTTP request only, so not exposed to rogue Javascript code;

  ![Example - Web app](images/oauth2_example-web-app.png)

- Native mobile app: authorization code flow with PKCE

  - There is a package 'AppAuth' to handle most of the work;

  ![Example - Native mobile app](images/oauth2_example-native-mobile-app.png)

- Javascript app (SPA): authorization code flow with PKCE
  - Implicit flow used to be recommended, but it's **deprecated** now;
  - Tokens need to be stored properly, but actually there's no 100% secure way to store tokens, they are accessible by JS code, browser addons, etc;

  ![Example - SPA](images/oauth2_example-spa.png)

- Microservices and APIs: client credentials flow

[implicit-flow-dead]: (https://developer.okta.com/blog/2019/05/01/is-the-oauth-implicit-flow-dead)


## SAML

An mature identify federation solution.

Three parties involved:
  - User
  - Identity Provider (IdP) (eg. Azure AD)
  - Service Provider (SP) (eg. Salesforce)

Setup process:

1. Register SP in IdP, providing ID and a bunch of URLs
2. Upload IdP's certificate to SP, so SP can trust IdP

Authentication process:

1. User tries to sign in
2. SP identifies this is from a paticular IdP
3. SP redirects user to IdP login page with a request (an encoded XML passed via GET parameter)
3. IdP authenticate user and POST to SP a response (a signed XML which includes the user's attributes)
4. SP validate the response using IdP certificate
5. SP signs in the user

The request and response are
  - In XML format
  - Passed through the browser, IdP and SP do not need to talk to each other directly
