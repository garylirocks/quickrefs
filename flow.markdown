Flow
=======
- [Flow](#flow)
  - [Overview](#overview)
    - [Flow vs. PropTypes](#flow-vs-proptypes)
  - [Setup](#setup)
    - [Config Babel to Strip Flow Annotations](#config-babel-to-strip-flow-annotations)
    - [Prepare Your Files for Flow](#prepare-your-files-for-flow)
  - [Type System](#type-system)
    - [Depth Subtyping](#depth-subtyping)
  - [Type Annotations](#type-annotations)
    - [Primitive Types](#primitive-types)
    - [Literal Types](#literal-types)
    - [Maybe Types](#maybe-types)
    - [Any Type](#any-type)
    - [Mixed](#mixed)
    - [Variable Types](#variable-types)
    - [Function Types](#function-types)
    - [Object Types](#object-types)
    - [Array Types](#array-types)
    - [Tuple Types](#tuple-types)
    - [Class Types](#class-types)
    - [Interface Types](#interface-types)
    - [Type Aliases](#type-aliases)
    - [Module Types](#module-types)
    - [Opt-out types](#opt-out-types)
  - [Optional Parameters or Properties](#optional-parameters-or-properties)
    - [Optional function parameters](#optional-function-parameters)
    - [Function params with defaults](#function-params-with-defaults)
    - [Optional object properties](#optional-object-properties)
  - [React](#react)
    - [Class Component example:](#class-component-example)
    - [Functional Component example](#functional-component-example)
    - [Event Handling](#event-handling)
    - [ref functions](#ref-functions)
    - [Children](#children)
    - [Higher-order Components](#higher-order-components)
    - [Context](#context)
    - [Redux](#redux)
  - [Strict Mode](#strict-mode)
  - [Refs](#refs)


## Overview

* Static type checker, identify problems in compile time;
* Improve developer workflow by adding features like auto-completion;

### Flow vs. PropTypes

* It's [recommended for larger code bases][react-doc-flow] instead of `PropTypes`, which it's going to [replace in the long term][flow-replaces-proptypes];
* There are Babel plugins which will generate `PropTypes` from Flow types such as `babel-plugin-react-flow-props-to-prop-types` if you want both static and runtime checks;


## Setup

```sh
# install Flow
yarn add -D flow-bin

# add a script to package.json
# "scripts": {
#    "flow": "flow",
# }

# run this command to add a Flow config file
yarn flow init

# run Flow, it starts a background process, monitoring files and do checking in real time
yarn flow
```

### Config Babel to Strip Flow Annotations

```sh
yarn add -D babel-preset-flow
```

add the `flow` preset to `.babelrc`

```json
{
  "presets": [ 
    "flow",
    "react"
  ]
}
```


### Prepare Your Files for Flow

By default, Flow only checks files that include this annotation:

```js
// @flow
```

it's usually placed at the top of a file

you can alos check all files with

```sh
flow check --all
```


## Type System

* Every value and expression has a type;
* Flow analyze the code statically to figure out type of each expression;
* Flow uses structural typing for objects and functions, but nominal typing for classes (you can use `Interface` for structural typing);

### Depth Subtyping

```js
// @flow
class Person { name: string }
class Employee extends Person { department: string }

var employee: Employee = new Employee;
var person: Person = employee;            // OK, pass a subtype instance to a supertype

var employee: { who: Employee } = { who: new Employee };
// $ExpectError
var person: { who: Person } = employee;   // Error, passing an object containing a subtype instance to an object containing a supertype
```

this is because objects are mutable, if you update `person.who`, `employee.who` get changed as well

```js
person.who = new Person;
```

We can use a plus sign to indicate the `who` property is "covariant", this makes it read-only, and allows us to use objects which have subtype-compatible values for that property:

```js
// @flow
class Person { name: string }
class Employee extends Person { department: string }

var employee: { who: Employee } = { who: new Employee };
var person: { +who: Person } = employee;    // OK
// $ExpectError
person.who = new Person;                    // Error!
```









## Type Annotations

### Primitive Types

there are `number`, `string`, `boolean`, `null`, `void` (for `undefined`):

```js
// @flow
function method(x: number, y: string, z: boolean) {
  // ...
}

method(3.14, "hello", true);
```

or use the constructed wrapper objects like `Number`, `String`, etc:

```js
// @flow
function method(x: Number, y: String, z: Boolean) {
  // ...
}

method(new Number(42), new String("world"), new Boolean(false));
```

### Literal Types

literal values (e.g.: `true`, `2`, `foo`) can be used as types as well:

```js
function acceptsTwo(value: 2) {
  // ...
}
```

### Maybe Types

`?number` would mean `number`, `null`, or `undefined`

```js
// @flow
function acceptsMaybeNumber(value: ?number) {
  // ...
}
```

### Any Type

It outs out type checker, it's **unsafe**, **should be avoided** when possible, the only use cases:

  * you are in the process of converting existing code base;
  * you are sure the Flow is not working correctly;

```js
// @flow
function add(one: any, two: any): number {
  return one + two;
}

add(1, 2);     // Works.
add("1", "2"); // Works.
add({}, []);   // Works.
```

avoid leaking `any`, cutting `any` off as soon as possible

```js
// @flow
function fn(obj: any) {
  let foo: number = obj.foo;    // type foo to be number here
  let bar = foo * 2;
  return bar;
}

let bar /* (:number) */ = fn({ foo: 2 });
``` 

### Mixed

accept any type, you must first figure out what the actual type is when you use a `mixed` value

```js
// @flow
function stringify(value: mixed) {
  if (typeof value === 'string') {    // this refinement is required, otherwise would end up in an error
    return "" + value; // Works!
  } else {
    return "";
  }
}

stringify("foo");
```

### Variable Types

When you declare a new variable: 
  * you may optionally declare its type, when you re-assign, the value must be of a compatible type;
  * or, Flow will infer the type from the value;

```js
const constVar: number = 2;
let letVar: string = 'foo';

letVar = 3;       // Error! type not compatible

let myVar = 10;   // Flow infers the type to be 'number'
```

### Function Types

```js
// @flow

// general example
function foo(str: string, bool?: boolean, ...nums: Array<number>): void {
  // ...
}

function foo2(func: () => mixed) {
  // ...
}
```

* `bool` is optional;
* `nums` must be of type `Array`;
* use `() => mixed` for arbitrary functions;

### Object Types

```js
var obj: {
  name: string,
  age?: number,             // optional property
  [year: string]: boolean,  // indexer property, allows reads and writes using any key of matching type
} = {
  name: 'Gary',
  age: 20,
  '2018': true,
  '2019': false,
};
```

### Array Types

Annotate arrays with `Array<T>`, which has a shorthand syntax: `Type[]`

```js
let arr1: Array<boolean> = [true, false];
let arr2: number[] = [1, 2, 3];

let arr3: (?number)[] = [1, null, 2]; // optional number type
```

`$ReadOnlyArray<T>` would not allow you to mutate the array

```js
// @flow
const readonlyArray: $ReadOnlyArray<number> = [1, 2, 3]

const first = readonlyArray[0] // OK to read
readonlyArray[1] = 20          // Error!
readonlyArray.push(4)          // Error!

// often used to annotate function parameters
const someOperation = (arr: $ReadOnlyArray<number | string>) => {
  // Nothing can be added to `arr`
}

const array: Array<number> = [1]
someOperation(array) // Works!
```

### Tuple Types

```js
let tuple2: [number, boolean] = [1, true];

let num: number = tuple2[0];

// Error! the length of a tuple is strictly enforced
let newTuple: [number] = tuple2;

// Error! tuple can't be assigned to an array
let array: number[] = tuple2;

// Error! can't mutate a tuple
tuple.push(3);
```

### Class Types

You can use the name of a class as a type, annotate class fields and methods within the class definition;

```js
class Person {
  name: string;
  age: number;
  increaseAge(value: number): number {
    // ...
  }
}

let gary: Person = new Person();
```

class generics, the parameters need to be passed when you use it:

```js
// @flow
class MyClass<A, B, C> {
  constructor(arg1: A, arg2: B, arg3: C) {
    // ...
  }
}

var val: MyClass<number, boolean, string> = new MyClass(1, true, 'three');
```

### Interface Types

```js
// interface types syntax is similar to object types
interface PersonInterface {
  name: string,
  age: number,
  hairColor: ?string,
  [key: string]: number,
}

// interface types can be implemented
class Person implements PersonInterface {
  // ...
}

// you can make properties read-only (covariant) or write-only (contravariant)
interface MyInterface {
  +covariant: number;     // read-only
  -contravariant: number; // write-only
}
```


### Type Aliases

```js
type NumberAlias = number;
type ObjectAlias = {
  property: string,
  method(): number,       // method is a function returning a number
};
type UnionAlias = 1 | 2 | 3;
type AliasAlias = ObjectAlias;

// generic type alias
type MyObject<A, B, C> = {
  property: A,
  method(val: B): C,
};
```

### Module Types

`exports.js`

```js
// @flow
export default class Foo {};
export type MyObject = { /* ... */ };
export interface MyInterface { /* ... */ };
```

`imports.js`

```js
// @flow
import type Foo, {MyObject, MyInterface} from './exports';
```


### Opt-out types

`any`, `Object`, `Function` lets you opt-out of type checker, they should be avoided;


## Optional Parameters or Properties

### Optional function parameters

```js
// @flow
function acceptsOptionalString(value?: string) {
  // ...
}
```

this is different from a maybe type, `value` can be `string`, `undefined` or omitted, but it **CAN'T** be `null`

### Function params with defaults

```js
// @flow
function acceptsOptionalString(value: string = "foo") {
  // ...
}
```

`value` can be `string`, `undefined` or omitted, **CAN'T** be `null`

### Optional object properties

```js
// @flow
function acceptsObject(value: { foo?: string }) {
  // ...
}
```

`foo` can be `string`, `undefined` or omitted, **CAN'T** be `null`


## React

### Class Component example:

```js
import * as React from 'react';

// add a Flow object type
type Props = {
  foo: number,
  bar?: string,
};

// use Props type
class MyComponent extends React.Component<Props> {
  // defaultProps is supported
  static defaultProps = {
    foo: 100
  };

  render() {
    this.props.doesNotExist; // Error! You did not define a `doesNotExist` prop.
    return <div>{this.props.bar}</div>;
  }
}

<MyComponent foo={42} />;
```

* if you only need `Props` type once, you can define it inline `React.Component<{ foo: number, bar?: string }>`;
* `React.Component<Props, State>` is a generic type that takes two arguments, `State` is optional, omitted above;

### Functional Component example

```js
import * as React from 'react';

type Props = {
  foo: number, // foo is required.
};

function MyComponent(props: Props) {}

MyComponent.defaultProps = {
  foo: 42, // ...but we have a default prop for foo.
};

// So we don't need to include foo.
<MyComponent />;
```

### Event Handling

```js
import * as React from 'react';

class MyComponent extends React.Component<{}, { count: number }> {
  handleClick = (event: SyntheticEvent<HTMLButtonElement>) => {
    // To access your button instance use `event.currentTarget`.
    (event.currentTarget: HTMLButtonElement);

    this.setState(prevState => ({
      count: prevState.count + 1,
    }));
  };

  render() {
    return (
      <div>
        <p>Count: {this.state.count}</p>
        <button onClick={this.handleClick}>
          Increment
        </button>
      </div>
    );
  }
}
```

* React provides `SyntheticEvent<T>`, the `T` is the type of the HTML element the event handler was placed on, you can also use it with no type arguments like: `SyntheticEvent<>`;
* React uses its own event system, ou need to use `SyntheticEvent` instead of the DOM types such as `Event`, `MouseEvent`;
* A list of the events:
    * `SyntheticEvent<T>` for `Event`
    * `SyntheticAnimationEvent<T>` for `AnimationEvent`
    * `SyntheticCompositionEvent<T>` for `CompositionEvent`
    * `SyntheticInputEvent<T>` for `InputEvent`
    * `SyntheticUIEvent<T>` for `UIEvent`
    * `SyntheticFocusEvent<T>` for `FocusEvent`
    * `SyntheticKeyboardEvent<T>` for `KeyboardEvent`
    * `SyntheticMouseEvent<T>` for `MouseEvent`
    * `SyntheticDragEvent<T>` for `DragEvent`
    * `SyntheticWheelEvent<T>` for `WheelEvent`
    * `SyntheticTouchEvent<T>` for `TouchEvent`
    * `SyntheticTransitionEvent<T>` for `TransitionEvent`

### ref functions

```js
import * as React from 'react';

class MyComponent extends React.Component<{}> {
  // The `?` here is important because you may not always have the instance.
  button: ?HTMLButtonElement;

  render() {
    return <button ref={button => (this.button = button)}>Toggle</button>;
  }
}
```

### Children

### Higher-order Components

### Context

### Redux




## Strict Mode

use 

```js
// @flow strict
```

to enable strict mode for current file, it enables strict rules


## Refs

* [React Doc - Static Type Checking][react-doc-flow]
* [Dan Abramov Twitter][flow-replaces-proptypes]


[react-doc-flow]: https://reactjs.org/docs/static-type-checking.html
[flow-replaces-proptypes]:  https://twitter.com/dan_abramov/status/745700243216437248?lang=en