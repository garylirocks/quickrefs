# HTML

- [DOM](#dom)
  - [Overview](#overview)
  - [Node classes](#node-classes)
  - [Navigation](#navigation)
    - [DOM collections](#dom-collections)
  - [Attributes and Properties](#attributes-and-properties)
  - [Classes and Styles](#classes-and-styles)
  - [Element Size and Scrolling](#element-size-and-scrolling)
    - [Be careful](#be-careful)
  - [Window sizes and scrolling](#window-sizes-and-scrolling)
- [DOM Events](#dom-events)
  - [Assign event handler](#assign-event-handler)
  - [Event Bubbling and Capturing](#event-bubbling-and-capturing)
    - [Bubbling](#bubbling)
    - [Capturing](#capturing)
  - [Passive Event Listeners](#passive-event-listeners)
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

- `elem.closest(css)` -> nearest ancestor matching the css, can be itself
- `elem.matches(css)` -> check whether an element matches the css selector

#### DOM collections

`node.childNodes` is an instance of `NodeList`, `elem.children` is an instance of `HTMLCollection`:

- They are array-like objects, not real arrays, array methods (`map`, `filter`, etc) don't work;
- Iterable, can be iterated using `for..of`;
- Can be converted to real arrays using `Array.from()`, `...`;
- Read-only;
- Live, if you keep a reference to it, and add/remove nodes into DOM, they appear in the collection directly;

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

- Use `window.scrollBy(x,y)` and `window.scrollTo(pageX,pageY)` to scroll a document.

## DOM Events

- You can only call `preventDefault` on `cancelable` event;

### Assign event handler

There are 3 ways to assign event handlers:

- HTML attribute: `onclick="myHandler(this)"`;

  - Not recommended;
  - `onclick` here is case-insensitive, it can be `onClick`, `ONCLICK`;

- DOM property: `elem.onclick = myHandler`;

  - Case sensitive;
  - Can only assign one handler for each type of event;
  - Some events are not supported, such as `transitioned` and `DOMContentLoaded`;

- Methods: `elem.addEventListener(event, handler[, phase])` to add, `removeEventListener` to remove;

  - Most flexible;
  - Support all event types;
  - Can add multiple handler for same event;
  - `handler` can be an object, then its `handleEvent` is called;

### Event Bubbling and Capturing

#### Bubbling

- `event.target` is always the original inner most element;
- `event.currentTarget` is the same as `this`, where the current handler is bound to;
- An event can bubble from the target to `<html>`, `document` object, even `window` object;
- **Most events bubble**, but not all, like `focus`;
- `event.stopPropagation()` stop the bubbling process, `event.stopImmediatePropagation()` stop the bubbling and prevent other handlers on the current target from running;
- You can write data to the event in one handler and read it from another one;

#### Capturing

![Event Phases](images/dom_event-phases.png)

- As in the diagram, an event actually has three phases, but the capturing phase is seldomly used;
- Use the third parameter to add handler to the capturing phase:

  ```js
  element.addEventListener('click', handler, true);
  // or
  element.addEventListener('click', handler, { capture: true });
  ```

### Passive Event Listeners

[Passive event listeners](https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md)

- Scrolling blocks on touch and wheel event listeners (`touchstart`, `touchmove`, `touchend`, `wheel`), the browser is waiting the handler to finish to see if there is any `preventDefault`, which will disable scrolling;

  ```js
  // 'preventDefault' here will prevent scrolling
  // if there is no 'preventDefault', scrolling is still blocked on this event listener
  document.addEventListener('wheel', e => {
    e.preventDefault();
  });
  ```

- You can add an option `{passive: true}` to the event listeners to indicate that it will never invoke `preventDefault`;

  ```js
  // call 'preventDefault' in handler will have no effects and result in an error
  document.addEventListener('wheel', handler, { passive: true });
  ```

- This is a breaking change to the `addEventListener` method, previously the third param is of boolean type, indicating whether respond in `capture` phase, so you may need to add a polyfill or do a feature detection;

## History API

- HTML5 supports history API;
- You can manipulate the history by `pushState` and `replaceState`
  - `pushState(state: any, title: string, path?: string)`, this add a new entry to the history object, and attach a `state` object to it, you can update the `path` at the same time, which doesn't send a query to the server;
- `popstate` event is triggered when you use `back`, `forward` or `go` method;
- Hash change triggers both `hashchange` and `popstate` event;

## Web Performance

[Google web performance tips on Youtube](https://www.youtube.com/playlist?list=PLNYkxOF6rcICVl6Vb-AFlw81bQLuv6a_P)

[Running Your JavaScript at the Right Time](https://www.kirupa.com/html5/running_your_code_at_the_right_time.htm)

### JS loading best practices

In a HTML page, any referenced JS files need to be loaded, parsed and executed, by default, browsers load scripts synchronously during HTML parsing, so it blocks visible content rendering.

Solutions:

- Good:

  Put most JS tags at the end of `<body>`, so they won't block visible content rendering, but browsers still tend to load them early;

- Better:

  - Set `async` attribute: allow async loading of the script, this means they are loaded independently of other scripts or the HTML document, once downloaded, the browser stop everthing else and execute the script;
  - Set `defer` attribute: similar to `async` and does even more, indicating the script should be executed after the HTML is parsed, but before firing `DOMContentLoaded`;

  But broswer still loads them concurrently with other resources, such as images;

- Best:

  Load script after the page is rendered:

  ```js
  $(window).on('load', function() {
    $('body').append('<script src="script.js">');
  });
  ```

![js script loading](images/js_script_loading.png)
