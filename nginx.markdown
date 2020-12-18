# Nginx

- [How a request is processed](#how-a-request-is-processed)
  - [`server` block](#server-block)
  - [`location` block](#location-block)
- [Directives](#directives)
  - [`server_name`](#server_name)
    - [Wildcard names](#wildcard-names)
    - [Regular expression names](#regular-expression-names)
    - [Default server](#default-server)
  - [`try_files`](#try_files)
  - [`return`](#return)
  - [`rewrite`](#rewrite)
    - [`rewrite` vs. `return`](#rewrite-vs-return)
  - [`upstream`](#upstream)
  - [`fastcgi_split_path_info`](#fastcgi_split_path_info)
  - [`map`](#map)
- [Cheatsheets](#cheatsheets)
  - [Standardizing domain names](#standardizing-domain-names)
  - [Add or removing the 'www' prefix](#add-or-removing-the-www-prefix)
  - [Forcing all request to use SSL/TLS](#forcing-all-request-to-use-ssltls)
  - [Enabling pretty permalinks for Wordpress](#enabling-pretty-permalinks-for-wordpress)
  - [Load balancing](#load-balancing)
  - [Get real client ip](#get-real-client-ip)
  - [CORS rules](#cors-rules)
  - [Serving protected files](#serving-protected-files)
- [Trivia](#trivia)

## How a request is processed

[How Nginx processes a request](http://nginx.org/en/docs/http/request_processing.html)

### `server` block

```nginx
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

- a request's `Host` field determines which server block is used;
- if no match, the first block is used;
- a `default_server` param can be used to set explicitly which block should be used:

  ```
  server {
      listen      80 default_server;
      server_name example.net www.example.net;
      ...
  }
  ```

### `location` block

```nginx
server {
    listen      80;
    server_name example.org www.example.org;
    root        /data/www;

    location / {                        # prefix matching
        index   index.html index.php;
    }

    location ~* \.(gif|jpg|png)$ {      # case-insensitive regex
        expires 30d;
    }

    location ~ \.php$ {                 # case-sensitive regex
        fastcgi_pass  localhost:9000;
        fastcgi_param SCRIPT_FILENAME
                      $document_root$fastcgi_script_name;
        include       fastcgi_params;
    }
}
```

1. Only the URI part of a request is tested, not the parameters;
2. Nginx searches for the **MOST SPECIFIC**(longest) prefix location given by literal strings regardless of the listed order (`/` matches every request, it is used if no other matches found);
3. Then locations given by regular expression are checked in order, the **FIRST** one is used, if no regular expression matches, the most specific prefix location in the first step is used;
4. `location` blocks can be nested;
5. Modifiers:
   1. `~` case-sensitive regex;
   2. `~*` case-insensitive regex;
   3. `=` exact prefix match, terminates the search;
   4. `^~` if the longest prefix location has this modifier, don't check regex expressions;
6. Regex can contain captures that can be used in other directives;

Example:

- `/about.html` is handled by the first location, `/data/www/about.html` is sent to the client if present;
- in above example, when `\` is requested, if `index.html` is present, it is sent out, if it is not, but `index.php` exists, then the directive does an internal redirect to `/index.php` as if the request comes from a client, it will be handled by the last `location` block;

## Directives

### `server_name`

```nginx
server {
    listen       80;
    server_name  example.org  www.example.org;
    ...
}

server {
    listen       80;
    server_name  *.example.org;
    ...
}

server {
    listen       80;
    server_name  mail.*;
    ...
}

server {
    listen       80;
    server_name  ~^(?<user>.+)\.example\.net$;
    ...
}
```

When searching for a virtual server by name, if name matches more than one of the specified variants, e.g. both wildcard name and regular expression match, the first matching variant will be chosen, in the following order of precedence:

1. exact name (**use exact names when possible, it is the fastest**)
2. longest wildcard name starting with an asterisk, e.g. "\*.example.org"
3. longest wildcard name ending with an asterisk, e.g. "mail.\*"
4. first matching regular expression (in order of appearance in a configuration file)

#### Wildcard names

- Can contain one asterisk, need to be either at the start or end, and only bordered with a dot;
- A special wildcard name `.example.com` can be used to match both the exact name `example.com` and the wildcard name `*.example.com`;

#### Regular expression names

- PCRE compatible;
- If the regex contains `{` or `}`, it should be quoted;
- A named regular expression capture can be used later as a variable;

```nginx
server {
    server_name   ~^(www\.)?(?<domain>.+)$;

    location / {
        root   /sites/$domain;
    }
}
```

#### Default server

default server should be configured using the listen directive:

```nginx
server {
    listen       80;
    listen       8080  default_server;
    server_name  example.net;
    ...
}

server {
    listen       80  default_server;
    listen       8080;
    server_name  example.org;
    ...
}
```

### `try_files`

- inside `server` or `location`;
- it takes one or more files and directories and a final URI;
  ```nginx
  try_files file ... uri;
  ```
- checks the existence of the files and directories in order (building the full path using `root` and `alias`), serves the first found;
- if none found, do an internal redirect to the URI defined by the final element;
- you need to define a `location` block to capture the internal redirect;

```nginx
# serve default.gif if the requested image not found
location /images/ {
    try_files $uri $uri/ /images/default.gif;
}

location = /images/default.gif {
    expires 30s;
}
```

### `return`

Tells Nginx to stop processing the request and send a code back immediately.

```nginx
server {
    listen 80;
    listen 443 ssl;
    server_name www.old-name.com;
    return 301 $scheme://www.new-name.com$request_uri;
}
```

- For `3xx` codes, specify a url for redirecting

  ```
  return (301 | 302 | 303 | 307) url;
  ```

- For other codes, you can optionally define a text which appears in the body of the response:

  ```
  return (1xx | 2xx | 4xx | 5xx) ["text"];
  ```

- Pass thru parameters

  ```
  return 301 https://www.example.com$uri$is_args$args;
  ```

  `$is_args` is either empty or `?`, `$args` is the paramters string

- Always use `return` for redirections whenever:

  - the rewritten URL is appropriate for every request in a `server` or `location` block;
  - and you can build the rewritten URL with standard Nginx variables;

### `rewrite`

```nginx
server {
    . . .
    server_name domain1.com;
    rewrite ^/(.*)$ http://domain2.com/$1 [redirect|permanent];
    . . .
}
```

- Redirect `domain1.com` to `domain2.com`;
- Use `redirect` for temporary (302) redirect; `permanent` for 301 redirect;

Use rewrite for site maintenance:

```
location / {
    return 503;
}

error_page 503 @maintenance;

location @maintenance {
    # NOTE: *the new url here is not a full url, and no `redirect` or `permanent` flag, so it's an internal redirection only*
    # looks like if the replacement is a file, it will be used directly, NO further location matching is performed
    # otherwise it will do further location matching
    rewrite ^(.*)$ /503.html break;
}
```

this will ensure every request gets a 503 response code, and the content of `503.html` is used.


#### `rewrite` vs. `return`

[https://www.nginx.com/blog/creating-nginx-rewrite-rules/]

- `return` is preferred to do redirections whenever possible;
- `rewrite` can only return `301` or `302`;
- `rewrite` doesn't necessarily halt Nginx's processing of the request as `return` does, and doesn't necessarily send a redirect to the client, see above url for details;

  ```nginx
  server {
      # ...
      rewrite ^(/download/.*)/media/(\w+)\.?.*$ $1/mp3/$2.mp3 last;
      rewrite ^(/download/.*)/audio/(\w+)\.?.*$ $1/mp3/$2.ra  last;
      return  403;
      # ...
  }
  ```

  the above code do internal rewrites, `last` indicates stop processing other Rewrite-module directives in current block, and start searching for a new matching `location`, if none of the `rewrite` rules match, it will return `403`.

### `upstream`

Used to define server groups that can be referenced by the `proxy_pass`, `fastcgi_pass`, `uwsgi_pass`, `memcached_pass` etc, this is actually a simple **load balancer**.

```nginx
upstream backend {
    server backend1.example.com       weight=5;
    server backend2.example.com:8080;
    server unix:/tmp/backend3;

    server backup1.example.com:8080   backup;
    server backup2.example.com:8080   backup;
}

server {
    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

You usually need to use `proxy_set_header` to pass a few headers to the backend, so it can get correct host, protocol, etc.

- `proxy_set_header Host $host;` sets 'Host' to the original 'Host' header, otherwise `$proxy_host` is set as 'Host', 'backend' in the example above;
- `proxy_set_header X-Forwarded-Proto https;` sets the protocol, in express it would be available as `req.protocol`;

To make sure Nginx starts even when any upstream is not up, you need to either use static ip address or variable for the upstream host, see https://stackoverflow.com/a/32846603

```nginx
# a resolver directive is required if you use a variable in upstream host
resolver 127.0.0.11 valid=30s;

server {
    listen 7009;
    server_name _;

    location / {
      # use a variable here
      set $upstream dummy-backend;
      proxy_pass http://$upstream:80;   # NOTE: a trailing slash like 'http://$upstream:80/;' would cause problems !!!
    }
}
```


### `fastcgi_split_path_info`

Defines a regular expression that captures a value for the `$fastcgi_path_info` variable. The regular expression should have two captures: the first becomes a value of the `$fastcgi_script_name` variable, the second becomes a value of the `$fastcgi_path_info` variable. For example, with these settings

```nginx
location ~ ^(.+\.php)(.*)$ {
    fastcgi_split_path_info       ^(.+\.php)(.*)$;
    fastcgi_param SCRIPT_FILENAME /path/to/php$fastcgi_script_name;
    fastcgi_param PATH_INFO       $fastcgi_path_info;
    ...
}
```

for this request `/show.php/article/0001`:

- the `SCRIPT_FILENAME` parameter will be equal to `/path/to/php/show.php`;
- and the `PATH_INFO` parameter will be equal to `/article/0001`;

### `map`

Define a new variables whose value depends on a source variable:

```nginx
map $http_host $myVar {
    hostnames;              # indicates source values can be hostnames with prefix/suffix mask
    
    .domain.com     1;      # matches domain.com and xxx.domain.com
    *.net           2;
}
```


## Cheatsheets

### Standardizing domain names

```nginx
server {
    listen 80;
    listen 443 ssl;
    server_name www.old-name.com old-name.com;
    return 301 $scheme://www.new-name.com$request_uri;

    # use following one if you only what to redirect to the homepage
    # return 301 $scheme://www.new-name.com;
}
```

```nginx
# redirect all traffic to correct domain name
server {
    listen 80 default_server;
    listen 443 ssl default_server;
    server_name _;
    return 301 $scheme://www.domain.com;
}
```

### Add or removing the 'www' prefix

```nginx
# add 'www'
server {
    listen 80;
    listen 443 ssl;
    server_name domain.com;
    return 301 $scheme://www.domain.com$request_uri;
}

# remove 'www'
server {
    listen 80;
    listen 443 ssl;
    server_name www.domain.com;
    return 301 $scheme://domain.com$request_uri;
}
```

### Forcing all request to use SSL/TLS

```nginx
server {
    listen 80;
    server_name www.domain.com;
    return 301 https://www.domain.com$request_uri;
}
```

### Enabling pretty permalinks for Wordpress

```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```

### Load balancing

```nginx
upstream backend {
    server backend1.example.com       weight=5;
    server 192.168.11.1:8080;
    server unix:/tmp/backend3;

    server backup1.example.com:8080   backup;
    server backup2.example.com:8080   backup;
}

server {
    listen *:80;
    server_name example.com;
    index index.html index.htm;

    location / {
        proxy_pass http://backend;
    }
}
```

### Get real client ip

When Nginx server is behind a load balancer or a proxy, it's not getting the real client ip address, you need to add some directives to enable it, see: http://nginx.org/en/docs/http/ngx_http_realip_module.html

```nginx
real_ip_header    X-Forwarded-For;
set_real_ip_from  10.0.0.0/8;
```

This allows Nginx to log the real ip, and do some access restrictions based on it.

### CORS rules

[CORS on Nginx](https://enable-cors.org/server_nginx.html)

```nginx
#
# Wide-open CORS config for nginx
#
location / {
     if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        #
        # Custom headers and headers various browsers *should* be OK with but aren't
        #
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
        #
        # Tell client that this pre-flight info is valid for 20 days
        #
        add_header 'Access-Control-Max-Age' 1728000;
        add_header 'Content-Type' 'text/plain; charset=utf-8';
        add_header 'Content-Length' 0;
        return 204;
     }
     if ($request_method = 'POST') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
     }
     if ($request_method = 'GET') {
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
        add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range';
     }
}
```

### Serving protected files

https://www.nginx.com/resources/wiki/start/topics/examples/x-accel/

To server protected files, you want to have backend script to handle authentication, logging etc, and then have NGINX handling serving contents from redirected location to the end user.

1. Configure the backend to send a header like `X-Accel-Redirect: /var/files/apple.jpg`;
2. Add this in NGINX conf

    ```nginx
    location /var/files {
        internal;          # this indicate this is an internal location
        alias /var/files;
    }
    ```
3. Then NINGX will serve `apple.jpg`;


## Trivia

- For a request `/path`, if `path` points to a directory, NGINX does a 301 redirect to `/path/` by default;

  Two related directives to this:

  - `absolute_redirect` controls whether absolute or relative path is used in the response headers;
  - `server_name_in_redirect` if on, the primary server name (specified by the `server_name` directive) is used in the absolute redirect url, otherwise it uses the name from the `Host` request header, if this field is not present, then the IP address of the server is used (this may leak internal IP address, which is a security vulnerability CVE-2000-0649);

- Redirect based on the query string (`location` only matches the uri, not including the query string)

    ```nginx
    location / {
        if ($args ~* "foo=1") {
            return 301 https://example.com/foo;
        }

        ...
    }
    ```

    [If is Evil](https://www.nginx.com/resources/wiki/start/topics/depth/ifisevil/), but it's safe in this case