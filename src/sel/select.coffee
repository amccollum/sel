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
        if document.querySelectorAll
            (selector, roots) ->
                if not combinatorPattern.exec(selector)
                    try
                        return roots.map((root) -> qSA(selector, root)).reduce(extend, [])
                    catch e

                return evaluate(parse(selector), roots)
            
        else
            (selector, roots) -> evaluate(parse(selector), roots)

    normalizeRoots = (roots) ->
        if not roots
            return [document]
        
        else if typeof roots == 'string'
            return select(roots, [document])
        
        else if typeof roots == 'object' and isFinite(roots.length)
            roots.sort(elCmp) if roots.sort
            return filterDescendants(roots)
        
        else
            return [roots]

    sel.sel = (selector, _roots) ->
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
            return select(selector, roots)

    sel.matching = (els, selector) -> filter(parse(selector), els)
