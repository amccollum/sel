Sel - A small, powerful CSS selector library.
===
Sel is a CSS selector engine, like Sizzle, which forms the core of jQuery.

Sel uses `querySelectorAll` when it's available, but will fallback on the custom engine when qSA fails.

Sel is written in CoffeeScript with an emphasis on making the code clear and easy to understand.

Support
-------
Sel supports all of the [CSS Level 3 Selectors](http://www.w3.org/TR/css3-selectors/#selectors), as well as the following
[Draft CSS Level 4 Selectors](http://dev.w3.org/csswg/selectors4/#overview):

``` css
div! .box                   /* subject overriding */ 
label /for/ input           /* id references */
[attr = "val" i]            /* case insensitive attribute matching */
div:nth-match(3 of .box)    /* :nth-match and :nth-last-match */
a:local-link(0)             /* :local-link */
td:column(col.profit)       /* :column */
td:nth-column(even)         /* :nth-column and :nth-last-column */
```

Sel also supports the following extensions:

``` css
[attr != "val"]
:contains(text)
:with(selector)             /* or :has(selector) */
:without(selector)
```

Roots
-----
You can also pass a root context to select from a subset of the document:

``` js
sel.sel('div', node); // a DOM node
sel.sel('div', [node1, node2, node3]); // a list of DOM nodes
sel.sel('div', '#foo'); // a selector
sel.sel('div', sel.sel('div')); // previous result set
```

Unlike Sizzle, which only supports using a single root node, Sel can use any number of nodes as roots for the query.

Custom pseudo-selectors
-------------------

Adding a custom pseudo-selector is easy:

``` js
sel.pseudos.radio = function (el, val) {
    return el.nodeName.toLowerCase() === "input" && el.type === "radio";
};

sel.sel('input:radio');
```

The function is passed the current element and, optionally, the value that was passed to the pseudo-selector. It
should return `true` if the element matches the pseudo-selector and `false` otherwise.

``` js
sel.pseudos.foo = function (el, val) {
    // val === 'bar'
    return el.getAttribute('foo') === val;
};

sel.sel('div:foo(bar)');
```

For pseudo-selectors that need to operate on the whole set of currently matched elements, add the `batch` attribute:

``` js
sel.pseudos.bar = function (els, val, roots) {
    // Do something with all of the elements
    return els.filter(function (el, i) { return (i < val); });
};

sel.pseudos.bar.batch = true
```

Ender
-----
It's easy to use Sel with Ender:

    $ ender build sel [module, ...]
    
When using Sel with Ender, there are some convenient methods you can take advantage of:

``` js
$('.parent').find('.child')         // Same as $('.parent .child') or $('.child', '.parent')
$('.foo').union('.bar')             // Same as $('.foo, .bar')
$('.baz').difference('.bat')        // Same as $('.baz:not(.bat)')
$('.qux').intersection('.thud')     // Same as $('.qux.thud')
```

You can also use the synonyms `and` and `not`, for `union` and `difference`, respectively.

Browser Support
---------------
Sel (with the [es5-basic](https://github.com/amccollum/es5-basic) module) supports the following browsers

  - IE 6-10
  - Chrome 1-12
  - Safari 3-5
  - Firefox 2-5
  - Opera

Tests
-----
CoffeeScript and NPM are required to build the test suite. Since the tests employ iframes, they cannot be run directly from disk.

Acknowledments
-------
This library was inspired by [Qwery](https://github.com/ded/qwery).
