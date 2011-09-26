    ### find.coffee ###

    _attrMap = {
        'tag': 'tagName',
        'class': 'className',
    }

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
    

    find = (roots, m) ->
        if m.id
            # Find by id
            els = []
            roots.forEach (root) ->
                el = (root.ownerDocument or root).getElementById(m.id)
                els.push(el) if el and contains(root, el)
                return # prevent useless return from forEach
            
        else if m.classes and html.getElementsByClassName
            # Find by class
            els = roots.map((root) ->
                m.classes.map((cls) ->
                    root.getElementsByClassName(cls)
                ).reduce(sel.union)
            ).reduce(extend, [])

            # Don't need to filter on class
            m.classes = null
        
        else
            # Find by tag
            els = roots.map((root) ->
                root.getElementsByTagName(m.tag or '*')
            ).reduce(extend, [])

            # Don't need to filter on tag
            m.tag = null

        if els and els.length
            return filter(els, m)
        else
            return []


    filter = (els, m) ->
        if m.tag
            # Filter by tag
            els = els.filter((el) -> el.nodeName.toLowerCase() == m.tag)
        
        if m.classes
            # Filter by class
            m.classes.forEach (cls) ->
                els = els.filter((el) -> " #{el.className} ".indexOf(" #{cls} ") >= 0)
                return # prevent useless return from forEach

        if m.attrs
            # Filter by attribute
            m.attrs.forEach ({name, op, val}) ->
                
                name = _attrMap[name] or name

                if val and val[0] in ['"', '\''] and val[0] == val[val.length-1]
                    val = val.substr(1, val.length - 2)

                els = els.filter (el) ->
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

                return # prevent useless return from forEach
            
        if m.pseudos
            # Filter by pseudo
            m.pseudos.forEach ({name, val}) ->

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
                    
                            parent._sel_children = indices
                    
                        return # prevent useless return from forEach
            
                # We need to wait to replace els so we can unset the special attributes
                filtered = els.filter((el) -> pseudo(el, val))

                if name of _positionalPseudos
                    els.forEach (el) ->
                        if (parent = el.parentNode) and parent._sel_children != undefined
                            indices = { '*': 0 }
                            eachElement parent, first, next, (el) ->
                                el._sel_index = el._sel_indexOfType = undefined
                                
                            parent._sel_children = undefined
                    
                        return # prevent useless return from forEach
                    
                els = filtered

                return # prevent useless return from forEach
            
        return els
