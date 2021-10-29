# HTML

- [DOM](#dom)
  - [Overview](#overview)
  - [Node classes](#node-classes)
  - [Navigation](#navigation)
    - [DOM collections](#dom-collections)
  - [XPath](#xpath)
    - [Common patterns](#common-patterns)
    - [In Google Chrome](#in-google-chrome)
    - [In JS](#in-js)
  - [Attributes and Properties](#attributes-and-properties)
  - [Classes and Styles](#classes-and-styles)
  - [Element Size and Scrolling](#element-size-and-scrolling)
    - [Be careful](#be-careful)
  - [Window sizes and scrolling](#window-sizes-and-scrolling)
  - [Coordinates](#coordinates)
    - [Bounding Rectangle](#bounding-rectangle)
    - [`elementFromPoint(x, y)`](#elementfrompointx-y)
  - [Document Coordinates](#document-coordinates)
- [DOM Events](#dom-events)
  - [Assign event handler](#assign-event-handler)
  - [Event object](#event-object)
  - [Event Bubbling and Capturing](#event-bubbling-and-capturing)
    - [Bubbling](#bubbling)
    - [Capturing](#capturing)
  - [Event delegation](#event-delegation)
  - [Browser default actions](#browser-default-actions)
  - [Passive Event Listeners](#passive-event-listeners)
  - [Custom events](#custom-events)
    - [UI Events](#ui-events)
    - [Custom Event](#custom-event)
    - [Prevent default](#prevent-default)
  - [Event Synchronization](#event-synchronization)
  - [Document lifecycle events](#document-lifecycle-events)
  - [Resources loading events](#resources-loading-events)
- [History API](#history-api)
- [Web Performance](#web-performance)
  - [JS loading best practices](#js-loading-best-practices)

## DOM

### Overview

JS was initially created for browsers, now it can run in different host environments, each environment provides own objects and functions additional to the language core.

Here is an overview of the browser environment for JS:

![broswer_js_overview](images/js_browser_js_overview.png)

- `window` is the global object and represents the browser window;
- `DOM` - Document Object Model
  - `document` is the "entry point" to DOM, all DOM operations start with it;
  - `DOM` can be used in other envs (e.g. Node) to process a HTML document as well;
- `BOM` - Browser Object Model
  - Provides additional objects about the host env;
  - `alert/confirm/prompt` are a part of BOM;
  - Is part of HTML specification;

### Node classes

Everything in HTML is represented by objects in the DOM tree, there are 12 types of nodes, here is the built-in node classes hierarchy:

![node classes hierarchy](images/js_node_class_hierarchy.png)

- Commmon Node types:
  - `HTMLDocument` - the `document` object;
  - element nodes - different elements may belong to different built-in classes;
  - `Text` text nodes - texts within tags or spaces/newlines between tags;
  - `Attr` - attribute nodes;
  - `Comment` - comments;
- `EventTarget`, `Node`, etc are abstract classes;
- `HTMLInputElement`, `HTMLBodyElement`, etc are concrete classes, each has some specific properties;
- Common node properties: `nodeType`, `nodeName`, `data` (the text for `Text` or `Comment` nodes);
- Common element properties: `tagName`, `innerHTML`, `outerHTML`, `textContent`;

### Navigation

![dom_navigation](images/js_dom_navigation.png)

- `document.documentElement` -> `<html>`
- `document.head` -> `<head>`
- `document.body` -> `<body>`
- `document.querySelectorAll(css)` -> a collection
- `document.querySelector(css)` -> first match

- **`elem.closest(css)`** -> nearest ancestor matching the css, can be itself
- `elem.matches(css)` -> check whether an element matches the css selector

#### DOM collections

`node.childNodes` is an instance of `NodeList`, `elem.children` is an instance of `HTMLCollection`:

- They are array-like objects, not real arrays, array methods (`map`, `filter`, etc) don't work;
- Iterable, can be iterated using `for..of`;
- Can be converted to real arrays using `Array.from()`, `...`;
- Read-only;
- Live, if you keep a reference to it, and add/remove nodes into DOM, they appear in the collection directly;

### XPath

#### Common patterns

- Find elements whose class attribute contains 'foo'

  ```
  //*[contains(@class, "foo")]
  ```



- Find elements whose (or its descendants') text contains 'Foo'

  ```
  //*[contains(string(), "Foo")]
  //*[contains(., "Foo")]
  ```

- Find elements whose own text contains 'Foo'

  ```
  //*[contains(text(), "Foo")]
  ```

- Find first `li`

  ```
  //li[1]
  ```

- Multiple conditions

  ```
  //span[contains(@class, "warn") and contains(., "1")]
  ```

- Select an element based on descendant

  ```sh
  # match against direct child div
  //*[child::div[@title="Foo"]]

  # match against any descendant div
  //*[descendant::div[@title="Foo"]]
  ```

- SVG

  Simple `//svg` seems not working, use

  ```sh
  //*[name()="svg"]

  # multiple conditions
  //*[name()="svg" and @role="img"]
  ```

#### In Google Chrome

You could use `$x()` in the Devtools to find elements

```js
$x('//*[@id="logo"]')
```

#### In JS

```js
// evaluate XPATH, and specify result type to be first matching node
const results = document.evaluate('//*[contains(@class, "foo")]', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE);

// get the node
const node = results.singleNodeValue;
```

### Attributes and Properties

- Standard attributes of an element are created as properties in the corresponding DOM object:

  ```html
  <body id="body" type="...">
    <input id="input" type="text" />
    <script>
      alert(input.type); // text
      alert(body.type); // undefined: 'type` is non-standard for <body>
    </script>
  </body>
  ```

  |       | Attributes                    | Properties                                                                                                    |
  | ----- | ----------------------------- | ------------------------------------------------------------------------------------------------------------- |
  | Name  | case-insensitive (`id`, `ID`) | lower-case (`id`)                                                                                             |
  | Type  | always strings                | can be other types: (`checked` is boolean, `style` is object)                                                 |
  | Value | as in the HTML                | can be different (`href` attribute of `<a>` may be a relative path, the `href` property is always a full URL) |

- Attributes and properties are synced most of the time, but there are exceptions, such as `value` for `input`;

  - `inputElement.getAttribute('value')` is the initial value for the input, and is the initial value of `inputElement.value`;
  - `inputElement.value` is what you see on the page, if you change it, the attribute doesn't change;

- `data-` attributes

  - Reserved for programmers' use, available in the `dataset` property;
    - `data-name` attribute is available as `dataset.name`;
    - `data-last-name` is available as `dataset.lastName`;

### Classes and Styles

- `class` attribute can be accessed in JS with:

  - `elem.className`: a string;
  - `elem.classList`: an iterable, array-like object, supports `add/remove/toggle/contains` methods;

- `style` attribute is available in `elem.style`:

  - you can update any style property: `elem.style.fontSize = '20px'`;
  - reset by assigning an empty string: `elem.style.fontSize = ''`;

- `getComputedStyle`

  - `getComputedStyle(element, [pseudo])`, returns an object like `elem.style`, with respect to all CSS rules and inheritance;
  - Used to return _computed_ values, but nowadays it returns **resolved values**:
    - A _computed style_ value refers to the result of CSS cascade, e.g.: `height: 1em` or `font-size: 125%`;
    - A _resolved style_ value refers to the final value applied to the element, it's has fixed and absolute units, e.g.: `height: 20px` or `font-size: 16px`;
  - You'd better use full property names like `getComputedStyle(elem).paddingLeft` instead of short names like `padding`;
  - Styles applied to `:visited` links are hidden, for example, if a visited link has a special color, it can't be accessed by `getComputedStyle`, this is for privacy reason;
    - And there is a limitation in CSS that forbids applying geometry-changing styles in `:visited`;

### Element Size and Scrolling

![exmaple element](images/html_element_sizing_example.png)

- If a browser reserves space for a scrollbar (some only show on hover), the space (16px above) is taking from the content width;
  - Scrollbar is between padding and border;
- `padding-bottom` may be filled with text (you can only see the bottom padding when you scroll to the end);

![sizing](images/html_element_geometry.png)

- `offsetParent`, `offsetLeft/Top`

  The offsetParent is the nearest ancestor that the browser uses for calculating coordinates during rendering. That’s the nearest ancestor that is one of the following:

  - CSS-positioned (position is `absolute`, `relative`, `fixed` or `sticky`), or
  - `<td>`, `<th>`, or `<table>`, or
  - `<body>`

- `offsetWidth/Height`

  The full size of an element, including borders, not including margins.

- `clientLeft/Top`

  Usually the same as left/top border width, unless the document is right-to-left and there is a scrollbar.

- `clientWidth/Height`

  Include content and paddings, without scrollbar.

- `scrollWidth/Height`

  Similar to `clientWidth/Height` but includes scrolled out parts.

- `scrollLeft/Top`

  How much have been scrolled out, can be modified to scroll an element.

#### Be careful

- **If an element is not in the document or has `display: none`, then all its geometry properties are 0, and `offsetParent` is `null`**
  - `!elem.offsetWidth && !elem.offsetHeight` can tell if an element is hidden (or take no space);
- Don't take width/height from CSS
  - CSS `width/height` depends on another property `box-sizing`;
  - CSS `width/height` may be `auto`;
  - When read `getComputedStyle(elem).width`, browsers behave differently regarding whether scrollbar width is included;

### Window sizes and scrolling

- Use `document.documentElement.clientWidth/Height` to get the width/height of visible part of a document, (scrollbar size excluded);

  - `window.innerWidth/Height` include scrollbar size;
  - `window.outerWidth/Height` is the broswer width/height;

- To get the full size of a doucment, including scrolled out part, due to browser inconsistencies, you need

  ```js
  let scrollHeight = Math.max(
    document.body.scrollHeight,
    document.documentElement.scrollHeight,
    document.body.offsetHeight,
    document.documentElement.offsetHeight,
    document.body.clientHeight,
    document.documentElement.clientHeight
  );
  ```

- To get scroll position of the document, it's better to use `window.pageXOffset/pageYOffset`, because `document.documentElement.scrollLeft/Top` is not consistent across browsers:

  ```js
  alert('Current scroll from the top: ' + window.pageYOffset);
  alert('Current scroll from the left: ' + window.pageXOffset);
  ```

- Use `window.scrollBy(x,y)` and `window.scrollTo(pageX,pageY)` to scroll a document;

- Use `elem.scrollIntoView(top)` to scroll the page to make `elem` visible, `top` controlles whether it appears at the top or the bottom of the page;

- Forbid the scrolling by `document.body.style.overflow = "hidden"`, this can be applied to other elements as well;

### Coordinates

![coordinates](images/html_coordinates_window_vs_document.png)

There are two coordinates systems:

  - Relative to the window: `clientX / clientY`, changes when page scrolls, stays the same if the element is `fixed`;
  - Relative to the document: `pageX / pageY`, stay the same when page scrolls;

#### Bounding Rectangle

![Bounding rectangle](images/html_getboundingclientrect.png)

`elem.getBoundingClientRect()` returns an object of `DOMRect` class, which has properties `x/y`, `width/height` and derived `top/left/right/bottom`;

  - `x/y` can be negative if the element is scrolled out;

#### `elementFromPoint(x, y)`

Returns the most nested element at window coordinates `(x, y)`, only works if `(x, y)` is within visible area, otherwise it returns `null`;

### Document Coordinates

There's no built in method for getting an element's document coordinates, it can be done by calculation based on window coordinates and page scroll position. This can be used to create an element positioned relative to another:

```js
// get document coordinates of an element
function getCoords(elem) {
  let box = elem.getBoundingClientRect();

  return {
    top: box.top + window.pageYOffset,
    left: box.left + window.pageXOffset,
    right: box.right + window.pageXOffset,
    bottom: box.bottom + window.pageYOffset,
  };
}

function createMessageUnder(elem, html) {
  let message = document.createElement('div');
  message.style.cssText = "position:absolute; color: red";

  let coords = getCoords(elem);

  message.style.left = coords.left + "px";
  message.style.top = coords.bottom + "px";

  message.innerHTML = html;

  return message;
}

// put 'Hello, world!' under a button
let elem = document.getElementById("button");
let message = createMessageUnder(elem, 'Hello, world!');
document.body.append(message);
```

## DOM Events

### Assign event handler

There are 3 ways to assign event handlers:

- HTML attribute: `onclick="myHandler(this)"`;

  - Not recommended;
  - `onclick` here is case-insensitive, it can be `onClick`, `ONCLICK`;
  - The browser actually creates a DOM property like this (so this method is basically the same as the one below):

    ```js
    elem.onclick = function(event) {
      // the event object is the first argument in the wrapper function
      myHanlder(this);
    }
    ```

- DOM property: `elem.onclick = myHandler`;

  - Case sensitive;
  - Can only assign one handler for each type of event;
  - Some events are not supported, such as `transitioned` and `DOMContentLoaded`;

- Methods: `elem.addEventListener(event, handler[, phase])` to add, `removeEventListener` to remove;

  - Most flexible;
  - Support all event types;
  - Can add multiple handler for same event;
  - `handler` can be an object, then its `handleEvent` is called;

### Event object

An event object carries all the info of an event:

- `event.target` is where the event happened, the original inner most element;
- `event.currentTarget` is the same as `this` (unless in an arrow function), where the current handler is bound to;
- `event.clientX` / `event.clientY`: window-relative coordinates of the cursor;


### Event Bubbling and Capturing

#### Bubbling

- An event bubbles from `event.target` all the way up to `<html>`, `document` object, even `window` object for some events;
- **Most events bubble**, but not all, like `focus`;
- An element can stop the bubbling by call `event.stopPropagation()`, `event.stopImmediatePropagation()` stop the bubbling and prevent other handlers on the current target from running;
- You can write data to the event in one handler and read it from another one;

#### Capturing

![Event Phases](images/dom_event-phases.png)

- As in the diagram, an event actually has three phases, by default only the target and bubbling phases are used, the capturing phase is seldomly used;
- Use the third parameter to add handler to the capturing phase:

  ```js
  element.addEventListener('click', handler, true);
  // or
  element.addEventListener('click', handler, { capture: true });
  ```

### Event delegation

Event delegation means instead of setting similar handlers on a bunch of elements one by one, you add a handler on their common ancestor, and handle it there.

```html
Counter: <input type="button" value="1" data-counter>
One more counter: <input type="button" value="2" data-counter>

<script>
  document.addEventListener('click', function(event) {
    // check whether the `data-counter` attribute exists
    if (event.target.dataset.counter != undefined) {
      event.target.value++;
    }
  });
</script>
```

### Browser default actions

Many events have default actions performed by the browser (navigating to a url, submitting a form, etc).

There are two ways to prevent the default action:

  - Call `event.preventDefault()`;
  - Returning `false` from a handler assigned by `on<event>`;

Effects:

  - After `event.preventDefault()`, `event.defaultPrevented` becomes true, this passes info to handlers on ancestor elements;
  - If you prevent one event, all its follow-up events are prevented as well, e.g. if you prevent the `mousedown` event of a input box, then there will be no `focus` event;


### Passive Event Listeners

[Passive event listeners](https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md)

- For events like `touchstart`, `touchmove`, `touchend`, `wheel`, browser waits all the handlers to finish to check if there is any `preventDefault`, if no, then it scrolls the page, this causes UI delays;

  ```js
  // 'scrolling' is blocked during the execution of the handler
  document.addEventListener('wheel', e => {
    e.preventDefault();
  });
  ```

- You can add an option `{ passive: true }` to the event listeners to indicate that it will never invoke `preventDefault`;

  ```js
  // call 'preventDefault' in handler will have no effects and result in an error
  document.addEventListener('wheel', handler, { passive: true });
  ```

- This is a breaking change to the `addEventListener` method, previously the third param is of boolean type, indicating whether respond in `capture` phase, so you may need to add a polyfill or do a feature detection;

### Custom events

The general way to create and dispatch an event:

```js
let event = new Event(type[, options]);

elem.dispatchEvent(event);
```

- `type` can be a built-in event type or a custom one;
- Default value for `options` is `{ bubbles: false, cancelable: false }`;
- `event.isTrusted` tells whether an event is from real user actions or generated by script;

#### UI Events

For UI Events, it's better to use specific classes to create them, this allows to specify more properties:

```js
let event = new MouseEvent("click", {
  bubbles: true,
  cancelable: true,
  clientX: 100,
  clientY: 100
});

alert(event.clientX); // 100
```
Common classes: `UIEvent`, `FocusEvent`, `MouseEvent`, `WheelEvent`, `KeyboardEvent`;

#### Custom Event

```js
new CustomEvent("hello", {
  detail: { name: "John" }
});
```

It's better to use `CustomEvent` to create a custom event, which
  - Makes it clear this event is of a custom type;
  - Allows you to specify a `detail` property in the options;


#### Prevent default

A custom event doesn't have any browser defined default actions, but it may have its own default actions:

```js
elem.addEventListener('hide', function(event) {
  if (confirm("Call preventDefault?")) {
    event.preventDefault();
  }
});

let event = new CustomEvent("hide", {
  cancelable: true // without that flag preventDefault doesn't work
});

if (!elem.dispatchEvent(event)) {
  alert('The action was prevented by a handler');
} else {
  elem.style.display = 'none'; // this is the default action of this event
}
```

- You can only call `preventDefault` on `cancelable` events;
- If any handler called `preventDefault`, then `dispathEvent` returns `false`;

### Event Synchronization

- By default events are handled asynchronously, if event B happend while event A is been processed, B will be processed after A's handling is done;
- But if event B is triggered inside A's handler, it will be run synchronously, you can use a zero-delay `setTimeout` to make it async again:

  ```html
  <button id="menu">Menu (click me)</button>

  <script>
    menu.onclick = function() {
      alert(1);

      // trigger an event inside a handler
      setTimeout(() => menu.dispatchEvent(new CustomEvent("menu-open", {
        bubbles: true
      })));

      alert(2);
    };

    document.addEventListener('menu-open', () => alert('nested'));
  </script>
  ```

  Output would be 1 -> 2 -> nested

### Document lifecycle events

- `DOMContentLoaded`: HTML fully loaded, DOM tree is built, external resources like images and stylesheets may not yet be loaded;
  - Browsers actually use this event to do auto-fill;
- `load`: all external resources loaded, styles are applied, image sizes are known;
- `beforeunload`: can check if there is unsaved changes;

  When the handler returns `false`, the browser will ask the user to confirm, but you can't customize the message, `alert` and `prompt` are blocked

  ```js
  window.onbeforeunload = function() {
    // alert, prompt in this handler are blocked
    return false;
  };
  ```

- `unload`: can send out statistics;

  There's a special `navigator.sendBeacon(url, data)` method, which works in the background, doesn't delay page transition

  ```js
  let analyticsData = { /* object with gathered data */ };

  window.addEventListener("unload", function() {
    navigator.sendBeacon("/analytics", JSON.stringify(analyticsData));
  };
  ```

- `readystatechange`

  Another way to track document loading status, fires whenever `document.readyState` changes:

  - "loading" – the document is loading;
  - "interactive" – the document was fully read, `DOMContentLoaded`;
  - "complete" - all resources (like images) are loaded;

### Resources loading events

Any resource that has external `src` have `load` and `error` events:

```js
let img = document.createElement('img');
img.src = "https://js.cx/clipart/train.gif"; // (*)
document.body.append(img);

img.onload = function() {
  alert(`Image loaded, size ${img.width}x${img.height}`);
};

img.onerror = function() {
  alert("Error occurred while loading image");
};
```

Notes:
  - Most resources start loading when they are added to the document, but `<img>` starts loading when it gets a `src`;
  - `iframe.onload` triggers even when loading failed;


## History API

- HTML5 supports history API;
- You can manipulate the history by `pushState` and `replaceState`
  - `pushState(state: any, title: string, path?: string)`, this add a new entry to the history object, and attach a `state` object to it, you can update the `path` at the same time, which doesn't send a query to the server;
  - They **don't** trigger `hashchange` or `popstate` event

- `popstate` event is triggered when you navigate with buttons or use `back`, `forward` or `go` method, **NOT** by `pushState` and `replaceState`;
- Hash change (by `location.hash` or anchor links) triggers both `popstate` and `hashchange` event, `popstate` happens before `hashchange`;

- Check out `https://github.com/remix-run/history`, which extends the History API, can listen to any url changes, used by React-Router.

## Web Performance

[Google web performance tips on Youtube](https://www.youtube.com/playlist?list=PLNYkxOF6rcICVl6Vb-AFlw81bQLuv6a_P)

[Running Your JavaScript at the Right Time](https://www.kirupa.com/html5/running_your_code_at_the_right_time.htm)

### JS loading best practices

In a HTML page, any JS files included synchronously or inline scripts need to be loaded, parsed and executed, as they may want to modify DOM (even `document.write` to it), so they blocks visible content rendering.

Solutions:

- Good:

  Put most JS tags at the end of `<body>`, so they won't block visible content rendering, but browsers still tend to load them early, which delays other resources;

- Better:

  - `defer`:
    - No blocking;
    - Loads 'in background', executes after the HTML is parsed, DOM is ready, but before firing `DOMContentLoaded`;
    - For multiple `defer` scripts, they are executed in document order;
    - No effect on inline scripts;

  - `async`:
    - No blocking, completely independent;
    - It may get loaded/run before or after `DOMContentLoaded`;
    - With multiple `async` scripts, whatever loads first, runs first;
    - Suitable for independent third-party scripts: ads, analytics, etc;

  But browser still loads them concurrently with other resources, such as images;

- Best:

  Load script after the page is rendered:

  ```js
  $(window).on('load', function() {
    $('body').append('<script src="script.js">');
  });
  ```

![js script loading](images/js_script_loading.png)
