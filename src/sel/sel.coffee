((sel) ->

    ### util.coffee ###

    html = document.documentElement
    
    extend = (a, b) ->
        for x in b
            a.push(x)
    
        return a
                    
    contains =
        if html.compareDocumentPosition?
            (a, b) -> (a.compareDocumentPosition(b) & 16) == 16
    
        else if html.contains?
            (a, b) ->
                if a.documentElement then b.ownerDocument == a
                else a != b and a.contains(b)
                
        else
            (a, b) ->
                if a.documentElement then return b.ownerDocument == a
                while b = b.parentNode
                    return true if a == b

                return false

    comparePosition = 
        if html.compareDocumentPosition
            (a, b) -> a.compareDocumentPosition(b)
    
        else
            (a, b) ->
                (a != b and a.contains(b) and 16) +
                (a != b and b.contains(a) and 8) +
                (if a.sourceIndex < 0 or b.sourceIndex < 0 then 1 else
                    (a.sourceIndex < b.sourceIndex and 4) +
                    (a.sourceIndex > b.sourceIndex and 2))

    nextElementSibling =
        if html.nextElementSibling
            (el) -> el.nextElementSibling
        else
            (el) ->
                while (el = el.nextSibling)
                    return el if el.nodeType == 1
                
                return null

    elCmp = (a, b) ->
        if not a then return -1
        else if not b then return 1
        else if a == b then return 0
        else if comparePosition(a, b) & 4 then -1
        else 1

    # Return the topmost ancestors of the element array
    filterDescendents = (els) -> els.filter (el, i) -> el and not (i and (els[i-1] == el or contains(els[i-1], el)))

    # Helper function for combining sorted arrays in various ways
    combine = (a, b, aRest, bRest, map) ->
        r = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch map[elCmp(a[i], b[j])]
                when -1 then i++
                when -2 then j++
                when 1 then r.push(a[i++])
                when 2 then r.push(b[j++])
                when 0
                    r.push(a[i++])
                    j++

        if aRest
            while i < a.length
                r.push(a[i++])

        if bRest
            while j < b.length
                r.push(b[j++])

        return r
    
    # Define these operations in terms of element operations to reduce code size
    sel.union = (a, b) -> combine a, b, true, true, {'0': 0, '-1': 1, '1': 2}
    sel.intersection = (a, b) -> combine a, b, false, false, {'0': 0, '-1': -1, '1': -2}
    sel.difference = (a, b) -> combine a, b, true, false, {'0': -1, '-1': 1, '1': -2}

    ### find.coffee ###

    find = (roots, m) ->
        if m.id
            els = findId(roots, m.id)

        else if m.classes and html.getElementsByClassName
            els = findClasses(roots, m.classes)
            m.classes = null
        
        else
            els = findTag(roots, m.tag or '*')
            m.tag = null

        return filterAll(els, m)

    findId = (roots, id) ->
        doc = (roots[0].ownerDocument or roots[0])
        el = doc.getElementById(id)
        if el and roots.some((root) -> contains(root, el))
            return [el]
            
        return []

    findClasses = (roots, classes) ->
        roots.map((root) ->
            classes.map((cls) ->
                root.getElementsByClassName(cls)
            ).reduce(sel.union)
        ).reduce(extend, [])
            
    findTag = (roots, tag) ->
        roots.map((root) ->
            root.getElementsByTagName(tag)
        ).reduce(extend, [])

    filterAll = (els, m) ->
        els = filterTag(els, m.tag) if m.tag
        els = filterClasses(els, m.classes) if m.classes

        if m.attrs
            m.attrs.forEach (attr) ->
                els = filterAttr(els, attr.name, attr.op, attr.val)
                return # prevent return from forEach
            
        if m.pseudos
            m.pseudos.forEach (pseudo) ->
                els = filterPseudo(els, pseudo.name, pseudo.val)
                return # prevent return from forEach
            
        return els

    filterTag = (els, tag) -> els.filter((el) -> el.nodeName.toLowerCase() == tag)

    filterClasses = (els, classes) ->
        classes.forEach (cls) ->
            els = els.filter((el) -> " #{el.className} ".indexOf(" #{cls} ") >= 0)
            return # prevent return from forEach
                
        return els

    _attrMap = {
        'tag': 'tagName',
        'class': 'className',
    }
    filterAttr = (els, name, op, val) ->
        if val and val[0] in ['"', '\''] and val[0] == val[val.length-1]
            val = val.substr(1, val.length - 2)

        name = _attrMap[name] or name

        return els.filter (el) ->
            attr = el[name] ? el.getAttribute(name)
            value = attr + ""
            
            return (attr or (el.attributes and el.attributes[name] and el.attributes[name].specified)) and (
                if not op then true
                else if op == '=' then value == val
                else if op == '!=' then value != val
                else if op == '*=' then value.indexOf(val) >= 0
                else if op == '^=' then value.indexOf(val) == 0
                else if op == '$=' then value.substr(value.length - val.length) == val
                else if op == '~=' then " #{value} ".indexOf(" #{val} ") >= 0
                else if op == '|=' then value == val or (value.indexOf(val) == 0 and value[val.length] == '-')
                else false # should never get here...
            )
    
    # All the positional pseudos and whether or not they are reversed
    _positionalPseudos = {
        'nth-child': false
        'nth-of-type': false
        'first-child': false
        'first-of-type': false

        'nth-last-child': true
        'nth-last-of-type': true
        'last-child': true
        'last-of-type': true

        'only-child': false
        'only-of-type': false
    }
    
    filterPseudo = (els, name, val) ->
        pseudo = sel.pseudos[name]
        if not pseudo
            throw new Error("no pseudo with name: #{name}")
        
        if name of _positionalPseudos
            first = if _positionalPseudos[name] then 'lastChild' else 'firstChild'
            next = if _positionalPseudos[name] then 'previousSibling' else 'nextSibling'
            
            els.forEach (el) ->
                indices = { '*': 0 }
                el = (parent = el.parentNode) and parent[first]
                while el
                    if el.nodeType == 1
                        return if el._sel_index != undefined
                        el._sel_index = ++indices['*']
                        el._sel_indexOfType = indices[el.nodeName] = (indices[el.nodeName] or 0) + 1
            
                    el = el[next]
                    
                if parent
                    parent._sel_children = indices
                    
                return # prevent return from forEach
            
        filtered = els.filter((el) -> pseudo(el, val))

        if name of _positionalPseudos
            els.forEach (el) ->
                el = (parent = el.parentNode) and parent[first]
                while el
                    if el.nodeType == 1
                        return if el._sel_index == undefined
                        el._sel_index = el._sel_indexOfType = undefined
        
                    el = el[next]
                        
                if parent
                    parent._sel_children = undefined
                    
                return # prevent return from forEach
                    
        return filtered
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

    ### parser.coffee ###

    attrPattern = ///
        (?:
            \[
                \s* ([-\w]+) \s*
                (?: ([~|^$*!]?=) \s* ( [-\w]+ | ['"][^'"]*['"] ) \s* )?
            \]
        )
    ///g

    pseudoPattern = ///
        (?:
            ::? ([-\w]+) (?: \( ( \( [^()]+ \) | [^()]+ ) \) )?
        )
    ///g

    selectorPattern = ///
        ^ \s*
        (?:
            # tag
            (?: (\* | \w+) )?

            # id
            (?: \# ([-\w]+) )?

            # classes
            (?: \. ([-\.\w]+) )?

            # attributes
            ( #{attrPattern.source}* )
    
            # pseudo
            ( #{pseudoPattern.source}* )

        ) ( [+~>\s]+ )? (,)? # combinator
    ///

    selectorGroups = {
        all: 0, tag: 1, id: 2, classes: 3,
        attrsAll: 4, pseudosAll: 8,
        combinator: 11, comma: 12
    }

    attrGroups = ['attrName', 'attrOp', 'attrVal']
    pseudoGroups = ['pseudoName', 'pseudoVal']

    parseChunk = (state) ->
        rest = state.selector.substr(state.selector.length - state.left)
        if not (m = selectorPattern.exec(rest))
             throw new Error('Parse error.')

        for name, group of selectorGroups
            m[name] = m[group]

        state.left -= m.all.length
    
        m.tag = m.tag.toLowerCase() if m.tag
        m.classes = m.classes.toLowerCase().split('.') if m.classes

        if m.attrsAll
            m.attrs = []
            m.attrsAll.replace attrPattern, (all, name, op, val) ->
                m.attrs.push({name: name, op: op, val: val})
                return ""
        
        if m.pseudosAll
            m.pseudos = []
            m.pseudosAll.replace pseudoPattern, (all, name, val) ->
                if name == 'not'
                    m.not = parse(val)
                else
                    m.pseudos.push({name: name, val: val})
                
                return ""
            
        if not state.left
            m.combinator = '$'
        else if m.comma
            m.combinator = ','
        else
            m.combinator = m.combinator.trim() or ' '

        return m

    parseSimple = (type, state) ->
        m = parseChunk(state)
        m.type = type

        switch m.combinator
            # descending selectors
            when ' ', '>'
                m.child = parseSimple(m.combinator, state)
    
            # combining selectors
            when '+', '~', ','
                state.rewind = m.combinator
        
            # end of input
            when '$'
                state.rewind = null
        
        return m

    parse = (selector) ->
        state = {
            selector: selector,
            left: selector.length,
        }

        m = parseSimple(' ', state)
        while state.rewind
            m = {
                type: state.rewind,
                children: [m, parseSimple(' ', state)],
            }

        return m

    ### eval.coffee ###

    evaluate = (m, roots) ->
        els = []

        if roots.length
            switch m.type
                when ' ', '>'
                    # Normally, we're searching all descendents anyway
                    outerRoots = filterDescendents(roots)
                    els = find(outerRoots, m)

                    if m.type == '>'
                        roots.forEach (el) ->
                            el._sel_mark = true
                            return
                            
                        els = els.filter((el) -> el._sel_mark if (el = el.parentNode))

                        roots.forEach (el) ->
                            el._sel_mark = false
                            return
                            
                    if m.not
                        els = sel.difference(els, find(outerRoots, m.not))
            
                    if m.child
                        els = evaluate(m.child, els)

                when '+', '~', ','
                    sibs = evaluate(m.children[0], roots)
                    els = evaluate(m.children[1], roots)
            
                    if m.type == ','
                        # sibs here is just the result of the first selector
                        els = sel.union(sibs, els)
                    
                    else if m.type == '+'
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = true 
                                
                            return
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = undefined
                                
                            return
                    
                    else if m.type == '~'
                        sibs.forEach (el) ->
                            while (el = nextElementSibling(el)) and not el._sel_mark
                                el._sel_mark = true
                                
                            return
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            while (el = nextElementSibling(el)) and el._sel_mark
                                el._sel_mark = undefined
                                
                            return

        return els

    ### select.coffee ###

    select =
        if document.querySelector and document.querySelectorAll
            (selector, roots) -> 
                try
                    return roots.map((root) ->
                        root.querySelectorAll(selector)
                    ).reduce(extend, [])
                
                catch e
                    return evaluate(parse(selector), roots)
            
        else
            (selector, roots) -> evaluate(parse(selector), roots)

    normalizeRoots = (roots) ->
        if not roots
            return [document]
        
        else if typeof roots == 'string'
            return select(roots, [document])
        
        else if typeof roots == 'object' and isFinite(roots.length)
            if roots.sort
                roots.sort(elCmp)
                
            return filterDescendents(roots)
        
        else
            return [roots]

    sel.sel = (selector, roots) ->
        roots = normalizeRoots(roots)

        if not selector
            return []
        else if selector in [window, 'window']
            return [window]
        else if selector in [document, 'document']
            return [document]
        else if selector.nodeType == 1
            if roots.some((root) -> contains(root, selector))
                return [selector]
            else
                return []
        else
            return select(selector, roots)

)(exports ? (@['sel'] = {}))

