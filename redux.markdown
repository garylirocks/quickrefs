Redux
===========

Redux is an implementation of the Flux pattern intended to manage an app's state.

Redux is inspired by functional programming, so there are a lot concepts coming from it (e.g. higher order functions, function composition), it's helpful if you can understand them well.

[Redux documentation](https://redux.js.org/)

## Basic 

* All data/state is saved in the store;
* Store is read-only, **don't update it directly**, when you need to update it, dispatch an action to it, it will call the reducers to update the state;
* Reducers `(prevState, action) => newState` should be **pure** functions, **never** do the following in a reducer:
  * mutate its argument;
  * perform side effects like API calls and routing transitions;
  * call non-pure functions like `Date.now()` or `Math.random()`;  
* Actions should be pure object, they are usually created by functions called action creators;


```js
import { createStore } from 'redux';

// reducer
const reducer = (state = 0, action) => {
    switch (action.type) {
        case 'INCREMENT':
            return state + 1;
            break;
        case 'DECREMENT': 
            return state - 1;
            break;
        default:
            return state;
            break;
    }
}

// action creators
const incrementAction = () => ({type: 'INCREMENT'});
const decrementAction = () => ({type: 'DECREMENT'});

// create a store
const store = createStore(reducer);

// add a listener
store.subscribe(() => console.log(store.getState()));

// dispatch actions
store.dispatch(incrementAction());
store.dispatch(decrementAction());
```


## Store

* Holds app state;
* Allows access to state via `getState()`;
* Allows state to be updated via `dispatch(action)`;
* Registers listeners via `subscribe(listener)`;
* Handles unregistering of listeners via the function returned by `subscribe(listener)`;


## Actions 

* Action is a plain object that carries payload to the store;
* Actions must have a `type` field, see [Flux Standard Action](https://github.com/redux-utilities/flux-standard-action) for recommended structure of actions;


## Dispatching Function

```js
type BaseDispatch = (a: Action) => Action
type Dispatch = (a: Action | AsyncAction) => any
```

be aware of **disaptching functions in general** and the **base `dispatch` function** provided by the store instance without any middleware.

* the base dispatch function **always synchronously** sends an action to the store's reducer, it expects actions to be plain objects ready to be consumed by the reducer;

* middleware wraps the base dispatch function, it allows the dispatch function to handle async actions in addition to actions, middleware may *transform, delay, ignore or otherwise interpret* actions or async actions before **passing** them to the next middleware;


## Action Creators

Calling an action creator only produces an action, **does not** dispatch it, you need to call `dispath` to do it;

If an action creator needs to read the current state, perform an API call, or cause a side effect (like a routing transition), it should return an **async action**.

```js
type ActionCreator = (...args: any) => Action | AsyncAction
```


## Async Actions

```js
type AsyncAction = any
```

An async action are often asynchronous primitives, usually a Promise or a thunk. It will be transformed by middleware into an action (or a series of actions) before being sent to the base `dispatch()` function. It is not passed to the reducer immediately, but trigger action dispatches once an operation is completed.

### A typical API call

Usually, an API request will dispatch at least three different kinds of actions: 

* **a begin action** -> toggle a `isFetching` flag in the state, let the UI show a spinner;
* **a success action** -> merge the fetched data to the state, reset `isFetching`;
* **an error action** -> reset `isFetching`, possibly show the error message;

you can use a dedicated `status` field:

```js
{ type: 'FETCH_POSTS' }
{ type: 'FETCH_POSTS', status: 'error', error: 'Oops' }
{ type: 'FETCH_POSTS', status: 'success', response: { ... } }
```

or define separate types

```js
{ type: 'FETCH_POSTS_REQUEST' }
{ type: 'FETCH_POSTS_FAILURE', error: 'Oops' }
{ type: 'FETCH_POSTS_SUCCESS', response: { ... } }
```

you can use any method, but stick to it throughout your app.



## Reducers

### Reducer Composition

Redux provide a helper function `combineReducers` to compose separate reducers together, this enables you to write small reducer functions that only need to concern part of the store

```js
import { combineReducers } from 'redux'
​
const todoApp = combineReducers({
  visibilityFilter,
  todos
})
​
export default todoApp
```

is equivalent to 

```js
export default function todoApp(state = {}, action) {
  return {
    visibilityFilter: visibilityFilter(state.visibilityFilter, action),
    todos: todos(state.todos, action)
  }
}
```

in ES6, you can do the copostion like this:

```js
import { combineReducers } from 'redux'
import * as reducers from './reducers'
​
const todoApp = combineReducers(reducers)
```

## Middleware

```js
type MiddlewareAPI = { dispatch: Dispatch, getState: () => State }
type Middleware = (api: MiddlewareAPI) => (next: Dispatch) => Dispatch
```

A middleware is a higher-order function that composes a dispatch function to return a new dispatch function. It often turns async actions into actions. Middleware is composable using function composition, it is useful for:

* logging actions;
* performing side effects like routing;
* turning an async API call to a series of sync actions;



