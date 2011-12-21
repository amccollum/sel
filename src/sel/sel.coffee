((sel) ->

    ### util.coffee ###

    html = document.documentElement
    
    extend = (a, b) ->
        for x in b
            a.push(x)
    
        return a
        
    takeElements = (els) -> els.filter((el) -> el.nodeType == 1)

    eachElement = (el, first, next, fn) ->
        el = el[first]
        while (el)
            fn(el) if el.nodeType == 1
            el = el[next]
            
        return
        
    nextElementSibling =
        if html.nextElementSibling
            (el) -> el.nextElementSibling
        else
            (el) ->
                el = el.nextSibling
                while (el and el.nodeType != 1)
                    el = el.nextSibling
                
                return el

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

    elCmp =
        if html.compareDocumentPosition
            (a, b) ->
                if a == b then 0
                else if a.compareDocumentPosition(b) & 4 then -1
                else 1
                
        else if html.sourceIndex                                                    
            (a, b) ->
                if a == b then 0
                else if a.sourceIndex < b.sourceIndex then -1
                else 1
                
    # Return the outermost elements of the array
    filterDescendants = (els) -> els.filter (el, i) -> el and not (i and (els[i-1] == el or contains(els[i-1], el)))

    # Return descendants one level above the given elements
    outerParents = (els) -> filterDescendents(els.map((el) -> el.parentNode))
        
    # Return the topmost root elements of the array
    findRoots = (els) ->
        r = []
        els.forEach (el) ->
            while el.parentNode
                el = el.parentNode
            
            if r[r.length-1] != el
                r.push(el)
                
            return
        
        return r
        
    # Helper function for combining sorted element arrays in various ways
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
    
    # Define these operations in terms of the above element operations to reduce code size
    sel.union = (a, b) -> combine a, b, true, true, {'0': 0, '-1': 1, '1': 2}
    sel.intersection = (a, b) -> combine a, b, false, false, {'0': 0, '-1': -1, '1': -2}
    sel.difference = (a, b) -> combine a, b, true, false, {'0': -1, '-1': 1, '1': -2}

    ### parser.coffee ###

    attrPattern = ///
        \[
            \s* ([-\w]+) \s*
            (?: ([~|^$*!]?=) \s* (?: ([-\w]+) | ['"]([^'"]*)['"] ) \s* )?
        \]
    ///g

    pseudoPattern = ///
        ::? ([-\w]+) (?: \( ( \( [^()]+ \) | [^()]+ ) \) )?
    ///g
    
    combinatorPattern = /// ^ \s* ([,+~]) ///
    
    selectorPattern = /// ^ 
        
        (?: \s* (>) )? # child selector
        
        \s*
        
        # tag
        (?: (\* | \w+) )?

        # id
        (?: \# ([-\w]+) )?

        # classes
        (?: \. ([-\.\w]+) )?

        # attrs
        ( (?: #{attrPattern.source} )* )

        # pseudos
        ( (?: #{pseudoPattern.source} )* )

    ///

    selectorGroups = {
        type: 1, tag: 2, id: 3, classes: 4,
        attrsAll: 5, pseudosAll: 10
    }

    parse = (selector) ->
        if selector of parse.cache
            return parse.cache[selector]
            
        result = last = e = parseSimple(selector)
        
        if e.compound
            e.children = []
        
        while e[0].length < selector.length
            selector = selector.substr(last[0].length)
            e = parseSimple(selector)
            
            if e.compound
                e.children = [result]
                result = e
                
            else if last.compound
                last.children.push(e)
                
            else
                last.child = e
                
            last = e

        return (parse.cache[selector] = result)

    parse.cache = {}
    
    parseSimple = (selector) ->
        if e = combinatorPattern.exec(selector)
            e.compound = true
            e.type = e[1]
            
        else if e = selectorPattern.exec(selector)
            e.simple = true

            for name, group of selectorGroups
                e[name] = e[group]

            e.type or= ' '
            e.tag and= e.tag.toLowerCase()
            e.classes = e.classes.toLowerCase().split('.') if e.classes

            if e.attrsAll
                e.attrs = []
                e.attrsAll.replace attrPattern, (all, name, op, val, quotedVal) ->
                    name = name.toLowerCase()
                    val or= quotedVal
                    
                    if op == '='
                        # Special cases...
                        if name == 'id' and not e.id
                            e.id = val
                            return ""
                            
                        else if name == 'class'
                            if e.classes
                                e.classes.append(val)
                            else
                                e.classes = [val]

                            return ""
                    
                    e.attrs.push({name: name, op: op, val: val})
                    return ""

            if e.pseudosAll
                e.pseudos = []
                e.pseudosAll.replace pseudoPattern, (all, name, val) ->
                    name = name.toLowerCase()

                    if name == 'not'
                        e.not = parse(val)
                    else
                        e.pseudos.push({name: name, val: val})
        
                    return ""
            
        else
            throw new Error("Parse error at: #{selector}")

        return e
    ### find.coffee ###

    # Attributes that we get directly off the node
    _attrMap = {
        'tag': (el) -> el.tagName
        'class': (el) -> el.className
    }
    
    # Map of all the positional pseudos and whether or not they are reversed
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
    

    find = (e, roots) ->
        if e.id
            # Find by id
            els = []
            roots.forEach (root) ->
                doc = root.ownerDocument or root
                
                if root == doc or contains(doc.documentElement, root)
                    el = doc.getElementById(e.id)
                    els.push(el) if el and contains(root, el)
                        
                else
                    # Detached elements, so make filter do the work
                    extend(els, root.getElementsByTagName(e.tag or '*'))
                    
                return # prevent useless return from forEach
            
        else if e.classes and find.byClass
            # Find by class
            els = roots.map((root) ->
                e.classes.map((cls) ->
                    root.getElementsByClassName(cls)
                ).reduce(sel.union)
            ).reduce(extend, [])

            # Don't need to filter on class
            e.ignoreClasses = true
        
        else
            # Find by tag
            els = roots.map((root) ->
                root.getElementsByTagName(e.tag or '*')
            ).reduce(extend, [])
            
            if find.filterComments and (not e.tag or e.tag == '*')
                els = takeElements(els)
            
            # Don't need to filter on tag
            e.ignoreTag = true

        if els and els.length
            els = filter(e, els)
        else
            els = []
            
        e.ignoreTag = undefined
        e.ignoreClasses = undefined
        return els

    filter = (e, els) ->
        if e.id
            # Filter by id
            els = els.filter((el) -> el.id == e.id)
            
        if e.tag and e.tag != '*' and not e.ignoreTag
            # Filter by tag
            els = els.filter((el) -> el.nodeName.toLowerCase() == e.tag)
        
        if e.classes and not e.ignoreClasses
            # Filter by class
            e.classes.forEach (cls) ->
                els = els.filter((el) -> " #{el.className} ".indexOf(" #{cls} ") >= 0)
                return # prevent useless return from forEach

        if e.attrs
            # Filter by attribute
            e.attrs.forEach ({name, op, val}) ->
                
                els = els.filter (el) ->
                    attr = if _attrMap[name] then _attrMap[name](el) else el.getAttribute(name)
                    value = attr + ""
            
                    return (attr or (el.attributes and el.attributes[name] and el.attributes[name].specified)) and (
                        if not op then true
                        else if op == '=' then value == val
                        else if op == '!=' then value != val
                        else if op == '*=' then value.indexOf(val) >= 0
                        else if op == '^=' then value.indexOf(val) == 0
                        else if op == '$=' then value.substr(value.length - val.length) == val
                        else if op == '~=' then " #{value} ".indexOf(" #{val} ") >= 0
                        else if op == '|=' then value == val or (value.indexOf(val) == 0 and value.charAt(val.length) == '-')
                        else false # should never get here...
                    )

                return # prevent useless return from forEach
            
        if e.pseudos
            # Filter by pseudo
            e.pseudos.forEach ({name, val}) ->

                pseudo = sel.pseudos[name]
                if not pseudo
                    throw new Error("no pseudo with name: #{name}")
        
                if name of _positionalPseudos
                    first = if _positionalPseudos[name] then 'lastChild' else 'firstChild'
                    next = if _positionalPseudos[name] then 'previousSibling' else 'nextSibling'
            
                    els.forEach (el) ->
                        if (parent = el.parentNode) and parent._sel_children == undefined
                            indices = { '*': 0 }
                            eachElement parent, first, next, (el) ->
                                el._sel_index = ++indices['*']
                                el._sel_indexOfType = indices[el.nodeName] = (indices[el.nodeName] or 0) + 1
                                return # prevent useless return from eachElement
                    
                            parent._sel_children = indices
                    
                        return # prevent useless return from forEach
            
                # We need to wait to replace els so we can unset the special attributes
                filtered = els.filter((el) -> pseudo(el, val))

                if name of _positionalPseudos
                    els.forEach (el) ->
                        if (parent = el.parentNode) and parent._sel_children != undefined
                            eachElement parent, first, next, (el) ->
                                el._sel_index = el._sel_indexOfType = undefined
                                return # prevent useless return from eachElement
                                
                            parent._sel_children = undefined
                    
                        return # prevent useless return from forEach
                    
                els = filtered

                return # prevent useless return from forEach
            
        return els

    # Feature detection
    do ->
        div = document.createElement('div')

        # Check whether getting url attributes returns the proper value
        div.innerHTML = '<a href="#"></a>'
        if div.firstChild.getAttribute('href') != '#'
            _attrMap['href'] = (el) -> el.getAttribute('href', 2)
            _attrMap['src'] = (el) -> el.getAttribute('src', 2)
            
        # Check if we can select on second class name
        div.innerHTML = '<div class="a b"></div><div class="a"></div>'
        if div.getElementsByClassName and div.getElementsByClassName('b').length
            # Check if we can detect changes
            div.lastChild.className = 'b'
            if div.getElementsByClassName('b').length == 2
                find.byClass = true
                
        # Check if getElementsByTagName returns comments
        div.innerHTML = ''
        div.appendChild(document.createComment(''))
        if div.getElementsByTagName('*').length > 0
            find.filterComments = true
        
        # Prevent IE from leaking memory
        div = null
        
        return # prevent useless return from do
    
    
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
        # See filter() for how el._sel_* values get set
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
        

    ### eval.coffee ###

    evaluate = (e, roots, matchRoots) ->
        els = []

        if roots.length
            switch e.type
                when ' ', '>'
                    # We only need to search from the outermost roots
                    outerRoots = filterDescendants(roots)
                    els = find(e, outerRoots)

                    if e.type == '>'
                        roots.forEach (el) ->
                            el._sel_mark = true
                            return
                        
                        els = els.filter((el) -> el._sel_mark if (el = el.parentNode))

                        roots.forEach (el) ->
                            el._sel_mark = undefined
                            return
                    
                    if e.not
                        els = sel.difference(els, find(e.not, outerRoots, matchRoots))
            
                    if matchRoots
                        els = sel.union(els, filter(e, takeElements(outerRoots)))
            
                    if e.child
                        els = evaluate(e.child, els)

                when '+', '~', ','
                    if e.children.length == 2
                        sibs = evaluate(e.children[0], roots, matchRoots)
                        els = evaluate(e.children[1], roots, matchRoots)
                    else
                        sibs = roots
                        els = evaluate(e.children[0], outerParents(roots), matchRoots)
            
                    if e.type == ','
                        # sibs here is just the result of the first selector
                        els = sel.union(sibs, els)
                    
                    else if e.type == '+'
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = true 
                                
                            return # prevent useless return from forEach
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = undefined
                                
                            return # prevent useless return from forEach
                    
                    else if e.type == '~'
                        sibs.forEach (el) ->
                            while (el = nextElementSibling(el)) and not el._sel_mark
                                el._sel_mark = true
                                
                            return # prevent useless return from forEach
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            while (el = nextElementSibling(el)) and el._sel_mark
                                el._sel_mark = undefined
                                
                            return # prevent useless return from forEach

        return els
    ### select.coffee ###

    parentMap = {
        thead: 'table',
        tbody: 'table',
        tfoot: 'table',
        tr: 'tbody',
        th: 'tr',
        td: 'tr',
        fieldset: 'form',
        option: 'select',
    }
    
    tagPattern = /^\s*<([^\s>]+)/

    create = (html, root) ->
        parent = (root or document).createElement(parentMap[tagPattern.exec(html)[1]] or 'div')
        parent.innerHTML = html

        els = []
        eachElement parent, 'firstChild', 'nextSibling', (el) -> els.push(el)
        return els

    qSA = (selector, root) ->
        if root.nodeType == 1
            id = root.id
            if not id
                root.id = '_sel_root'
                
            selector = "##{root.id} #{selector}"
                
        els = root.querySelectorAll(selector)

        if root.nodeType == 1 and not id
            root.removeAttribute('id')

        return els

    select =
        # See whether we should try qSA first
        if html.querySelectorAll
            (selector, roots, matchRoots) ->
                if not matchRoots and not combinatorPattern.exec(selector)
                    try
                        return roots.map((root) -> qSA(selector, root)).reduce(extend, [])
                    catch e

                return evaluate(parse(selector), roots, matchRoots)
            
        else
            (selector, roots, matchRoots) -> evaluate(parse(selector), roots, matchRoots)

    normalizeRoots = (roots) ->
        if not roots
            return [document]
        
        else if typeof roots == 'string'
            return select(roots, [document])
        
        else if typeof roots == 'object' and isFinite(roots.length)
            if roots.sort
                roots.sort(elCmp)
            else
                # NodeList
                roots = extend([], roots)
                
            return roots
        
        else
            return [roots]

    sel.sel = (selector, _roots, matchRoots) ->
        roots = normalizeRoots(_roots)

        if not selector
            return []
            
        else if Array.isArray(selector)
            return selector
            
        else if tagPattern.test(selector)
            return create(selector, roots[0])
            
        else if selector in [window, 'window']
            return [window]
            
        else if selector in [document, 'document']
            return [document]
            
        else if selector.nodeType == 1
            if not _roots or roots.some((root) -> contains(root, selector))
                return [selector]
            else
                return []
                
        else
            return select(selector, roots, matchRoots)
    
    sel.matching = (els, selector, roots) ->
        e = parse(selector)
        
        if not e.child and not e.children
            return filter(e, els)
        else
            return sel.intersection(els, sel.sel(selector, roots or findRoots(els), true))
    )(exports ? (@['sel'] = {}))

