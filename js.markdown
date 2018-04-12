Javascript
===============

General topics about Javascript and front-end develpoment.

## Data types in JS

* undefined
* null
* boolean
* number
* string
* object
* symbol	-> introduced in ES6

string and number got accompanying wrapper object (`String` and `Number`)

please note: 

* **`String('abc')` is the same as `'abc'`, they are both of primitive string value**
* **`String('abc')` is different from `new String('abc')`, the later is an object**

example

	> typeof 'abc'
	'string'
	> typeof String('abc')
	'string'
	> 'abc' === String('abc')
	true							// the same

	> s = new String('abc')
	[String: 'abc']
	> typeof s
	'object'
	> s === 'abc'
	false							// different


## Objects

* define object using object literal

        var circle = {
                radius: 2;
        };

* define object using Object constructor:

        var circle = new Object();
        circle.radius = 2;

* define objects using custom constructor:

        var Circle = function(radius) {
            this.radius = radius;
            this.area = function () {
                return Math.PI * this.radius * this.radius;
            };
        }

        var circle = new Circle(2);

    **constructor function return `this` if no explicit `return`**

## Prototype

    function Dog (breed) {
      this.breed = breed;
    };

    var buddy = new Dog("golden Retriever");

    // add a method to prototype of Dog
    Dog.prototype.bark = function() {
      console.log("Woof");
    };

## Inheritance by Prototype

