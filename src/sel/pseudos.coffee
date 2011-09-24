    ### pseudos.coffee ###

    nthPattern = /\s*((?:\+|\-)?(\d*))n\s*((?:\+|\-)\s*\d+)?\s*/;

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
        # See filterPseudo for how the el._sel_* values get set
        'nth-child': (el, val) -> checkNth(el._sel_index, val)
        'nth-of-type': (el, val) -> checkNth(el._sel_indexOfType, val)
        'first-child': (el) -> el._sel_index == 1
        'first-of-type': (el) -> el._sel_indexOfType == 1
        'only-child': (el) -> el._sel_index == 1 and el.parentNode._sel_children['*'] == 1
        'only-of-type': (el) -> el._sel_indexOfType == 1 and el.parentNode._sel_children[el.nodeName] == 1

        target: (el) -> (el.getAttribute('id') == location.hash.substr(1))
        checked: (el) -> el.checked == true
        enabled: (el) -> el.disabled == false
        disabled: (el) -> el.disabled == true
        selected: (el) -> el.selected == true
        focus: (el) -> el.ownerDocument.activeElement == el
        empty: (el) -> not el.childNodes.length

        contains: (el, val) -> (el.textContent ? el.innerText).indexOf(val) >= 0
        with: (el, val) -> select(val, [el]).length > 0
        without: (el, val) -> select(val, [el]).length == 0

    _synonyms = {
        'has': 'with',
        
        # For these methods, the reversing is done in filterPseudo
        'nth-last-child': 'nth-child',
        'nth-last-of-type': 'nth-of-type',
        'last-child': 'first-child',
        'last-of-type': 'first-of-type',
    }
    
    for synonym, name of _synonyms
        sel.pseudos[synonym] = sel.pseudos[name]

