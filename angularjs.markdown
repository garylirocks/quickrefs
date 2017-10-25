AngularJS
===============

**this is for AngularJS (1.x), not Angular (> 2.0)**


## basic ideas

Add directives to html to make it more dynamic


## basic example

`app.js`

```js
(function() {
    var app = angular.module('gemStore', []);                         // define a module

    app.controller('StoreController', ['$http', function($http){      // define a controller 
        var store = this;                                               // save this in a variable to be used in a callback
        store.products = [];

        $http.get('/store-products.json').success(function(data) {      // get a json file using the $http service
            store.products = data;
        });
    });
})();
```

**NOTE: dependencies are passed in an array, so it works with Dependency Injection even after the JS file got minimized (the argument name `$http` would be changed to something like `a`)**


`index.html`

	<!DOCTYPE html>
	<html ng-app="gemStore">
	  <head>
		<link rel="stylesheet" type="text/css" href="bootstrap.min.css" />
		<script type="text/javascript" src="angular.min.js"></script>
		<script type="text/javascript" src="app.js"></script>
	  </head>
	  <body class="container" ng-controller="StoreController as store">
		<div class="product row" ng-repeat="product in store.products">
		  <h3 ng-include="'product-title.html'">
		  </h3>
		</div>
	  </body>
	</html>


`product-title.html`

	{{product.name}}
	<em class="pull-right">${{product.price}}</em>


* Directives

	* `ng-app`					app's scope
	* `ng-controller`			attach a controller
	* `ng-repeat`				iterating thru something
	* `ng-show`, `ng-hide`		show/hide something according to value of a variable
	* `ng-src`					specifies the source url for images / media
		
		`<img ng-src="{{product.image}}" />`

	* `ng-include`				includes a html snippet from another file, **CAUTION: it takes another http request to get the snippet**


	**CAUTION: anything inside the double quotes of a directive will be evaluated directly as JS code, so if you want to use a literal string, using:**

		<div ng-include="'product-title.html'">
		</div>


* Expressions

	`{{product.name}}`


* Services

	`$http` is a builtin service, it gets injected to a controller


* Filters

	`{{ data | filter:options }}`

	1. upper / lower case

		`{{'gary li' | uppercase}}`		->	'GARY LI'

	* currency

		`{{20 | currency}}`				-> $20.00

	* text length limit

		`{{'this is long' | limitTo:6}}`	->	'this i'

	* date formatting

		`{{1504160083144 | date:'yyyy-MM-dd @ hh:mm:ss a'}}`	->		'2017-08-31 @ 06:14:43 PM'

	* loop limits

		`<li ng-repeat="product in store.products | limitTo:3">`

	* ordering

		`<li ng-repeat="product in store.products | orderBy:'-price'">`



## Custom Directives

###	Template-expanding Directives

`index.html`

	...
	<product-title></product-title>					// do not use a self-closing tag for custom element
	...


`app.js`

	...
	app.directive('productTitle', function() {
		return {
			restrict: 'E',							// type of directive, 'E' for 'Element'
			templateUrl: 'product-title.html',		// url of a template file

			controller: function() {
				this.prefix = 'NEW!';
				...
			},
			controllerAs: 'pt',
		};
	});
	...

`product-title.html`

	<h3>
		{{pt.prefix}} {{product.name}}
		<em class="pull-right">${{product.price}}</em>
	</h3>


**CAUTION**

`product-title` in html, `productTitle` in JS


### Attribute Directives

`app.js`

	...
	app.directive('productTitle', function() {
		return {
			restrict: 'A',							// type of directive, 'A' for 'attribute'
			templateUrl: 'product-title.html',		// url of a template file
		};
	});
	...
	
`index.html`

	<div product-title></div>


## Forms


`app.js`

	app.controller("ReviewController", function() {
		this.review = {};

		this.addReview = function(product) {
			this.review.createdOn = Date.now();
			product.reviews.push(this.review);
			this.review = {};
		);
	});


`index.html`

	<form name="reviewForm" ng-controller="ReviewController as reviewCtrl"
							ng-submit="reviewForm.$valid && reviewCtrl.addReview(product)" novalidate>
		<blockquote>
			<b>Stars: {{reviewCtrl.review.stars}}</b>
			{{reviewCtrl.review.body}}
			<cite>by: {{reviewCtrl.review.author}} on {{reviewCtrl.review.createdOn | date}}</cite>
		</blockquote>

		<select ng-model="reviewCtrl.review.stars"
				ng-options="stars for stars in [5,4,3,2,1]" required>
			<option value="">Rate the Product</option>
		</select>

		<textarea ng-model="review.body"></textarea>

		<label>by: </label>
		<input ng-model="review.author" type="email" />
		<input type="submit" value="Submit" />
	</form>


* `ng-model`

	two way binding

* `ng-submit`

	action to do when submitting a form

	`myForm.$valid && myCtrl.submit()`	-> only submit when the form is valid, `$valid` is an AngularJS builtin

* `ng-options`

	populate options for a select field

* `novalidate`

	turn off default form validation of the browser

* `required`

	mark a field as required


AngularJS do input validation automatically for each input type: `email`, `number`, ...


## `factory` vs. `service`

[SERVICE VS FACTORY - ONCE AND FOR ALL](https://blog.thoughtram.io/angular/2015/07/07/service-vs-factory-once-and-for-all.html)

the following two snippets do basically the same thing

`.factory` accepts a function that returns an object

    app.factory('MyService', function () {
      return {
        sayHello: function () {
          console.log('hello');
        }
      }
    });


`.service` usually accepts a constructor function

    app.service('MyService', function () {
      this.sayHello = function () {
        console.log('hello');
      };
    });


but `.service` can accepts a function that returns an object as well

    app.service('MyService', function () {
      // we could do additional work here too
      return {
        sayHello: function () {
          console.log('hello');
        };
      }
    });

and `.service` allows us to use ES6 classes, it's not possible with `.factory`

    class MyService {
      sayHello() {
        console.log('hello');
      }
    }

    app.service('MyService', MyService);


**so always use `.service` over `.factory`**