[Douglas Crockford's video course: Prototypal Inheritance](http://app.pluralsight.com/training/player?author=douglas-crockford&name=javascript-good-parts-m0&mode=live&clip=0&course=javascript-good-parts)

    function Gizmo(id) {
        this.id = id;
    }

    Gizmo.prototype.toString = function() {
        return "gizmo " + this.id;
    }
    var g = new Gizmo(1);

![Object](./images/js_obj.png)

* `Gizmo` is a Function Object, which has a `prototype` property points to another Object;
* `Gizmo.prototype` has a `constructor` property points to `Gizmo`, a `__proto__` property points to `Object.prototype`;
* `g` does **not** have a `prototype` property, but has a `__proto__` property, which points to `Gizmo.prototype`

        g.__proto__ === Gizmo.prototype; // true
        Gizmo.prototype.__proto__ === Object.prototype; // true

* then add a Hoozit constructor:

        function Hoozit(id) {
            this.id = id;
        }
        Hoozit.prototype = new Gizmo();
        Hoozit.prototype.test = function (id) {
            return this.id === id;
        }
        var h = new Hoozit(2);



* **only functions have `prototype` property;**
* **every object has an `__proto__` property;**
* `(new Foo).__proto__ === Foo.prototype`, so the `prototype` of a function is used to build the `__proto__` chain;
* **everytime a function is defined, it got a prototype object, `Foo` is an object, `Foo.prototype` is another object;**

* when using `new Foo()` to create an object, the function `Foo()` will always be run, although `Foo.prototype.constructor` can point to another function

        > function Animal(name, age) {
        ... this.name = name;
        ... this.age = age;
        ... }
        undefined

        > Animal.prototype.constructor === Animal   // 'constructor' points to the function now
        true

        > Animal.prototype = {} // 'prototype' can be changed to point to another object
        {}

        > Animal.prototype.constructor
        [Function: Object]

        > a = new Animal('Snowball', 5) // although Animal.prototype does not point to Animal now, Animal is still used when creating an object
        { name: 'Snowball', age: 5 }

another illustration created by myself:

![JS prototype system](./images/JavaScript.object.prototype.system.png)

## Javascript: The Good Parts

* **`var`**

        var a = 0; //local to function scope
        b = 0;     //global scope

   the following statement:

        var a=b=0;

    equals to:

        b = 0;      // b becomes global !!!
        var a = b;

* **variable scope**

    javascript is **function scoped**, not block scoped, so:

        // declaration of variable i will be hoisted to the beggining of the function
        // so, it is available at any place inside foo, not just the for loop
        function foo() {
            ...
            for(var i=0; ...) {}    
            ...
        }

    you should **put variable declaration in the begining of a function**:

        function foo() {
            var i = 0;
            ...
            for(i=0; ...) {}
            ...
        }

* **`let` statement**

    `let` statement respect block scoping, so the following code does what it seems to do:

        foo(let i=0; ...} {}    

* **numbers**

        0.1 + 0.2 !== 0.3; // this can cause problems when dealing with money
        (a + b) + c === a + (b + c);  // can be false, this is not a js specific problem

        Infinity + 1 === Infinity; // true
        Number.MAX_VALUE + 1 === Number.MAX_VALUE;  // true

    * **javascript only has one number type, which is 64bit double**
    * **NaN is a number**
    * **NaN is not equal to anything, including NaN itself**
    * **any arithmetic operation with NaN will result in NaN**

* **`null` isn't anything**

        typeof null === 'object'; // actually, null is not an object

* **`undefined`: default value for uninitialized variables and parameters**

	always use `typof x === undefined` to check if a variable exists or not

* **`typeof`**

        var a = [1, 2];
        typeof a === 'object'; // typeof array returns 'object'
        Array.isArray(a);      // true, use this to check arrays

* **`+`**

        if both operands are numbers  
        then
            add them  
        else  
            convert to string and concatenate  
        end  

        2 + '3' -> '23'

* **`%`**

    `%` is a remainder operator, takes sign from the first operator, not a modulo operator, which takes sign from the second operator

        -1 % 8 -> -1;

* **`&&`** , **`||`**

    **not necessarily return boolean values**, just return values of one operand

* **`!!`**

    convert truesy value to `true`, falsy value to `false`

## convert strings to numbers

        +"42" -> 42;
        Number("42") -> 42;
        parseInt("42", 10) -> 42;

## truesy and falsey

* falsey values:

	`false`, `null`, `undefined`, `''`, `0`, `NaN`

* trusey values:

	`'0'`, `'false'`, `[]`, `{}`, ...

## functions

	// function expression
	var foo = funcion() {};

	// function statement
	function foo() {};

	// function statement is a short-hand for var statement, which will expand to:
	var foo = undefined;
	foo = function() {};


the difference between these two methods of defining functions:

	console.log(typeof statementFoo);   // function
	statementFoo();    // NOTE this function runs fine here

	console.log(typeof expressionFoo);  // undefined
	expressionFoo();   // NOTE throws an error, expressionFoo is still undefined here

	function statementFoo() {
		console.log("an statement function");
	}

	var expressionFoo = function() {
		console.log("an expression function");
	};


**don't put function statement in a block, such as `if` block, since the function name will also be hoisted**

* pseudo parameters

    **each function receives two pseudo parameters: `arguments` and `this`**

    `arguments` is an **array-like object** which has an `length` property and contains all the parameters

        // use arguments to create a function with variable length parameters
        function sum() {
          var i,
              n = arguments.length,
              total = 0;
          for (i=0; i<n; i++) {
            total += arguments[i];
          }
          return total;
        }

        console.log(sum(1, 2, 3, 4));

* function invocation and `this`

    **`this` is bound at invocation time**

    four ways to call a function:

    * Function form

        `this` binds to the global object, which cause problems  
        in ES5/Strict, `this` binds to `undefined`  
        outer `this` is not accessible from inner functions, use `var that = this;` to pass it

            functionObject(arguments);


    * Method form

        `this` binds to `thisObject`

            thisObject.methodName(arguments);
            thisObject['methodName'](arguments);

    * Constructor form

        a new object is created and assigned to `this`, if not an explicit return value, then `this` will be returned

            new FunctionObject(arguments);

    * Apply form

		explicitly bind an object to 'this'

            functionObject.apply(thisObject, arguements);
            functionObject.call(thisObject, arguement...);


* `this` scope example


		var person = {
			'name': 'Gary',
			'hobbies': ['tennis', 'badminton', 'hiking'],

			// 'this' scope error, will be undefined
			'print': function(){
				console.log("// Wrong, \'this\' will be undefined.");
				this.hobbies.forEach(function(hobby){
					console.log(this.name + ' likes ' + hobby);
				});
			},

			// use '_this' to pass the correct context this in
			'print2': function(){
				var _this = this;
				console.log("// use '_this' to pass the correct context this in");
				this.hobbies.forEach(function(hobby){
					console.log(_this.name + ' likes ' + hobby);
				});
			},

			// use 'bind' to get the correct this
			'print3': function(){
				console.log("// use 'bind' to get the correct this");
				this.hobbies.forEach(function(hobby){
					console.log(this.name + ' likes ' + hobby);
				}.bind(this));
			},

			// use arrow function syntax
			'print4': function(){
				console.log("// use arrow function syntax");
				this.hobbies.forEach(hobby => {
					console.log(this.name + ' likes ' + hobby);
				});
			}
		}



* closures

    The context of an inner function includes the scope of the outer function  
    An inner function enjoys that context even after the parent function have returned   


        var digit_name = (function(){
          var names = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];
          return function(n){
            return names[n];
          };
        }());

        console.log(digit_name(2));


