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

Ender support
-------------
Qwery is the recommended selector engine for [Ender](http://ender.no.de). If you don't have Ender, install it, and don't ever look back.

    $ npm install ender -g

To include Query in a custom build of Ender you can include it as such:

    $ ender build qwery[,mod2,mod3,...]

Or add it to an existing Ender installation

    $ ender add qwery

Ender bridge additions
---------
Assuming you already know the happs on Ender -- Qwery provides some additional niceties when included with Ender:

``` js
// the context finder - find all p elements descended from a div element
$('div').find('p')

// join one set with another
$('div').and('p')

// element creation
$('<p>hello world</p>'); // => [HTMLParagraphElement "hello world"]
```

Recommended sibling modules
----------
In most cases, if you're hunting for a selector engine, you probably want to pair Qwery with a DOM module. In that case qwery pairs quite nicely with [Bonzo](https://github.com/ded/bonzo) (a DOM util) and [Bean](https://github.com/fat/bean) (an event util). Add them to your Ender installation as such:

    $ ender -b qwery bonzo bean

Then write code like a boss:

``` js
$('a.boosh')
  .css({
    color: 'red',
    background: 'white'
  })
  .after('√')
  .bind({
    'click.button': function () {
      $(this).hide().unbind('click.button')
    }
  })
```

Acknowledments
-------
This library was inspired by [Qwery](https://github.com/ded/qwery)
