# Javascript

- [Data types](#data-types)
  - [Truesy and falsey](#truesy-and-falsey)
  - [Type casting and coercion](#type-casting-and-coercion)
  - [Wrapper objects](#wrapper-objects)
  - [Operators](#operators)
- [Numbers](#numbers)
  - [toString(base) and parseInt(str, base)](#tostringbase-and-parseintstr-base)
- [Strings](#strings)
  - [Comparison](#comparison)
  - [Surrogate pairs](#surrogate-pairs)
  - [Diacritical marks and normalization](#diacritical-marks-and-normalization)
- [Objects](#objects)
  - [Define an object](#define-an-object)
  - [Property order](#property-order)
  - [Transforming objects](#transforming-objects)
- [Prototype](#prototype)
  - [Inheritance by Prototype](#inheritance-by-prototype)
- [Symbol](#symbol)
  - [Main usages](#main-usages)
  - [Symbol.iterator](#symboliterator)
  - [Symbol.toPrimitive](#symboltoprimitive)
- [Arrays](#arrays)
  - [Methods](#methods)
  - [length](#length)
  - [Array-like](#array-like)
  - [Create a number range array](#create-a-number-range-array)
- [Map and Set](#map-and-set)
  - [Map](#map)
  - [Set](#set)
- [WeakMap and WeakSet](#weakmap-and-weakset)
  - [Garbage collection](#garbage-collection)
  - [WeakMap](#weakmap)
  - [WeakMap usage: caching](#weakmap-usage-caching)
  - [WeakSet](#weakset)
- [Functions](#functions)
  - [Function expression vs. function statement](#function-expression-vs-function-statement)
  - [the arguments parameter](#the-arguments-parameter)
- [The this keyword](#the-this-keyword)
- [Closures](#closures)
  - [Temporal Dead Zone](#temporal-dead-zone)
- [Regular Expression](#regular-expression)
  - [named groups](#named-groups)
- [Iterations](#iterations)
- [Promise](#promise)
  - [Callback hell](#callback-hell)
  - [resolved vs. rejected](#resolved-vs-rejected)
- [Generator](#generator)
- [Async/Await](#asyncawait)
- [Event Loop](#event-loop)
  - [setTimout](#settimout)
  - [Multiple runtimes](#multiple-runtimes)
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
  - [Error](#error)
  - [try...catch...finally](#trycatchfinally)
  - [Promise](#promise-1)
  - [async/await](#asyncawait)
- [Javascript: The Good Parts](#javascript-the-good-parts)
- [Tricks](#tricks)
  - [Deboucing an event](#deboucing-an-event)
  - [Bind a function multiple times](#bind-a-function-multiple-times)
  - [Object.is()](#objectis)
  - [JSON.stringify and JSON.parse](#jsonstringify-and-jsonparse)
- [Reference](#reference)

## Data types

- undefined
  - if a variable is declared but not assigned, then its value is `undefined`;
  - if you want to assign an empty value to a variable, it's better using `null`;
- null
  - a special value representing nothing;
  - `typeof null` is `object`, this is an error in the language;
- boolean
- number
  - special numeric values: `Infinity`, `-Infinity`, `NaN`;
  - math operations are **safe**, you can do anthing: divide by zero, treat non-numeric strings as numbers, you may get `NaN`, but the script will not crash;
- bigint
  - can represent numbers out of the -2<sup>53</sup> and 2<sup>53</sup> range;
  - define it by adding an `n` to the end of an integer literal: `const a = 1234567890123456789012345678901234567890n;`
- string
- object
- symbol
  - introduced in ES6

### Truesy and falsey

- falsey values:

  `false`, `null`, `undefined`, `''`, `0`, `NaN`

- trusey values:

  `'0'`, `'false'`, `[]`, `{}`, ...

### Type casting and coercion

```javascript
+"42" -> 42;
Number("42") -> 42;

// always use a radix here
parseInt("42", 10) -> 42;
```

### Wrapper objects

see https://javascript.info/primitives-methods

JS allows you to use some primitives as objects, such as in `'abc'.toUpperCase()`, JS creates wrapper objects internally to accomplish this;

- Object wrappers: `String`, `Number`, `Boolean` and `Symbol`;
- They can be used to convert a value to the corresponding type: `Number('2.5')`;
- But **don't** use them as constructors;

Example:

```javascript
typeof "abc"; // 'string'
typeof String("abc"); // 'string'
"abc" === String("abc"); // true

s = new String("abc"); // [String: 'abc']
typeof s; // 'object'
s === "abc"; // false
```

### Operators

- `-` can be:
  - unary, negate a number;
  - binary, subtract one number from another;
- `+` can be:
  - unary, convert a value to number, same as `Number()`;
  - binary, sums two number;
  - binary, concatenate two strings;
- `=` is an operator as well, it assigns a value to a variable and returns the value;
- `,` is an operator dividing several expressions, the value of the last one is returned;

## Numbers

- JS uses double precision floating point numbers;
- It's 64-bit, 52 bits for digits, 11 for the position of the decimal point, and 1 for the sign, can represent numbers between -2<sup>53</sup> and 2<sup>53</sup>;

### `toString(base)` and `parseInt(str, base)`

```js
const n = 4;

n.toString(2);
// 100

// opposite operation
parseInt("100", 2);
// 4
```

## Strings

### Comparison

use `str.localeCompare` to compare strings properly:

```js
"Zealand" > "Österreich";
// false

"Zealand".localeCompare("Österreich");
// 1
```

### Surrogate pairs

JS uses UTF-16 as internal format for strings, most frequently used characters have 2-byte codes, that covers 65536 symbols, some rare symbols are encoded with a pair of 2-byte characters called a _surrogate pair_;

The first character of a surrogate pair has code in range `0xd800..0xdbff`, the second one must be in range `0xdc00..0xdfff`, these intervals are reserved for surrogate pairs, so they should always come in pairs, an individual one means nothing;

Surrogate pairs didn't exist when JS was created, so they are not processed correctly sometimes:

```js
"a".length;
// 1

const s = "𩷶";

// one symbol, but the length is 2
s.length;
// 2

// `slice` doesn't work properly
s.slice(0, 1);
// '�'

// #### `charCodeAt/fromCharCode` are not surrogate-pair aware, you can get each code in the pair
s.charCodeAt(0).toString(16);
// 'd867'
s.charCodeAt(1).toString(16);
// 'ddf6
```

The following functions work on surrogate pairs correctly:

```js
// #### the newer functions `codePointAt/fromCodePoint` are surrogate-pair aware
s.codePointAt(0).toString(16);
// '29df6'

s.split(); // [ '𩷶' ]

Array.from(s); // [ '𩷶' ]

for (let char of s) {
  console.log(char);
}
// 𩷶

// #### get the correct length of a string
Array.from(s).length; // 1
```

### Diacritical marks and normalization

In Unicode, there are characters that decorate other characters, such as diacritical marks. For example, `\u0307` adds a 'dot above' the preceding character, `\u0323` means 'dot below'.

```js
"S\u0307";
// 'Ṡ'

"S\u0307\u0323";
// 'Ṩ'
```

This causes a problem: a symbol with multiple decorations can be represented in different ways.

```js
const s1 = "S\u0307\u0323";
const s2 = "S\u0323\u0307";

// s1 and s2 looks the same 'Ṩ', but they are not equal
s1 === s2; // false
```

There is a "unicode normalization" algorithm that brings each string to a single "normal" form.

```js
// #### 'Ṩ' has its own code \u1e68 in Unicode
const normalizedS = "S\u0307\u0323".normalize();

normalizedS.length; // 1
normalizedS.codePointAt(0).toString(16); // '1e68'

// #### 'Q̣̇' don't have its own code, normalization will put \u0323 before \u0307
const normalizedQ = "Q\u0307\u0323";

normalizedQ.length; // 3
normalizedQ.codePointAt(0).toString(16); // '51'
normalizedQ.codePointAt(1).toString(16); // '323'
normalizedQ.codePointAt(2).toString(16); // '307'
```

## Objects

### Define an object

- object literal

  ```javascript
  var circle = {
      radius: 2;
  };
  ```

- the `Object` constructor:

  ```javascript
  var circle = new Object();
  circle.radius = 2;
  ```

- custom constructor:

  ```javascript
  var Circle = function(radius) {
    this.radius = radius;
    this.area = function() {
      return Math.PI * this.radius * this.radius;
    };
  };

  var circle = new Circle(2);
  ```

  - It's a good practice to capitalize the first letter of constructor name and always call it with `new`;
  - **constructor function return `this` if no explicit `return`**

### Property order

```js
a = { 64: "NZ", 1: "US", name: "gary", age: 20 };

Object.keys(a);
// ["1", "64", "name", "age"]
```

Integer properties are ordered, others appear in creation order, so `1` comes before `64` when iterating through all the properties;

_A property key can only be a string or a symbol_, when you use a number as property key, it's converted to a string;

### Transforming objects

Use `Object.entries` and `Object.fromEntries` to convert an object to and from an array:

```js
const ages = { gary: 20, jack: 30 };

const newAges = Object.fromEntries(
  Object.entries(ages).map(([key, value]) => [key, value + 1])
);
// { gary: 21, jack: 31 }
```

## Prototype

```javascript
function Dog(breed) {
  this.breed = breed;
}

var buddy = new Dog("golden Retriever");

// add a method to prototype of Dog
Dog.prototype.bark = function() {
  console.log("Woof");
};
```

### Inheritance by Prototype

[Douglas Crockford's video course: Prototypal Inheritance](http://app.pluralsight.com/training/player?author=douglas-crockford&name=javascript-good-parts-m0&mode=live&clip=0&course=javascript-good-parts)

```javascript
function Gizmo(id) {
  this.id = id;
}

Gizmo.prototype.toString = function() {
  return "gizmo " + this.id;
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

## Symbol

ref: [ES6 Symbols in Depth](https://ponyfoo.com/articles/es6-symbols-in-depth#the-runtime-wide-symbol-registry)

Symbol is a new primitive value type in ES6, there are three different flavors of symbols - each flavor is accessed in a different way:

1.  Local symbols

    Create a local symbol:

    ```js
    let s = Symbol("gary symbol");

    console.log(s.description);
    // 'gary symbol'
    ```

    - 'gary symbol' is a description of the symbol, it's just for debugging purpose;
    - **you can NOT use `new Symbol()` to create a symbol value**
    - local symbols are **immutable** and **unique**

      ```js
      Symbol() === Symbol(); // false
      ```

2.  Global symbols

    these symbols exist in a _global symbol registry_, you can get one by using `Symbol.for()` (create if absent):

    ```js
    let s = Symbol.for("Gary");
    ```

    - it's **idempotent**, which means for any given key, you will always get the exactly same symbol:

      ```js
      Symbol.for("Gary") === Symbol.for("Gary");
      ```

    - get the key of a symbol:

      ```js
      let key = Symbol.keyFor(s);
      ```

3.  "Well-known" symbols

    - They exist across realms, but you can't create them and they're not on the global registry;

    - These **actually are NOT well-known at all**, they are JS built-ins, and they are used to control parts of the language, they weren't exposed to user code before ES6;

    - Refer to this [MDN - Symbol](https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Symbol) page to see a full list:

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

### Main usages

1.  **As property keys**

    as each symbol is unique, it can be used to avoid name clashes: if you do `obj[Symbol('id')] = 1;`, you are guaranteed it won't overwrite anything;

2.  **Privacy ?**

    symbol keys can not be accessed by `Object.keys`, `Object.getOwnPropertyNames`, `JSON.stringify`, and `for..in` loops

    ```js
    let obj = {
      [Symbol("name")]: 1,
      [Symbol("name")]: 2,
      [Symbol.for("age")]: 10,
      color: "red"
    };

    Object.keys(obj);
    // [ 'color' ]

    console.log(Object.getOwnPropertyNames(obj));
    // [ 'color' ]

    console.log(JSON.stringify(obj));
    // {"color":"red"}

    for (let key in obj) {
      console.log(key);
    }
    // color
    ```

    but you can access them thru `Object.getOwnPropertySymbols`

    ```js
    console.log(Object.getOwnPropertySymbols(obj));
    // [ Symbol(name), Symbol(name), Symbol(age) ]
    ```

3.  **Defining Protocols**

    just like there's `Symbol.iterator` which allows you to define how an object can be iterated

### `Symbol.iterator`

One of the most useful symbols, can be used to make an object iterable, it's just like implementing the `Iterable` interface in other languages, see the [Iterations](#Iterations) section

### `Symbol.toPrimitive`

see https://javascript.info/object-toprimitive

When an object is used in a context where a primitive value is expected, JS tries to:

1. Call `obj[Symbol.toPrimitive](hint)`, if such method exists;
2. Otherwise if hint is "string"
   try `obj.toString()` and `obj.valueOf()`, whatever exists;
3. Otherwise if hint is "number" or "default"
   try `obj.valueOf()` and `obj.toString()`, whatever exists;

```js
const gary = {
  name: "Gary",
  age: 20,
  [Symbol.toPrimitive](hint) {
    console.log(hint);
    return hint === "string" ? `{name: ${this.name}}` : this.age;
  }
};
console.log(`${gary}`);
// string
// {name: Gary}

console.log(gary + 30);
// default
// 50

console.log(gary * 2);
// number
// 40
```

``

## Arrays

- An array is a special kind of object, the syntax `arr[index]` is esentially the same as `obj[key]`;
- JS engines do optimizations for arrays, but if you use an array as a regular object, those optimizations will be turned off, so don't do:

  ```js
  // add a non-numeric property
  arr.test = 5;

  // make holes
  const arr2 = [];
  arr2[100] = 100;
  ```

### Methods

- `splice`

  can be used to remove, insert, replace elements of an array
  `arr.splice(index[, deleteCount, elem1, ..., elemN])`

  ```js
  a = ["Amy", "Gary", "Jack", "Zoe"];

  // #### removing
  a.splice(1, 1);
  // [ 'Gary' ]
  a;
  // [ 'Amy', 'Jack', 'Zoe' ]

  // #### replacing
  a.splice(2, 1, "Zolo");
  // [ 'Zoe' ]
  a;
  // [ 'Amy', 'Jack', 'Zolo' ]

  // #### inserting
  a.splice(2, 0, "Nick", "Peter");
  // []
  a;
  // [ 'Amy', 'Jack', 'Nick', 'Peter', 'Zolo' ]
  ```

### `length`

- `length` is not actually the count of values in the array, but the greatest numeric index plus one;

  ```js
  const a = [];
  a[99] = "nighty nine"; // NOTE: we should not leave holes in an array like this

  a.forEach(x => console.log(x));
  // nighty nine

  a.length;
  // 100
  ```

- `length` is writable, so you can clear an array by setting its `length` to 0

  ```js
  const a = ["gary", "jack", "nick"];
  a.length = 1;

  a;
  // [ 'gary' ]

  a.length = 0;
  a;
  // []
  ```

### Array-like

If an object has indexed properties and `length` is an array-like object, such as strings and `arguments`;

You can create one yourself, you can access it's property like an array `arrLike[0]`, but it doesn't have methods like `pop`, `push` etc;

```js
// #### Create an array-like object
const arr = {
  0: "gary",
  1: "jack",
  length: 2
};

const names = ["amy"];

names.concat(arr);
// [ 'amy', { '0': 'gary', '1': 'jack', length: 2 } ]

// #### Make the array-like object spreadable in concatenation
arr[Symbol.isConcatSpreadable] = true;
names.concat(arr);
// [ 'amy', 'gary', 'jack' ]
```

`Array.from()` can turn an array-like or iterable object into a real array, see below.

### Create a number range array

- https://itnext.io/heres-why-mapping-a-constructed-array-doesn-t-work-in-javascript-f1195138615a
- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/from

```js
let a = Array(100)
  .fill()
  .map((e, i) => i);
/*
`Array(100)` creates an empty array, which don't have any value, but a `length` property;
`fill()` creates all the elements, all of them are `undefined`;
`map()` creates a new array;
*/

// or
let a = Array.from({ length: 100 }, (e, i) => i);
```

## Map and Set

### Map

- Map is a collection of keyed data items, like `Object`, the main difference is that `Map` allows keys of any type;

  ```js
  const gary = { name: "Gary" };
  const myMap = new Map();

  myMap.set(gary, 1);
  myMap.get(gary);
  // 1
  ```

- Map uses the algorithm [SameValueZero](https://tc39.github.io/ecma262/#sec-samevaluezero) to test keys for equivalence, roughly the same as strict equality `===`, but it considers `NaN` equal to `NaN` as well;

- Iteration

  - `map.keys()`
  - `map.values()`
  - `map.entries()` gets an array of `[key, value]`
  - `for..of` iterates over `[key, value]` pairs
  - `forEach((value, key, map) => {...})`

- Maps from/to objects

  ```js
  const obj = { name: "Gary", age: 20 };

  const myMap = new Map(Object.entries(obj));
  // Map { 'name' => 'Gary', 'age' => 20 }

  const newObj = Object.fromEntries(myMap);
  // { name: 'Gary', age: 20 }
  ```

### Set

- For compatiblity, all iteration methods on map are also available for set, values are used as keys:

  - `map.keys()` gets values
  - `map.values()` gets values as well
  - `map.entries()` gets an array of `[value, value]`
  - `for..of` iterates over `[value, value]` pairs
  - `forEach((value, value, map) => {...})`

## WeakMap and WeakSet

### Garbage collection

JS engines clear unreachable objects from memory.

```js
let gary = { name: "Gary" };

// overwrite the reference
gary = null;

// then there is no reference to the object, it's unreachable, so the object will be cleared from the memory
```

If an object is in an array, or used as a map key, while the array/map is alive, it won't be cleared:

```js
let gary = { name: "Gary" };
let jack = { name: "Jack" };

let myArray = [gary];
let myMap = new Map();
myMap.set(jack, 1);

// overwrite the reference
gary = null;
jack = null;

// the array and map are still alive, so the objects won't be cleared
```

### WeakMap

- WeakMap keys must be objects;
- WeakMap does not support `size`, `keys()`, `values()` and `entries()`, so you can't get all keys or values from it;
- For WeakMap keys, if there are no other references to them, they will be garbage collected;

### WeakMap usage: caching

```js
// cache.js
let cache = new WeakMap();

// calculate and remember the result
function process(obj) {
  if (!cache.has(obj)) {
    let result = /* calculate the result for */ obj;

    cache.set(obj, result);
  }

  return cache.get(obj);
}

// main.js
let obj = {
  /* some object */
};

let result1 = process(obj);
let result2 = process(obj); // the result is cached

// when obj set to null, it will be cleared from the WeakMap cache as well
obj = null;
```

### WeakSet

- Only allow objects;
- Supports `add`, `has` and `delete`, but not `size` and iteration methods such as `keys()`, etc;
- If an element doesn't have other references, it will be cleared from the WeakSet;

Usage: keep track those who visited a site:

```js
let visitedSet = new WeakSet();

let john = { name: "John" };
let pete = { name: "Pete" };
let mary = { name: "Mary" };

visitedSet.add(john); // John visited us
visitedSet.add(pete); // Then Pete
visitedSet.add(john); // John again

// check if John visited?
visitedSet.has(john); // true

// check if Mary visited?
visitedSet.has(mary); // false

john = null;

// John will be cleared from the set
```

## Functions

- A function is a value representing an "action";
- `typeof` a function is `function`, but it's just a special type of `object`;

### Function expression vs. function statement

```javascript
// function expression
var foo = function() {};

// function statement/declaration
function foo() {}

// function statement is a short-hand for var statement, which will expand to:
var foo;
foo = function() {};
```

the difference between these two methods of defining functions:

```javascript
console.log(typeof statementFoo); // function
statementFoo(); // NOTE this function runs fine here

console.log(typeof expressionFoo); // undefined
expressionFoo(); // NOTE throws an error, expressionFoo is still undefined here

function statementFoo() {
  console.log("an statement function");
}

var expressionFoo = function() {
  console.log("an expression function");
};
```

If a function statement/declaration is inside a code block (e.g. `if` block):

- in unstrict mode, the function name is hoisted, it's visible outside of the code block, but it's value would be empty until the declaration runs;
- in strict mode, the function is block-scoped, it's only visible inside the block;

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

Every function receives an implicit `this` parameter, which is bound at invocation time

Four ways to call a function:

- Function form

  ```javascript
  foo(arguments);
  ```

  - `this` binds to the global object, which cause problems
  - in ES5/Strict, `this` binds to `undefined`
  - outer `this` is not accessible from inner functions, use `var that = this;` to pass it

- Method form

  ```javascript
  thisObject.methodName(arguments);
  thisObject["methodName"](arguments);
  ```

  `this` binds to `thisObject`

  **CAUTION** if you assign the method to a variable and call it, it doesn't have access to `this`

  ```js
  const a = {
    name: "gary",
    sayHi() {
      console.log("Hi " + this.name);
    }
  };
  // {name: "gary", sayHi: ƒ}
  a.sayHi();
  // Hi gary

  const foo = a.sayHi;
  foo(); // `this` is undefined in foo
  ```

  So, although `foo === a.sayHi`, but `a.sayHi()` has `a` as `this`, `foo()` doesn't, see https://javascript.info/object-methods#internals-reference-type

- Constructor form

  ```javascript
  new Foo(arguments);
  ```

  a new object is created and assigned to `this`, if not an explicit return value, then `this` will be returned

- Apply form

  ```javascript
  foo.apply(thisObject, arguements);
  foo.call(thisObject, arg1, arg2, ...);
  ```

  explicitly bind an object to 'this'

- `this` scope example

  ```javascript
  var person = {
    name: "Gary",
    hobbies: ["tennis", "badminton", "hiking"],

    print: function() {
      // when run person.print(), `this` is person here
      this.hobbies.forEach(function(hobby) {
        // but 'this' is undefined here
        console.log(this.name + " likes " + hobby);
      });
    },

    // use '_this' to pass the correct context this in
    print2: function() {
      var _this = this;
      console.log("// use '_this' to pass the correct context this in");
      this.hobbies.forEach(function(hobby) {
        console.log(_this.name + " likes " + hobby);
      });
    },

    // use 'bind' to get the correct this
    print3: function() {
      console.log("// use 'bind' to get the correct this");
      this.hobbies.forEach(
        function(hobby) {
          console.log(this.name + " likes " + hobby);
        }.bind(this)
      );
    },

    // recommended way: use arrow function, which uses `this` from the outer context
    print4: function() {
      console.log("// use arrow function syntax");
      this.hobbies.forEach(hobby => {
        console.log(this.name + " likes " + hobby);
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
    "zero",
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine"
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
    console.log("Index: " + i + ", element: " + arr[i]);
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
        console.log("The index of this number is: " + i);
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
  // using let, it creates a new binding
  // every single time the function is created
  // read more here: http://exploringjs.com/es6/ch_variables.html#sec_let-const-loop-heads
  setTimeout(function() {
    console.log("The index of this number is: " + i);
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

````js
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
const date = "2018-05-16";
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
````

back reference named groups in a regular expression

```js
const re = /(?<fruit>apple|orange) == \k<fruit>/u;

console.log(
  re.test("apple == apple"), // true
  re.test("orange == orange"), // true
  re.test("apple == orange") // false
);
```

use named groups in string repalcing

```js
const re = /(?<firstName>[a-zA-Z]+) (?<lastName>[a-zA-Z]+)/u;

console.log("Arya Stark".replace(re, "$<lastName>, $<firstName>")); // Stark, Arya
```

## Iterations

Iterations over any iterables: Objects, Arrays, strings, Maps, Set etc.

- `Object.keys`, `Object.values` and `Object.entries`

  ```javascript
  let o = {
    5e5: "$500K",
    1e6: "$1M",
    2e6: "$2M"
  };

  Object.keys(o);
  // [ '500000', '1000000', '2000000' ]

  Object.values(o);
  // [ '$500K', '$1M', '$2M' ]

  Object.entries(o).forEach(([k, v]) => {
    console.log(k, v);
  });

  // 500000 $500K
  // 1000000 $1M
  // 2000000 $2M
  ```

* `for..of` and `for..in`

  ```javascript
  "use strict";

  let characters = ["Jon", "Sansa", "Arya", "Tyrion", "Cercei"];

  for (let c of characters) {
    console.log(c);
  }
  // Jon
  // Sansa
  // Arya
  // Tyrion
  // Cercei

  // for..in
  for (let c in characters) {
    console.log(c);
  }
  // 0
  // 1
  // 2
  // 3
  // 4

  // loop an object
  const obj = {
    name: "gary",
    age: 20,
    [Symbol("a")]: "a symbol"
  };

  obj.__proto__.job = "IT";

  for (let k in obj) {
    console.log(k);
  }
  // name
  // age
  // job
  ```

  Note:

  - `for..in` is optimized for generic objects, not arrays, it's slower than `for..of` on arrays;
  - `for..in` iterates over all properties, it gets keys from the prototype chain as well, but not symbol properties;

* Custom iterator

  You can add a custom iterator to an object:

  - Using the `Symbol.iterator` property, which should be a function, this function executes once when the iteration starts, and returns an object containing a `next` method;

  - This `next` method should instead return an object that contains two properties: `done` and `value`, the `done` property is checked to see if the iteration finished;

  Example

  ```javascript
  // NOTE you can define a custom iteration function for an object
  "use strict";

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
var form = document.querySelector("form");

form.onsubmit = function(submitEvent) {
  var name = document.querySelector("input").value;
  request(
    {
      uri: "http://example.com/upload",
      body: name,
      method: "POST"
    },
    function(err, response, body) {
      var statusMessage = document.querySelector(".status");
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
  var name = document.querySelector("input").value;
  request(
    {
      uri: "http://example.com/upload",
      body: name,
      method: "POST"
    },
    postResponse
  );
}

function postResponse(err, response, body) {
  var statusMessage = document.querySelector(".status");
  if (err) return (statusMessage.value = err);
  statusMessage.value = body;
}
```

then import it in the main file

```js
var formUploader = require("formuploader");
document.querySelector("form").onsubmit = formUploader.submit;
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

## Event Loop

[Concurrency model and Event Loop - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/EventLoop)

- **Run-to-completion**: Each message in the loop is processed completely before any other message is processed;

### `setTimout`

The time argument for setTimout only indicates the **minimum** delay after which the message will be pushed into the queue, it only runs only when other messages before it have been cleared;

```js
const s = new Date().getSeconds();

setTimeout(function() {
  // prints out "2", meaning that the callback is not called immediately after 500 milliseconds.
  console.log("Ran after " + (new Date().getSeconds() - s) + " seconds");
}, 500);

while (true) {
  if (new Date().getSeconds() - s >= 2) {
    console.log("Good, looped for 2 seconds");
    break;
  }
}
```

### Multiple runtimes

A _web worker_ or a cross-origin _iframe_ has its own stack, heap, and message queue. Two distinct runtimes can only communicate through sending messages via the `postMessage` method. This method adds a message to the other runtime if the latter listens to message events.

## Immutability

- [Immutability in React: There’s nothing wrong with mutating objects](https://blog.logrocket.com/immutability-in-react-ebe55253a1cc)
- [Immutability in JavaScript: A Contrarian View](http://desalasworks.com/article/immutability-in-javascript-a-contrarian-view/)

### What is immutability ?

the `string` primitive type is immutable in JS, whenever you do any manipulation on a string, a new string get created

but the `String` object type _is mutable_

```js
const s = new String("hello");
//undefined

s;
//[String: 'hello']

// add a new property to a String object
s.name = "gary";
s;
// { [String: 'hello'] name: 'gary' }
```

### Reference equality vs. value equality

two references are equal when they refer to the same value if this value is immutable:

```js
var str1 = "abc";
var str2 = "abc";
str1 === str2; // true

var n1 = 1;
var n2 = 1;
n1 === n2; // also true
```

![js_equality_immutable](./images/js_equality_immutable.png)

but if the value is mutable, the two references are not equal:

```js
var str1 = new String("abc");
var str2 = new String("abc");
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
  import produce from "immer";

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
      1: { id: 1, name: "product-1" }
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
  name: "gary",
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
import theDefault from "./mod-a";
import * as all from "./mod-a";

console.log("theDefault:", theDefault);
console.log("all:", all);
```

```sh
theDefault: { name: 'gary', age: 30 }
all: [Module] { a: 20, b: 30, default: { name: 'gary', age: 30 } }
```

- For both default and named exports, you can put `export`, `export default` directly before the variable definition or do it at the end of file, in the above example, both `a`, `b` are exported;

- Or you can import everything on one line:

  ```js
  import theDefault, { a as myA, b } from "./mod-a";
  ```

- If you just want to trigger the side effect, do not actually import any binding:

  ```js
  import "./mod-a";
  ```

## Error Handling

### Error

1. Common builtin Errors in JS

   ```js
   a; // ReferrenceError: not defined
   @@; // SyntaxError: invalid or unexpected token
   "a".foo(); // TypeError: not a function
   Array(-2); // RangeError: bad arguments
   ```

2. You can create your own custom Error classes extending the builtin ones:

   ```js
   class MyError extends Error {
     consturctor(message) {
       super(message);
       this.name = "MyError";
     }
   }
   ```

3. A `throw` statement terminates current code block (like `return`, `break`, `continue`), and passes control to the first `catch` block (you can throw any value, not just `Error` object, but it should be avoided);

### `try...catch...finally`

- [MDN - try...catch](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/try...catch)
- [MDN - onerror](https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onerror)

1. Check error type using `instanceof`

   ```js
   try {
     foo.bar();
   } catch (e) {
     if (e instanceof EvalError) {
       console.log(e.name + ": " + e.message);
     } else if (e instanceof RangeError) {
       console.log(e.name + ": " + e.message);
     }
     // ... etc
   }
   ```

2. the catch block only catches synchronous errors, not async ones (**you should use a promise chain to catch async errors**):

   ```js
   try {
     setTimeout(() => {
       console.log("in setTimeout");
       throw new Error("throw in setTimeout"); // this error is not caught
     });
     console.log("in try");
   } catch (e) {
     console.log("in catch");
   }
   ```

3. in a browser, when there is an unhandled error, it goes to `window.onerror`, it can be used for error logging;

4. `finally` block always executes, if it returns a value, it becomes the entire block's return value, regardless of any return statement or error thrown in `try` and `catch` blocks;

   ```js
   function foo() {
     try {
       throw new Error("xx");
       return 1;
     } catch (e) {
       console.log("in catch");
       throw e;
       return 2;
     } finally {
       console.log("in finally");
       return 3; // would throw an error if there is no 'return' here
     }

     return 100;
     console.log("after try...catch");
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
4. you should **always** add a `catch` to your promise chain;

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

  JS is **function scoped**, not block scoped, so:

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
  typeof null === "object"; // null's type is 'object'
  ```

- **`undefined`: default value for uninitialized variables and parameters**

  - Always use `typeof x === 'undefined'` to check if a variable exists or not;
  - Comparison with `null`:

    - `undefined` is a super global variable, you can override it: `let undefined = 'foo'`, while `null` is a keyword;
    - `undeined` is of type `undefined`, `null` is of type `object`;

* **`typeof`**

  ```js
  var a = [1, 2];
  typeof a === "object"; // typeof array returns 'object'
  Array.isArray(a); // true, use this to check arrays
  ```

* **`+`**

  ```
  if both operands are numbers
  then
      add them
  else
      convert to string and concatenate
  end
  ```

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

## Tricks

### Deboucing an event

http://stackoverflow.com/questions/5489946/jquery-how-to-wait-for-the-end-of-resize-event-and-only-then-perform-an-ac

in the following code, the `updateLayout` function will only run after the `resize` event stopped 250ms

```javascript
// debounce the resize event
$(window).on("resize", function() {
  clearTimeout(window.resizedFinished);
  window.resizedFinished = setTimeout(function() {
    updateLayout();
  }, 250);
});
```

### Bind a function multiple times

If you bind a function multiple times, for each parameter(inclding `this`) in the original function, only the first bound value is used, any later bound values will be disarded, put it in another way, **you can only bind a value to each parameter once**

```js
function foo(arg1) {
  console.log(this);
  console.log(arg1);
}

const fooBound = foo.bind({ name: "gary" }); // this bound
const fooBound2 = fooBound.bind({ name: "jack" }, "hello"); // 'hello' bound to arg1
const fooBound3 = fooBound2.bind({}, "hola"); // both {} and 'hola' are discarded

fooBound("bar");
// {name: "gary"}
// bar

fooBound2("bar");
// {name: "gary"}
// hello

fooBound3();
// {name: "gary"}
// hello

console.log("foo.name: " + foo.name + ", foo.length: " + foo.length);
// foo.name: foo, foo.length: 1

console.log(
  "fooBound.name: " + fooBound.name + ", fooBound.length: " + fooBound.length
);
// fooBound.name: bound foo, fooBound.length: 1

console.log(
  "fooBound2.name: " +
    fooBound2.name +
    ", fooBound2.length: " +
    fooBound2.length
);
// fooBound2.name: bound bound foo, fooBound2.length: 0

console.log(
  "fooBound3.name: " +
    fooBound3.name +
    ", fooBound3.length: " +
    fooBound3.length
);
// fooBound3.name: bound bound bound foo, fooBound3.length: 0
```

### `Object.is()`

It's identical to `===` in most cases, except:

```js
NaN === NaN;
// false

Object.is(NaN, NaN);
// true
```

### `JSON.stringify` and `JSON.parse`

- If an object has a custom `toJSON` method, it's used to convert the object to JSON string:

  ```js
  const o = {
    id: 202,
    name: "Gary",
    toJSON() {
      return this.id;
    }
  };

  JSON.stringify(o);
  // '202'
  ```

- Use replacer function in `JSON.stringify` to deal with circular referencing issue:

  ```js
  const member = { name: "Gary" };
  const team = { name: "Dev" };
  member.team = team;
  team.members = [member];

  team;
  // { name: 'Dev', members: [ { name: 'Gary', team: [Circular] } ] }

  JSON.stringify(team); // throws an error: circular references

  // #### using replacer function to ignore the 'team' key
  JSON.stringify(team, (key, value) => (key === "team" ? undefined : value));
  // '{"name":"Dev","members":[{"name":"Gary"}]}'
  ```

- Use a reviver function to parse a string to a `Date` object

  ```js
  // #### JSON.stringify converts a Date to a string
  const s = JSON.stringify({ name: "JS Conf", date: new Date() });
  // '{"name":"JS Conf","date":"2019-12-29T08:16:31.262Z"}'

  // #### JSON.parse doesn't convert a Date to a string
  JSON.parse(s);
  // { name: 'JS Conf', date: '2019-12-29T08:16:31.262Z' }

  // #### JSON.parse accepts a reviver function to do any data conversions
  JSON.parse(s, (key, value) => (key === "date" ? new Date(value) : value));
  ```

## Reference

[JavaScript Symbols, Iterators, Generators, Async/Await, and Async Iterators — All Explained Simply
][symbol-iterator-etc]: **Read this one to fully understand the relations between Symbols, Iterators, Generators, Async/Await and Aync Iterators**

[callback-hell]: http://callbackhell.com/
[symbol-iterator-etc]: https://medium.freecodecamp.org/some-of-javascripts-most-useful-features-can-be-tricky-let-me-explain-them-4003d7bbed32
[tc39 process]: https://tc39.github.io/process-document/
