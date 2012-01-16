    ### pseudos.coffee ###

    sel.pseudos = pseudos = 
        # CSS 3
        selected: (el) -> el.selected == true
        focus: (el) -> el.ownerDocument.activeElement == el
        
        enabled: (el) -> el.disabled == false
        checked: (el) -> el.checked == true
        disabled: (el) -> el.disabled == true
        
        root: (el) -> (el.ownerDocument.documentElement == el)
        target: (el) -> (el.id == location.hash.substr(1))
        empty: (el) -> not el.childNodes.length

        # CSS 4
        dir: (el, val) ->
            while el
                if el.dir
                    return el.dir == val
                    
                el = el.parentNode
            
            return false
        
        lang: (el, val) ->
            while el
                if (lang = el.lang)
                    return lang == val or lang.indexOf("#{val}-") == 0
                    
                el = el.parentNode
            
            el = select('head meta[http-equiv="Content-Language" i]', el.ownerDocument)[0]
            if el
                lang = getAttribute(el, 'content').split(',')[0]
                return lang == val or lang.indexOf("#{val}-") == 0
            
            return false
        
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
        
    # Pseudo Synonyms
    pseudos['has'] = pseudos['with']

    # :not and :matches
    pseudos.matches = (els, val, roots, matchRoots) -> intersection(els, select(val, roots, matchRoots))
    pseudos.matches.batch = true
    
    pseudos.not = (els, val, roots, matchRoots) -> difference(els, select(val, roots, matchRoots))
    pseudos.not.batch = true

    # Positional Pseudos
    do ->
        nthPattern = ///
            ^
            \s*
            
            ( even | odd | 
                (?: (\+|\-)? (\d*)(n))?         # Coefficient
                (?: \s* (\+|\-)? \s* (\d+))?    # Constant
            )
            
            (?: \s+ of \s+ (.*?))?              # Match expr

            \s*
            $
        ///

        checkNth = (i, m) ->
            a = parseInt((m[2] or '+') + (if m[3] == '' then (if m[4] then '1' else '0') else m[3]))
            b = parseInt((m[5] or '+') + (if m[6] == '' then '0' else m[6]))
            
            if m[1] == 'even' then (i % 2 == 0)
            else if m[1] == 'odd' then (i % 2 == 1)
            else if a then (((i - b) % a == 0) and ((i - b) / a >= 0))
            else if b then (i == b)
            else throw new Error('Invalid nth expression')

        # column, nth-column and nth-last-column
        matchColumn = (nth, reversed) ->
            first = if reversed then 'lastChild' else 'firstChild'
            next = if reversed then 'previousSibling' else 'nextSibling'

            return (els, val, roots) ->
                set = []
                if nth
                    m = nthPattern.exec(val)
                    check = (i) -> checkNth(i, m)
                    
                select('table', roots).forEach (table) ->
                    if not nth
                        col = select(val, [table])[0]
                        
                        min = 0
                        eachElement col, 'previousSibling', 'previousSibling', (col) ->
                            min += parseInt(col.getAttribute('span') or 1)
                        
                        max = min + parseInt(col.getAttribute('span') or 1)
                        check = (i) -> min < i <= max
                    
                    for tbody in table.tBodies
                        eachElement tbody, 'firstChild', 'nextSibling', (row) ->
                            return if row.tagName.toLowerCase() != 'tr'
                            
                            i = 0
                            eachElement row, first, next, (col) ->
                                span = parseInt(col.getAttribute('span') or 1)
                                while span
                                    set.push(col) if check(++i)
                                    span--
                                
                                return
                            
                            return
                    
                    return
                
                return intersection(els, set)
        
        pseudos['column'] = matchColumn(false)
        pseudos['column'].batch = true

        pseudos['nth-column'] = matchColumn(true)
        pseudos['nth-column'].batch = true

        pseudos['nth-last-column'] = matchColumn(true, true)
        pseudos['nth-last-column'].batch = true
        
        # nth-match and nth-last-match
        nthMatchPattern = ///^(.*?) \s* of \s* (.*)$///
        
        nthMatch = (reversed) ->
            return (els, val, roots) ->
                m = nthPattern.exec(val)
                set = select(m[7], roots)
                len = set.length
            
                set.forEach (el, i) ->
                    el._sel_index = (if reversed then (len - i) else i) + 1
                    return

                filtered = els.filter((el) -> checkNth(el._sel_index, m))
            
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

            return (els, val) ->
                m = nthPattern.exec(val) if val

                els.forEach (el) ->
                    if (parent = el.parentNode) and parent._sel_children == undefined
                        indices = { '*': 0 }
                        eachElement parent, first, next, (el) ->
                            el._sel_index = ++indices['*']
                            el._sel_indexOfType = indices[el.nodeName] = (indices[el.nodeName] or 0) + 1
                            return

                        parent._sel_children = indices

                    return
                
                filtered = els.filter((el) -> fn(el, m))

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
            'nth-child': (el, m) -> checkNth(el._sel_index, m)

            'first-of-type': (el) -> el._sel_indexOfType == 1
            'only-of-type': (el) -> el._sel_indexOfType == 1 and el.parentNode._sel_children[el.nodeName] == 1
            'nth-of-type': (el, m) -> checkNth(el._sel_indexOfType, m)
        }
        
        for name, fn of positionalPseudos
            pseudos[name] = nthPositional(fn)
            pseudos[name].batch = true

            # Reversed versions -- the same only set positions in reverse order
            if name.substr(0, 4) != 'only'
                name = name.replace('first', 'last').replace('nth', 'nth-last')
                pseudos[name] = nthPositional(fn, true)
                pseudos[name].batch = true

        return
        
    
