# PayPal

- [IPN](#ipn)

## IPN

[PayPal IPN Intro](https://developer.paypal.com/docs/classic/ipn/integration-guide/IPNIntro/)

PayPal will send an IPN message to your app/website when some events occur, your app need to send the original message back to PayPal to verify it.

The code in your app handles this is often called listener/handler, after the IPN message is verified, the listener can trigger other business logic in your app, such as updating order status, handling shipping, sending email etc;

The auth flow works like this:

![IPN Auth Flow](./images/paypal_ipn-auth-flow.gif)
