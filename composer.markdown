# Composer

Tips about the Composer package management tool.

## Autoloading

loading `Mynamespace` from the `src` folder in the package root

```php
"autoload": {
	"psr-4": {
		"Mynamespace\\": "src"
	}
}
```

or loading from multiple locations

```php
"autoload": {
	"psr-4": {
		"Mynamespace\\": ["src/app", "src/test/"]
	}
}
```
