HTML
===========

- [DOM Events](#dom-events)
  - [Event Bubbling and Capturing](#event-bubbling-and-capturing)
    - [Bubbling](#bubbling)
    - [Capturing](#capturing)
  - [Passive Event Listeners](#passive-event-listeners)
- [History API](#history-api)


## DOM Events

* You can only call `preventDefault` on `cancelable` event;


### Event Bubbling and Capturing

#### Bubbling

* `event.target` is always the original inner most element;
* `event.currentTarget` is the same as `this`, where the current handler is bound to;
* An event can bubble from the target to `<html>`, `document` object, even `window` object;
* **Most events bubble**, but not all, like `focus`;
* `event.stopPropagation()` stop the bubbling process, `event.stopImmediatePropagation()` stop the bubbling and prevent other handlers on the current target from running;
* You can write data to the event in one handler and read it from another one;

#### Capturing

![Event Phases](images/dom_event-phases.png)

* As in the diagram, an event actually has three phases, but the capturing phase is seldomly used;
* Use the third parameter to add handler to the capturing phase:

    ```js
    element.addEventListener('click', handler, true);
    // or
    element.addEventListener('click', handler, { capture: true });
    ```


### Passive Event Listeners

[Passive event listeners](https://github.com/WICG/EventListenerOptions/blob/gh-pages/explainer.md)

* Scrolling blocks on touch and wheel event listeners (`touchstart`, `touchmove`, `touchend`, `wheel`), the browser is waiting the handler to finish to see if there is any `preventDefault`, which will disable scrolling;

    ```js
    // 'preventDefault' here will prevent scrolling
    // if there is no 'preventDefault', scrolling is still blocked on this event listener
    document.addEventListener('wheel', (e) => {
        e.preventDefault();
    });
    ```

* You can add an option `{passive: true}` to the event listeners to indicate that it will never invoke `preventDefault`;

    ```js
    // call 'preventDefault' in handler will have no effects and result in an error
    document.addEventListener('wheel', handler, { passive: true });
    ```

* This is a breaking change to the `addEventListener` method, previously the third param is of boolean type, indicating whether respond in `capture` phase, so you may need to add a polyfill or do a feature detection;


## History API

* HTML5 supports history API;
* You can manipulate the history by `pushState`, `replaceState`, and listen for `popstate` event;
* `pushState(state: any, title: string, path?: string)`, this add a new entry to the history object, and attach a `state` object to it, you can update the `path` at the same time, which doesn't send a query to the server;
* `popstate` happens when you use `back`, `forward`, `go`;