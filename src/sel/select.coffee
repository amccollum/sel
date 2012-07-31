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
        
        else if typeof roots is 'string'
            return select(roots, [document])
        
        else if typeof roots is 'object' and isFinite(roots.length)
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
            
        else if selector.nodeType == 1
            if not _roots or roots.some((root) -> contains(root, selector))
                return [selector]
            else
                return []
                
        else if selector in [window, 'window']
            return [window]
            
        else if selector in [document, 'document']
            return [document]
            
        else if typeof selector is 'object' and isFinite(selector.length)
            return selector
            
        else if tagPattern.test(selector)
            return create(selector, roots[0])
            
        else
            return select(selector, roots, matchRoots)
