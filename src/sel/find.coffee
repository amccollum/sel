    ### find.coffee ###

    # Attributes that we get directly off the node
    _attrMap = {
        'tag': 'tagName',
        'class': 'className',
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
                el = (root.ownerDocument or root).getElementById(e.id)
                els.push(el) if el and contains(root, el)
                return # prevent useless return from forEach
            
            # Don't need to filter on id
            e.id = null
        
        else if e.classes and html.getElementsByClassName
            # Find by class
            els = roots.map((root) ->
                e.classes.map((cls) ->
                    root.getElementsByClassName(cls)
                ).reduce(sel.union)
            ).reduce(extend, [])

            # Don't need to filter on class
            e.classes = null
        
        else
            # Find by tag
            els = roots.map((root) ->
                root.getElementsByTagName(e.tag or '*')
            ).reduce(extend, [])

            # Don't need to filter on tag
            e.tag = null

        if els and els.length
            return filter(e, els)
        else
            return []


    filter = (e, els) ->
        if e.id
            # Filter by id
            els = els.filter((el) -> el.id == e.id)
            
        if e.tag and e.tag != '*'
            # Filter by tag
            els = els.filter((el) -> el.nodeName.toLowerCase() == e.tag)
        
        if e.classes
            # Filter by class
            e.classes.forEach (cls) ->
                els = els.filter((el) -> " #{el.className} ".indexOf(" #{cls} ") >= 0)
                return # prevent useless return from forEach

        if e.attrs
            # Filter by attribute
            e.attrs.forEach ({name, op, val}) ->
                
                if val and val[0] in ['"', '\''] and val[0] == val[val.length-1]
                    val = val.substr(1, val.length - 2)

                els = els.filter (el) ->
                    attr = if _attrMap[name] then el[_attrMap[name]] else el.getAttribute(name)
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
