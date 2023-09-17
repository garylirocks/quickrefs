# PHP cheatsheet

## Installation

### Multiple versions of PHP

ref: [How to Run Multiple Versions of PHP on One Server](https://www.sitepoint.com/run-multiple-versions-php-one-server/)

### Build PHP from source

[PHP Git Access](http://php.net/git.php)

- clone git repo

      	```bash
      	sudo mkdir /opt/source && cd /opt/source
      	git clone git@github.com:php/php-src.git && cd php-src

      	# switch to any branch you want
      	git checkout PHP-5.6
      	```

- generate the configure script

      	```bash
      	sudo ./buildconf
      	```

- create a directory for this version of php

      	```bash
      	cd /opt
      	sudo mkdir php-5.6
      	```

- (optional) you need to get some tools ready before your build

      	* get bison 2.7

      		http://askubuntu.com/questions/444982/install-bison-2-7-in-ubuntu-14-04

      		```bash
      		wget http://launchpadlibrarian.net/140087283/libbison-dev_2.7.1.dfsg-1_amd64.deb http://launchpadlibrarian.net/140087282/bison_2.7.1.dfsg-1_amd64.deb
      		dpkg -i libbison-dev_2.7.1.dfsg-1_amd64.deb bison_2.7.1.dfsg-1_amd64.deb

      		# prevent update manager from overwriting this package
      		sudo apt-mark hold libbison-dev bison
      		```

- configure your php build

      	```bash
      	./configure --prefix=/opt/php-5.6 --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data
      	```

- compile and install

      	```bash
      	make
      	sudo make install
      	```

      	now new version of php is installed at `/opt/php-5.6/bin/php`

- edit config files

      	```bash
      	cd /opt/php-5.6/
      	sudo cp etc/php-fpm.conf.default etc/php-fpm.conf
      	sudo cp /opt/source/php-src/php.ini-development lib/php.ini
      	```

      	now

      	```bash
      	./bin/php --ini
      	```

      	```
      	Configuration File (php.ini) Path: /opt/php-5.6/lib
      	Loaded Configuration File:         /opt/php-5.6/lib/php.ini
      	Scan for additional .ini files in: (none)
      	Additional .ini files parsed:      (none)
      	```

      	edit php-fpm config (refer to following section of this doc):

      	```bash
      	sudo vi etc/php-fpm.conf
      	```

      	make sure:

      	```bash
      	user = www-data
      	group = www-data

      	listen = 127.0.0.1:9200
      	```

- init script setup

      	```bash
      	sudo cp /opt/source/php-src/sapi/fpm/init.d.php-fpm /etc/init.d/php5.6-fpm
      	sudo chmod 755 /etc/init.d/php5.6-fpm
      	```

- start fpm

      	```bash
      	sudo /etc/init.d/php5.6-fpm start
      	```

### Install a new PHP version and make Apache it

    apt-get -y update
    add-apt-repository ppa:ondrej/php
    apt-get -y update
    apt-get -y install php5.6 php5.6-mcrypt php5.6-mbstring php5.6-curl php5.6-cli php5.6-mysql php5.6-gd php5.6-intl php5.6-xsl php5.6-zip

it also installs a php5.6 module for apache `libapache2-mod-php5.6`, you need to enable it

    sudo a2dismod php5
    sudo a2dismod php5.6
    sudo service apache2 restart

looks like `pecl` doesn't work with multiple php versions, just download the source file and compile it, install `memcached` in php5.6, make sure use `phpize5.6` when compiling

## mod_php vs. FastCGI vs. PHP-FPM

ref: `http://www.openlogic.com/wazi/bid/209956/mod_php-vs-FastCGI-vs-PHP-FPM-for-Web-Server-Scripting`

- mod_php

  Pros:

      	* Easy to install and update.
      	* Easy to configure with Apache.

  Cons:

      	* Works only with Apache.
      	* Forces every Apache child to use more memory.
      	* Needs a restart of Apache to read an updated php.ini file.

- FastCGI

  a generic protocol for interfacing interactive programs with a web server,
  Apache can use FastCGI in the form of `mod_fcgid`

  Pros:

      	* Compatible with many web servers.
      	* Smaller memory footprint than mod_php.
      	* More configuration options, including multiple PHP and suexec.

  Cons:

      	* Requires more configuration than mod_php.
      	* Not widely known in the IT community.

- PHP-FPM

  an alternative PHP FastCGI implementation with some additional features

  Pros:

      	* Compatible with many web servers.
      	* Smaller memory footprint than mod_php.
      	* More configuration options than FastCGI.

  Cons:

      	* Requires more configuration than mod_php.
      	* Not widely known in the IT community.
      	* Project is still relatively young.

### Install php-fpm

ref: `http://www.binarytides.com/install-nginx-php-fpm-mariadb-debian/`

```bash
sudo apt-get install php5-fpm

# config files are at /etc/php5/fpm/

# restart php fpm
sudo service php5-fpm restart
```

### Make php-fpm work with Apache

ref:

- [Httpd Wiki - PHP-FPM](https://wiki.apache.org/httpd/PHP-FPM)
- [PHP FPM installation](http://php.net/manual/en/install.fpm.install.php)

### php-fpm

**from 5.3.3, PHP includes the fastCGI process manager (php-fpm) in the stock source code, your distribution or OS will either include it in the stock PHP package, or make it available as an add-on package**

**you can build it from source by adding `--enable-fpm` to your `./configure` options**, other options include `--with-fpm-user`, `--with-fpm-group`

in Ubuntu, there is a separate package `php5-fpm`, its config files are at `/etc/php5/fpm/`

global config is in `php-fpm.conf`, each process pool should got a separate config in `pool.d` folder, do the following config in `www.conf`

```ini
user = www-data
group = www-data

listen = 127.0.0.1:9100
```

start php-fpm

```bash
sudo service php5-fpm start
```

### Apache

Apache httpd 2.4 introduced a new proxy module for fastCGI (mod_proxy_fcgi), and moved to event MPM as process manager

enable the modules:

```bash
sudo a2enmod proxy proxy_fcgi
sudo service apache2 restart
```

create a vhost config file `/etc/apache2/sites-available/test-fpm.local.conf`, add config:

```apache
ServerName test-fpm.local

DocumentRoot /var/www/test-fpm
ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9100/var/www/fpm/$1
DirectoryIndex /index.php index.php
```

enable config and restart apache:

```bash
sudo a2ensite test-fpm.local
sudo service apache2 restart
```

Done! try visit `http://test-fpm.local/phpinfo.php`

Server API should be 'FPM/FastCGI'

## XML

When using `DOMDocument`, add a meta tag to make sure your HTML file is treated as 'UTF-8' encoded, this will cause a 'misplaced tag' warning, suppress with '@'

    $doc = new DOMDocument();
    @$doc->loadHTML('<meta http-equiv="content-type" content="text/html; charset=utf-8">' . $html);

## Arrays

### array elements order:

    $a = array(1=>'1', 0=>0, 2=>2);

    foreach ($a as $value) {
        echo $value . ' ';
    }

output:

    1 0 2

## Coding styles

- PHP 5.4 will always have the `<?=` tag available.

## New Features in Each Version

_Only some prominent changes are listed here, always refer to the official doc for a full list._

### 5.6

- Constant expressions

      	```php
      	const X = 20;

      	// a constant expression is allowed now, previously only static value is allowed
      	const Y = X * 2;
      	```

      	```php
      	// constant array is possible now
      	const ARR = ['Arya', 'Sansa'];
      	```

- Variadic functions / rest operator

      	```php
      	function foo($x, $y, ...$others) {
      		// $others is an arrow containing remaining arguments
      	}
      	```

- Argument unpacking

      	```php
      	function ($a, $b, $c) {
      		return $a + $b + $c;
      	}

      	$arr = [2, 3];
      	echo add(1, ...$arr);
      	```

- Exponentiation operator `**`

      	```php
      	2 ** 3	// 8
      	```

- `use function` and `use const`

      	previously `use` operator can only be used to import classes

      	```php
      	namespace My\Namespace {
      		const NAME = 'Gary';
      		function f() { echo __FUNCTION__ . "\n"; }
      	}

      	namespace {
      		use const My\Namespace\NAME;
      		use function My\Namespace\f;

      		echo NAME . "\n";
      		f();
      	}
      	```

### 7.0

- Scalar type declarations

- Return type declarations

- Null coalescing operator

      	```php
      	$name = $_GET['name'] ?? 'unknown';
      	// equivalent to
      	$name = isset($_GET['name']) ? $_GET['name'] : 'unknown';

      	// chaining
      	$name = $_GET['name'] ?? $_POST['name'] ?? 'unknown';
      	```

- Spaceship operator

      	compares two expressions and return -1, 0 or 1

      	```php
      	echo 1 <=> 1; 		// 0
      	echo 'a' <=> 'b'; 	// -1
      	echo 2.5 <=> 1.5; 	// 1
      	```

### 7.1

- Nullable types

      	prefixing a type name with a '?' to signify `NULL` can be passed or returned as well as the specific type

      	```php
      	function foo(): ?string {
      		return 'hello'; 	// return a string
      		// return null;		// you can return null as well
      	}

      	function bar(?string $name) {	// accepts a string or null
      		echo 'hello ' . $name;
      	}

      	```

- Void functions

      	```php
      	function foo(): void {
      		// no return statement
      	}
      	```

- Symmetric array destructuring

      	```php
      	$data = [
      		[1, 'US'],
      		[2, 'China'],
      	];

      	foreach ($data as [$id, $country]) {
      		// do something
      	}
      	```

- class constant visibility

      	```php
      	class Animal {
      		const PUBLIC_A = 1;
      		public const PUBLIC_B = 2;
      		private const PRIVATE_C = 3;
      		protected const PROTECTED_C = 4;
      	}
      	```

### 7.2

- New object type

      	```php
      	function foo(object $obj) : object {
      		return new StdClass();
      	}
      	```

- Extension loading by name

      	In `php.ini`, extensions' file extension (*.so* or *.dll*) is not required, just use the name

## Pitfalls

### Session get cleared

On Ubuntu (probably on other systems as well), PHP installs a crontab file to clear sessions, the file is here `/etc/cron.d/php`

```
09,39 *     * * *     root   [ -x /usr/lib/php/sessionclean ] && if [ ! -d /run/systemd/system ]; then /usr/lib/php/sessionclean; fi
```

it runs every 30 minutes, and clears every session files older than `session.gc_maxlifetime` (24mins by default), so by default all sessions get cleared around 30 mins

## Resources

- test php skills

  http://testphpskills.com
