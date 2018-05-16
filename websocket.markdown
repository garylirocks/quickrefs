WebSocket
===========

- [WebSocket](#websocket)
    - [Why](#why)
    - [Intro](#intro)
    - [basic demo](#basic-demo)


[WebSocket 教程 - 阮一峰](http://www.ruanyifeng.com/blog/2017/05/websocket.html) 


## Why

Problems with HTTP

* One-way
* stateless
* Half-Duplex protocol


## Intro

It enables the server to push messages to the client

![WebSocket Protocol](./images/websocket.png)

* based on TCP;
* compatible with HTTP, using port 80 and 443, using HTTP protocol when in handshaking phase;
* lightweight, efficient;
* can send text or binary data;
* no same-origin limitation, can connect to any server;
* using `ws`, `wss` as identifier;

`ws://example.com:80/some/path`

![WS protocol structure](./images/ws-protocol-structure.jpg)

## basic demo

<p data-height="265" data-theme-id="0" data-slug-hash="wjExaZ" data-default-tab="js,result" data-user="garylirocks" data-embed-version="2" data-pen-title="WebSocket" class="codepen">See the Pen <a href="https://codepen.io/garylirocks/pen/wjExaZ/">WebSocket</a> by Gary Li (<a href="https://codepen.io/garylirocks">@garylirocks</a>) on <a href="https://codepen.io">CodePen</a>.</p>
<script async src="https://static.codepen.io/assets/embed/ei.js"></script>