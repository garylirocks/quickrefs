Apache tips
==============


## configuration

set environment variables for PHP in apache config:

    <VirtualHost *:80>
        ...

        SetEnv MY_NAME gary


[set php ini values in apache config][php_config_change]

    <VirtualHost *:80>
        ...

        # !! CAT NOT USE PHP CONSTANTS, USE INT VALUES INSTEAD !!
        # 22519 means: E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED
        php_admin_value error_reporting 22519


## deny access to some files

	<Files ~ "\.log$">
		Order allow,deny
		Deny from all
	</Files>


## redirection

### rewrite log

[rewrite loggin][apache_rewrite_logging]

in Apache 2.4+, `RewriteLog` and `RewriteLogLevel` directives have been replaced, use the `LogLevel` directive

	LogLevel alert rewrite:trace3

check rewrite logs:

	tail -f error_log|fgrep '[rewrite:'


### rewrite example, rewrite query strings as path

	# redirect testing: add query string to path
	RewriteCond %{QUERY_STRING} ^(.+)$
	RewriteRule ^redirecttest.html$ redirecttest@%1.html [L]

makes `redirecttest.html?a=10&b=20` redirect to `redirecttest@a=10&b=20.html`


[php_config_change]: http://php.net/manual/en/configuration.changes.php
[apache_rewrite_logging]: http://httpd.apache.org/docs/current/mod/mod_rewrite.html
