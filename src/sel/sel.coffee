((sel) ->

    ### util.coffee ###

    html = document.documentElement
    
    sel.extend = extend = (a, b) ->
        for x in b
            a.push(x)
    
        return a
        
    takeElements = (els) -> els.filter((el) -> el.nodeType == 1)

    eachElement = (el, first, next, fn) ->
        el = el[first] if first
        while (el)
            if el.nodeType == 1
                if fn(el) == false
                    break
                
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
    sel.union = union = (a, b) -> combine a, b, true, true, {'0': 0, '-1': 1, '1': 2}
    sel.intersection = intersection = (a, b) -> combine a, b, false, false, {'0': 0, '-1': -1, '1': -2}
    sel.difference = difference = (a, b) -> combine a, b, true, false, {'0': -1, '-1': 1, '1': -2}

    ### parser.coffee ###

    attrPattern = ///
        \[
            \s* ([-\w]+) \s*
            (?: ([~|^$*!]?=) \s* (?: ([-\w]+) | ['"]([^'"]*)['"]) \s* (i)? \s* )?
        \]
    ///g

    pseudoPattern = ///
        ::? ([-\w]+) (?: \( ( \( [^()]+ \) | [^()]+ ) \) )?
    ///g
    
    combinatorPattern = /// ^ \s* ([,+~] | /([-\w]+)/) ///
    
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
        
        # subject marker
        (!)?

    ///

    selectorGroups = {
        type: 1, tag: 2, id: 3, classes: 4,
        attrsAll: 5, pseudosAll: 11, subject: 14
    }

    parse = (selector) ->
        selector = selector.trim()
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
            e.type = e[1].charAt(0)
            
            if e.type == '/'
                e.idref = e[2]
            
        else if (e = selectorPattern.exec(selector)) and e[0].trim()
            e.simple = true

            for name, group of selectorGroups
                e[name] = e[group]

            e.type or= ' '
            e.tag and= e.tag.toLowerCase()
            e.classes = e.classes.toLowerCase().split('.') if e.classes

            if e.attrsAll
                e.attrs = []
                e.attrsAll.replace attrPattern, (all, name, op, val, quotedVal, ignoreCase) ->
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
                    
                    if ignoreCase
                        val = val.toLowerCase()
                
                    e.attrs.push({name: name, op: op, val: val, ignoreCase: ignoreCase})
                    return ""

            if e.pseudosAll
                e.pseudos = []
                e.pseudosAll.replace pseudoPattern, (all, name, val) ->
                    name = name.toLowerCase()
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
    
    getAttribute = (el, name) -> if _attrMap[name] then _attrMap[name](el) else el.getAttribute(name)
    
    find = (e, roots, matchRoots) ->
        if e.id
            # Find by id
            els = []
            roots.forEach (root) ->
                doc = root.ownerDocument or root
                
                if root == doc or (root.nodeType == 1 and contains(doc.documentElement, root))
                    el = doc.getElementById(e.id)
                    els.push(el) if el and contains(root, el)
                        
                else
                    # Disconnected elements, so make filter do the work
                    extend(els, root.getElementsByTagName(e.tag or '*'))
                    
                return
                
        else if e.classes and find.byClass
            # Find by class
            els = roots.map((root) ->
                e.classes.map((cls) ->
                    root.getElementsByClassName(cls)
                ).reduce(union)
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
            els = filter(els, e, roots, matchRoots)
        else
            els = []
            
        e.ignoreTag = undefined
        e.ignoreClasses = undefined

        if matchRoots
            # Allow roots to be matched, and separately filter
            els = union(els, filter(takeElements(roots), e, roots, matchRoots))

        return els

    filter = (els, e, roots, matchRoots) ->
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
                return

        if e.attrs
            # Filter by attribute
            e.attrs.forEach ({name, op, val, ignoreCase}) ->
                els = els.filter (el) ->
                    attr = getAttribute(el, name)
                    value = attr + ""
            
                    if ignoreCase
                        # We already lowercase val in the parser
                        value = value.toLowerCase()
                
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

                return
            
        if e.pseudos
            # Filter by pseudo
            e.pseudos.forEach ({name, val}) ->
                pseudo = pseudos[name]
                if not pseudo
                    throw new Error("no pseudo with name: #{name}")
                    
                if pseudo.batch
                    els = pseudo(els, val, roots, matchRoots)
                else
                    els = els.filter((el) -> pseudo(el, val))

                return
            
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
        
        return
    
    
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
        
    
    ### eval.coffee ###

    evaluate = (e, roots, matchRoots) ->
        els = []

        if roots.length
            switch e.type
                when ' ', '>'
                    # We only need to search from the outermost roots
                    outerRoots = filterDescendants(roots)
                    els = find(e, outerRoots, matchRoots)

                    if e.type == '>'
                        roots.forEach (el) ->
                            el._sel_mark = true
                            return
                        
                        els = els.filter((el) -> el.parentNode._sel_mark if el.parentNode)

                        roots.forEach (el) ->
                            el._sel_mark = undefined
                            return
                    
                    if e.child
                        if e.subject
                            # Need to check each element individually
                            els = els.filter((el) -> evaluate(e.child, [el]).length)
                        else
                            els = evaluate(e.child, els)

                when '+', '~', ',', '/'
                    if e.children.length == 2
                        sibs = evaluate(e.children[0], roots, matchRoots)
                        els = evaluate(e.children[1], roots, matchRoots)
                    else
                        sibs = roots
                        els = evaluate(e.children[0], outerParents(roots), matchRoots)
            
                    if e.type == ','
                        # sibs here is just the result of the first selector
                        els = union(sibs, els)
                        
                    else if e.type == '/'
                        # IE6 still doesn't return the plain href sometimes...
                        ids = sibs.map((el) -> getAttribute(el, e.idref).replace(/^.*?#/, ''))
                        els = els.filter((el) -> ~ids.indexOf(el.id))
                    
                    else if e.type == '+'
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = true 
                                
                            return
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = undefined
                                
                            return
                    
                    else if e.type == '~'
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
            # Fix element-rooted qSA queries by adding an id
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
                # Array -- make sure it's sorted in document order
                roots.sort(elCmp)
            else
                # NodeList -- in document order, but convert to an Array
                roots = extend([], roots)
                
            return roots
        
        else
            return [roots]

    # The main selector interface
    sel.sel = (selector, _roots, matchRoots) ->
        roots = normalizeRoots(_roots)

        if not selector
            return []
            
        else if typeof selector == 'object' and isFinite(selector.length)
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
    matchesSelector = html.matchesSelector or html.mozMatchesSelector or html.webkitMatchesSelector or html.msMatchesSelector
    matchesDisconnected = matchesSelector and matchesSelector.call(document.createElement('div'), 'div')
    
    sel.matching = matching = (els, selector) ->
        if matchesSelector and (matchesDisconnected or els.every((el) -> el.document and el.document.nodeType != 11))
            try
                return els.filter((el) -> matchesSelector.call(el, selector))
            catch e
    
        e = parse(selector)
        if not e.child and not e.children and not e.pseudos
            return filter(els, e)
        else
            return intersection(els, sel.sel(selector, findRoots(els), true))
    return
)(exports ? (@['sel'] = {}))

