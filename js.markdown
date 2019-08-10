# Javascript

General topics about Javascript and front-end develpoment.

- [Data types in JS](#data-types-in-js)
  - [Type casting and coercion](#type-casting-and-coercion)
  - [Truesy and falsey](#truesy-and-falsey)
- [Objects](#objects)
- [Prototype](#prototype)
  - [Inheritance by Prototype](#inheritance-by-prototype)
- [Javascript: The Good Parts](#javascript-the-good-parts)
- [Functions](#functions)
  - [the `arguments` parameter](#the-arguments-parameter)
- [The `this` keyword](#the-this-keyword)
- [Closures](#closures)
  - [Temporal Dead Zone](#temporal-dead-zone)
- [Regular Expression](#regular-expression)
  - [named groups](#named-groups)
- [Style guide](#style-guide)
- [Symbol](#symbol)
- [Iterations](#iterations)
- [Promise](#promise)
  - [Callback hell](#callback-hell)
  - [resolved vs. rejected](#resolved-vs-rejected)
- [Generator](#generator)
- [Async/Await](#asyncawait)
- [Immutability](#immutability)
  - [What is immutability ?](#what-is-immutability)
  - [Reference equality vs. value equality](#reference-equality-vs-value-equality)
  - [Immutability tools](#immutability-tools)
    - [The JS way](#the-js-way)
    - [Immutable.js](#immutablejs)
    - [Immer](#immer)
    - [immutability-helper](#immutability-helper)
- [ECMAScript](#ecmascript)
- [Module Systems](#module-systems)
  - [AMD (Asynchronous Module Design)](#amd-asynchronous-module-design)
  - [CommonJS (CJS)](#commonjs-cjs)
  - [ES6](#es6)
- [Error Handling](#error-handling)
  - [`try...catch...finally`](#trycatchfinally)
  - [Promise](#promise-1)
  - [async/await](#asyncawait)
- [Tricks](#tricks)
  - [Deboucing an event](#deboucing-an-event)
  - [Initialize an array with a value range](#initialize-an-array-with-a-value-range)
  - [Bind a function multiple times](#bind-a-function-multiple-times)
- [Reference](#reference)

## Data types in JS

- undefined
- null
- boolean
- number
- string
- object
- symbol -> introduced in ES6

string and number got accompanying wrapper object (`String` and `Number`)

please note:

- **`String('abc')` is the same as `'abc'`, they are both of primitive string value**
- **`String('abc')` is different from `new String('abc')`, the later is an object**

example

```javascript
typeof 'abc'; // 'string'
typeof String('abc'); // 'string'
'abc' === String('abc'); // true

s = new String('abc'); // [String: 'abc']
typeof s; // 'object'
s === 'abc'; // false
```

### Type casting and coercion

```javascript
+"42" -> 42;
Number("42") -> 42;

// always use a radix here
parseInt("42", 10) -> 42;
```

### Truesy and falsey

- falsey values:

      	`false`, `null`, `undefined`, `''`, `0`, `NaN`

- trusey values:

      	`'0'`, `'false'`, `[]`, `{}`, ...

## Objects

- define object using object literal

```javascript
var circle = {
    radius: 2;
};
```

- define object using Object constructor:

```javascript
var circle = new Object();
circle.radius = 2;
```

- define objects using custom constructor:

```javascript
var Circle = function(radius) {
  this.radius = radius;
  this.area = function() {
    return Math.PI * this.radius * this.radius;
  };
};

var circle = new Circle(2);
```

**constructor function return `this` if no explicit `return`**

## Prototype

```javascript
function Dog(breed) {
  this.breed = breed;
}

var buddy = new Dog('golden Retriever');

// add a method to prototype of Dog
Dog.prototype.bark = function() {
  console.log('Woof');
};
```

### Inheritance by Prototype

[Douglas Crockford's video course: Prototypal Inheritance](http://app.pluralsight.com/training/player?author=douglas-crockford&name=javascript-good-parts-m0&mode=live&clip=0&course=javascript-good-parts)

```javascript
function Gizmo(id) {
  this.id = id;
}

Gizmo.prototype.toString = function() {
  return 'gizmo ' + this.id;
};
var g = new Gizmo(1);
```

![Object](./images/js_obj.png)

- `Gizmo` is a Function Object, which has a `prototype` property points to another Object;
- `Gizmo.prototype` has a `constructor` property points to `Gizmo`, a `__proto__` property points to `Object.prototype`;
- `g` does **not** have a `prototype` property, but has a `__proto__` property, which points to `Gizmo.prototype`

```javascript
g.__proto__ === Gizmo.prototype; // true
Gizmo.prototype.__proto__ === Object.prototype; // true
```

- then add a Hoozit constructor:

```javascript
function Hoozit(id) {
  this.id = id;
}
Hoozit.prototype = new Gizmo();
Hoozit.prototype.test = function(id) {
  return this.id === id;
};
var h = new Hoozit(2);
```

- **only functions have `prototype` property;**
- **every object has an `__proto__` property;**
- `(new Foo).__proto__ === Foo.prototype`, so the `prototype` of a function is used to build the `__proto__` chain;
- **everytime a function is defined, it got a prototype object, `Foo` is an object, `Foo.prototype` is another object;**

- when using `new Foo()` to create an object, the function `Foo()` will always be run, although `Foo.prototype.constructor` can point to another function

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

- **`var`**

```js
var a = 0; //local to function scope
b = 0; //global scope
```

the following statement:

```js
var a = (b = 0);
```

equals to:

```js
b = 0; // b becomes global !!!
var a = b;
```

- **variable scope**

javascript is **function scoped**, not block scoped, so:

```js
// declaration of variable i will be hoisted to the beggining of the function
// so, it is available at any place inside foo, not just the for loop
function foo() {
    ...
    for(var i=0; ...) {}
    ...
}
```

you should **put variable declaration in the begining of a function**:

```js
function foo() {
    var i = 0;
    ...
    for(i=0; ...) {}
    ...
}
```

- **`let` statement**

`let` statement respect block scoping, so the following code does what it seems to do:

```js
foo(let i=0; ...} {}
```

- **numbers**

  - javascript only has one number type, which is 64bit double;
  - `NaN` is a number;
  - `NaN` is not equal to anything, including `NaN` itself;
  - any arithmetic operation with `NaN` will result in `NaN`;

  ```js
  0.1 + 0.2 !== 0.3; // this can cause problems when dealing with money
  a + b + c === a + (b + c); // can be false, this is not a js specific problem

  Infinity + 1 === Infinity; // true
  Number.MAX_VALUE + 1 === Number.MAX_VALUE; // true
  ```

- **`null` isn't anything**

  ```js
  typeof null === 'object'; // null's type is 'object'
  ```

- **`undefined`: default value for uninitialized variables and parameters**

      	always use `typeof x === 'undefined'` to check if a variable exists or not,

  Comparison with `null`:

  - `undefined` is a super global variable, you can override it: `let undefined = 'foo'`, while `null` is a keyword;
  - `undeined` is of type `undefined`, `null` is of type `object`;

* **`typeof`**

  ```js
  var a = [1, 2];
  typeof a === 'object'; // typeof array returns 'object'
  Array.isArray(a); // true, use this to check arrays
  ```

* **`+`**

        if both operands are numbers
        then
            add them
        else
            convert to string and concatenate
        end

  ```js
  2 + '3' -> '23'
  ```

* **`%`**

  `%` is a remainder operator, takes sign from the first operator, not a modulo operator, which takes sign from the second operator

```js
-1 % 8 -> -1;
```

- **`&&`** , **`||`**

  **not necessarily return boolean values**, just return values of one operand

- **`!!`**

  convert truesy value to `true`, falsy value to `false`

## Functions

```javascript
// function expression
var foo = function() {};

// function statement
function foo() {}

// function statement is a short-hand for var statement, which will expand to:
var foo = undefined;
foo = function() {};
```

the difference between these two methods of defining functions:

```javascript
console.log(typeof statementFoo); // function
statementFoo(); // NOTE this function runs fine here

console.log(typeof expressionFoo); // undefined
expressionFoo(); // NOTE throws an error, expressionFoo is still undefined here

function statementFoo() {
  console.log('an statement function');
}

var expressionFoo = function() {
  console.log('an expression function');
};
```

**don't put function statement in a block, such as `if` block, since the function name will also be hoisted**

### the `arguments` parameter

- each function receives two pseudo parameters: `arguments` and `this`;

- `arguments` is an **array-like object** which has an `length` property and contains all the parameters;

- it is recommended to use rest syntax instead of `arguments`;

```javascript
// use arguments to create a function with variable length parameters
function sum() {
  var i,
    n = arguments.length,
    total = 0;
  for (i = 0; i < n; i++) {
    total += arguments[i];
  }
  return total;
}

console.log(sum(1, 2, 3, 4));

// with rest syntax
function sum(...args) {
  return args.reduce((total, e) => total + e, 0);
}

console.log(sum(1, 2, 3, 4));
```

## The `this` keyword

every function receives an implicit `this` parameter, which is bound at invocation time

four ways to call a function:

- Function form

  - `this` binds to the global object, which cause problems
  - in ES5/Strict, `this` binds to `undefined`
  - outer `this` is not accessible from inner functions, use `var that = this;` to pass it

```javascript
functionObject(arguments);
```

- Method form

`this` binds to `thisObject`

```javascript
thisObject.methodName(arguments);
thisObject['methodName'](arguments);
```

- Constructor form

a new object is created and assigned to `this`, if not an explicit return value, then `this` will be returned

```javascript
new FunctionObject(arguments);
```

- Apply form

explicitly bind an object to 'this'

```javascript
functionObject.apply(thisObject, arguements);
functionObject.call(thisObject, arg1, arg2, ...);
```

- `this` scope example

```javascript
var person = {
  name: 'Gary',
  hobbies: ['tennis', 'badminton', 'hiking'],

  // 'this' scope error, will be undefined
  print: function() {
    console.log("// Wrong, 'this' will be undefined.");
    this.hobbies.forEach(function(hobby) {
      console.log(this.name + ' likes ' + hobby);
    });
  },

  // use '_this' to pass the correct context this in
  print2: function() {
    var _this = this;
    console.log("// use '_this' to pass the correct context this in");
    this.hobbies.forEach(function(hobby) {
      console.log(_this.name + ' likes ' + hobby);
    });
  },

  // use 'bind' to get the correct this
  print3: function() {
    console.log("// use 'bind' to get the correct this");
    this.hobbies.forEach(
      function(hobby) {
        console.log(this.name + ' likes ' + hobby);
      }.bind(this)
    );
  },

  // use arrow function syntax, this is the recommended way
  print4: function() {
    console.log('// use arrow function syntax');
    this.hobbies.forEach(hobby => {
      console.log(this.name + ' likes ' + hobby);
    });
  }
};
```

## Closures

When a function gets declared, it contains a function definition and _a closure_. The closure is a collection of all the variables in scope at the time of creation of the function.

Think of a closure as a backpack, it is attached to the function, when a function get passed around, the backpack get passed around with it.

```javascript
var digit_name = (function() {
  var names = [
    'zero',
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine'
  ];
  return function(n) {
    return names[n];
  };
})();

console.log(digit_name(2));
```

[A Tricky JavaScript Interview Question Asked by Google and Amazon](https://medium.com/coderbyte/a-tricky-javascript-interview-question-asked-by-google-and-amazon-48d212890703)

```javascript
// interviewer: what will the following code output?
const arr = [10, 12, 15, 21];
for (var i = 0; i < arr.length; i++) {
  setTimeout(function() {
    console.log('Index: ' + i + ', element: ' + arr[i]);
  }, 300);
}
```

output:

    Index: 4, element: undefined
    Index: 4, element: undefined
    Index: 4, element: undefined
    Index: 4, element: undefined

when the anonymous function executes, the value of `i` is `4`

you can fix this by add a separate closure for each loop iteration, in this case, the `i` is separate for each closure

```js
const arr = [10, 12, 15, 21];
for (var i = 0; i < arr.length; i++) {
  setTimeout(
    (function(i) {
      return function() {
        console.log('The index of this number is: ' + i);
      };
    })(i),
    300
  );
}
```

or use `let`, it creates a new block binding for each iteration (**this is because `let` is block scoped, a new 'backpack' is created for each iteration, in contrast, `var` is function scoped, so the `i` is shared in the first example**)

```javascript
const arr = [10, 12, 15, 21];
for (let i = 0; i < arr.length; i++) {
  // using the ES6 let syntax, it creates a new binding
  // every single time the function is called
  // read more here: http://exploringjs.com/es6/ch_variables.html#sec_let-const-loop-heads
  setTimeout(function() {
    console.log('The index of this number is: ' + i);
  }, 300);
}
```

### Temporal Dead Zone

See [let - MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/let) for details

- `var` declarations will be hoisted to the top of **function scope**, and the value is `undefined`;
- `let` bindings are created at the top of the **block scope**, but unlike `var`, you can't read or write it, you get a `ReferenceError` if using it before the definition is evaluated;

```js
function do_something() {
  console.log(bar); // undefined
  console.log(foo); // ReferenceError, in 'Temporal Dead Zone'
  var bar = 1;
  let foo = 2;
}
```

the `foo` in `(foo + 55)` is the `foo` in the `if` block, not the `foo` declared by `var`

```js
function test() {
  var foo = 33;
  if (true) {
    let foo = foo + 55; // ReferenceError
  }
}
test();
```

## Regular Expression

### named groups

_ES 2018_

```js
const date = '2018-05-16';
const re = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/u;
const result = re.exec(date);
console.log(result);
//[ '2018-05-16',
//  '2018',
//  '05',
//  '16',
//  index: 0,
//  input: '2018-05-16',
//  groups: { year: '2018', month: '05', day: '16' } ]

console.log(result.groups.year); // get the value of a matched group
//2018
```

back reference named groups in a regular expression

```js
const re = /(?<fruit>apple|orange) == \k<fruit>/u;

console.log(
  re.test('apple == apple'), // true
  re.test('orange == orange'), // true
  re.test('apple == orange') // false
);
```

use named groups in string repalcing

```js
const re = /(?<firstName>[a-zA-Z]+) (?<lastName>[a-zA-Z]+)/u;

console.log('Arya Stark'.replace(re, '$<lastName>, $<firstName>')); // Stark, Arya
```

## Style guide

please refer to the specific note on JS Coding Styles

## Symbol

ref: [ES6 Symbols in Depth](https://ponyfoo.com/articles/es6-symbols-in-depth#the-runtime-wide-symbol-registry)

Symbol is a new primitive value type in ES6

There are three different flavors of symbols - each flavor is accessed in a different way:

1.  **local symbols**

    you can obtain a reference to them directly;

    create a local symbol:

    ```js
    let s = Symbol('a desc');
    ```

    **you can NOT use `new Symbol()` to create a symbol value**

    local symbols are **immutable** and **unique**

    ```js
    Symbol() === Symbol(); // false
    ```

    you can add a description when creating symbols, it's just for debugging purpose

    ```js
    s = Symbol('gary symbol'); // Symbol(gary symbol)
    ```

2.  **global registry symbols**

    you can place symbols to the global registry and access them across realms;

    create a global symbol by `Symbol.for(key)`:

        	let s = Symbol.for('Gary');

    it's **idempotent**, which means for any given key, you will always get the exactly same symbol:

        	Symbol.for('Gary') === Symbol.for('Gary');

    get the key of a symbol:

        	let key = Symbol.keyFor(s);

3) **"Well-known" symbols**

   they exist across realms, but you can't create them and they're not on the global registry;

   **these actually are NOT well-known at all**, they are JS built-ins, and they are used to control parts of the language, they weren't exposed to user code before ES6.

   refer to this [MDN - Symbol](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Symbol) page to see a full list:

   - `Symbol.hasInstance`
   - `Symbol.isConcatSpreadable`
   - `Symbol.iterator`
   - `Symbol.match`
   - `Symbol.prototype`
   - `Symbol.replace`
   - `Symbol.search`
   - `Symbol.species`
   - `Symbol.split`
   - `Symbol.toPrimitive`
   - `Symbol.toStringTag`
   - `Symbol.unscopables`

   one of the most useful symbols is `Symbol.iterator`, which can be used to define the `@@iterator` method on an object, convert it to be `iterable`, it's just like implementing the `Iterable` interface in other languages


    ```js
    var foo = {
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

    for (let p of foo) {
        console.log(p)
    }
    // p
    // o
    // n
    // y
    // f
    // o
    // o
    ```

    see [this article][symbol-iterator-etc] for defining a custom search function on any object

Main usages for symbols:

1.  **as property keys**

    as each symbol is unique, it can be used to avoid name clashes

2.  **Privacy ?**

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

## Iterations

- `for..of` loop

```javascript
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
```

- iterate an object's properties

```javascript
let o = {
  5e5: '$500K',
  1e6: '$1M',
  2e6: '$2M',
  3e6: '$3M',
  5e6: '$5M',
  10e6: '$10M'
};

for (let [n, v] of Object.entries(o)) {
  console.log(n, v);
}

// 500000 $500K
// 1000000 $1M
// 2000000 $2M
// 3000000 $3M
// 5000000 $5M
// 10000000 $10M
```

- custom iterator

  you can add a custom iterator to an object:

  - using the `Symbol.iterator` property, which should be a function, this function executes once when the iteration starts, and returns an object containing a `next` method;

  - this `next` method should instead return an object that contains two properties: `done` and `value`, the `done` property is checked to see if the iteration finished;

example

```javascript
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
          value: currentId++
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
```

## Promise

JS uses callbacks a lot, if not handled properly, it will lead to [Callback Hell][callback-hell], Promise was introduced in ES6, it's a way to simplify asynchronous programming by making code _look_ synchronous and avoid callback hell.

[A Simple Guide to ES6 Promises](https://codeburst.io/a-simple-guide-to-es6-promises-d71bacd2e13a)

### Callback hell

[this page][callback-hell] explains what is callback hell and how to avoid it, by **giving callback functions a name, moving them to the top level of a file or a separate file**

```js
var form = document.querySelector('form');

form.onsubmit = function(submitEvent) {
  var name = document.querySelector('input').value;
  request(
    {
      uri: 'http://example.com/upload',
      body: name,
      method: 'POST'
    },
    function(err, response, body) {
      var statusMessage = document.querySelector('.status');
      if (err) return (statusMessage.value = err);
      statusMessage.value = body;
    }
  );
};
```

refactor the above code by moving the callback functions to a separate module

```js
module.exports.submit = formSubmit;

function formSubmit(submitEvent) {
  var name = document.querySelector('input').value;
  request(
    {
      uri: 'http://example.com/upload',
      body: name,
      method: 'POST'
    },
    postResponse
  );
}

function postResponse(err, response, body) {
  var statusMessage = document.querySelector('.status');
  if (err) return (statusMessage.value = err);
  statusMessage.value = body;
}
```

then import it in the main file

```js
var formUploader = require('formuploader');
document.querySelector('form').onsubmit = formUploader.submit;
```

### resolved vs. rejected

please see here for detailed examples about when a promise is resolved or rejected: https://github.com/garylirocks/js-es6/tree/master/promises

take note:

- it is recommended to only pass the resolved callback to `.then()`, use `.catch()` to handle errors;
- always use a `.catch()`;

## Generator

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

## Async/Await

[Ref - Hackernoon](https://hackernoon.com/6-reasons-why-javascripts-async-await-blows-promises-away-tutorial-c7ec10518dd9)

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
    // the compiler pauses here, when the promise resolves, the value is assigned to x,
    //  if the promise is rejected, an error is thrown
    var x = await resolveAfter2Seconds(10);
    console.log(x); // 10
  } catch (e) {
    console.log(e);
  }
}

f1();
```

See the Pen <a href='https://codepen.io/garylirocks/pen/yKRzeM/'>async/await</a>

- `await` can only be used in `async` functions
- `await` is followed by a Promise, if it resolves, it returns the resolved value, or it can throw an error

## Immutability

- [Immutability in React: There’s nothing wrong with mutating objects](https://blog.logrocket.com/immutability-in-react-ebe55253a1cc)
- [Immutability in JavaScript: A Contrarian View](http://desalasworks.com/article/immutability-in-javascript-a-contrarian-view/)

### What is immutability ?

the `string` primitive type is immutable in JS, whenever you do any manipulation on a string, a new string get created

but the `String` object type _is mutable_

```js
const s = new String('hello');
//undefined

s;
//[String: 'hello']

// add a new property to a String object
s.name = 'gary';
s;
// { [String: 'hello'] name: 'gary' }
```

### Reference equality vs. value equality

two references are equal when they refer to the same value if this value is immutable:

```js
var str1 = 'abc';
var str2 = 'abc';
str1 === str2; // true

var n1 = 1;
var n2 = 1;
n1 === n2; // also true
```

![js_equality_immutable](./images/js_equality_immutable.png)

but if the value is mutable, the two references are not equal:

```js
var str1 = new String('abc');
var str2 = new String('abc');
str1 === str2; // false

var arr1 = [];
var arr2 = [];
arr1 === arr2; // false
```

![js_equality_mutable](./images/js_equality_mutable.png)

You need to use your custom methods or something like `_.isEqual` from Lo-Dash to check value equality on objects.

### Immutability tools

- [Redux Ecosystem - Immutable Data](https://github.com/markerikson/redux-ecosystem-links/blob/master/immutable-data.md#immutable-update-utilities)

#### [The JS way](https://github.com/reduxjs/redux/blob/master/docs/recipes/reducers/ImmutableUpdatePatterns.md)

- Updating Nested Objects

  if you want to update deeply nested state, it's become quite verbose and hard to read:

  ```js
  function updateVeryNestedField(state, action) {
    return {
      ...state,
      first: {
        ...state.first,
        second: {
          ...state.first.second,
          [action.someId]: {
            ...state.first.second[action.someId],
            fourth: action.someValue
          }
        }
      }
    };
  }
  ```

  **it's recommended to keep your state flattened, and compose reducers as much as possible, so you only need to update flat objects or arrays**

- Appending/Prepending/Inserting/Removing/Replacing/Updating Items in arrays

  ```js
  // append item
  function appendItem(array, action) {
    return array.concat(action.item);
  }

  // prepend item
  function prependItem(array, action) {
    return action.item.concat(array);
  }

  // insert item
  function insertItem(array, action) {
    let newArray = array.slice();
    newArray.splice(action.index, 0, action.item);
    return newArray;
  }

  // remove item
  function removeItem(array, action) {
    let newArray = array.slice();
    newArray.splice(action.index, 1);
    return newArray;
  }

  // remove item (alternative way)
  function removeItem(array, action) {
    return array.filter((item, index) => index !== action.index);
  }

  // replace item
  function replaceItem(array, action) {
    let newArray = array.slice();
    newArray.splice(action.index, 1, action.item);
    return newArray;
  }

  // update item
  function removeItem(array, action) {
    return array.map((item, index) => {
      if (index !== action.index) {
        return item;
      }

      // update the one we want
      return {
        ...item,
        ...action.item
      };
    });
  }
  ```

#### [Immutable.js](https://facebook.github.io/immutable-js/)

- Fully-featured data structures library;
- Using [persistent data structures](http://en.wikipedia.org/wiki/Persistent_data_structure);
- Using structural sharing via [hash maps tries](http://en.wikipedia.org/wiki/Hash_array_mapped_trie) and [vector tries](http://hypirion.com/musings/understanding-persistent-vector-pt-1);
- Provides data structures including: `List`, `Stack`, `Map`, `OrderedMap`, `Set`, `OrderedSet` and `Record`;

#### [Immer](https://github.com/mweststrate/immer)

- A tiny package, based on the [`copy-on-write`](https://en.wikipedia.org/wiki/Copy-on-write) mechanism;
- Idea: all changes are applied to a temporary _draftState_ (a proxy of the _currentState_), once all mutations are done, `Immer` will produce the _nextState_;

  ![immer-idea](images/js-immer-how-it-works.png)

- Auto freezing

  - Immer automatically freezes any state trees that are modified using `produce`, this protects against any accidental modifications of the state tree outside of a producer;
  - It's a **deep freeze**, while `Object.freeze` only does a **shalow freeze**;
  - It impacts performance, by default it is turned on during local develpoment, off in production;
  - Use `setAutoFreeze(true/false)` to control it explicitly;

- Read the doc for:

  - Limitations;
  - TypeScript or Flow;
  - Patches;
  - `this`, `void`;
  - Performance;
  - More examples;

- API

  `produce(currentState, producer: (draftState) => void): nextState`

- basic usage:

  ```js
  import produce from 'immer';

  cosnt a = {name: 'Gary', age: 20};
  // { name: 'Gary', age: 20 }

  // update draft in whatever way you like, and no need to return anything
  const b = produce(a, draft => {
      draft.name = 'Federer';
  });
  // { name: 'Federer', age: 20 }

  console.log(`${a.name} vs. ${b.name}`);
  // Gary vs. Federer
  ```

- React `setState`

  ```js
  increaseAge = () => {
      this.setState(
          produce(draft => {
              draft.user.age += 1
          });
      );
  }
  ```

- Redux reducers

  ```js
  import produce from 'immer';

  const byId = produce(
    (draft, action) => {
      switch (action.type) {
        case RECEIVE_PRODUCTS:
          action.products.forEach(product => {
            draft[product.id] = product;
          });
          return;
      }
    },
    {
      1: { id: 1, name: 'product-1' }
    }
  );
  ```

#### [immutability-helper](https://github.com/kolodny/immutability-helper)

- Provides a simple immutability helper, `update()`;
- It's syntax is inspired by MongoDB's query language;
- Commands:

  - `{$push: array}` `push()` all the items in `array` on the target.
  - `{$unshift: array}` `unshift()` all the items in `array` on the target.
  - `{$splice: array of arrays}` for each item in `arrays` call `splice()` on the target with the parameters provided by the item. **Note**: _The items in the array are applied sequentially, so the order matters. The indices of the target may change during the operation._
  - `{$set: any}` replace the target entirely.
  - `{$toggle: array of strings}` toggles a list of boolean fields from the target object.
  - `{$unset: array of strings}` remove the list of keys in a`rray from the target object.
  - `{$merge: object}` merge the keys of object with the target.
  - `{$apply: function}` passes in the current value to the function and updates it with the new returned value.
  - `{$add: array of objects}` add a value to a `Map` or `Set`. When adding to a Set you pass in an array of objects to add, when adding to a Map, you pass in `[key, value]` arrays like so: `update(myMap, {$add: [['foo', 'bar'], ['baz', 'boo']]})`.
  - `{$remove: array of strings}` remove the list of keys in array from a `Map` or `Set`.

- You can define you own commands;
- Baisc examples:

  ```js
  // push
  const initialArray = [1, 2, 3];
  const newArray = update(initialArray, { $push: [4] }); // => [1, 2, 3, 4]

  // nested
  const collection = [1, 2, { a: [12, 17, 15] }];
  const newCollection = update(collection, {
    2: { a: { $splice: [[1, 1, 13, 14]] } }
  });
  // => [1, 2, {a: [12, 13, 14, 15]}]

  // merge
  const obj = { a: 5, b: 3 };
  const newObj = update(obj, { $merge: { b: 6, c: 7 } }); // => {a: 5, b: 6, c: 7}

  // update based on current value
  const obj = { a: 5, b: 3 };
  const newObj = update(obj, {
    b: {
      $apply: function(x) {
        return x * 2;
      }
    }
  });
  // => {a: 5, b: 6}
  ```

## ECMAScript

The language specification is managed by ECMA's TC39 committee now, the general process of making changes to the specification is here: [TC39 Process]

There are 5 stages, from 0 to 4, all finished proposals (reached stage 4) are here: https://github.com/tc39/proposals/blob/master/finished-proposals.md

## Module Systems

https://www.airpair.com/javascript/posts/the-mind-boggling-universe-of-javascript-modules

### AMD (Asynchronous Module Design)

asynchronous, unblocking

```js
// this is an AMD module
define(function() {
  return something;
});
```

### CommonJS (CJS)

synchronous, blocking, easier to understand

```js
// and this is CommonJS
module.exports = something;
```

### ES6

```js
// mod-a.js
const person = {
  name: 'gary',
  age: 30
};

export const a = 20; // one syntax
const b = 30;

export default person;
export { b }; // another way
```

`app.js`:

```js
// main.js
import theDefault from './mod-a';
import * as all from './mod-a';

console.log('theDefault:', theDefault);
console.log('all:', all);
```

```sh
theDefault: { name: 'gary', age: 30 }
all: [Module] { a: 20, b: 30, default: { name: 'gary', age: 30 } }
```

- For both default and named exports, you can put `export`, `export default` directly before the variable definition or do it at the end of file, in the above example, both `a`, `b` are exported;

- Or you can import everything on one line:

  ```js
  import theDefault, { a as myA, b } from './mod-a';
  ```

- If you just want to trigger the side effect, do not actually import any binding:

  ```js
  import './mod-a';
  ```

## Error Handling

### `try...catch...finally`

- [MDN - try...catch](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/try...catch)
- [MDN - onerror](https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onerror)

1. the catch block only catches synchronous errors, not async ones:

   ```js
   try {
     setTimeout(() => {
       console.log('in setTimeout');
       throw new Error('throw in setTimeout'); // this error is not caught
     });
     console.log('in try');
   } catch (e) {
     console.log('in catch');
   } finally {
     console.log('in finally');
   }
   ```

2. in a browser, when there is an unhandled error, it goes to `window.onerror`, it can be used for error logging;

3. `finally` block always executes, if it returns a value, it becomes the entire block's return value, regardless of any return statement or error thrown in `try` and `catch` blocks;

   ```js
   function foo() {
     try {
       throw new Error('xx');
       return 1;
     } catch (e) {
       console.log('in catch');
       throw e;
       return 2;
     } finally {
       console.log('in finally');
       return 3; // would throw an error if there is no 'return' here
     }

     return 100;
     console.log('after try...catch');
   }

   console.log(foo());
   ```

   outputs:

   ```
   in catch
   in finally
   3
   ```

### Promise

[javascript.info - Promise error handling](https://javascript.info/promise-error-handling)
[MDN - unhandledrejection](https://developer.mozilla.org/en-US/docs/Web/API/Window/unhandledrejection_event)

```js
new Promise((resolve, reject) => {
  reject('reject it');
  .finally(() => {
    console.log('in first finally');
  })
  .then(res => {
    console.log('in then: ', res);
  })
  .catch(e => {
    console.log('in catch: ', e);
    throw e;
  })
  .finally(() => {
    console.log('in last finally');
  });
```

outputs:

```
in first finally
in catch:  reject it
in last finally

Uncaught (in promise) reject it
```

1. a `finally` block always executes, it doesn't have access to the resolved result or the rejection error;
2. a `catch` block returns a resolved promise, unless it throws an error it self;
3. in a browser, any unhandledrejection goes to the `unhandledrejection` event handler on `window`, it can be used for error logging;

### async/await

[javascript.info - async/await](https://javascript.info/async-await)

```js
const loadSomething = () => {
  return fetchSomeData()
    .then(data => doSomethingWith(data))
    .catch(error => logAndReport(error));
};
```

is the same as:

```js
const loadSomething = async () => {
  try {
    const data = await fetchSomeData();
    return doSomethingWith(data);
  } catch (error) {
    logAndReport(error);
  }
};
```

1. the promise after `await` either resolves and return a value or throws an error;
2. you should use normal `try...catch..finally` block to handle errors;

## Tricks

### Deboucing an event

http://stackoverflow.com/questions/5489946/jquery-how-to-wait-for-the-end-of-resize-event-and-only-then-perform-an-ac

in the following code, the `updateLayout` function will only run after the `resize` event stopped 250ms

```javascript
// debounce the resize event
$(window).on('resize', function() {
  clearTimeout(window.resizedFinished);
  window.resizedFinished = setTimeout(function() {
    updateLayout();
  }, 250);
});
```

### Initialize an array with a value range

- https://itnext.io/heres-why-mapping-a-constructed-array-doesn-t-work-in-javascript-f1195138615a
- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/from

```js
let a = Array(100)
  .fill()
  .map((e, i) => i);
/*
Array(100) creates an empty array
{
    length: 100
},
you need to call fill() before map()
*/

// or
let a = Array.from({ length: 100 }, (e, i) => i);
```

### Bind a function multiple times

If you bind a function multiple times, for each parameter(inclding `this`) in the original function, only the first bound value is used, any later bound values will be disarded, put it in another way, **you can only bind a value to each parameter once**

```js
function foo(arg1) {
  console.log(this);
  console.log(arg1);
}

const fooBound = foo.bind({ name: 'gary' }); // this bound
const fooBound2 = fooBound.bind({ name: 'jack' }, 'hello'); // 'hello' bound to arg1
const fooBound3 = fooBound2.bind({}, 'hola'); // both {} and 'hola' are discarded

fooBound('bar');
// {name: "gary"}
// bar

fooBound2('bar');
// {name: "gary"}
// hello

fooBound3();
// {name: "gary"}
// hello

console.log('foo.name: ' + foo.name + ', foo.length: ' + foo.length);
// foo.name: foo, foo.length: 1

console.log(
  'fooBound.name: ' + fooBound.name + ', fooBound.length: ' + fooBound.length
);
// fooBound.name: bound foo, fooBound.length: 1

console.log(
  'fooBound2.name: ' +
    fooBound2.name +
    ', fooBound2.length: ' +
    fooBound2.length
);
// fooBound2.name: bound bound foo, fooBound2.length: 0

console.log(
  'fooBound3.name: ' +
    fooBound3.name +
    ', fooBound3.length: ' +
    fooBound3.length
);
// fooBound3.name: bound bound bound foo, fooBound3.length: 0
```

## Reference

[JavaScript Symbols, Iterators, Generators, Async/Await, and Async Iterators — All Explained Simply
][symbol-iterator-etc]: **Read this one to fully understand the relations between Symbols, Iterators, Generators, Async/Await and Aync Iterators**

[callback-hell]: http://callbackhell.com/
[symbol-iterator-etc]: https://medium.freecodecamp.org/some-of-javascripts-most-useful-features-can-be-tricky-let-me-explain-them-4003d7bbed32
[tc39 process]: https://tc39.github.io/process-document/
