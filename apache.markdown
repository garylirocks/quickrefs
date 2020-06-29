# Apache

- [Configuration](#configuration)
  - [Envs and PHP ini values](#envs-and-php-ini-values)
  - [Deny access to some files](#deny-access-to-some-files)
- [Rewrite](#rewrite)
  - [Logging](#logging)
  - [Example: rewrite the query string as path](#example-rewrite-the-query-string-as-path)
- [Create a SSL certificate for Apache](#create-a-ssl-certificate-for-apache)
  - [Use Let's Encrypt](#use-lets-encrypt)

## Configuration

### Envs and PHP ini values

Set environment variables for PHP in apache config:

```apache
<VirtualHost *:80>
    ...
    SetEnv MY_NAME gary
    ...
</VirtualHost>
```

[Set php ini values in Apache config][php_config_change]

```apache
<VirtualHost *:80>
    ...

    # !! CAN NOT USE PHP CONSTANTS, USE INT VALUES INSTEAD !!
    # 22519 means: E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
    php_admin_value error_reporting 22519

    ...
</VirtualHost>
```

### Deny access to some files

```apache
<Files ~ "\.log$">
    Order allow,deny
    Deny from all
</Files>
```

## Redirect

If you need a external redirection, use `Redirect` and `RedirectMatch`, `Rewrite` is mostly used for internal redirection

```
Redirect [status] [URL-path] URL
```

```apache
Redirect permanent "/one" "https://new.example.com/one"
```

Redirect is matching the beginning of the path, any additional path and GET parameters will be appended to the new URL, so `https://old.example.com/one/foo?id=1` is redirected to `https://new.example.com/one/foo?id=1`

```
RedirectMatch [status] regex URL
```

```apache
RedirectMatch "^/one(/|$)(.*)" "https://new.example.com/one$1$2"
```

For `RedirectMatch`, it's matching the whole path, and GET parameters are appended automatically

## Rewrite

### Logging

[Rewrite logging][apache_rewrite_logging]

In Apache 2.4+, `RewriteLog` and `RewriteLogLevel` directives have been replaced, use the `LogLevel` directive

```apache
LogLevel alert rewrite:trace3
```

check rewrite logs:

```sh
tail -f error_log | fgrep '[rewrite:'
```

### Example: rewrite the query string as path

```apache
# redirect testing: add query string to path
RewriteCond %{QUERY_STRING} ^(.+)$
RewriteRule ^redirecttest.html$ redirecttest@%1.html [L]
```

this rewrites `redirecttest.html?a=10&b=20` to `redirecttest@a=10&b=20.html`

## Create a SSL certificate for Apache

Ref: [How To Create a SSL Certificate on Apache for Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-ssl-certificate-on-apache-for-ubuntu-14-04)

- Activate SSL module

  ```sh
  sudo a2enmod ssl
  sudo service apache2 restart
  ```

- Create a self-signed SSL certificate

  ```sh
  sudo service apache2 restart
  sudo openssl req -x509 -nodes \
              -days 365 \
              -newkey rsa:2048 \
              -keyout /etc/apache2/ssl/apache.key \
              -out /etc/apache2/ssl/apache.crt
  ```

  it will prompt some questions, fill in something like following:

  ```
  Country Name (2 letter code) [AU]:US
  State or Province Name (full name) [Some-State]:New York
  Locality Name (eg, city) []:New York City
  Organization Name (eg, company) [Internet Widgits Pty Ltd]:Your Company
  Organizational Unit Name (eg, section) []:Department of Kittens
  Common Name (e.g. server FQDN or YOUR name) []:your_domain.com
  Email Address []:your_email@domain.com
  ```

- Config Apache

  ```sh
  cd /etc/apache2/sites-available
  sudo cp default-ssl.conf your_domain.com.conf
  ```

  edit the config file like something following:

  ```apache
  <IfModule mod_ssl.c>
      <VirtualHost _default_:443>
          ServerAdmin admin@example.com
          ServerName your_domain.com

          ...

          SSLEngine on
          SSLCertificateFile /etc/apache2/ssl/apache.crt
          SSLCertificateKeyFile /etc/apache2/ssl/apache.key

          <FilesMatch "\.(cgi|shtml|phtml|php)$">
              SSLOptions +StdEnvVars
          </FilesMatch>

          <Directory /usr/lib/cgi-bin>
              SSLOptions +StdEnvVars
          </Directory>

          BrowserMatch "MSIE [2-6]" \
                          nokeepalive ssl-unclean-shutdown \
                          downgrade-1.0 force-response-1.0
          BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
      </VirtualHost>
  </IfModule>
  ```

- Activate site

  ```sh
  sudo a2ensite your_domain.com
  sudo service apache2 restart
  ```

- Testing

  visit `https://your_domain.com`, the connection is encrypted now, but it will show the certificate is not valid, that's fine

### Use Let's Encrypt

Ref: [How To Secure Apache with Let's Encrypt on Ubuntu 14.04](https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-14-04)

[php_config_change]: http://php.net/manual/en/configuration.changes.php
[apache_rewrite_logging]: http://httpd.apache.org/docs/current/mod/mod_rewrite.html
