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
    el = document.getElementById(id)
    if el
        for root in roots
            if contains(root, el)
                return [el]
    
    return []

findClasses = (roots, classes) ->
    els = []
    for root in roots
        for cls in classes
            for el in root.getElementsByClassName(cls)
                els.push(el)
            
    return uniq(els)
            
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

    if not op
        return els.filter((el) -> el.getAttribute(name) != null)
    else if op == '='
        return els.filter((el) -> el.getAttribute(name) == val)
    else if op == '!='
        return els.filter((el) -> el.getAttribute(name) != val)

    pattern = switch op
        when '^=' then memoRegExp("^#{val}")
        when '$=' then memoRegExp("#{val}$")
        when '*=' then memoRegExp("#{val}")
        when '~=' then memoRegExp("(^|\\s+)#{val}(\\s+|$)")
        when '|=' then memoRegExp("^#{val}(-|$)")

    return els.filter((el) -> (attr = el.getAttribute(name)) != null and pattern.test(attr))
    
filterPseudo = (els, name, val) ->
    pseudo = sel.pseudos[name]
    if not pseudo
        throw new Error("no pseudo with name: #{name}")
        
    return els.filter((el) -> pseudo(el, val))

