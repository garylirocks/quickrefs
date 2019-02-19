# react router

ref: [A simple react router v4 tutorial](https://medium.com/@pshrmn/a-simple-react-router-v4-tutorial-7f23ff27adf)

## general

since version 4, `react-router` has been broken into three packages `react-router`, `react-router-dom`, and `react-router-native`

- `react-router-dom` is for browsers
- `react-router-native` is for react native apps

`react-router` will be imported automatically, so no need to install it directly, all its exports will be re-exported by the other two packages

## differences between v4- and v4+

V4+

- no `activeClassname` on `<Link>` component

## `BrowserRouter` and `HashRouter`

always use `BrowserRouter`, unless you are using a static-file server

## Routes

Routes have three props that can be used to define what should be rendered when the route’s path matches. Only one should be provided to a `<Route>` element.

- component — A React component. When a route with a component prop matches, the route will return a new element whose type is the provided React component (created using React.createElement).

- render — A function that returns a React element. It will be called when the path matches. This is similar to component, but is useful for inline rendering and passing extra props to the element.

- children — A function that returns a React element. Unlike the prior two props, this will always be rendered, regardless of whether the route’s path matches the current location.

        <Route path='/page' component={Page} />

        const extraProps = { color: 'red' }
        <Route path='/page' render={(props) => (
          <Page {...props} data={extraProps}/>
        )}/>

        <Route path='/page' children={(props) => (
          props.match
            ? <Page {...props}/>
            : <EmptyPage {...props}/>
        )}/>

The element rendered by the `<Route>` will be passed a number of props. These will be the match object, the current location object, and the history object (the one created by our router).

## Switch

in `<Switch>`, only the first mathing `<Route>` is rendered

    <Switch>
        <Route exact path='/' component={Home}/>
        <Route path='/roster' component={Roster}/>
        <Route path='/schedule' component={Schedule}/>
    </Switch>
