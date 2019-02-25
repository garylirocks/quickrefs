# React

- [General Ideas](#general-ideas)
- [State and Props](#state-and-props)
- [State](#state)
  - [Initializing](#initializing)
  - [Updating](#updating)
- [Components](#components)
  - [Presentational vs. Container](#presentational-vs-container)
    - [Presentational](#presentational)
    - [Container](#container)
    - [How to do it](#how-to-do-it)
  - [How to bind event handlers](#how-to-bind-event-handlers)
  - [Controlled vs. Uncontrolled Components](#controlled-vs-uncontrolled-components)
- [Example with lifecycle functions](#example-with-lifecycle-functions)
  - [v16.4](#v164)
  - [Before v16.3](#before-v163)
- [PropTypes](#proptypes)
- [JSX Syntaxes](#jsx-syntaxes)
- [Context](#context)
- [Refs and the DOM](#refs-and-the-dom)
  - [`ref` on DOM element](#ref-on-dom-element)
  - [`ref` on Components](#ref-on-components)
  - [Another way to create `ref` since v16.3](#another-way-to-create-ref-since-v163)
  - [Error Handling](#error-handling)
- [Hooks](#hooks)
  - [State Hooks](#state-hooks)
  - [Effect Hooks](#effect-hooks)
  - [Custom Hooks](#custom-hooks)
  - [Other Hooks](#other-hooks)
  - [Rules of Hooks](#rules-of-hooks)
- [Styling](#styling)
- [`ReactDOMServer`](#reactdomserver)
- [SSR - Server Side Rendering](#ssr---server-side-rendering)

## General Ideas

- HTML is written in JavaScript (usually JSX), so react can construct a virtual DOM;

## State and Props

- props are fixed, can not be changed
- state is dynamic, can be changed, is private and fully controlled by the component

## State

### Initializing

with ES6 class syntax, add a `state` property to the class

    class Book extends React.Component {
        state = {
            title: 'Moby Dick',
            ...
        }

        ...
    }

### Updating

- always use `this.setState({})` to update the state
- state updates may be asynchronous, if new state is depended upon the previous state, use the second form of `setState()`:

        this.setState((prevState, props) => ({
            counter: prevState.counter + props.increment
        }));

## Components

read [Dan Abramov's article](https://medium.com/@dan_abramov/smart-and-dumb-components-7ca2f9a7c7d0) about presentational and container components

- function components

  do not have states, if a component does not need any interactive activity, then use a function component, often used for bottom level reprenstational component;

  it's called '**stateless**' component

  **they can have states when using hooks**

- class components

  it's called '**stateful**' component

  have internal states, useful for top level components

### Presentational vs. Container

#### Presentational

- **May contain both presentational and container components inside**;
- Usually have some DOM markup and styles of their own;
- Receive data and callbacks exclusively via props;
- Rarely have their own when they do, it’s UI state rather than data);
- Examples: _Page, Sidebar, Story, UserInfo, List_;
- Redux
  - Not aware of Redux;
  - Data from props;
  - Invoke callbacks from props;
  - Written by hand;

#### Container

- **May contain both presentational and container components inside**;
- Usually don’t have any DOM markup of their own except for some wrapping divs, and never have any styles;
- Usually generated using higher order components such as connect() from React Redux;
- Examples: _UserPage, FollowersSidebar, StoryContainer, FollowedUserList_;
- Redux
  - Aware of Redux;
  - Subscribe to Redux state;
  - Dispatch Redux actions;
  - Usually generate by React Redux;

#### How to do it

- They are usually put into different folders to make the disdinction clear;
- Start with only presentational components;
- When you realize you are passing too many props down the intermediate components, it’s a good time to introduce some container components without burdening the unrelated components in the middle of the tree;
- Don’t try to get it right the first time, you’ll develop an intuitive sense when you keeping do it;

### How to bind event handlers

- [Arrow Functions in Class Properties Might Not Be As Great As We Think](https://medium.com/@charpeni/arrow-functions-in-class-properties-might-not-be-as-great-as-we-think-3b3551c440b1)
- [garylirocks: class-in-depth.js](https://github.com/garylirocks/js-es6/blob/master/class-syntax/class-in-depth.js)

```js
class A {
  static color = "red";
  counter = 0;

  handleClick = () => {
    this.counter++;
  };

  handleLongClick() {
    this.counter++;
  }
}
```

are transpiled(with the help of `babel-plugin-transform-class-properties`) into

```js
class A {
  constructor() {
    this.counter = 0;

    this.handleClick = () => {
      this.counter++;
    };
  }

  handleLongClick() {
    this.counter++;
  }
}
A.color = "red";
```

General Rules:

- **Don't bind all class methods**, only bind those ones that you're going to pass around;
- Arrow functions in class properties are transpiled into the constructor, so it's not in the prototype chain, not available in `super`, not shared, it's created for each instance;
- Arrow functions is almost the same as do binding manually in the constructor, but for binding functions, the bound one is in the instance, the original function is still in the prototype;
- Arrow functions and bound functions are **slower** than usual methods;

### Controlled vs. Uncontrolled Components

An input field can be a controlled element or an uncontrolled one:

<iframe height='265' scrolling='no' title='React - Contolled vs. Uncontolled Component' src='//codepen.io/garylirocks/embed/jYgQLO/?height=265&theme-id=dark&default-tab=js,result&embed-version=2' frameborder='no' allowtransparency='true' allowfullscreen='true' style='width: 100%;'>See the Pen <a href='https://codepen.io/garylirocks/pen/jYgQLO/'>React - Contolled vs. Uncontolled Component</a> by Gary Li (<a href='https://codepen.io/garylirocks'>@garylirocks</a>) on <a href='https://codepen.io'>CodePen</a>.
</iframe>

## Example with lifecycle functions

### v16.4

![react-lifecyle-explained](./images/react-lifecycle-v16.4.png)

see this **[CodeSandbox example](https://codesandbox.io/s/2jxjn85n0j)** to understand how each method is supposed to work

- **`getDerivedStateFromProps`** introduced to replace `componentWillMount` and `componentWillReceiveProps`;

  ```
  static getDerivedStateFromProps(props, state)
  ```

  it should return an object to update state, so no need to call `this.setState()`

  this method add complexity to components, often leads to bugs, you should consider [simpler alternatives](https://reactjs.org/blog/2018/06/07/you-probably-dont-need-derived-state.html)

  it is always called any time a parent component rerenders, regardless of whether the props are "different" from before

- **`getSnapshotBeforeUpdate`** is introduced, it is run after `render`, can be used to capture any DOM status before it is actually updated, the returned value is available to `componentDidUpdate`;

  ```
  getSnapshotBeforeUpdate(prevProps, prevState)
  ```

  it's not often needed, can be useful in cases like manually preserving scroll position during rerenders

- **`componentDidUpdate`** is definded as:

  ```
  componentDidUpdate(prevProps, prevState, snapshot)
  ```

### Before v16.3

![react-lifecyle-explained](./images/react-lifecycle.png)

    class Clock extends React.Component {
      constructor(props) {
        super(props);
        this.state = {date: new Date()};
      }

      // NOTE setup a timer after the component has been rendered
      componentDidMount() {
        this.timerID = setInterval(
          () => this.tick(),
          1000
        );
      }

      // NOTE it's a good practice to clear the timer when this component is removed from the DOM
      componentWillUnmount() {
        clearInterval(this.timerID);
      }

      tick() {
        this.setState({
          date: new Date()
        });
      }

      render() {
        return (
          <div>
            <h1>Hello, world!</h1>
            <h2>It is {this.state.date.toLocaleTimeString()}.</h2>
          </div>
        );
      }
    }

    ReactDOM.render(
      <Clock />,
      document.getElementById('root')
    );

## PropTypes

we can use static class variables within class definition to define `defaultProps` and `propTypes`

```js
import React from 'react';
import PropTypes from 'prop-types';

export class Book extends React.Component {
    static defaultProps = {
        title: 'untitled book',
    }

    static propTypes = {
        title: PropTypes.string.isRequired,

//      you can also use a custom validation rule here
//      title: function(props) {
//            if ((typeof props.title) !== 'string' || props.title.length < 5) {
//                return new Error('title should be a string and longer than 5');
//            } else {
//                return null;
//            }
//      }

    }

    ...
}
```

## JSX Syntaxes

- Embed JavaScript expressions in curly braces, for readability, put it in multiple lines and wrap it in parentheses

        const element = (
          <h1>
            Hello, {formatName(user)}!
          </h1>
        );

* attributes: use quotes for string literals and curly braces for JS expressions

        const element = <div tabIndex="0"></div>;
        const element = <img src={user.avatarUrl}></img>;

- use `camelCase` for attributes names, and some attributes' tag need to be modified to avoid conflicting with JS keywords

  - `for` -> `htmlFor`
  - `class` -> `className`
  - `tabindex` -> `tabIndex`
  - `colspan` -> `colSpan`
  - `style` -> `style` value should be wrapped by double brackets, and CSS property names should be in camelCase: `background-color` -> `backgroundColor`

          <div htmlFor="nameField" className="wide" style={{border: "1px solid #000", backgroundColor: 'red'}}>a demo div</div>

## Context

- Context allows you to pass data down the component tree without having to pass props down manually at every level;
- Suitable for "global" data, such as current authenticated user, theme, or preferred language;

```js
// create a context object, with a default value
const ThemeContext = React.createContext("light");

class ContextDemo extends React.Component {
  render() {
    // use a context provider, with a value,
    // providers can be nested, a consumer will get the nearest one's value
    return (
      <ThemeContext.Provider value="#f00">
        <Wrapper />
      </ThemeContext.Provider>
    );
  }
}

// an intermediate component, don't need to worry about context
function Wrapper(props) {
  return (
    <div>
      <InnerText />
    </div>
  );
}

class InnerText extends React.Component {
  // For class component, specify which context to use by a static property
  // React will find the closest Provider above and make its value available as this.context
  static contextType = ThemeContext;

  render() {
    return (
      <div style={{ color: this.context }}>
        Current Context Value: {this.context}
      </div>
    );
  }
}
```

For function component, use `Context.Consumer`

```js
<MyContext.Consumer>
  {value => /* render something based on the context value */}
</MyContext.Consumer>
```

## Refs and the DOM

[Official Doc](https://reactjs.org/docs/refs-and-the-dom.html)

usually `props` is the way for parent components to interact with children, but sometimes you would like to modify a child outside of the typical dataflow:

- Managing focus, text selection, or media playback;
- Triggering imperative animations;
- Integrating with third-party DOM libraries;

`ref`

- can be added to either a React component or a DOM element;
- takes a callback function, which is executed immediately after the component is mounted or unmounted;

### `ref` on DOM element

the callback function receives the underlying DOM element as its argument, following is a common usage:

    <input
        type="text"
        ref={(input) => { this.textInput = input; }} />

### `ref` on Components

an instance of the component will be passed to the callback function (it won't work with functional components, which don't have instances)

    <MyButton ref={button => this.buttonInstance = button;} />

### Another way to create `ref` since v16.3

v16.3 introduced the `React.createRef()` function, the callback way of creating a ref still works

```
class MyComponent extends React.Component {
  constructor(props) {
    super(props);

    this.inputRef = React.createRef();
  }

  render() {
    return <input type="text" ref={this.inputRef} />;
  }

  componentDidMount() {
    this.inputRef.current.focus();
  }
}
```

### Error Handling

[Error Handling in React 16](https://reactjs.org/blog/2017/07/26/error-handling-in-react-16.html)
[Demo](https://codepen.io/gaearon/pen/wqvxGa?editors=0010)

- the benefit of an error boundary is an error within it will not crash the whole app;
- any component with a `componentDidCatch` lifecycle method becomes an error boundary;
- an error boundary only catches errors in its subtree, not itself;
- you can use error boundary components to wrap different parts of your app;

```js
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  componentDidCatch(error, info) {
    // Display fallback UI
    this.setState({ hasError: true });
    // You can also log the error to an error reporting service
    logErrorToMyService(error, info);
  }

  render() {
    if (this.state.hasError) {
      // You can render any custom fallback UI
      return <h1>Something went wrong.</h1>;
    }

    return this.props.children;
  }
}
```

then use it to wrap other components

```js
<ErrorBoundary>
  <MyWidget />
</ErrorBoundary>
```

## Hooks

- Added in v16.8;
- Allow you to use state in functional components (without classes);
- Hooks cover all existing use cases for classes, but classes are still supported, a gradual adoption strategy is recommended, do not rewrite everything straightaway;

### State Hooks

Previously if you want to add state to a function component, you need to convert it to a class.

```js
function ExampleWithManyStates() {
  // Declare multiple state variables!
  const [age, setAge] = useState(42);
  const [fruit, setFruit] = useState("banana");
  const [todos, setTodos] = useState([{ text: "Learn Hooks" }]);

  // Lazy initilize a state variable
  const [lazy, setLazy] = useState(() => longOperation());
  // ...

  return (
    <div>
      {/* pass a value */}
      <button onClick={() => setAge(18)}>Back to 18</button>
      {/* pass a function */}
      <button onClick={() => setAge(prev => prev + 1)}>Increment age</button>
      {/* ... */}
    </div>
  );
}
```

- Provide initial state to `useState`, it can be of any type;
- `useState` returns an array, first element is the state, second is the function to update the state;
- By passing a function to `useState`, you can **lazy initialize** a state variable, the function only get called when the variable is first used;
- The state value is kept when component re-renders;
- The value-updating function replace the variable, instead of merging it as `this.setState` does;

### Effect Hooks

- Data fetching, subscriptions, manually changing the DOM: these are "side effects", they can affect other components and can't be done during rendering;
- The Effect Hook `useEffect` performs side effects from a function component;
- The code in an effect runs after every render, equivalent to `componentDidMount`, `componentDidUpdate`;
- If an effect requires cleanup, you can return a function from it, it runs when the component unmounts (`componentWillUnmount`), as well as before subsequent render;
- React defers running `useEffect` until after the browser has painted;
- A second param to `useEffect` tells React to **only run an effect when the param changes**, if this param is `[]`, then the effect is only run on mount and clean up on unmount;

```js
function FriendStatusWithCounter(props) {
    const [count, setCount] = useState(0);

    // performs a side-effect
    useEffect(() => {
        document.title = `You clicked ${count} times`;
    });

    const [isOnline, setIsOnline] = useState(null);

    useEffect(() => {
        ChatAPI.subscribeToFriendStatus(props.friend.id, handleStatusChange);

        // return a function for 'cleanup'
        return () => {
            ChatAPI.unsubscribeFromFriendStatus(props.friend.id, handleStatusChange);
        };
    });

    // only run when props.friend.id changes
    useEffect(() => {
      // ...
    }, [props.friend.id]);

    function handleStatusChange(status) {
        setIsOnline(status.isOnline);
    }
    // ...
```

### Custom Hooks

- Extract stateful logic, so it can be used in multiple components;
- Accomplish the same as higher-order components and render props;

```js
import React, { useState, useEffect } from "react";

function useFriendStatus(friendID) {
  const [isOnline, setIsOnline] = useState(null);

  function handleStatusChange(status) {
    setIsOnline(status.isOnline);
  }

  useEffect(() => {
    ChatAPI.subscribeToFriendStatus(friendID, handleStatusChange);
    return () => {
      ChatAPI.unsubscribeFromFriendStatus(friendID, handleStatusChange);
    };
  });

  return isOnline;
}
```

Now we can use it from multiple components:

```js
function FriendStatus(props) {
  const isOnline = useFriendStatus(props.friend.id);

  if (isOnline === null) {
    return "Loading...";
  }
  return isOnline ? "Online" : "Offline";
}
```

```js
function FriendListItem(props) {
  const isOnline = useFriendStatus(props.friend.id);

  return (
    <li style={{ color: isOnline ? "green" : "black" }}>{props.friend.name}</li>
  );
}
```

### Other Hooks

- `useContext`: subscribe to React context without introducing nesting, a rerender is triggered when provider updates:

```js
function Example() {
  const locale = useContext(LocaleContext);
  const theme = useContext(ThemeContext);
  // ...
}
```

- `useReducer`: manage local state with a reducer:

```js
function Todos() {
    const [todos, dispatch] = useReducer(todosReducer);
    // ...
```

- `useCallback`
- `useMemo`
- `useRef`
- `useImperativeHandle`
- `useLayoutEffect`
- `useDebugValue`

### Rules of Hooks

React relies on the order in which Hooks are called, so you should:

- Only call Hooks at the top level, don't call them inside loops, conditions or nested functions;
- Only call Hooks from React function components (or custom Hooks), not from regular functions;

## Styling

- Inline styles

define styles in a separate file, and import it into the Component file and use it with the 'style' tag

cons: can't use Media Queries, Pseudo Selectors, Keyframe Animations

`app.js`

    ...
    import styles from './app-styles.js';

    ...
        return (<div style={styles.root}>
            ...
        </div>);
    ...

`app-styles.js`

    const defaultFontSize = '20px';

    export default {
        'root': {
            color: 'red',
            fontSize: defaultFontSize,
        }
        ...
    }

- Radium

[https://github.com/FormidableLabs/radium](https://github.com/FormidableLabs/radium)

a enhanced version of 'Inline styles', supporting Media Queries, Pseudo Selectors, Keyframe Animations

`app.js`

    ...
    import Radium from 'radium';
    import styles from './app-styles.js';

    ...
        return (<div style={styles.root}>
                    ...
                    <button style={styles.submit}> Submit </button>
        </div>);
    ...

    exports default Radium(App);					// wrap the component with the Radium function

`app-styles.js`

    const defaultFontSize = '20px';

    const pulse = Radium.keyframes({				// create key frame animations
        '0%': {
            transform: 'scale3d(1, 1, 1)'
        },
        '15%': {
            transform: 'scale3d(1.05, 1.05, 1.05)'
        },
        '100%': {
            transform: 'scale3d(1, 1, 1)'
        },
    }, 'Nav');

    const btn = {
        ...
        animation: `${pulse} 4s 2s infinite`,		// animation

        ':hover': {									// pseudo selectors
            transition: 'all 1s',
            color: 'red',
        }
    };

    export default {
        'root': {
            color: 'red',
            fontSize: defaultFontSize,
        },
        'submit': {
            ...btn
        },
        ...
    }

- CSS Modules

in webpack config file, add a `modules` parameter for the css loader:

    module.exports = {
      ...

        module: {
            loaders: [
            ...
            {
                test: /\.css/,
                loaders: ['style', 'css?modules&localIdentName=[local]--[hash:base64:5]', 'cssnext'],
            }]
        }
    }

`app.js`

    ...
    import styles from './app-styles.css';

    ...
        return (<div className={styles.btn}>
            ...
        </div>);
    ...

`app-styles.css`: almost pure css, see [https://github.com/css-modules/css-modules](https://github.com/css-modules/css-modules) for details

    @import 'basic.css';

    .btn {
        color: 'red',
        fontSize: 14px,
    }

    :global(.info) {
        background: 'green';
    }

## `ReactDOMServer`

- `renderToString`

  ```js
  ReactDOMServer.renderToString(element);
  ```

  - Render an element to HTML string;
  - Return markup on initial request for faster page loads;
  - Allow search engine to crawl the page;
  - `ReactDOM.hydrate()` on a node that has sever-rendered markup, React will preserve it and only attach event handlers;

- `renderToStaticMarkup`

  - Similar to `renderToStaticMarkup`;
  - Generate statick markup without extra DOM attributes used by React;
  - `ReactDOM.hydrate()` won't work on the generated markup;

## SSR - Server Side Rendering

A good step by step guide: [Demystifying server-side rendering in React](https://medium.freecodecamp.org/demystifying-reacts-server-side-render-de335d408fe4)

- On server side:

  - Render the root component with `ReactDOMServer.renderToString`, put the result in the HTML page;
  - Load the necessary data, and output the initial Redux state;
  - Use a `StaticRouter` to match the request path;

- On client side:
  - Use the data from the server as initial state;
  - `ReactDOM.hydrate`;

```js
// server.js
import express from "express";
import path from "path";

import React from "react";
import { renderToString } from "react-dom/server";
import { StaticRouter, matchPath } from "react-router-dom";
import { Provider as ReduxProvider } from "react-redux";
import Helmet from "react-helmet";
import routes from "./routes";
import Layout from "./components/Layout";
import createStore, { initializeSession } from "./store";

const app = express();

app.use(express.static(path.resolve(__dirname, "../dist")));

app.get("/*", (req, res) => {
  const context = {};
  const store = createStore();

  store.dispatch(initializeSession());

  const dataRequirements = routes
    .filter(route => matchPath(req.url, route)) // filter matching paths
    .map(route => route.component) // map to components
    .filter(comp => comp.serverFetch) // check if components have data requirement
    .map(comp => store.dispatch(comp.serverFetch())); // dispatch data requirement

  Promise.all(dataRequirements).then(() => {
    const jsx = (
      <ReduxProvider store={store}>
        <StaticRouter context={context} location={req.url}>
          <Layout />
        </StaticRouter>
      </ReduxProvider>
    );
    const reactDom = renderToString(jsx);
    const reduxState = store.getState();
    const helmetData = Helmet.renderStatic();

    res.writeHead(200, { "Content-Type": "text/html" });
    res.end(htmlTemplate(reactDom, reduxState, helmetData));
  });
});

app.listen(2048);

function htmlTemplate(reactDom, reduxState, helmetData) {
  return `
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>React SSR</title>
            ${helmetData.title.toString()}
            ${helmetData.meta.toString()}
        </head>

        <body>
            <div id="app">${reactDom}</div>
            <script>
                window.REDUX_DATA = ${JSON.stringify(reduxState)}
            </script>
            <script src="./app.bundle.js"></script>
        </body>
        </html>
    `;
}
```

```js
// client.js
import React from "react";
import ReactDOM from "react-dom";
import { BrowserRouter as Router } from "react-router-dom";
import { Provider as ReduxProvider } from "react-redux";

import Layout from "./components/Layout";
import createStore from "./store";

const store = createStore(window.REDUX_DATA);

const jsx = (
  <ReduxProvider store={store}>
    <Router>
      <Layout />
    </Router>
  </ReduxProvider>
);

const app = document.getElementById("app");
ReactDOM.hydrate(jsx, app);
```

In order for the server to use ES modules and JSX, require `babel-register` at the entry:

```js
// index.js
require("babel-register")({
  presets: ["env"]
});

require("./src/server");
```
