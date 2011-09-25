    ### pseudos.coffee ###

    nthPattern = /\s*((?:\+|\-)?(\d*))n\s*((?:\+|\-)\s*\d+)?\s*/;

    checkNth = (i, val) ->
        if not val then false
        else if isFinite(val) then `i == val`       # Use loose equality check since val could be a string
        else if val == 'even' then (i % 2 == 0)
        else if val == 'odd' then (i % 2 == 1)
        else if m = nthPattern.exec(val)
            a = if m[2] then parseInt(m[1]) else parseInt(m[1] + '1')   # Check case where coefficient is omitted
            b = if m[3] then parseInt(m[3].replace(/\s*/, '')) else 0   # Check case where constant is omitted

            if not a then (i == b)
            else (((i - b) % a == 0) and ((i - b) / a >= 0))

        else throw new Error('invalid nth expression')

    sel.pseudos = 
        # See filterPseudo for how el._sel_* values get set
        'first-child': (el) -> el._sel_index == 1
        'only-child': (el) -> el._sel_index == 1 and el.parentNode._sel_children['*'] == 1
        'nth-child': (el, val) -> checkNth(el._sel_index, val)

        'first-of-type': (el) -> el._sel_indexOfType == 1
        'only-of-type': (el) -> el._sel_indexOfType == 1 and el.parentNode._sel_children[el.nodeName] == 1
        'nth-of-type': (el, val) -> checkNth(el._sel_indexOfType, val)

        target: (el) -> (el.getAttribute('id') == location.hash.substr(1))
        checked: (el) -> el.checked == true
        enabled: (el) -> el.disabled == false
        disabled: (el) -> el.disabled == true
        selected: (el) -> el.selected == true
        focus: (el) -> el.ownerDocument.activeElement == el
        empty: (el) -> not el.childNodes.length

        # Extensions
        contains: (el, val) -> (el.textContent ? el.innerText).indexOf(val) >= 0
        with: (el, val) -> select(val, [el]).length > 0
        without: (el, val) -> select(val, [el]).length == 0

    # Pseudo function synonyms
    (sel.pseudos[synonym] = sel.pseudos[name]) for synonym, name of {
        'has': 'with',
        
        # For these methods, the reversing is done in filterPseudo
        'last-child': 'first-child',
        'nth-last-child': 'nth-child',

        'last-of-type': 'first-of-type',
        'nth-last-of-type': 'nth-of-type',
    }
        