## style guides

* **start constructor name with uppercase**

        function Person(name){
            this.name = name;
        }

* **put curly braces on the right**

        // result in a silent error, since a semicolon will be inserted after 'return'
        return
        {
            id: 20
        };

    so, always put curly braces on the right:

        // this is fine
        return {
            id: 20
        };


    **always add semicolons, do not trust auto insertion**

* **imdediate invoking function**

        (funtion() {
            ...
        }());

* **always use `===`, never `==`**


## Module Systems

https://www.airpair.com/javascript/posts/the-mind-boggling-universe-of-javascript-modules

### AMD (Asynchronous Module Design)

asynchronous, unblocking

	// this is an AMD module
	define(function () {
		return something
	})


### CommonJS (CJS)

synchronous, blocking, easier to understand

	// and this is CommonJS
	module.exports = something


### ES6

example, `lib.js`:

	let person = {
		'name': 'gary',
		'age': 30,
	};

	let position = {
		'x': 20,
		'y': 30,
	};

	export default person;
	export {position};


`app.js`:

	import theDefault from './lib';
	import {position as p, imaginedVar} from './lib';
	import * as all from './lib';


	console.log('theDefault:');
	console.log(theDefault);

	console.log('position:');
	console.log(p);

	console.log('imaginedVar:');
	console.log(imaginedVar);

	console.log('all:');
	console.log(all);


run `app.js`:

	theDefault:
	{ name: 'gary', age: 30 }
	position:
	{ x: 20, y: 30 }
	imaginedVar:
	undefined
	all:
	{ default: { name: 'gary', age: 30 },
	  position: { x: 20, y: 30 } }


or you can put everything on one line:

	import theDefault, {position as p, imaginedVar} from './lib';


if you just want to trigger the side effect, do not actually import any binding:

	import './myModule';



## Symbol

