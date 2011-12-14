    ### find.coffee ###

    # Attributes that we get directly off the node
    _attributeMap = {
        'tag': (el) -> el.tagName
        'class': (el) -> el.className
    }
    
    getAttribute = (el, name) -> if _attrMap[name] then _attrMap[name](el) else el.getAttribute(name)
    
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
        if e.id or e.idref
            # Find by id or idref
            els = []
            roots.forEach (root) ->
                id = if e.idref then getAttribute(root, e.idref) else e.id
                
                if root.getElementById
                    el = root.getElementById(id)
                    els.push(el) if el and el.id == id
                        
                else
                    # IE <= 8 doesn't support Element.getElementById, so get by tag and filter instead
                    extend(els, extend([], root.getElementsByTagName(e.tag or '*')).filter((el) -> el.id == id))
                    
                return
                
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
                return

        if e.attrs
            # Filter by attribute
            e.attrs.forEach ({name, op, val}) ->
                
                els = els.filter (el) ->
                    attr = getAttribute(el, name)
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

                return
            
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
                                return
                    
                            parent._sel_children = indices
                    
                        return
            
                # We need to wait to replace els so we can unset the special attributes
                filtered = els.filter((el) -> pseudo(el, val))

                if name of _positionalPseudos
                    els.forEach (el) ->
                        if (parent = el.parentNode) and parent._sel_children != undefined
                            eachElement parent, first, next, (el) ->
                                el._sel_index = el._sel_indexOfType = undefined
                                return
                                
                            parent._sel_children = undefined
                    
                        return
                    
                els = filtered

                return
            
        return els

    # Feature detection
    do ->
        div = document.createElement('div')

        # Check whether getting url attributes returns the proper value
        div.innerHTML = '<a href="#"></a>'
        if div.firstChild.getAttribute('href') != '#'
            _attributeMap['href'] = (el) -> el.getAttribute('href', 2)
            _attributeMap['src'] = (el) -> el.getAttribute('src', 2)
            
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
    
    
