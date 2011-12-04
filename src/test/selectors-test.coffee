assert = require('assert')
vows = require('vows')


selectors = {
    'body': 1,
    'div': 51,
    'body div': 51,
    'div p': 140,
    'div > p': 134,
    'div + p': 22,
    'div ~ p': 183,
    'div[class^=exa][class$=mple]': 43,
    'div p a': 12,
    'div, p, a': 671,
    '.note': 14,
    'div.example': 43,
    'ul .tocline2': 12,
    'div.example, div.note': 44,
    '#title': 1,
    'h1#title': 1,
    'div #title': 1,
    'ul.toc li.tocline2': 12,
    'ul.toc > li.tocline2': 12,
    'h1#title + div > p': 0,
    'h1[id]:contains(Selectors)': 1,
    'a[href][lang][class]': 1,
    'div[class]': 51,
    'div[class=example]': 43,
    'div[class^=exa]': 43,
    'div[class$=mple]': 43,
    'div[class*=e]': 50,
    'div[class|=dialog]': 0,
    'div[class!=made_up]': 51,
    'div[class~=example]': 43,
    'div:not(.example)': 8,
    'p:contains(selectors)': 54,
    'div:has(p a)': 4,
    'div:with(p a)': 4,
    'div:without(p a)': 47,
    'p:nth-child(even)': 158,
    'p:nth-child(2n)': 158,
    'p:nth-child(odd)': 166,
    'p:nth-child(2n+1)': 166,
    'p:nth-child(n)': 324,
    'p:first-child': 54,
    'p:last-child': 19,
    'p:only-child': 3,
    'p:nth-of-type(even)': 148,
    'p:nth-of-type(2n)': 148,
    'p:nth-of-type(odd)': 176,
    'p:nth-of-type(2n+1)': 176,
    'p:nth-of-type(n)': 324,
    'p:first-of-type': 57,
    'p:last-of-type': 57,
    'p:only-of-type': 15,
}

tests = {}
for s, num of selectors
    do (s, num) ->
        tests[s] = ($, root) -> assert.equal $(s, root).length, num

testTopic = (lib, success) ->
    el = document.createElement('iframe')
    el.src = 'template.html'
    el.style.width = 0
    el.style.height = 0
    el.style.display = 'none'
    el.style.visibility = 'hidden'
    
    onload = ->
        doc = el.contentWindow or el.contentDocument
        if (doc.document) doc = doc.document
        success(lib, doc)
        return
        
    if window.addEventListener
        el.addEventListener 'load', onload
    else
        el.attachEvent 'onload', onload
    
    document.body.appendChild(el)
    return
    

vows.add 'Slickspeed Selectors',
    'sel': 
        topic: () -> testTopic(require('sel').sel, @success)
        '':  tests

    # 'sizzle': 
    #     topic: () -> testTopic(require('sizzle'), @success)
    #     '':  tests

    # 'qwery': 
    #      topic: () -> testTopic(require('qwery'), @success)
    #      '':  tests
