Flow
=======
- [Flow](#flow)
  - [Overview](#overview)
    - [Flow vs. PropTypes](#flow-vs-proptypes)
  - [Setup](#setup)
    - [Config Babel to Strip Flow Annotations](#config-babel-to-strip-flow-annotations)
    - [Prepare Your Files for Flow](#prepare-your-files-for-flow)
  - [Type Annotations](#type-annotations)
    - [Primitive Types](#primitive-types)
    - [Maybe Types](#maybe-types)
  - [Optional Parameters or Properties](#optional-parameters-or-properties)
    - [Optional function parameters](#optional-function-parameters)
    - [Function params with defaults](#function-params-with-defaults)
    - [Optional object properties](#optional-object-properties)
  - [React](#react)
    - [Class Component example:](#class-component-example)
    - [Functional Component example](#functional-component-example)
    - [Event Handling](#event-handling)
    - [ref functions](#ref-functions)
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

### Maybe Types

`?number` would mean `number`, `null`, or `undefined`

```js
// @flow
function acceptsMaybeNumber(value: ?number) {
  // ...
}
```

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