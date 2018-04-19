react
===============

## general ideas

* HTML is written in JavaScript (usually JSX), so react can construct a virtual DOM;


## State and Props

* props are fixed, can not be changed
* state is dynamic, can be changed, is private and fully controlled by the component


## components

* function components
	
	do not have states, if a component does not need any interactive activity, then use a function component, often used for bottom level reprenstational component;

	it's called '**stateless**' component

	**have `props`, no `state`**

* class components

	it's called '**stateful**' component

	have internal states, useful for top level components


## JSX Syntaxes

* Embed JavaScript expressions in curly braces, for readability, put it in multiple lines and wrap it in parentheses

		const element = (
		  <h1>
			Hello, {formatName(user)}!
		  </h1>
		);


* attributes: use quotes for string literals and curly braces for JS expressions

		const element = <div tabIndex="0"></div>;
		const element = <img src={user.avatarUrl}></img>;


* use `camelCase` for attributes names, and some attributes' tag need to be modified to avoid conflicting with JS keywords

	* `for`			-> `htmlFor`
	* `class`		-> `className`
	* `tabindex`	-> `tabIndex`
    * `colspan`     -> `colSpan`
	* `style`		->	`style`  value should be wrapped by double brackets, and CSS property names should be in camelCase: `background-color` -> `backgroundColor`

			<div htmlFor="nameField" className="wide" style={{border: "1px solid #000", backgroundColor: 'red'}}>a demo div</div>

## Example with lifecycle functions

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


## state

### state initializing

with ES6 class syntax, add a `state` property to the class

    class Book extends React.Component {
        state = {
            title: 'Moby Dick',
            ...
        }

        ...
    }

### state updating

* always use `this.setState({})` to update the state
* state updates may be asynchronous, if new state is depended upon the previous state, use the second form of `setState()`:

		this.setState((prevState, props) => ({
			counter: prevState.counter + props.increment
		}));


## defaultProps and propTypes

we can use static class variables within class definition to define defaultProps and propTypes

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


## Refs and the DOM

[Official Doc](https://reactjs.org/docs/refs-and-the-dom.html)

usually `props` is the way for parent components to interact with children, but sometimes you would like to modify a child outside of the typical dataflow:

    * Managing focus, text selection, or media playback;
    * Triggering imperative animations;
    * Integrating with third-party DOM libraries;

`ref` 
    
    * can be added to either a React component or a DOM element;
    * takes a callback function, which is executed immediately after the component is mounted or unmounted;

### `ref` on DOM element

the callback function receives the underlying DOM element as its argument, following is a common usage:

    <input
        type="text"
        ref={(input) => { this.textInput = input; }} />

### `ref` on Components

an instance of the component will be passed to the callback function (it won't work with functional components, which don't have instances)

    <MyButton ref={button => this.buttonInstance = button;} />


## Controlled vs. Uncontrolled Components

An input field can be a controlled element or an uncontrolled one: 

<iframe height='265' scrolling='no' title='React - Contolled vs. Uncontolled Component' src='//codepen.io/garylirocks/embed/jYgQLO/?height=265&theme-id=dark&default-tab=js,result&embed-version=2' frameborder='no' allowtransparency='true' allowfullscreen='true' style='width: 100%;'>See the Pen <a href='https://codepen.io/garylirocks/pen/jYgQLO/'>React - Contolled vs. Uncontolled Component</a> by Gary Li (<a href='https://codepen.io/garylirocks'>@garylirocks</a>) on <a href='https://codepen.io'>CodePen</a>.
</iframe>


## Styling

* Inline styles

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


* Radium

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


* CSS Modules

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



















