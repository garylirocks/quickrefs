# jQuery

## Deferred and Promises

    // create a deferred object by
    var dfd = jQuery.Deferred();

    // create a promise object by
    var promise = dfd.promise();

the differences between them:

The Promise exposes only the Deferred methods needed to attach additional handlers or determine the state(`then`, `done`, `fail`, `always`, `pipe`, `progress`, `state`, `promise`),  
**NOT** the ones that change the state (`resolve`, `reject`, `notify`, `resolveWith`, `rejectWith` and `notifyWith`)

### AJAX and Promises

the AJAX function `$.ajax()` returns a jqXHR object, it implements the Promise interface, so you can add callbacks to it by `.done()`, `.fail()` and `.always()`

### Synchronise asynchronous actions

do something only when multiple actions are completed:

    $.when(promise1, promise2).done(function() {
    	// do something here, it will only be executed when both the promises have been resolved
    })
