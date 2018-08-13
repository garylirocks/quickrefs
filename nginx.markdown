Nginx
==========

[How Nginx processes a request](http://nginx.org/en/docs/http/request_processing.html)

## How a request is processed

### `server` block

```
server {
    listen      80;
    server_name example.org www.example.org;
    ...
}

server {
    listen      80;
    server_name example.net www.example.net;
    ...
}

server {
    listen      80;
    server_name example.com www.example.com;
    ...
}
```

* a request's `Host` field determines which server block is used;
* if no match, the first block is used;
* a `default_server` param can be used to set explicitly which block should be used:

    ```
    server {
        listen      80 default_server;
        server_name example.net www.example.net;
        ...
    }
    ```

### `location` block

```
server {
    listen      80;
    server_name example.org www.example.org;
    root        /data/www;

    location / {
        index   index.html index.php;
    }

    location ~* \.(gif|jpg|png)$ {
        expires 30d;
    }

    location ~ \.php$ {
        fastcgi_pass  localhost:9000;
        fastcgi_param SCRIPT_FILENAME
                      $document_root$fastcgi_script_name;
        include       fastcgi_params;
    }
}
```

1. nginx searches for the **MOST SPECIFIC** prefix location given by literal strings regardless of the listed order (`/` matches every request, it is used if no other matches found);
2. then locations given by regular expression are checked in order, the **FIRST** one is used, if no regular expression matches, the most specific prefix location in the first step is used;

Notes:

* only the URI part of a request is tested, not the arguments;
* `/about.html` is handled by the first location, `/data/www/about.html` is sent to the client if present;
* in above example, when `\` is requested, if `index.html` is present, it is sent out, if it is not, but `index.php` exists, then the directive does an internal redirect to `/index.php` as if the request comes from a client, it will be handled by the last `location` block;
