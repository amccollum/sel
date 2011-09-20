((sel) ->

    ### util.coffee ###

    html = document.documentElement

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

    # Return the outer-most ancestors of the element array
    subsume = (arr) -> arr.filter((el, i) -> el and not (i and (arr[i-1] == el or contains(arr[i-1], el))))

    sel.union = (a, b) ->
        arr = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch elCmp(a[i], b[j])
                when -1 then arr.push(a[i++])
                when 1 then arr.push(b[j++])
                when 0
                    arr.push(a[i++])
                    j++

        while i < a.length
            arr.push(a[i++])

        while j < b.length
            arr.push(b[j++])

        return arr

    sel.intersection = (a, b) ->
        arr = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch elCmp(a[i], b[j])
                when -1 then i++
                when 1 then j++
                when 0 then arr.push(a[i++])

        return arr

    sel.difference = (a, b) -> 
        arr = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch elCmp(a[i], b[j])
                when -1 then arr.push(a[i++])
                when 1 then j++
                when 0 then i++

        while i < a.length
            arr.push(a[i++])

        return arr
    ### find.coffee ###

    find = (roots, m) ->
        if m.id
            els = findId(roots, m.id)
            els = filterTag(els, m.tag) if m.tag
            els = filterClasses(els, m.classes) if m.classes

        else if m.classes and html.getElementsByClassName
            els = findClasses(roots, m.classes)
            els = filterTag(els, m.tag) if m.tag
        
        else
            els = findTag(roots, m.tag or '*')
            els = filterClasses(els, m.classes) if m.classes

        if m.attrs
            for attr in m.attrs
                els = filterAttr(els, attr.name, attr.op, attr.val)

        if m.pseudos
            for pseudo in m.pseudos
                els = filterPseudo(els, pseudo.name, pseudo.val)
            
        return els

    findId = (roots, id) ->
        doc = (roots[0].ownerDocument or roots[0])
        el = doc.getElementById(id)
        if el and roots.some((root) -> contains(root, el))
            return [el]
            
        return []

    findClasses = (roots, classes) ->
        els = []
        for root in roots
            rootEls = []
            for cls in classes
                rootEls = sel.union(rootEls, root.getElementsByClassName(cls))
                
            els = els.concat(rootEls)
            
        return els
            
    findTag = (roots, tag) ->
        els = []
        for root in roots
            for el in root.getElementsByTagName(tag)
                els.push(el)
    
        return els
        
    filterTag = (els, tag) -> els.filter((el) -> el.nodeName.toLowerCase() == tag)

    filterClasses = (els, classes) ->
        for cls in classes
            els = filterAttr(els, 'class', '~=', cls)
                
        return els

    filterAttr = (els, name, op, val) ->
        if val and val[0] in ['"', '\''] and val[0] == val[val.length-1]
            val = val.substr(1, val.length - 2)

        return els.filter (el) ->
            attr = if name == 'class' then el.className else el.getAttribute(name)
            value = attr + ""
                
            attr != null and (
                if not op then true
                else if op == '=' then value == val
                else if op == '!=' then value != val
                else if op == '*=' then value.indexOf(val) >= 0
                else if op == '^=' then value.indexOf(val) == 0
                else if op == '$=' then value.substr(value.length - val.length) == val
                else if op == '~=' then " #{value} ".indexOf(" #{val} ") >= 0
                else if op == '|=' then value == val or (value.indexOf(val) == 0 and value[val.length] == '-')
                else false
            )
    
    filterPseudo = (els, name, val) ->
        pseudo = sel.pseudos[name]
        if not pseudo
            throw new Error("no pseudo with name: #{name}")
        
        return els.filter((el) -> pseudo(el, val))

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
                    # We don't need to search descendents of other roots...
                    outerRoots = subsume(roots)
                    els = find(outerRoots, m)
                
                    if m.type == '>'
                        els = els.filter (el) ->
                            el and (parent = el.parentNode) and roots.some((root) -> parent == root)
            
                    if m.not
                        els = sel.difference(els, find(roots, m.not))
            
                    if m.child
                        els = evaluate(m.child, els)

                when '+', '~', ','
                    sibs = evaluate(m.children[0], roots)
                    els = evaluate(m.children[1], roots)
            
                    if m.type == ','
                        els = sel.union(els, sibs)
                    
                    else if m.type == '+'
                        sibs = sibs.map((el) -> nextElementSibling(el))
                        sibs.sort(elCmp)
                        els = sel.intersection(els, sibs)
                    
                    else if m.type == '~'
                        els = els.filter (el) ->
                            el and (parent = el.parentNode) and sibs.some (sib) ->
                                sib != el and sib.parentNode == parent and elCmp(sib, el) == -1
                
        return els

    ### select.coffee ###

    select =
        if document.querySelector and document.querySelectorAll
            (selector, roots) -> 
                try
                    els = []
                    for root in roots
                        for el in root.querySelectorAll(selector)
                            els.push(el)
            
                    return els
                
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
                
            return subsume(roots)
        
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


)(exports ? (@sel = {}))

