    ### pseudos.coffee ###

    nthPattern = /\s*((?:\+|\-)?(\d*))n\s*((?:\+|\-)\s*\d+)?\s*/;

    childIndex = (el, reversed, ofType) ->
        start = if reversed then 'lastChild' else 'firstChild'
        next = if reversed then 'previousSibling' else 'nextSibling'
    
        index = 0
        node = el.parentNode and el.parentNode[start]
        while node
            if ofType and node.nodeName != ofType
                continue
            
            if node.nodeType == 1
                index++
        
            if node == el
                return index
            
            node = node[next]

        return NaN

    checkNth = (i, val) ->
        if not val then false
        else if isFinite(val) then `i == val`
        else if val == 'even' then (i % 2 == 0)
        else if val == 'odd' then (i % 2 == 1)
        else if m = nthPattern.exec(val)
            a = if m[2] then parseInt(m[1]) else parseInt(m[1] + '1')   # Check case where coefficient is omitted
            b = if m[3] then parseInt(m[3].replace(/\s*/, '')) else 0   # Check case where constant is omitted

            if not a then i == b
            else ((i - b) % a == 0 and (i - b) / a >= 0)

        else throw new Error('invalid nth expression')

    sel.pseudos = 
        'nth-child': (el, val) -> checkNth(childIndex(el), val)
        'nth-last-child': (el, val) -> checkNth(childIndex(el, true), val)
        'nth-of-type': (el, val) -> checkNth(childIndex(el, false, el.nodeName), val)
        'nth-last-of-type': (el, val) -> checkNth(childIndex(el, true, el.nodeName), val)
    
        'first-child': (el) -> childIndex(el) == 1
        'last-child': (el) -> childIndex(el, true) == 1
        'first-of-type': (el) -> childIndex(el, false, el.nodeName) == 1
        'last-of-type': (el) -> childIndex(el, true, el.nodeName) == 1
    
        'only-child': (el) -> childIndex(el) == 1 and childIndex(el, true) == 1
        'only-of-type': (el) -> childIndex(el, false, el.nodeName) == 1 and childIndex(el, true, el.nodeName) == 1

        target: (el) -> (el.getAttribute('id') == location.hash.substr(1))
        checked: (el) -> el.checked == true
        enabled: (el) -> el.disabled == false
        disabled: (el) -> el.disabled == true
        selected: (el) -> el.selected == true
        focus: (el) -> el.ownerDocument.activeElement == el
        empty: (el) -> not el.childNodes.length

        contains: (el, val) -> (el.textContent ? el.innerText).indexOf(val) >= 0
    	has: (el, val) -> select(val, [el]).length > 0


