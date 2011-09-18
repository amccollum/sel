Sel - Sizzle, but smaller
===
Sel is a tiny selector engine that has all of the power of Sizzle in about half the code size.

Sel uses <code>querySelectorAll</code> when available, but will fallback on the custom engine when qSA fails.

Support
-------
Sel supports all of the [CSS3 selectors](http://www.w3.org/TR/css3-selectors/#selectors), as well as the following selector extensions:

    [attr!=val]
    :contains(text)
    :has(selector)

Roots
-----
You can also pass a root context to select from a subset of the document:

``` js
sel.sel('div', node); // a DOM node
sel.sel('div', [node1, node2, node3]); // a list of DOM nodes
sel.sel('div', '#foo'); // a selector
sel.sel('div', sel.sel(div)); // previous result set
```

Unlike Sizzle, which only supports using a single root node, Sel can use any number of nodes as roots for the query.

Custom pseudo-selectors
-------------------

Adding a custom pseudo-selector is easy:

``` js
sel.pseudos.radio = function (el, val) {
    return el.nodeName.toLowerCase() === "input" && el.type === "radio";
};
```

The function is passed the current element and an option value that was passed to the pseudo-selector, and it
should return `true` if the element matches the pseudo-selector and `false` otherwise.

``` js
sel.sel('div:foo(bar)');

sel.pseudos.foo = function (el, val) {
    // val === 'bar'
    return el.getAttribute('foo') === val;
}
```

Browser Support
---------------
Sel (with the [es5-basic](https://github.com/amccollum/es5-basic) module) supports the following browsers

  - IE 6-10
  - Chrome 1 - 12
  - Safari 3-5
  - Firefox 2-5
  - Opera

Tests
-----

CoffeeScript and NPM are required to build the test suite. Since the tests employ iframes, they cannot be run directly from disk.

Ender
-----
It's easy to use Sel with Ender:

    $ ender build sel [module, ...]

Acknowledments
-------
This library was inspired by [Qwery](https://github.com/ded/qwery)