ref: [ES6 Symbols in Depth](https://ponyfoo.com/articles/es6-symbols-in-depth#the-runtime-wide-symbol-registry)

Symbol is a new primitive value type in ES6

There are three different flavors of symbols - each flavor is accessed in a different way:

1. **local symbols**

	you can obtain a reference to them directly;

	create a local symbol:

			let s = Symbol('a desc');

	**you can NOT use `new Symbol()` to create a symbol value**

	local symbols are **immutable** and **unique**

		> Symbol() === Symbol()
		false

	you can add a description when creating symbols, it's just for debugging purpose

		> s = Symbol('gary symbol')
		Symbol(gary symbol)


2. **global registry symbols**

	you can place symbols to the global registry and access them across realms;

	create a global symbol by `Symbol.for(key)`:

			let s = Symbol.for('Gary');

	it's **idempotent**, which means for any given key, you will always get the exactly same symbol:

			Symbol.for('Gary') === Symbol.for('Gary');

	get the key of a symbol:

			let key = Symbol.keyFor(s);
	

3. **"Well-known" symbols**

	they exist across realms, but you can't create them and they're not on the global registry;

	**these actually are NOT well-known at all**, they are JS built-ins, and they are used to control parts of the language, they weren't exposed to user code before ES6.

	refer to this [MDN - Symbol](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Symbol) page to see a full list:

	* `Symbol.hasInstance`
	* `Symbol.isConcatSpreadable`
	* `Symbol.iterator`
	* `Symbol.match`
	* `Symbol.prototype`
	* `Symbol.replace`
	* `Symbol.search`
	* `Symbol.species`
	* `Symbol.split`
	* `Symbol.toPrimitive`
	* `Symbol.toStringTag`
	* `Symbol.unscopables`

	one of the most useful symbols is `Symbol.iterator`, which can be used to define the `@@iterator` method on an object, convert it to be `iterable`, it's just like implementing the `Iterable` interface in other languages


		> var foo = {
			  [Symbol.iterator]: () => ({
				  items: ['p', 'o', 'n', 'y', 'f', 'o', 'o'],
				  next: function next () {
					  return {
						  done: this.items.length === 0,
						  value: this.items.shift()
						}
					}
				})
			}
		undefined

		> for (let p of foo) {
			console.log(p)
			}
		p
		o
		n
		y
		f
		o
		o


Main usages for symbols:

1. **as property keys**
		
	as each symbol is unique, it can be used to avoid name clashes

2. **Privacy ?**

	symbol keys can not be accessed by `Object.keys`, `Object.getOwnPropertyNames`, `JSON.stringify`, and `for .. in` loops

		> let obj = {
			[Symbol('name')]: 1,
			[Symbol('name')]: 2,
			[Symbol.for('age')]: 10,
			color: 'red'
			}

		> Object.keys(obj)
		[ 'color' ]

		> console.log(Object.getOwnPropertyNames(obj))
		[ 'color' ]

		> console.log(JSON.stringify(obj))
		{"color":"red"}

		> for (let key in obj) {
			console.log(key);
			}
		color


	but you can access them thru `Object.getOwnPropertySymbols`

		> console.log(Object.getOwnPropertySymbols(obj))
		[ Symbol(name), Symbol(name), Symbol(age) ]


3. **Defining Protocols**

	just like there's `Symbol.iterator` which allows you to define how an object can be iterated


## iterations

* `for..of` loop

		'use strict';

		let characters = ['Jon', 'Sansa', 'Arya', 'Tyrion', 'Cercei'];

		for (let c of characters) {
			console.log(c);
		}
		// Jon
		// Sansa
		// Arya
		// Tyrion
		// Cercei


		// NOTE compare with the for..in loop
		for (let c in characters) {
			console.log(c);
		}
		// 0
		// 1
		// 2
		// 3
		// 4


* iterate an object's properties

		let o = {5e5: '$500K', 1e6: '$1M', 2e6: '$2M', 3e6: '$3M', 5e6: '$5M', 10e6: '$10M'};

		for (let [n, v] of Object.entries(o)) {
			console.log(n, v);
		}

	output

		500000 $500K
		1000000 $1M
		2000000 $2M
		3000000 $3M
		5000000 $5M
		10000000 $10M


* custom iterator

	you can add a custom iterator to an object:

	* using the `Symbol.iterator` property, which should be a function, this function executes once when the iteration starts, and returns an object containing a `next` method;

	* this `next` method should instead return an object that contains two properties: `done` and `value`, the `done` property is checked to see if the iteration finished;

	example

		// NOTE you can define a custom iteration function for an object
		'use strict';

		// a custom id maker that generates ids from 100 to 105
		let idMaker = {
			[Symbol.iterator]() {
				let currentId = 100;
				let maxId = 105;
				return {
					next() {
						return {
							done: currentId > maxId,
							value: currentId++,
						};
					}
				};
			}
		};

		for (let id of idMaker) {
			console.log(id);
		}
		// 100
		// 101
		// 102
		// 103
		// 104
		// 105


		// NOTE another way to iterate through the id maker object
		let iter = idMaker[Symbol.iterator]();
		let next = iter.next();

		while (!next.done) {
			console.log(next.value);
			next = iter.next();
		}
		// 100
		// 101
		// 102
		// 103
		// 104
		// 105


## generator

	'use strict';

	// NOTE define an infinite generator
	let idMaker = function* () {
		let nextId = 100;

		while(true) {
			yield nextId++;
		}
	};

	// NOTE generator function returns an iterable
	for (let id of idMaker()) {
		if (id > 105) {
			break;
		}
		console.log(id);
	}

you can even yield into another iterable within a generator:

	// NOTE yield another iterable in a generator
	let myGenerator = function* () {
		yield 'start';
		yield* [1, 2, 3];       // <- yield into another iterable
		yield 'end';			// <- back to the main loop
	};

	for (let i of myGenerator()) {
		console.log(i);
	}
	// start
	// 1
	// 2
	// 3
	// end


## promises



## Async/Await

[ref](https://hackernoon.com/6-reasons-why-javascripts-async-await-blows-promises-away-tutorial-c7ec10518dd9)

```javascript
function resolveAfter2Seconds(x) { 
    return new Promise(resolve => {
        setTimeout(() => {
            resolve(x);
        }, 2000);
    });
}

async function f1() {
    try {
        var x = await resolveAfter2Seconds(10);
        console.log(x); // 10
    } catch (e) {
        console.log(e);
    }
}

f1();
```

* `await` can only be used in `async` functions
* `await` is followed by a Promise, if it resolves, it returns the resolved value, or it can throw an error


## tricks

### deboucing an event

http://stackoverflow.com/questions/5489946/jquery-how-to-wait-for-the-end-of-resize-event-and-only-then-perform-an-ac

in the following code, the `updateLayout` function will only run after the `resize` event stopped 250ms

		// debounce the resize event
		$(window).on('resize', function() {
			clearTimeout(window.resizedFinished);
			window.resizedFinished = setTimeout(function(){
				updateLayout();
			}, 250);
		});
