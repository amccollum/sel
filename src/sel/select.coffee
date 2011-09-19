    ### select.coffee ###

    select =
        if document.querySelector and document.querySelectorAll
            (selector, roots) -> 
                try
                    els = []
                    for root in roots
                        for el in root.querySelectorAll(selector)
                            els.push(el)
            
                    return uniq(els)
                
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
            return roots
        
        else
            return [roots]

    sel.sel = (selector, roots) ->
        roots = normalizeRoots(roots)

        if not selector
            return []
        else if selector in [window, 'window']
            return [window]
        else if selector in [document, 'document']
            return [document]
        else if selector.nodeType == 1
            if roots.some((root) -> contains(root, selector))
                return [selector]
            else
                return []
        else
            return select(selector, roots)

