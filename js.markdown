# Javascript

- [Data types](#data-types)
  - [Truesy and falsey](#truesy-and-falsey)
  - [Type casting and coercion](#type-casting-and-coercion)
  - [Wrapper objects](#wrapper-objects)
  - [Operators](#operators)
- [Numbers](#numbers)
  - [`toString(base)` and `parseInt(str, base)`](#tostringbase-and-parseintstr-base)
- [Strings](#strings)
  - [Comparison](#comparison)
  - [Surrogate pairs](#surrogate-pairs)
  - [Diacritical marks and normalization](#diacritical-marks-and-normalization)
- [Objects](#objects)
  - [Define an object](#define-an-object)
  - [Property order](#property-order)
  - [Property flags/descriptors](#property-flagsdescriptors)
  - [Seal/freeze an object](#sealfreeze-an-object)
  - [Accessor properties](#accessor-properties)
  - [Transforming objects](#transforming-objects)
- [Prototype](#prototype)
  - [Inheritance by Prototype](#inheritance-by-prototype)
  - [What is `this`](#what-is-this)
  - [Native prototypes](#native-prototypes)
    - [Polyfilling](#polyfilling)
    - [Borrowing from prototypes](#borrowing-from-prototypes)
  - [Plain objects](#plain-objects)
- [Symbol](#symbol)
  - [Main usages](#main-usages)
  - [`Symbol.iterator`](#symboliterator)
  - [`Symbol.toPrimitive`](#symboltoprimitive)
- [Arrays](#arrays)
  - [Methods](#methods)
  - [`length`](#length)
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
  - [Function properties](#function-properties)
  - [Named Function Expressions (NFE)](#named-function-expressions-nfe)
  - [The `arguments` parameter](#the-arguments-parameter)
  - [Arrow functions](#arrow-functions)
- [The `this` keyword](#the-this-keyword)
- [Closures](#closures)
  - [Temporal Dead Zone](#temporal-dead-zone)
  - [Lexical environment](#lexical-environment)
- [Classes](#classes)
  - [Class vs. constructor function](#class-vs-constructor-function)
  - [Getters/setters](#getterssetters)
  - [Class inheritance](#class-inheritance)
    - [Built-in classes](#built-in-classes)
    - [Constructors](#constructors)
    - [How `super` works](#how-super-works)
  - [Static properties/methods](#static-propertiesmethods)
  - [Mixins](#mixins)
- [Iterations](#iterations)
- [Promise](#promise)
  - [Callback hell](#callback-hell)
  - [resolved vs. rejected](#resolved-vs-rejected)
- [Generator](#generator)
  - [Async generators](#async-generators)
  - [Using generators for iterables](#using-generators-for-iterables)
- [Async/await](#asyncawait)
- [Event Loop](#event-loop)
  - [Message queue / task queue](#message-queue--task-queue)
  - [`setTimout` and `setInterval`](#settimout-and-setinterval)
  - [Microtasks](#microtasks)
  - [Render steps and `requestAnimationFrame`](#render-steps-and-requestanimationframe)
  - [Multiple runtimes](#multiple-runtimes)
- [ECMAScript](#ecmascript)
- [Module Systems](#module-systems)
  - [AMD (Asynchronous Module Design)](#amd-asynchronous-module-design)
  - [CommonJS (CJS)](#commonjs-cjs)
  - [ES](#es)
  - [Re-export](#re-export)
  - [Modules in browsers](#modules-in-browsers)
- [Error Handling](#error-handling)
  - [Error](#error)
  - [`try...catch...finally`](#trycatchfinally)
  - [Promise](#promise-1)
  - [async/await errors](#asyncawait-errors)
- [Regular Expression](#regular-expression)
  - [Methods](#methods-1)
  - [Capturing groups](#capturing-groups)
    - [Named groups](#named-groups)
    - [Non-capturing groups](#non-capturing-groups)
  - [Unicode](#unicode)
  - [Escaping](#escaping)
- [Immutability](#immutability)
  - [What is immutability ?](#what-is-immutability-)
  - [Reference equality vs. value equality](#reference-equality-vs-value-equality)
  - [Immutability tools](#immutability-tools)
    - [The JS way](#the-js-way)
    - [Immutable.js](#immutablejs)
    - [Immer](#immer)
    - [immutability-helper](#immutability-helper)
- [Javascript: The Good Parts](#javascript-the-good-parts)
- [Tricks](#tricks)
  - [Deboucing an event](#deboucing-an-event)
  - [Bind a function multiple times](#bind-a-function-multiple-times)
  - [Currying](#currying)
  - [`Object.is()`](#objectis)
  - [Object property iteration methods comparison](#object-property-iteration-methods-comparison)
  - [`JSON.stringify` and `JSON.parse`](#jsonstringify-and-jsonparse)
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
typeof 'abc'; // 'string'
typeof String('abc'); // 'string'
'abc' === String('abc'); // true

s = new String('abc'); // [String: 'abc']
typeof s; // 'object'
s === 'abc'; // false
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
parseInt('100', 2);
// 4
```

## Strings

### Comparison

use `str.localeCompare` to compare strings properly:

```js
'Zealand' > 'Österreich';
// false

'Zealand'.localeCompare('Österreich');
// 1
```

### Surrogate pairs

JS uses UTF-16 as internal format for strings, most frequently used characters have 2-byte codes, that covers 65536 symbols, some rare symbols are encoded with a pair of 2-byte characters called a _surrogate pair_;

The first character of a surrogate pair has code in range `0xd800..0xdbff`, the second one must be in range `0xdc00..0xdfff`, these intervals are reserved for surrogate pairs, so they should always come in pairs, an individual one means nothing;

Surrogate pairs didn't exist when JS was created, so they are not processed correctly sometimes:

```js
'a'.length;
// 1

const s = '𩷶';

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
'S\u0307';
// 'Ṡ'

'S\u0307\u0323';
// 'Ṩ'
```

This causes a problem: a symbol with multiple decorations can be represented in different ways.

```js
const s1 = 'S\u0307\u0323';
const s2 = 'S\u0323\u0307';

// s1 and s2 looks the same 'Ṩ', but they are not equal
s1 === s2; // false
```

There is a "unicode normalization" algorithm that brings each string to a single "normal" form.

```js
// #### 'Ṩ' has its own code \u1e68 in Unicode
const normalizedS = 'S\u0307\u0323'.normalize();

normalizedS.length; // 1
normalizedS.codePointAt(0).toString(16); // '1e68'

// #### 'Q̣̇' don't have its own code, normalization will put \u0323 before \u0307
const normalizedQ = 'Q\u0307\u0323';

normalizedQ.length; // 3
normalizedQ.codePointAt(0).toString(16); // '51'
normalizedQ.codePointAt(1).toString(16); // '323'
normalizedQ.codePointAt(2).toString(16); // '307'
```

## Objects

### Define an object

- Object literal

  ```js
  let circle = {
    radius: 2;
  };
  ```

- The `Object` constructor

  ```js
  let circle = new Object();
  circle.radius = 2;
  ```

- Constructor function

  ```js
  let Circle = function(radius) {
    this.radius = radius;
    this.area = function() {
      return Math.PI * this.radius * this.radius;
    };
  };

  let circle = new Circle(2);
  ```

  - It's a good practice to capitalize the first letter of constructor name and always call it with `new`;
  - **constructor function return `this` if no explicit `return`**

- `Object.create`

  ```js
  let shape = { x: 0 };

  // #### create an object using shape as the prototype
  let circle = Object.create(shape, { radius: { value: 10 } });

  c.radius;
  // 10

  // #### copy all properties and the right [[Prototype]]
  let clone = Object.create(
    Object.getPrototypeOf(obj),
    Object.getOwnPropertyDescriptors(obj)
  );
  ```

### Property order

```js
a = { 64: 'NZ', 1: 'US', name: 'gary', age: 20 };

Object.keys(a);
// ["1", "64", "name", "age"]
```

Integer properties are ordered, others appear in creation order, so `1` comes before `64` when iterating through all the properties;

_A property key can only be a string or a symbol_, when you use a number as property key, it's converted to a string;

### Property flags/descriptors

- `writable`
- `enumerable`
- `configurable` whether the property can be deleted and flags can be modified:
  - If a property is non-configurable, you can't change it back;
  - A non-configurable property can still be writable;

You can get these flags by `Object.getOwnPropertyDescriptor` and change them using `Object.defineProperty`

There are `Object.getOwnPropertyDescriptors` and `Object.defineProperties`, which allows you to define and access multiple properties' flags at once;

```js
let clone = Object.defineProperties({}, Object.getOwnPropertyDescriptors(obj));
```

This allows you to copy all properties of an object, including symbolic properties and all property flags.

### Seal/freeze an object

- `Object.preventExtensions(obj)`: forbids adding new properties;
- `Object.seal(obj)`: forbids adding/removing of properties, sets `configurable: false` for all properties;
- `Object.freeze(obj)`: forbids adding/removing/changing of properties, sets `configurable: false, writable: false` for all properties;

There are methods to check an objects

### Accessor properties

There are two kinds of properties:

|                    | Data properties | Accessor properties |
| ------------------ | --------------- | ------------------- |
| Unique Descriptors | value, writable | get, set            |

- A property can be either a data property or an accessor property, not both;

Usages:

- Use an accessor property as a wrapper for a data property, so you can control what value is allowed for the data property;
- For compatiblity;

```js
'use strict';

// #### define fullName as an accessor property
var person = {
  firstName: 'Gary',
  lastName: 'Li',
  age: 20,
  get fullName() {
    return this.firstName + ' ' + this.lastName;
  },

  set fullName(value) {
    [this.firstName, this.lastName] = value.split(' ');
  }
};

person.fullName;
// 'Gary Li'
person.fullName = 'Joe Doe';
// 'Joe Doe'

// #### can't define a getter function for an existing data property, this has no effect
Object.defineProperty(person, 'age', {
  get age() {
    return 100;
  }
});

// #### use defineProperty
let o = {};
Object.defineProperty(o, 'name', {
  get: function() {
    // ...
  },

  set: function(value) {
    // ...
  }
});
```

Refactor the person object above, add a `birthday` property, and convert `age` to an accessor property for compatibility, so it's still available:

```js
var person = {
  firstName: 'Gary',
  lastName: 'Li',
  birthday: new Date('2000-01-01'),

  get age() {
    return new Date().getFullYear() - this.birthday.getFullYear();
  }
  // ...
};
```

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

- In JS, objects have a special hidden property `[[Prototype]]`, which can be `null` or another object;
- `__proto__` is an accessor property of `Object.prototype`, a historical getter/setter for `[[Prototype]]`, you should use newer functions `Object.getPrototypeOf/Object.setPrototypeOf` when possible;
- Although you can get/set `[[Prototype]]` at anytime, but usually we only set it once at the object creation time, changing an object's prototype is very slow and will break internal optimizations;

### Inheritance by Prototype

[Douglas Crockford's video course: Prototypal Inheritance](http://app.pluralsight.com/training/player?author=douglas-crockford&name=javascript-good-parts-m0&mode=live&clip=0&course=javascript-good-parts)

```javascript
function Gizmo(id) {
  this.id = id;
}

Gizmo.prototype.toString = function() {
  return 'gizmo ' + this.id;
};

let g = new Gizmo(1);
```

![Object](./images/js_obj.png)

- `Gizmo` is a function object, which has a `prototype` property;
- `Gizmo.prototype` has a `constructor` property pointing back to `Gizmo`, `[[Prototype]]` pointing to `Object.prototype`;
- `g` is a plain object, does **not** have a `prototype` property, its `[[Prototype]]` points to `Gizmo.prototype`

  ```js
  g.__proto__ === Gizmo.prototype; // true
  Gizmo.prototype.__proto__ === Object.prototype; // true
  ```

In general:

- **Every function (not arrow functions) has a `prototype` property, this is a normal property, not the hidden `[[Prototype]]` property;**
- **`Foo.prototype` is used to build the prototype chain, `(new Foo).__proto__ === Foo.prototype`;**
- When using `new Foo()` to create an object, the function `Foo` will always be run, although `Foo.prototype` may have been changed to point to something else;

  ```js
  function Animal(name, age) {
    this.name = name;
    this.age = age;
  }

  Animal.prototype.constructor === Animal; // 'constructor' points to the function now
  // true

  Animal.prototype = { x: 10 }; // 'prototype' can be changed to point to another object

  Animal.prototype.constructor === Animal; // Animal.prototype.constructor does not point to Animal anymore
  // false

  a = new Animal('Snowball', 5); // Animal is always used to create the object
  // { name: 'Snowball', age: 5 }

  a.__proto__; // a.__proto__ always points to Animal.prototype
  // { x: 10 }
  ```

Another illustration created by myself:

![JS prototype system](./images/JavaScript.object.prototype.system.png)

### What is `this`

```js
let user = {
  name: 'John',
  surname: 'Smith',

  set fullName(value) {
    [this.name, this.surname] = value.split(' ');
  },

  get fullName() {
    return `${this.name} ${this.surname}`;
  }
};

// admin inherits from user
let admin = {
  __proto__: user,
  isAdmin: true
};

admin.fullName = 'Gary Li';
// 'Gary Li'

admin;
// { isAdmin: true, name: 'Gary', surname: 'Li' }

user;
// { name: 'John', surname: 'Smith', fullName: [Getter/Setter] }
```

When you call `admin.fullName`, `this` refers to `admin`, not `user`, so `name` and `surname` is added to `admin`;

**No matter where the method is found: in an object or its prototype. In a method call, `this` is always the object before the dot.**

### Native prototypes

Native constructors have their own prototypes:

- `Object.prototype`
- `Function.prototype`
- `Array.prototype`
- `Date.prototype`
- `Number.prototype`
- `String.prototype`
- `Boolean.prototype`
- `Symbol.prototype`

![object prototype](./images/js_native_prototypes.png)

- For primitive values such as numbers, strings and booleans, when you try to access their properties, temporary wrapper objects are created using built-in constructors `String`, `Number` and `Boolean`;
- `null` and `undefined` don't have wrapper objects and prototypes;

#### Polyfilling

It's generally a bad idea to modify a native prototype except for polyfilling:

```js
if (!String.prototype.repeat) {
  // if there's no such method add it to the prototype

  String.prototype.repeat = function(n) {
    // actually, the code should be a little bit more complex than that
    // (the full algorithm is in the specification)
    // but even an imperfect polyfill is often considered good enough
    return new Array(n + 1).join(this);
  };
}

alert('La'.repeat(3)); // LaLaLa
```

#### Borrowing from prototypes

```js
// #### o is an array-like object
// #### it doesn't have methods from Array.prototype
let o = { 0: 'Hello', 1: 'world', length: 2 };

// #### 1) call the prototype method directly
Array.prototype.join.call(o, ' | ');
// 'Hello | world'

// #### 2) borrow the prototype method
o.join = Array.prototype.join;
o.join(' | ');
// 'Hello | world'
```

### Plain objects

Normally an object has `[[Prototype]]`, and you can access it thru the accessor property `__proto__`. But, if you want to use an object as a dictionary, then `__proto__` can't be used as a key, to avoid this, either:

- Use `Map`;
- Or use a "very plain" or "pure dictionary" object:

  ```js
  // #### use null as [[Prototype]] to create a very plain object
  let obj = Object.create(null);

  obj.__proto__ = 10; // now __proto__ becomes a plain property

  obj.toString(); // but it doesn't have access to Object.prototype methods anymore
  // TypeError
  ```

## Symbol

ref: [ES6 Symbols in Depth](https://ponyfoo.com/articles/es6-symbols-in-depth#the-runtime-wide-symbol-registry)

Symbol is a new primitive value type in ES6, there are three different flavors of symbols - each flavor is accessed in a different way:

1.  Local symbols

    Create a local symbol:

    ```js
    let s = Symbol('gary symbol');

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
    let s = Symbol.for('Gary');
    ```

    - it's **idempotent**, which means for any given key, you will always get the exactly same symbol:

      ```js
      Symbol.for('Gary') === Symbol.for('Gary');
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
      [Symbol('name')]: 1,
      [Symbol('name')]: 2,
      [Symbol.for('age')]: 10,
      color: 'red'
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
  name: 'Gary',
  age: 20,
  [Symbol.toPrimitive](hint) {
    console.log(hint);
    return hint === 'string' ? `{name: ${this.name}}` : this.age;
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
  a = ['Amy', 'Gary', 'Jack', 'Zoe'];

  // #### removing
  a.splice(1, 1);
  // [ 'Gary' ]
  a;
  // [ 'Amy', 'Jack', 'Zoe' ]

  // #### replacing
  a.splice(2, 1, 'Zolo');
  // [ 'Zoe' ]
  a;
  // [ 'Amy', 'Jack', 'Zolo' ]

  // #### inserting
  a.splice(2, 0, 'Nick', 'Peter');
  // []
  a;
  // [ 'Amy', 'Jack', 'Nick', 'Peter', 'Zolo' ]
  ```

### `length`

- `length` is not actually the count of values in the array, but the greatest numeric index plus one;

  ```js
  const a = [];
  a[99] = 'nighty nine'; // NOTE: we should not leave holes in an array like this

  a.forEach(x => console.log(x));
  // nighty nine

  a.length;
  // 100
  ```

- `length` is writable, so you can clear an array by setting its `length` to 0

  ```js
  const a = ['gary', 'jack', 'nick'];
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
  0: 'gary',
  1: 'jack',
  length: 2
};

const names = ['amy'];

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
  const gary = { name: 'Gary' };
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
  const obj = { name: 'Gary', age: 20 };

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
let gary = { name: 'Gary' };

// overwrite the reference
gary = null;

// then there is no reference to the object, it's unreachable, so the object will be cleared from the memory
```

If an object is in an array, or used as a map key, while the array/map is alive, it won't be cleared:

```js
let gary = { name: 'Gary' };
let jack = { name: 'Jack' };

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

let john = { name: 'John' };
let pete = { name: 'Pete' };
let mary = { name: 'Mary' };

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

For a function statement, its definition is hoisted to the top.

```javascript
console.log(typeof statementFoo); // function
statementFoo(); // NOTE this function runs fine here

console.log(typeof expressionFoo); // undefined
expressionFoo(); // NOTE throws an error, expressionFoo is still undefined here

// function statement/declaration
function statementFoo() {
  console.log('an statement function');
}

// function expression
var expressionFoo = function() {
  console.log('an expression function');
};
```

If a function statement/declaration is inside a code block (e.g. `if` block):

- In unstrict mode, the function name is hoisted, it's visible outside of the code block, but it's value would be empty until the declaration, like `var`;
- In strict mode, the function is block-scoped, it's only visible inside the block, like `let`;

### Function properties

```js
let foo = function(a, b, ...rest) {
  // do something
};

Object.getOwnPropertyNames(X);
// [ 'length', 'name', 'arguments', 'caller', 'prototype' ]

foo.length; // the ...rest parameter doesn't count
// 2

foo.name;
// 'foo'
```

### Named Function Expressions (NFE)

```js
let foo = function hello(name) {
  if (name) {
    console.log(`Hello ${name}`);
  } else {
    hello('Guest');
  }
};

foo.name;
// 'hello'

foo();
```

- `hello` is the name of the function;
- It allows the function to call itself;
- It is only visible inside the function;

There is no way to add an "internal" name for a function statement.

### The `arguments` parameter

Each function receives two pseudo parameters: `arguments` and `this`;

| `argument`           | ...rest parameters  |
| -------------------- | ------------------- |
| all arguments        | only rest arguments |
| array-like, iterable | array               |

**Always use ...rest parameters when possible**

```js
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

### Arrow functions

- Do not have `this` or `super`;
- Do not have `arguments`;
- Can't be called with `new`;

They don't have their own "context", but rather work in the current one.

```js
function defer(f, ms) {
  return function() {
    setTimeout(() => f.apply(this, arguments), ms); // `this` and `arguments` come from outer context
  };
}

function sayHi(who) {
  alert('Hello, ' + who);
}

let sayHiDeferred = defer(sayHi, 2000);
sayHiDeferred('John'); // Hello, John after 2 seconds
```

Without an arrow function, it would look like:

```js
function defer(f, ms) {
  return function(...args) {
    let ctx = this;
    setTimeout(function() {
      return f.apply(ctx, args); // pass in `this` and `arguments` from outer context
    }, ms);
  };
}
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
  thisObject['methodName'](arguments);
  ```

  `this` binds to `thisObject`

  **CAUTION** if you assign the method to a variable and call it, it doesn't have access to `this`

  ```js
  const a = {
    name: 'gary',
    sayHi() {
      console.log('Hi ' + this.name);
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
    name: 'Gary',
    hobbies: ['tennis', 'badminton', 'hiking'],

    print: function() {
      // when run person.print(), `this` is person here
      this.hobbies.forEach(function(hobby) {
        // but 'this' is undefined here
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

    // recommended way: use arrow function, which uses `this` from the outer context
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

You can fix this by:

- Adding a separate closure for each loop iteration, in this case, the `i` is separate for each closure;

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

- Or using `let`, which creates a new block binding for each iteration

  - **`let` is block scoped**, a new 'backpack' is created for each iteration, in contrast, `var` is function scoped, so the `i` is shared in the first example;
  - Although `let i` is outside of `{...}`, but `for` construct is special, the declaration is still considered a part of the block;
  - Read more here: http://exploringjs.com/es6/ch_variables.html#sec_let-const-loop-heads

  ```javascript
  const arr = [10, 12, 15, 21];
  for (let i = 0; i < arr.length; i++) {
    setTimeout(function() {
      console.log('The index of this number is: ' + i);
    }, 300);
  }
  ```

### Temporal Dead Zone

See [let - MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/let) for details

- `var` declarations will be hoisted to the top of **function scope**, but the value assignment is not, so the value is `undefined` before assignment;
- `let` bindings are created at the top of the **block scope**, but unlike `var`, you can't read or write it, you get a `ReferenceError` if using it before the declaration;

```js
function do_something() {
  console.log(bar); // undefined
  console.log(baz); // undefined
  console.log(foo); // ReferenceError, in 'Temporal Dead Zone'

  var bar = 1;

  if (false) {
    var baz = 10; // this will never be executed, but the `baz` declaration is still hoisted
  }

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

### Lexical environment

- In JS, every function, code block `{...}` and the script as whole have an internal associated object known as the `Lexical Environment`, which saves all local variables and a reference to the outer lexical environment;
- All functions have a hidden property `[[Environment]]`, which remembers the Lexical Environment in which the function was created;

  ![Lexical Environment](./images/js_lexical_environment.png)

- After `makeCounter` finishes, the lexical environment is still available thru `counter.[[Environment]]`, so it won't be garbage collected, if you do `counter = null;`, then the lexical environment will be cleared;
- For `for (let i = 0; i < 10; i++){ }`, a new lexical environment is created for every run of the code in `{...}`, each one has its own `i` variable;
- In theory, all outer variables of a function should be available as long as the function is alive, but some JS engines (V8) try to optimize that, a side effect is that such variable will become unavailable in debugging;

## Classes

### Class vs. constructor function

```js
class MyClass {
  consturctor(name) {
    this.name = name;
  }

  show() {
    console.log(this.name);
  }
}

typeof MyClass; // MyClass is actually a function
// 'function'

MyClass.prototype.constructor === MyClass;
// true

MyClass.prototype.show; // class method is on the class prototype
// [Function: show]
```

The `class MyClass {}` construct actually creates a function, it's very similar to creating a constructor function `function MyClass () {}`, with a few differences:

1. A class function is labelled by a special internal property `[[FunctionKind]]:"classConstructor"`, it must by called with `new`;
2. Class methods are non-enumerable;
3. All code inside the class construct is always in _strict mode_;

### Getters/setters

```js
class User {
  age = 20;

  constructor(name) {
    // invokes the setter
    this.name = name;
  }

  get name() {
    return this._name;
  }

  set name(value) {
    if (value.length < 4) {
      alert('Name is too short.');
      return;
    }
    this._name = value;
  }
}

let user = new User('John');
user;
// User { age: 20, _name: 'John' }
```

- Class property `age` is not in `User.prototype`, instead it is created by `new` before calling the constructor, it's a property of the created object `user`;
- `name` is an accessor property of `User.prototype`, if an accessor only has the getter, not the setter, then it's read-only;
- `_name` is in the created object;

### Class inheritance

```js
class Animal {
  constructor(name) {
    this.name = name;
  }

  // ...
}

class Rabbit extends Animal {
  constructor(name, earLength) {
    super(name);
    this.name = name;
  }

  // ...
}

Rabbit.prototype.__proto__ === Animal.prototype;
// true

Rabbit.__proto__ === Animal;
// true

Animal.__proto__ === Function.prototype;
// true
```

![class inheritance](./images/js_class_inheritance.png)

Not only `Rabbit.prototype` extends `Animal.prototype`, **`Rabbit` itself extends `Animal` as well !**

#### Built-in classes

![builtin classes](./images/js_builtin_inheritance.png)

Although `Date.prototype` extends `Object.prototype`, but `Date` doesn't extend `Object`, so there is `Object.keys()` but no `Date.keys()`;

#### Constructors

An inheriting class doesn't need to define a constructor explicitly, but if it does, then **it must call `super()` and do it before using `this`**, because a derived constructor has a special internal label: `[[ConstructorKind]]:"derived"`, which affects its behavior with `new`:

- When a regular function is executed with `new`, it creates an empty object and assigns it to `this`;
- But when a derived consturctor runs, it expects the parent constructor to create `this`;

#### How `super` works

- JS has another internal property for functions called `[[HomeObject]]`, when a function is specified as a class or object methods, its `[[HomeObject]]` points to that object, `super` uses this to resolve the parent prototype;
- Function properties don't have `[[HomeObject]]`;
- Arrow functions don't have `super`;

```js
let animal = {
  name: 'Animal',
  sleep: function() {
    // this is a function property, not a method
  },

  eat() {
    // animal.eat.[[HomeObject]] == animal
    alert(`${this.name} eats.`);
  },

  run() {
    console.log('Running');
  }
};

let rabbit = {
  __proto__: animal,
  name: 'Rabbit',
  sleep: function() {
    // this is a function property, not a method,
    // no [[HomeOjbect]], you can't call `super.sleep()` here
  },

  eat() {
    // rabbit.eat.[[HomeObject]] == rabbit
    super.eat();
  },

  run() {
    // arrow functions don't have its own `this` or `super`, it's gettings `super` from the context
    setTimeout(() => super.run(), 1000);
  }
};
```

### Static properties/methods

```js
class Article {
  static publisher = 'Foo Books';

  constructor(title, date) {
    this.title = title;
    this.date = date;
  }

  static createTodays() {
    // remember, this = Article
    return new this("Today's digest", new Date());
  }
}

let article = Article.createTodays();
```

- Static properties/methods belong to the class (constructor function), not the created object instance;
- It's a good way to create factory method, use `new this()` in a static method to create an instance;
- When `class Child extends Parent { }`, then `Child.__proto__ === Parent`, so all static properties/methods are inherited by `Child`;

### Mixins

In JS, a class can only extends one other class, if there is something else you want to extend, you can use a "mixin".

```js
let sayMixin = {
  say(phrase) {
    alert(phrase);
  }
};

// **sayHiMixin extends sayMixin**
let sayHiMixin = {
  __proto__: sayMixin, // (or we could use Object.create to set the prototype here)

  sayHi() {
    // call parent method
    super.say(`Hello ${this.name}`); // (*)
  },

  sayBye() {
    super.say(`Bye ${this.name}`); // (*)
  }
};

class User {
  constructor(name) {
    this.name = name;
  }
}

// ** copy the methods **
Object.assign(User.prototype, sayHiMixin);

// now User can say hi
new User('Dude').sayHi(); // Hello Dude!
```

`super` in `sayHiMixin` methods always refers to `sayMixin`

![js mixins](./images/js_mixin.png)

## Iterations

Iterations over any iterables: Objects, Arrays, strings, Maps, Set etc.

- `Array.from()` converts any iterable or array-like value into an array;
- `...` spread operator works on any iterable;

- `Object.keys`, `Object.values` and `Object.entries`

  ```javascript
  let o = {
    5e5: '$500K',
    1e6: '$1M',
    2e6: '$2M'
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
    name: 'gary',
    age: 20,
    [Symbol('a')]: 'a symbol'
  };

  obj.__proto__.job = 'IT';

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
  - If a property is not enumerable, it will not be listed, that's why you don's see properties from `Object.prototype`;
  - `for..of` works on any iterable value;

* Custom iterator

  You can add a custom iterator to an object:

  - Using the `Symbol.iterator` property, which should be a function, this function executes once when the iteration starts, and returns an object containing a `next` method;

  - This `next` method should instead return an object that contains two properties: `done` and `value`, the `done` property is checked to see if the iteration finished;

  Example

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

JS uses callbacks a lot, if not handled properly, it will lead to Callback Hell, Promise was introduced in ES6, it's a way to simplify asynchronous programming by making code _look_ synchronous and avoid callback hell.

[A Simple Guide to ES6 Promises](https://codeburst.io/a-simple-guide-to-es6-promises-d71bacd2e13a)

### Callback hell

When there are multiple nested callbacks, the code becomes quite hard to read and understand

```js
loadScript('1.js', function(error, script) {
  if (error) {
    handleError(error);
  } else {
    // ...
    loadScript('2.js', function(error, script) {
      if (error) {
        handleError(error);
      } else {
        // ...
        loadScript('3.js', function(error, script) {
          if (error) {
            handleError(error);
          } else {
            // ...continue after all scripts are loaded (*)
          }
        });
      }
    });
  }
});
```

rewrite `loadScript` to return a promise:

```js
loadScript('1.js')
  .then(() => loadScript('2.js'))
  .then(() => loadScript('3.js'))
  .catch(e => {
    // handle error
  });
```

### resolved vs. rejected

Please see here for detailed examples about when a promise is resolved or rejected: https://github.com/garylirocks/js-es6/tree/master/promises

Take note:

- It is recommended to only pass the resolved callback to `.then()`, use `.catch()` to handle errors;
- Always use a `.catch()`;

## Generator

```js
'use strict';

// NOTE define an infinite generator
let idMaker = function*() {
  let nextId = 100;

  while (true) {
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
```

you can even yield into another iterable within a generator:

```js
// NOTE yield another iterable in a generator
let myGenerator = function*() {
  yield 'start';
  yield* [1, 2, 3]; // <- yield into another iterable
  yield 'end'; // <- back to the main loop
};

for (let i of myGenerator()) {
  console.log(i);
}
// start
// 1
// 2
// 3
// end
```

### Async generators

```js
async function* generateSequence(start, end) {
  for (let i = start; i <= end; i++) {
    // yay, can use await!
    await new Promise(resolve => setTimeout(resolve, 1000));

    yield i;
  }
}

(async () => {
  let generator = generateSequence(1, 5);
  for await (let value of generator) {
    alert(value); // 1, then 2, then 3, then 4, then 5
  }
})();
```

- Use `async`;
- Use `for await..of` to iterate thru the results;

### Using generators for iterables

- Sync iterators

  ```js
  let range = {
    from: 1,
    to: 5,

    *[Symbol.iterator]() {
      // a shorthand for [Symbol.iterator]: function*()
      for (let value = this.from; value <= this.to; value++) {
        yield value;
      }
    }
  };

  alert([...range]); // 1,2,3,4,5
  ```

- Async iterables

  ```js
  let range = {
    from: 1,
    to: 5,

    async *[Symbol.asyncIterator]() {
      // same as [Symbol.asyncIterator]: async function* ()
      for (let value = this.from; value <= this.to; value++) {
        // wait 1 second
        await new Promise(resolve => setTimeout(resolve, 1000));

        yield value;
      }
    }
  };

  (async () => {
    for await (let value of range) {
      alert(value); // 1, then 2, then 3, then 4, then 5
    }
  })();
  ```

## Async/await

[Ref - Hackernoon](https://hackernoon.com/6-reasons-why-javascripts-async-await-blows-promises-away-tutorial-c7ec10518dd9)

```js
async function f() {
  return 1;
}

f().then(alert); // 1
```

`async` makes the following function return a promise.

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

Refs:

- [Concurrency model and Event Loop - JavaScript | MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/EventLoop)
- [Event loop: microtasks and macrotasks - Javascript.info](https://javascript.info/event-loop)
- [What the heck is the event loop anyway? | Philip Roberts | JSConf EU](https://youtu.be/8aGhZQkoFbQ)
- [Jake Archibald: In The Loop](https://youtu.be/cCOL7MC4Pl0)
- [Jake Archibald: The compositor thread](https://vimeo.com/254947206#t=1470s)

### Message queue / task queue

![JS message queue](images/js_message-queue.png)

- JS is single threaded, it relies on environment provided APIs to handle asynchronous actions.
- The browser provides APIs for **DOM**, **network request** and **timer**.
- JS runtime uses a message queue, each message has an associated function which gets called(put in the stack) to handle the message.
- Once the stack is empty, the oldest item in the message queue is put in the stack.
- **Run-to-completion**: each task is processed completely before any other message is processed, so it won't be interrupted by other async tasks.

### `setTimout` and `setInterval`

- The time argument for `setTimout` only indicates the **minimum** delay after which the message will be pushed into the queue, it only runs when other messages before it have been cleared;

  ```js
  const s = new Date().getSeconds();

  setTimeout(function() {
    // prints out "2", meaning that the callback is not called immediately after 500 milliseconds.
    console.log('Ran after ' + (new Date().getSeconds() - s) + ' seconds');
  }, 500);

  while (true) {
    if (new Date().getSeconds() - s >= 2) {
      console.log('Good, looped for 2 seconds');
      break;
    }
  }
  ```

- **Zero-delay timeout**, is not actually 0ms, there's a minimal delay of around 4ms, and subject to whether there are other tasks in the queue

  ```js
  setTimeout(func, 0);
  ```

- Nested `setTimeout` vs. `setInterval`

  Nested `setTimeout` can set the execution delay more precisely than `setInterval`:

  ```js
  // setInterval
  let i = 1;
  setInterval(function() {
    func(i++);
  }, 100);
  ```

  ![setInterval](./images/js_set_interval.png)

  ```js
  // nested setTimeout
  let j = 1;
  setTimeout(function run() {
    func(j++);
    setTimeout(run, 100);
  }, 100);
  ```

  ![nested setTimeout](./images/js_set_timeout_nested.png)

- Garbage collection

  - When a function is passed in `setTimeout/setInterval`, an internal reference is created, so it won't be garbage collected;
  - For `setInterval` the function will be cleared when `clearInterval` is called;
  - Since a function references the outer lexical environment, that takes memory, so it's better to **cancel a timer when it's not needed**;


### Microtasks

- Apart from the task queue(aka *mactotask queue*), there is a **microtask queue**;
- Microtasks come solely from our code, usually created by
  - **promises**: `.then/catch/finally` or `await`,
  - **`queueMicrotask(func)`**: a special function that queues `func` in the microtask queue
  - **`new MutationObserver(func)`**
- Microtask queue has higher priority than macrotask queue and rendering, once the stack is empty, the microtask queue gets executed immediately until it's empty, so newly added microtasks get executed as well

Example:

```js
function foo() {
  console.log('sync: start');
	setTimeout(() => console.log('macrotask: timeout'), 0);
  const promise = Promise.resolve();
  const promiseRejected = Promise.resolve().then(() => {throw new Error('Rejected!')});
  promise
    .then(x => console.log('microtask: promise'))
    .then(() => {
    	queueMicrotask(()  => console.log('microtask: added by queueMicrotask'));
    	Promise.resolve().then(() => console.log('microtask: nested promise'));

  	})
  console.log('sync: end');
  window.addEventListener('unhandledrejection', e => {
    console.log('macrotask: unhandledrejection')
  });
}

foo();

// sync: start
// sync: end
// microtask: promise
// microtask: added by queueMicrotask
// microtask: nested promise
// macrotask: timeout
// macrotask: unhandledrejection
```

As you can see,

1. synchronous code is executed first,
2. then microtasks, including those newly added microtasks, until the microtasks queue is empty,
3. then macrotask executes

Note:

-  *a promise handler is always put into the microtask queue when the promise settles, even for already resolved promises*
- After the microtask queue is complete, if there is any rejected promise, the `unhandledrejection` event is triggered

There are three queues, they are processed differently:

- Tasks: one at a time, new items enqueued
- Microtasks: all items are processed, including new items just enqueued
- Animation callbacks: all existing items are processed, new items just enqueued will wait for next turn

![Three types of queue](images/js_queues-tasks-microtasks-animation.png)

### Render steps and `requestAnimationFrame`

- Render steps include style calculation, layout and painting, they happen at the begining of each frame, which lasts 16.6ms for a 60Hz display

  ![Render steps and frames](images/js_render-steps.png)

- If you use a zero-delay timeout loop for DOM updating, in each frame the callback can be run around 4 times, but 3 of them are wasted

  ![DOM updates by setTimeout](images/js_dom-updates-by-settimeout.png)

- You can use the `requestAnimationFrame` to schedule some style/DOM updating actions, they will be picked up immediately in each frame

  ![Eventloop with mictotask queue](images/js_eventloop.png)
  ![DOM updates by requestAnimationFrame](images/js_dom-updates-by-requestanimationframe.png)


### Multiple runtimes

[Jake Archibald: Multiple Event Loops](https://vimeo.com/254947206#t=1470s)

- Tabs

  Usually each tab has its own event loop

- Iframe

  - Same-origin: using the same event loop as the parent frame, so the parent can access the iframe's DOM
  - Cross-origin: has its own event loop

- Web worker

  Has its own event loop

- `window.open()`

  Similar to iframe

- `<a href="//example.com" target="_blank">`

  - Same-origin: same event loop, last tab is available as `window.opener`, new tab can access last tab's DOM
  - Cross-origin: new tab has a new event loop, can't access last tab's DOM, but still can change its location by `window.opener.location = ...`, this is **a security risk**, so you should add the **`rel="noopener"`** attribute, then `window.opener` is `null`

A _web worker_ or a cross-origin _iframe_ has its own stack, heap, and message queue. Two distinct runtimes can only communicate through sending messages via the `postMessage` method. This method adds a message to the other runtime if the latter listens to message events.


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

### ES

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

### Re-export

```js
export { login, logout } from './helpers.js';
export { default as User } from './user.js';

export * from './foo.js'; // to re-export named exports
export { default } from './foo.js'; // to re-export the default export
```

- Rexporting is a good way to consolidate multipe exports into a single entry point;
- `import * from './foo.js';'` includes `default`, but `export * from './foo.js';` only re-exports named exports, not including `default`, some people don't use `export default` to avoid this oddity;

### Modules in browsers

If you want to use ES modules directly (without Webpack) in broswer:

```html
<!DOCTYPE html>
<script type="module">
  import { sayHi } from './say.js';
  import { foo } from 'foo'; // ** no path, not allowed
  document.body.innerHTML = sayHi('John');

  let name = 'module 1'; // ** module-scope

  alert(this); // ** undefined
</script>

<script type="module">
  alert(name); // Error, name not defined
</script>
```

- Use `<script type="module">` to indicate it's a module;
- Strict mode is implied for modules;
- Top level variables is in module scope;
- A module is evaluated only the first time when imported;
- `this` is undefined, insted of `window`;
- Module scripts are always deferred, for both external and inline scripts:
  - Downloading external module scripts doesn't block HTML processing, they load in parallel with other resources;
  - They are run after HTML is fully ready, this has implications:
    - Module scripts can access the whole document;
    - User may see the page before JS app is ready, you need 'loading indicators';
  - They are executed according to their order in the document;
- If an inline module script has `async` attribute, it loads independently of other scripts or the HTML, runs immediately when ready;
- External scripts from another origin requires CORS headers;
- A moudle must have a path;

## Error Handling

### Error

1. Common builtin Errors in JS

   ```js
   a; // ReferrenceError: not defined
   @@; // SyntaxError: invalid or unexpected token
   'a'.foo(); // TypeError: not a function
   Array(-2); // RangeError: bad arguments
   ```

2. You can create your own custom Error classes extending the builtin ones:

   ```js
   class MyError extends Error {
     consturctor(message) {
       super(message);
       this.name = 'MyError';
     }
   }
   ```

3. A `throw` statement terminates current code block (like `return`, `break`, `continue`), and passes control to the first `catch` block (you can throw any value, not just `Error` object, but it should be avoided);

### `try...catch...finally`

- [MDN - try...catch](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/try...catch)
- [MDN - onerror](https://developer.mozilla.org/en-US/docs/Web/API/GlobalEventHandlers/onerror)

1. Catch should only process expected errors and "rethrow" all others:

   ```js
   try {
     let user = JSON.parse(json);
     if (!user.name) {
       throw new SyntaxError('Imcomplete dat: no name');
     }

     notExistingFunction(); // unexpected error
   } catch (e) {
     if (e instanceof SyntaxErrorn) {
       // **handle known errors**
       console.log(e.name + ': ' + e.message);
     } else {
       throw e; // **rethrow unexpected errors here**
     }
   }
   ```

2. It only catches run-time errors, not parse-time errors;
3. It only catches synchronous errors, **not async ones** (you need `try..catch` inside the async code, or a promise chain):

   ```js
   try {
     setTimeout(() => {
       console.log('in setTimeout');
       throw new Error('throw in setTimeout'); // this error is not caught
     });
     console.log('in try');
   } catch (e) {
     console.log('in catch');
   }
   ```

4. `finally` block always executes, if it returns a value, it becomes the entire function's return value, regardless of any return statement or error thrown in `try` and `catch` blocks;

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
       return 3; // this will suppress the error
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

5. In a browser, when there is an unhandled error, it goes to `window.onerror`, it can be used for error logging;

### Promise

[javascript.info - Promise error handling](https://javascript.info/promise-error-handling)

[MDN - unhandledrejection](https://developer.mozilla.org/en-US/docs/Web/API/Window/unhandledrejection_event)

```js
new Promise((resolve, reject) => {
  reject('reject it');
})
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

1. A `finally` block always executes, it doesn't have access to the resolved result or the rejection error;
2. A `catch` block returns a resolved promise, unless it throws an error it self;
3. You should **always** add a `catch` to your promise chain;
4. In a browser, any unhandled rejection goes to the `unhandledrejection` event handler on `window`, it can be used for error logging;

### async/await errors

[javascript.info - async/await](https://javascript.info/async-await)

```js
const loadSomething = async () => {
  try {
    // **wrap try..catch around await
    const data = await fetchSomeData();
    return doSomethingWith(data);
  } catch (error) {
    logAndReport(error);
  }
};

// **top level .catch
loadSomething().catch(() => {
  // ...
});
```

1. The promise after `await` either resolves returning a value or throws an error;
2. You should use normal `try...catch..finally` block to handle errors in `async` function;
3. At the top level, `await` is not allowed, so you still need a `.catch` there to handle falling-through errors;

## Regular Expression

### Methods

- `str.match`

  ```js
  // ** with 'g', returns an array of all matches, no capturing groups
  'hello world'.match(/(.)o/g);
  // [ 'lo', 'wo' ]

  // ** without 'g', returns an array, containing the first match , capturing groups, and additional properties
  'hello world'.match(/(.)o/);
  // [ 'lo', 'l', index: 3, input: 'hello world', groups: undefined ]

  // ** no match, returns null
  'hello world'.match(/x/);
  // null
  ```

- `str.matchAll`

  ```js
  const matches = 'hello world'.matchAll(/(.)o/g);
  // Object [RegExp String Iterator] {}

  [...matches];
  // [
  //   [ 'lo', 'l', index: 3, input: 'hello world', groups: undefined ],
  //   [ 'wo', 'w', index: 6, input: 'hello world', groups: undefined ]
  // ]
  ```

  This is an improved version of `match`, it:

  - Returns an iterable object, instead of an array, this is for optimization purpose: it doesn't perform the search initially, only do it each time you iterate over it;
  - Contains the full result of each match, including capturing groups;

### Capturing groups

#### Named groups

- Use `(?<groupName>)` for named groups

  ```js
  const date = '2018-05-16';
  const re = /(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/;
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

- Use `\k<groupName>` for back referencing

  ```js
  const re = /(?<fruit>apple|orange) == \k<fruit>/;

  console.log(
    re.test('apple == apple'), // true
    re.test('apple == orange') // false
  );
  ```

  - Use `$<groupName>` in replacing string

  ```js
  const re = /(?<firstName>[a-zA-Z]+) (?<lastName>[a-zA-Z]+)/;

  console.log('Arya Stark'.replace(re, '$<lastName>, $<firstName>'));
  // Stark, Arya
  ```

#### Non-capturing groups

Use `(?:)` for a non-capturing group, you can still have quantifiers on it, but it won't be captured in a separate result item

```js
'gogogo gary'.match(/(?:go)+ (gary)/);
// [
//   'gogogo gary',
//   'gary',
//   index: 0,
//   input: 'gogogo gary',
//   groups: undefined
// ]
```

### Unicode

The `u` flag enables full unicode support:

- Handle 4-byte characters correctly,

  ```js
  '😄'.match(/./g);
  // [ '�', '�' ]

  '😄'.match(/./gu); // with `u`, 4-byte characters are processed correctlyk
  // [ '😄' ]
  ```

- Make Unicode property search available:

  Every character in Unicode has a lot of properties, such as `Letter`, `Number`, `Punctuation` etc., we can use `\p{..}` to match characters with paticular properties.

  Common character categories:

  - Letter `Lettter` `L`
    - lowercase `Ll`
    - uppercase `Lu`
  - Number `Number` `N`
  - Punctuation `Punctuation` `P`
    - dash `Pd`
    - ...
  - Hexadecimal `Hex_Digit`
  - ...

  ```js
  'H-'.match(/\p{Letter}\p{Pd}/gu);
  // [ 'H-' ]

  // match chinese hieroglyphs
  '你好'.match(/\p{Script=Han}/gu);
  // [ '你', '好' ]
  ```

### Escaping

```js
/\d\/\d/.test('2/3');
// true

new RegExp('\\d/\\d').test('2/3');
// true
```

- Forward slash '/' needs to be escaped in a regex literal as `\/`, not in `new RegExp()`;
- `\d` in a regex literal needs to be `'\\d'` in `new RegExp()` construct, since `'\d' === 'd'`;

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
  typeof null === 'object'; // null's type is 'object'
  ```

- **`undefined`: default value for uninitialized variables and parameters**

  - Always use `typeof x === 'undefined'` to check if a variable exists or not;
  - Comparison with `null`:

    - `undefined` is a super global variable, you can override it: `let undefined = 'foo'`, while `null` is a keyword;
    - `undeined` is of type `undefined`, `null` is of type `object`;

* **`typeof`**

  ```js
  var a = [1, 2];
  typeof a === 'object'; // typeof array returns 'object'
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
$(window).on('resize', function() {
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

### Currying

```js
function curry(func) {
  return function curried(...args) {
    if (args.length >= func.length) {
      return func.apply(this, args); // enough parameters, run
    } else {
      // otherwise return a function
      return function(...args2) {
        return curried.apply(this, args.concat(args2));
      };
    }
  };
}

function sum(a, b, c) {
  return a + b + c;
}

let curriedSum = curry(sum);

curriedSum(1, 2, 3); // 6, still callable normally
curriedSum(1)(2, 3); // 6, currying of 1st arg
curriedSum(1)(2)(3); // 6, full currying
```

### `Object.is()`

It's identical to `===` in most cases, except:

```js
NaN === NaN;
// false

Object.is(NaN, NaN);
// true
```

### Object property iteration methods comparison

- `Object.getOwnPropertyNames(obj)` returns non-symbol keys;
- `Object.getOwnPropertySymbols(obj)` returns symbol keys;
- `Object.keys/values()` returns non-symbol keys/values with enumerable flag;
- `for..in` loops over non-symbol keys with enumerable flag, and also prototype keys;

### `JSON.stringify` and `JSON.parse`

- If an object has a custom `toJSON` method, it's used to convert the object to JSON string:

  ```js
  const o = {
    id: 202,
    name: 'Gary',
    toJSON() {
      return this.id;
    }
  };

  JSON.stringify(o);
  // '202'
  ```

- Use replacer function in `JSON.stringify` to deal with circular referencing issue:

  ```js
  const member = { name: 'Gary' };
  const team = { name: 'Dev' };
  member.team = team;
  team.members = [member];

  team;
  // { name: 'Dev', members: [ { name: 'Gary', team: [Circular] } ] }

  JSON.stringify(team); // throws an error: circular references

  // #### using replacer function to ignore the 'team' key
  JSON.stringify(team, (key, value) => (key === 'team' ? undefined : value));
  // '{"name":"Dev","members":[{"name":"Gary"}]}'
  ```

- Use a reviver function to parse a string to a `Date` object

  ```js
  // #### JSON.stringify converts a Date to a string
  const s = JSON.stringify({ name: 'JS Conf', date: new Date() });
  // '{"name":"JS Conf","date":"2019-12-29T08:16:31.262Z"}'

  // #### JSON.parse doesn't convert a Date to a string
  JSON.parse(s);
  // { name: 'JS Conf', date: '2019-12-29T08:16:31.262Z' }

  // #### JSON.parse accepts a reviver function to do any data conversions
  JSON.parse(s, (key, value) => (key === 'date' ? new Date(value) : value));
  ```

## Reference

[JavaScript Symbols, Iterators, Generators, Async/Await, and Async Iterators — All Explained Simply
][symbol-iterator-etc]: **Read this one to fully understand the relations between Symbols, Iterators, Generators, Async/Await and Aync Iterators**

[symbol-iterator-etc]: https://medium.freecodecamp.org/some-of-javascripts-most-useful-features-can-be-tricky-let-me-explain-them-4003d7bbed32
[tc39 process]: https://tc39.github.io/process-document/
