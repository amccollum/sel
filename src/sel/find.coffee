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
    
    
