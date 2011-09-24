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
