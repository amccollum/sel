    matchesSelector = html.matchesSelector or html.mozMatchesSelector or html.webkitMatchesSelector or html.msMatchesSelector
    matchesDisconnected = matchesSelector and matchesSelector.call(document.createElement('div'), 'div')
    
    sel.matching = matching = (els, selector, roots) ->
        if matchesSelector and (matchesDisconnected or els.every((el) -> el.document and el.document.nodeType != 11))
            try
                return els.filter((el) -> matchesSelector.call(el, selector))
            catch e
    
        e = parse(selector)
        if not e.child and not e.children and not e.pseudos
            return filter(els, e)
        else
            return intersection(els, sel.sel(selector, findRoots(els), true))
