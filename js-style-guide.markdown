JS Style Guide
==============

- [Refs](#refs)
- [Variable declaration](#variable-declaration)
- [Object](#object)
- [Arrays](#arrays)
- [Destructuring](#destructuring)
- [Strings](#strings)
- [Functions](#functions)
- [Arrow functions](#arrow-functions)
- [Modules](#modules)
- [Iterators and Generators](#iterators-and-generators)
- [Properties](#properties)
- [Variables](#variables)
- [Comparison Operators & Equality](#comparison-operators--equality)
- [Comments](#comments)
- [Whitespace](#whitespace)
- [Semicolons](#semicolons)
- [Type casting & Coercion](#type-casting--coercion)
- [Naming Conventions](#naming-conventions)
- [Events](#events)
- [jQuery](#jquery)
- [Standard Library](#standard-library)
- [Test](#test)

## Refs

* [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript/blob/master/README.md#airbnb-javascript-style-guide-)
* [Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html)
* [Popular JS Coding Convention on GitHub](http://sideeffect.kr/popularconvention/#javascript)

## Variable declaration

always use `const` or `let`, **DO NOT** use `var`


## Object

* use computed property names:

```javascript
const obj = {
  id: 5,
  [getKey('x')]: true
}
```

* user property value shorthand (put it at the top), use object method shorthand:

```javascript
const name = 'Gary';

const obj = {
    name,                       // property value shorthand

    getName() {                 // object method shorthand
        return this.name;
    }
}
```

* only quote properties that are invalid identifiers:

```javaScript
const obj = {
    name: 'Gary',           // don't quote
    'anormal-key': 20       // only quote this
}
```

* prefer object spread operator over `Object.assign` to shallow-copy objects, and get new object without certain properties:

```javascript
const original = { a: 1, b: 2 };
const copy = { ...original, c: 3 }; // copy => { a: 1, b: 2, c: 3 }

const { a, ...noA } = copy; 		// noA => { b: 2, c: 3 }
```


## Arrays

* use line breaks after open and before close array brackets if an array has multiple lines

> **add a trailing comma to the last item as well**

```javascript
const arr = [
    1,
    2,
];
```

* use spreads `...` to copy arrays

```javascript
const itemsCopy = [...items];
```

* convert an array-like object to array using spreads `...`

```javascript
const foo = document.querySelectorAll('.foo');

// good
const nodes = Array.from(foo);

// best
const nodes = [...foo];
```

## Destructuring

* use object destructuring, it avoids creating temporary references

```javascript
// bad
function getFullName(user) {
  const firstName = user.firstName;
  const lastName = user.lastName;

  return `${firstName} ${lastName}`;
}

// good
function getFullName(user) {
  const { firstName, lastName } = user;
  return `${firstName} ${lastName}`;
}

// best
function getFullName({ firstName, lastName }) {
  return `${firstName} ${lastName}`;
}
```

* use array destructuring

```javascript
const arr = [1, 2, 3];

const [first, second] = arr;    // order is important for array destructuring
```

* use object destructring when returning multiple values, so the caller do not need to no the order of properties

```javascript
// bad
function foo() {
    // ...
    return [x, y, z];
}

const [x, __, z] = foo();   // caller needs to know the order

// good
function foo() {
    // ...
    return {x, y, z};
}

const {x, z} = foo();       // caller doesn't need to care about the order
```

## Strings

* use single quote `'` for strings

* long strings should not be broken into multiple lines, **broken strings make code less searchable**

```javascript
// bad
const errorMessage = 'This is a super long error that was thrown because \
of Batman. When you stop to think about how Batman had anything to do \
with this, you would get nowhere \
fast.';

// bad (Google Guide suggests this)
const errorMessage = 'This is a super long error that was thrown because ' +
  'of Batman. When you stop to think about how Batman had anything to do ' +
  'with this, you would get nowhere fast.';

// good
const errorMessage = 'This is a super long error that was thrown because of Batman. When you stop to think about how Batman had anything to do with this, you would get nowhere fast.';
```

* use template strings instead of concatenation

```javascript
// bad
function sayHi(name) {
  return 'How are you, ' + name + '?';
}

// bad
function sayHi(name) {
  return ['How are you, ', name, '?'].join();
}

// bad
function sayHi(name) {
  return `How are you, ${ name }?`;
}

// good
function sayHi(name) {
  return `How are you, ${name}?`;
}
```

## Functions

* use function expressions instead of function declarations, *function declaration is hoisted*

```javascript
// bad
function foo() {
    // ...
}

// better
const foo = function() {

}

// best, this helps debugging
const foo = function aLongAndDescriptiveName() {

}
```

* wrap IIFE (immediately invoked function expresss) in parentheses

```javascript
(function() {
    // ...
}());
```

* never declare a function in a non-function block (`if`, `while`, etc)

```javascript
// bad
if (currentUser) {
  function test() {
    console.log('Nope.');
  }
}

// good
let test;
if (currentUser) {
  test = () => {
    console.log('Yup.');
  };
}
```

* never use `arguments`, use rest syntax `...` instead

```javascript
// bad
function concatenateAll() {
  const args = Array.prototype.slice.call(arguments);   // arguments is not a true array, only an array like object
  return args.join('');
}

// good
function concatenateAll(...args) {
  return args.join('');     // args is a true array
}
```

* use default parameter syntax rather than mutating function arguments

```javascript
// bad
function foo(id) {
    id = id || 1;
}

// good
function foo(id = 1) {

}
```

* spacing in a function signature

```javascript
// bad
const f = function(){};
const g = function (){};
const h = function() {};

// good
const x = function () {};
const y = function a() {};
```

* never reassign parameters, make a copy

> reassigning can cause optimization issues

```javascript
// bad
function f1(a) {
  a = 1;
  // ...
}

function f2(a) {
  if (!a) { a = 1; }
  // ...
}

// good
function f3(a) {
  const b = a || 1;
  // ...
}

function f4(a = 1) {
  // ...
}
```

* functions with multiline signature, or invocations, each item should be on a line by itself, with a trailing comma for the last item

```javascript
function foo(
    name,
    age,            // <- trailing comma here
) {
    // ...
}

console.log(
    name,
    age,            // <- trailing comma here
);
```

## Arrow functions

* prefer arrow functions as inline callback functions


## Modules

* always use modules (`export/import`) instead of a non-standard module system (`require`, etc)

* do not use wildcard imports

* do not export mutable bindings

```javascript
// bad
let name = 'gary';
export { name };

// good
const name = 'gary';
export { name };
```

* if a module only exports one thing, prefer default export

```javascript
// bad
export function foo() {}

// good
export default function foo() {}        // <- use default
```

* it's fine to use multiline imports

```javascript
// bad
import {longNameA, longNameB, longNameC, longNameD, longNameE} from 'path';

// good
import {
  longNameA,
  longNameB,
  longNameC,
  longNameD,
  longNameE,
} from 'path';
```


## Iterators and Generators

* **Don't use iterators**, prefer JS's higher-order functions instead of loops like `for-in` or `for-of`

    * Use `map()` / `every()` / `filter()` / `find()` / `findIndex()` / `reduce()` / `some()` / ... to iterate over arrays
    * and `Object.keys()` / `Object.values()` / `Object.entries()` to produce arrays so you can iterate over objects

```javascript
const arr = [1, 2, 3];

const sum = arr.reduce((total, e) => total + e, 0);

const newArr = arr.map(e => e + 1);

const obj = {
    name: 'gary',
    age: 20,
};

Object.values(obj);     // ['gary', 20]
```

* don't use generators for now, if you must, use the following syntax,
`function*` is a unique construct

```javascript
const foo = function* () {
    // ...
}
```


## Properties

* use dot notation whenever possible, only use `[]` when accessing properties with a variable


## Variables

* use one `const` or `let` declaration per variable

> easier to debug, easier when adding new variables

```javascript
// bad
const items = getItems(),
    goSportsTeam = true,
    dragonball = 'z';

// good
const items = getItems();
const goSportsTeam = true;
const dragonball = 'z';
```

* group all `const`s then all `let`s

```javascript
// good
const goSportsTeam = true;
const items = getItems();
let dragonball;
let i;
let length;
```

* don't chain variable assignment, which creates implicit global variables

```javascript
// bad
(function example() {
  // JavaScript interprets this as
  // let a = ( b = ( c = 1 ) );
  // The let keyword only applies to variable a; variables b and c become
  // global variables.
  let a = b = c = 1;
}());

console.log(a); // throws ReferenceError
console.log(b); // 1
console.log(c); // 1

// good
(function example() {
  let a = 1;
  let b = a;
  let c = a;
}());

console.log(a); // throws ReferenceError
console.log(b); // throws ReferenceError
console.log(c); // throws ReferenceError

// the same applies for `const`
```

## Comparison Operators & Equality

* always use `===` and `!==` over `==` and `!=`;

* conditional statement (`if` etc) evaluation rules

    * **Object** -> `true`
    * **undefined** -> `false`
    * **NULL** -> `false`
    * for numbers, `+0`, `-0`, `NaN` -> `false`, otherwise `true`
    * for strings, `''` -> `false`, otherwise `true`
    * an **array** is an object, so it's always `true`

```javascript
if ([0] && []) {
  // true
  // an array (even an empty one) is an object, objects will evaluate to true
}
```

* use shortcut for booleans, but explicit comparisons for strings and numbers

```javascript
// bad
if (isValid === true) {
  // ...
}

// good
if (isValid) {
  // ...
}

// bad
if (name) {
  // ...
}

// good
if (name !== '') {
  // ...
}

// bad
if (collection.length) {
  // ...
}

// good
if (collection.length > 0) {
  // ...
}
```

* Use braces to create blocks in `case` and `default` clauses that contain lexical declarations (e.g. `let`, `const`, `function`, and `class`)

```javascript
// bad
switch (foo) {
  case 1:
    let x = 1;
    break;
  case 2:
    const y = 2;
    break;
  case 3:
    function f() {
      // ...
    }
    break;
  default:
    class C {}
}

// good
switch (foo) {
  case 1: {
    let x = 1;
    break;
  }
  case 2: {
    const y = 2;
    break;
  }
  case 3: {
    function f() {
      // ...
    }
    break;
  }
  case 4:
    bar();
    break;
  default: {
    class C {}
  }
}
```

* avoid unneeded ternary statements

```javascript
// bad
const foo = a ? a : b;
const bar = c ? true : false;
const baz = c ? false : true;

// good
const foo = a || b;
const bar = !!c;
const baz = !c;
```

## Comments

* use `/** */` for multi-line comment

* use `//` for a single line comment, and always put it on a new line above the subject of the comment, insert an empty line before the comment unless it's on the first line of a block

```javascript
// bad
const active = true;  // is current tab

// good
// is current tab
const active = true;

// bad
function getType() {
  console.log('fetching type...');
  // set the default type to 'no type'
  const type = this.type || 'no type';

  return type;
}

// good
function getType() {
  console.log('fetching type...');

  // set the default type to 'no type'
  const type = this.type || 'no type';

  return type;
}

// also good
function getType() {
  // set the default type to 'no type'
  const type = this.type || 'no type';

  return type;
}
```

* start all comments with a space

* use `// FIXME:` to annotate problems

```javascript
class Calculator extends Abacus {
  constructor() {
    super();

    // FIXME: shouldn’t use a global here
    total = 0;
  }
}
```

* use `// TODO:` to annotate solutions to problems

```javascript
class Calculator extends Abacus {
  constructor() {
    super();

    // TODO: total should be configurable by an options param
    this.total = 0;
  }
}
```

## Whitespace

* use soft tabs (space character) set to **2 spaces**

* place 1 space before the opening brace

```javascript
// good
function test() {                   // <- one space before the brace
  console.log('test');
}

// good
dog.set('attr', {                   // <- one space before the brace
  age: '1 year',
  breed: 'Bernese Mountain Dog',
});
```

* 1 space before the opening parenthesis in control statements (`if`, `while` etc), but **no space** between the function name and the argument list

```javascript
// good
if (isJedi) {                   // <- space after if
  fight();
}

// good
function fight() {              // <- no space after function name
  console.log('Swooosh!');      // <- no space after function name
}
```

* end files with a single newline character

```javascript
// good
import { es6 } from './AirbnbStyleGuide';
  // ...
export default es6;↵
```

* use indentation when making more than 2 method chains, use a leading dot on each line

```javascript
// good
const leds = stage.selectAll('.led')
    .data(data)
  .enter().append('svg:svg')
    .classed('led', true)
    .attr('width', (radius + margin) * 2)
  .append('svg:g')
    .attr('transform', `translate(${radius + margin},${radius + margin})`)
    .call(tron.led);

// good
const leds = stage.selectAll('.led').data(data);
```

* leave a blank line after blocks and before the next statement

```javascript
// bad
if (foo) {
  return bar;
}
return baz;

// good
if (foo) {
  return bar;
}

return baz;

// bad
const obj = {
  foo() {
  },
  bar() {
  },
};
return obj;

// good
const obj = {
  foo() {
  },

  bar() {
  },
};

return obj;

// bad
const arr = [
  function foo() {
  },
  function bar() {
  },
];
return arr;

// good
const arr = [
  function foo() {
  },

  function bar() {
  },
];

return arr;
```

* do not add space inside parenthesis

```javascript
// bad
function bar( foo ) {
  return foo;
}

// good
function bar(foo) {
  return foo;
}

// bad
if ( foo ) {
  console.log(foo);
}

// good
if (foo) {
  console.log(foo);
}
```

* do not add spaces inside brackets

```javascript
// bad
const foo = [ 1, 2, 3 ];
console.log(foo[ 0 ]);

// good
const foo = [1, 2, 3];
console.log(foo[0]);
```

* add spaces inside curly braces

```javascript
// bad
const foo = {clark: 'kent'};

// good
const foo = { clark: 'kent' };
```

* avoid having lines of code that are longer than 100 characters (long strings are emxempt from this rule)

* additional trailing comma

" this leads to cleaner git diffs, and transpilers like Babel will remove the additional trailing comma in the tranpiled code

```javascript
// bad - git diff without trailing comma
const hero = {
     firstName: 'Florence',
-    lastName: 'Nightingale'
+    lastName: 'Nightingale',
+    inventorOf: ['coxcomb chart', 'modern nursing']
};

// good - git diff with trailing comma
const hero = {
     firstName: 'Florence',
     lastName: 'Nightingale',
+    inventorOf: ['coxcomb chart', 'modern nursing'],
};


// bad
const hero = {
  firstName: 'Dana',
  lastName: 'Scully'
};

const heroes = [
  'Batman',
  'Superman'
];

// good
const hero = {
  firstName: 'Dana',
  lastName: 'Scully',
};

const heroes = [
  'Batman',
  'Superman',
];

// bad
function createHero(
  firstName,
  lastName,
  inventorOf
) {
  // does nothing
}

// good
function createHero(
  firstName,
  lastName,
  inventorOf,
) {
  // does nothing
}

// good (note that a comma must not appear after a "rest" element)
function createHero(
  firstName,
  lastName,
  inventorOf,
  ...heroArgs
) {
  // does nothing
}

// bad
createHero(
  firstName,
  lastName,
  inventorOf
);

// good
createHero(
  firstName,
  lastName,
  inventorOf,
);

// good (note that a comma must not appear after a "rest" element)
createHero(
  firstName,
  lastName,
  inventorOf,
  ...heroArgs
);
```

## Semicolons

* **always use a semicolon to terminate your statements explicitly**

## Type casting & Coercion

* do type coercion at the beginning of the statement

* Strings

```javascript
// => this.reviewScore = 9;

// bad
const totalScore = new String(this.reviewScore); // typeof totalScore is "object" not "string"

// bad
const totalScore = this.reviewScore + ''; // invokes this.reviewScore.valueOf()

// bad
const totalScore = this.reviewScore.toString(); // isn’t guaranteed to return a string

// good
const totalScore = String(this.reviewScore);
```

* Numbers, use `Number` for type casting and `parseInt` always with a radix for parsing strings

```javascript
const inputValue = '4';

// bad
const val = new Number(inputValue);

// bad
const val = +inputValue;

// bad
const val = inputValue >> 0;

// bad
const val = parseInt(inputValue);

// good
const val = Number(inputValue);

// good
const val = parseInt(inputValue, 10);
```

* Booleans, use `!` or `!!`

```javascript
const age = 0;

// bad
const hasAge = new Boolean(age);

// good
const hasAge = Boolean(age);

// best
const hasAge = !!age;
```

## Naming Conventions

* use camelCase when naming objects, functions and instances

* use PascalCase (upper camel case) only when naming constructors or classes

* don't use leading underscores to denotate "private", there is no privacy in JS

* don't save references to `this`, use **arrow functions**

```javascript
// bad
function foo() {
  const self = this;
  return function () {
    console.log(self);
  };
}

// bad
function foo() {
  const that = this;
  return function () {
    console.log(that);
  };
}

// good
function foo() {
  return () => {
    console.log(this);
  };
}
```

* a base filename should exactly match the name of its default export

```javascript
// file 1 -> should be named CheckBox.js
class CheckBox {
  // ...
}
export default CheckBox;

// file 2 -> should be named fortyTwo.js
export default function fortyTwo() { return 42; }

// file 3 -> should be named insideDirectory.js
export default function insideDirectory() {}

// in another file
// good
import CheckBox from './CheckBox'; // PascalCase export/import/filename
import fortyTwo from './fortyTwo'; // camelCase export/import/filename
import insideDirectory from './insideDirectory'; // camelCase export/import/directory name/implicit "index"
// ^ supports both insideDirectory.js and insideDirectory/index.js
```

* Acronyms and initialisms should always be all capitalized, or all lowercased.

```javascript
// bad
import SmsContainer from './containers/SmsContainer';

// bad
const HttpRequests = [
  // ...
];

// good
import SMSContainer from './containers/SMSContainer';

// good
const HTTPRequests = [
  // ...
];

// also good
const httpRequests = [
  // ...
];

// best
import TextMessageContainer from './containers/TextMessageContainer';

// best
const requests = [
  // ...
];
```

**Google suggests differently**

| Prose form              | Correct           | Incorrect                         |
| ----------------------- | ----------------- | --------------------------------- |
| "XML HTTP request"      | XmlHttpRequest    | XMLHTTPRequest                    |
| "new customer ID"       | newCustomerId     | newCustomerID                     |
| "inner stopwatch"       | innerStopwatch    | innerStopWatch                    |
| "supports IPv6 on iOS?" | supportsIpv6OnIos | supportsIPv6OnIOS                 |
| "YouTube importer"      | YouTubeImporter   | YoutubeImporter (not recommended) |

* optionally uppercase a constant only if it (1) is exported, (2) is a const (it can not be reassigned), and (3) the programmer can trust it (and its nested properties) to never change

    * constants within a file should not be uppercased
    * for exported objects, only uppercase at the top level of export (e.g. `EXPORTED_OBJECTS.key`)

```javascript
// allowed but does not supply semantic value
export const apiKey = 'SOMEKEY';

// better in most cases
export const API_KEY = 'SOMEKEY';

// ---

// bad - unnecessarily uppercases key while adding no semantic value
export const MAPPING = {
  KEY: 'value'
};

// good
export const MAPPING = {
  key: 'value'
};
```

## Events

* when attaching data payload to an event, use an object literal instead of a raw value. This allows subsequently adding more data to the payload withoud updating every handler

```javascript
// bad
$(this).trigger('listingUpdated', listing.id);

$(this).on('listingUpdated', (e, listingID) => {
  // do something with listingID
});


// good
$(this).trigger('listingUpdated', { listingID: listing.id });

$(this).on('listingUpdated', (e, data) => {
  // do something with data.listingID
});

```

## jQuery

*  Prefix jQuery object variables with a `$`

```javascript
// bad
const sidebar = $('.sidebar');

// good
const $sidebar = $('.sidebar');

// good
const $sidebarBtn = $('.sidebar-btn');
```

* Cache jQuery lookups

```javascript
// bad
function setSidebar() {
  $('.sidebar').hide();

  // ...

  $('.sidebar').css({
    'background-color': 'pink',
  });
}

// good
function setSidebar() {
  const $sidebar = $('.sidebar');
  $sidebar.hide();

  // ...

  $sidebar.css({
    'background-color': 'pink',
  });
}
```

* use `find` with scoped jQuery object queries

```javascript
// bad
$('ul', '.sidebar').hide();

// bad
$('.sidebar').find('ul').hide();

// good
$('.sidebar ul').hide();

// good
$('.sidebar > ul').hide();

// good
$sidebar.find('ul').hide();
```

## Standard Library

The [Standard Library](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects) contains utilities that are functionally broken but remain for legacy reasons.

* use `Number.isNaN` instead of global `isNaN`

> the global `isNaN` coerces non-numbers to numbers

* use `Number.isFinite` instead of global `isFinite`

> the global `isFinite` coerces non-numbers to numbers


## Test

* **you should write tests !!**

* Whenever you fix a bug, write a *regression test*. A bug fixed without a regression test is almost certainly going to break again in the future
