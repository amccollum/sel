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

    select =
        # See whether we should try qSA first
        if document.querySelector and document.querySelectorAll
            (selector, roots) ->
                try roots.map((root) -> root.querySelectorAll(selector)).reduce(extend, [])
                catch e then evaluate(parse(selector), roots)
        else
            (selector, roots) -> evaluate(parse(selector), roots)

    normalizeRoots = (roots) ->
        if not roots
            return [document]
        
        else if typeof roots == 'string'
            return select(roots, [document])
        
        else if typeof roots == 'object' and isFinite(roots.length)
            roots.sort(elCmp) if roots.sort
            return filterDescendents(roots)
        
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

