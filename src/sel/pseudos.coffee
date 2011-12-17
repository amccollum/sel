    ### pseudos.coffee ###

    sel.pseudos = pseudos = 
        # CSS 3
        selected: (el) -> el.selected == true
        focus: (el) -> el.ownerDocument.activeElement == el
        
        enabled: (el) -> el.disabled == false
        checked: (el) -> el.checked == true
        disabled: (el) -> el.disabled == true
        
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
        
    # :not and :matches
    pseudos.matches = (els, val, roots, matchRoots) -> intersection(els, select(val, roots, matchRoots))
    pseudos.matches.batch = true
    
    pseudos.not = (els, val, roots, matchRoots) -> difference(els, select(val, roots, matchRoots))
    pseudos.not.batch = true

    # Pseudo Synonyms
    pseudos['has'] = pseudos['with']

    # Positional Pseudos
    do ->
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

        # nth-match and nth-last-match
        nthMatch = (reversed) ->
            return (els, val, roots) ->
                val = val.split(' of ', 1)
                
                set = select(val[1], roots)
                len = set.length
            
                set.forEach (el, i) ->
                    el._sel_index = (if reversed then (len - i) else i) + 1
                    return

                filtered = els.filter((el) -> checkNth(el._sel_index, val[0]))
            
                set.forEach (el, i) ->
                    el._sel_index = undefined
                    return
            
                return filtered
        
        pseudos['nth-match'] = nthMatch()
        pseudos['nth-match'].batch = true
        
        pseudos['nth-last-match'] = nthMatch(true)
        pseudos['nth-last-match'].batch = true

        # All other positional pseudo-selectors
        nthPositional = (fn, reversed) ->
            first = if reversed then 'lastChild' else 'firstChild'
            next = if reversed then 'previousSibling' else 'nextSibling'

            return (els) ->
                els.forEach (el) ->
                    if (parent = el.parentNode) and parent._sel_children == undefined
                        indices = { '*': 0 }
                        eachElement parent, first, next, (el) ->
                            el._sel_index = ++indices['*']
                            el._sel_indexOfType = indices[el.nodeName] = (indices[el.nodeName] or 0) + 1
                            return

                        parent._sel_children = indices

                    return
                
                filtered = els.filter((el) -> fn(el))

                els.forEach (el) ->
                    if (parent = el.parentNode) and parent._sel_children != undefined
                        eachElement parent, first, next, (el) ->
                            el._sel_index = el._sel_indexOfType = undefined
                            return
                    
                        parent._sel_children = undefined
        
                    return
                
                return filtered

        positionalPseudos = {
            'first-child': (el) -> el._sel_index == 1
            'only-child': (el) -> el._sel_index == 1 and el.parentNode._sel_children['*'] == 1
            'nth-child': (el, val) -> checkNth(el._sel_index, val)

            'first-of-type': (el) -> el._sel_indexOfType == 1
            'only-of-type': (el) -> el._sel_indexOfType == 1 and el.parentNode._sel_children[el.nodeName] == 1
            'nth-of-type': (el, val) -> checkNth(el._sel_indexOfType, val)
        }
        
        for name, fn of positionalPseudos
            pseudos[name] = nthPositional(fn)
            pseudos[name].batch = true

            # Reversed versions -- the same only set positions in reverse order
            if name.substr(0, 4) != 'only'
                name = name.replace('first', 'last').replace('nth', 'nth-last')
                pseudos[name] = nthPositional(fn, true)
                pseudos[name].batch = true

    
