HTTP/2
========

- [HTTP/2](#http-2)
    - [Reference](#reference)
    - [Server Push](#server-push)
        - [config it in Nginx](#config-it-in-nginx)
        - [config it in Apache](#config-it-in-apache)
        - [push using back-end scripts](#push-using-back-end-scripts)
            - [in PHP](#in-php)
            - [in Node.js](#in-nodejs)

## Reference

[HTTP/2 服务器推送（Server Push）教程 - 阮一峰](http://www.ruanyifeng.com/blog/2018/03/http2_server_push.html)

[HTTP/2 Server Push with Node.js](https://blog.risingstack.com/node-js-http-2-push/)

[Using HTTP/2 Server Push with PHP](https://blog.cloudflare.com/using-http-2-server-push-with-php/)


## Server Push

![HTTP/2 Server Push](./images/http2-server-push.png)

the core idea is **reducing HTTP requests, with one request, the server pushes all needed assets to the browser**

for a simple html page

```html
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>hello world</h1>
  <img src="example.png">
</body>
</html>
```

to render this page, browser will need to send three requests to the server, the first one:

`GET /index.html HTTP/1.1`

then after browser parses the html, it will send two other requests:

`GET /style.css HTTP/1.1`

`GET /example.png HTTP/1.1`

the page will be blank before the stylesheet is received

in HTTP/1.1, there are two ways to cut the two requests:
* inline the stylesheet and image (use Data URL);
* use 'preload' (this doesn't work in this case)

    ```html
    <link rel="preload" href="/styles.css" as="style">
    <link rel="preload" href="/example.png" as="image">
    ```

with **server push**, the server can send all `index.html`, `style.css`, `example.png` to the browser in one go

server push is the *only* feature in HTTP/2 that requires manual configuration

### config it in Nginx

in `conf/conf.d/default.conf`

```nginx
server {
    listen 443 ssl http2;
    server_name  localhost;

    ssl                      on;
    ssl_certificate          /etc/nginx/certs/example.crt;
    ssl_certificate_key      /etc/nginx/certs/example.key;

    ssl_session_timeout  5m;

    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers   on;

    location / {
      root   /usr/share/nginx/html;
      index  index.html index.htm;
      http2_push /style.css;           # server push
      http2_push /example.png;         # server push
    }
}
```

the two server push lines tell the server to push `style.css` and `example.png` when the root path `/` is requested

### config it in Apache

```apache
<FilesMatch "\index.html$">
    Header add Link "</styles.css>; rel=preload; as=style"
    Header add Link "</example.png>; rel=preload; as=image"
</FilesMatch>
```

### push using back-end scripts

it's not a good practice to add the push configurations in server config files, it's better to achieve it in back-end applications

to create pushes, back-end app need to create a `Link` header in the response:

`Link: </styles.css>; rel=preload; as=style`

if pusing multiple assets:

`Link: </styles.css>; rel=preload; as=style, </example.png>; rel=preload; as=image`

the syntax comes from [preload](https://w3c.github.io/preload/)

#### in PHP

```php
<?php
function pushImage($uri) {
    header("Link: <{$uri}>; rel=preload; as=image", false);
    return <<<HTML
<img src="{$uri}">
HTML;
}

$image1 = pushImage("/images/drucken.jpg");
$image2 = pushImage("/images/empire.jpg");
?>

<html>

<head><title>PHP Server Push</title></head>
<body>

<h1>PHP Server Push</h1>

<?php
echo $image1;
echo $image2;
?>

</body>
</html>
```

now in nginx config

```nginx
server {
    listen 443 ssl http2;

    # ...

    root /var/www/html;

    location = / {
        proxy_pass http://upstream;
        http2_push_preload on;      # push preload
    }
}
```

if the server or browser doesn't support HTTP/2, the browser will see the `Link` header as an instruction for preloading assets

#### in Node.js

use built-in `http2` module, NodeJS is working as the server here, so no need to configure Apache or Nginx 

```node
const http2 = require('http2')
const server = http2.createSecureServer(
  { cert, key },
  onRequest
)

function push (stream, filePath) {
  const { file, headers } = getFile(filePath)
  const pushHeaders = { [HTTP2_HEADER_PATH]: filePath }

  stream.pushStream(pushHeaders, (pushStream) => {
    pushStream.respondWithFD(file, headers)
  })
}

function onRequest (req, res) {
  // Push files with index.html
  if (reqPath === '/index.html') {
    push(res.stream, 'bundle1.js')
    push(res.stream, 'bundle2.js')
  }

  // Serve file
  res.stream.respondWithFD(file.fileDescriptor, file.headers)
}
```