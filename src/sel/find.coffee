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
                return
            
        if m.pseudos
            m.pseudos.forEach (pseudo) ->
                els = filterPseudo(els, pseudo.name, pseudo.val)
                return
            
        return els

    filterTag = (els, tag) -> els.filter((el) -> el.nodeName.toLowerCase() == tag)

    filterClasses = (els, classes) ->
        classes.forEach (cls) ->
            els = filterAttr(els, 'class', '~=', cls)
            return
                
        return els

    filterAttr = (els, name, op, val) ->
        if val and val[0] in ['"', '\''] and val[0] == val[val.length-1]
            val = val.substr(1, val.length - 2)

        if name == 'class'
            name = 'className'
                
        return els.filter (el) ->
            attr =  el[name] ? el.getAttribute(name)
            value = attr + ""
            
            return attr != null and (
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

