### pseudos.coffee ###

nthPattern = /\s*((?:\+|\-)?(\d*))n\s*((?:\+|\-)\s*\d+)?\s*/;

children = (el, ofType) ->
    return (child for child in el.childNodes when child.nodeType == 1 and (not ofType or child.nodeName == ofType))

checkNthExpr = (el, els, a, b) ->
    if not a
        return el == els[b-1]
    else
        `
        for (var i = b; (a > 0 ? i <= els.length : i >= 1); i += a)
            if (el === els[i-1])
                return true;
                
        `
        return false

checkNth = (el, els, val) ->
    if not val then false
    else if isFinite(val) then el == els[val-1]
    else if val == 'even' then checkNthExpr(el, els, 2, 0)
    else if val == 'odd' then checkNthExpr(el, els, 2, 1)
    else if m = nthPattern.exec(val)
        a = if m[2] then parseInt(m[1]) else parseInt(m[1] + '1')   # Check case where coefficient is omitted
        b = if m[3] then parseInt(m[3].replace(/\s*/, '')) else 0   # Check case where constant is omitted
        return checkNthExpr(el, els, a, b)
    else throw new Error('invalid nth expression')

sel.pseudos = 
    'nth-child': (el, val) -> ((p = el.parentNode) and (els = children(p)) and checkNth(el, els, val))
    'nth-last-child': (el, val) -> ((p = el.parentNode) and (els = children(p).reverse()) and checkNth(el, els, val))
    'nth-of-type': (el, val) -> ((p = el.parentNode) and (els = children(p, el.nodeName)) and checkNth(el, els, val))
    'nth-last-of-type': (el, val) -> ((p = el.parentNode) and (els = children(p, el.nodeName).reverse()) and checkNth(el, els, val))
    
    'first-child': (el) -> sel.pseudos['nth-child'](el, 1)
    'last-child': (el) -> sel.pseudos['nth-last-child'](el, 1)
    'first-of-type': (el) -> sel.pseudos['nth-of-type'](el, 1)
    'last-of-type': (el) -> sel.pseudos['nth-last-of-type'](el, 1)
    
    'only-child': (el) -> ((p = el.parentNode) and (els = children(p)) and (els.length == 1) and (el == els[0]))
    'only-of-type': (el) -> ((p = el.parentNode) and (els = children(p, el.nodeName)) and (els.length == 1) and (el == els[0]))

    contains: (el, val) -> (el.textContent ? el.innerText).indexOf(val) >= 0
    target: (el) -> (el.getAttribute('id') == location.hash.substr(1))
    checked: (el) -> el.checked
    enabled: (el) -> not el.disabled
    disabled: (el) -> el.disabled
    empty: (el) -> !el.childNodes.length

