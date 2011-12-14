    ### pseudos.coffee ###

    nthPattern = ///
        \s*
        (\+|\-)? (\d*)n      # Coefficient
        \s*
        (?: (\+|\-) \s* (\d+))?  # Constant
        \s*
    ///

    checkNth = (i, val) ->
        if not val then false
        else if isFinite(val) then `i == val`       # Use loose equality check since val could be a string
        else if val == 'even' then (i % 2 == 0)
        else if val == 'odd' then (i % 2 == 1)
        else if m = nthPattern.exec(val)
            # Convert values and check omissions
            a = parseInt((m[1] or '+') + (if m[2] == '' then '1' else m[2]))
            b = parseInt((m[3] or '+') + (if m[4] == '' then '0' else m[4]))

            if not a then (i == b)
            else (((i - b) % a == 0) and ((i - b) / a >= 0))

        else throw new Error('invalid nth expression')

    sel.pseudos = 
        # CSS 3
        selected: (el) -> el.selected == true
        focus: (el) -> el.ownerDocument.activeElement == el
        
        enabled: (el) -> el.disabled == false
        checked: (el) -> el.checked == true
        disabled: (el) -> el.disabled == true
        
        # See filter() for how el._sel_* values get set
        'first-child': (el) -> el._sel_index == 1
        'only-child': (el) -> el._sel_index == 1 and el.parentNode._sel_children['*'] == 1
        'nth-child': (el, val) -> checkNth(el._sel_index, val)

        'first-of-type': (el) -> el._sel_indexOfType == 1
        'only-of-type': (el) -> el._sel_indexOfType == 1 and el.parentNode._sel_children[el.nodeName] == 1
        'nth-of-type': (el, val) -> checkNth(el._sel_indexOfType, val)

        root: (el) -> (el.ownerDocument.documentElement == el)
        target: (el) -> (el.getAttribute('id') == location.hash.substr(1))
        empty: (el) -> not el.childNodes.length

        # CSS 4
        'local-link': (el, val) ->
            return false if not el.href

            href = el.href.replace(/#.*?$/, '')
            location = el.ownerDocument.location.href.replace(/#.*?$/, '')
            
            if val == undefined
                return href == location
            else
                # Split into parts and remove protocol
                href = href.split('/').slice(2)
                location = location.split('/').slice(2)
                
                for i in [0..val] by 1
                    if href[i] != location[i]
                        return false
                        
                return true

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
        

