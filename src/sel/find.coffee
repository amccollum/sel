    ### find.coffee ###

    find = (roots, m) ->
        if m.id
            els = findId(roots, m.id)
            els = filterTag(els, m.tag) if m.tag
            if m.classes
                for cls in m.classes
                    els = filterAttr(els, 'class', '~=', cls)

        else if m.classes and html.getElementsByClassName
            els = findClasses(roots, m.classes)
            els = filterTag(els, m.tag) if m.tag
        
        else
            els = findTag(roots, m.tag or '*')
            if m.classes
                for cls in m.classes
                    els = filterAttr(els, 'class', '~=', cls)

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
        for cls in m.classes
            els = filterAttr(els, roots, 'class', '~=', cls)
    
        return els

    filterAttr = (els, name, op, val) ->
        if val and val[0] in ['"', '\''] and val[0] == val[val.length-1]
            val = val.substr(1, val.length - 2)

        return els.filter (el) ->
            (attr = el.getAttribute(name)) != null and (
                if not op then true
                else if op == '=' then attr == val
                else if op == '!=' then attr != val
                else if op == '*=' then attr.indexOf(val) >= 0
                else if op == '^=' then attr.indexOf(val) == 0
                else if op == '$=' then attr.substr(attr.length - val.length) == val
                else if op == '~=' then " #{attr} ".indexOf(" #{val} ") >= 0
                else if op == '|=' then attr == val or (attr.indexOf(val) == 0 and attr[val.length] == '-')
                else false
            )
    
    filterPseudo = (els, name, val) ->
        pseudo = sel.pseudos[name]
        if not pseudo
            throw new Error("no pseudo with name: #{name}")
        
        return els.filter((el) -> pseudo(el, val))

