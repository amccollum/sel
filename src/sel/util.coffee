    ### util.coffee ###

    html = document.documentElement
    
    extend = (a, b) ->
        for x in b
            a.push(x)
    
        return a
        
    takeElements = (els) -> els.filter((el) -> el.nodeType == 1)

    eachElement = (el, first, next, fn) ->
        el = el[first]
        while (el)
            fn(el) if el.nodeType == 1
            el = el[next]
            
        return
        
    nextElementSibling =
        if html.nextElementSibling
            (el) -> el.nextElementSibling
        else
            (el) ->
                el = el.nextSibling
                while (el and el.nodeType != 1)
                    el = el.nextSibling
                
                return el

    contains =
        if html.compareDocumentPosition?
            (a, b) -> (a.compareDocumentPosition(b) & 16) == 16
    
        else if html.contains?
            (a, b) ->
                if a.documentElement then b.ownerDocument == a
                else a != b and a.contains(b)
                
        else
            (a, b) ->
                if a.documentElement then return b.ownerDocument == a
                while b = b.parentNode
                    return true if a == b

                return false

    elCmp =
        if html.compareDocumentPosition
            (a, b) ->
                if a == b then 0
                else if a.compareDocumentPosition(b) & 4 then -1
                else 1
                
        else if html.sourceIndex                                                    
            (a, b) ->
                if a == b then 0
                else if a.sourceIndex < b.sourceIndex then -1
                else 1
                
    # Return the outermost elements of the array
    filterDescendants = (els) -> els.filter (el, i) -> el and not (i and (els[i-1] == el or contains(els[i-1], el)))

    # Return descendants one level above the given elements
    outerParents = (els) -> filterDescendents(els.map((el) -> el.parentNode))
        
    # Return the topmost root elements of the array
    findRoots = (els) ->
        r = []
        els.forEach (el) ->
            while el.parentNode
                el = el.parentNode
            
            if r[r.length-1] != el
                r.push(el)
                
            return
        
        return r
        
    # Helper function for combining sorted element arrays in various ways
    combine = (a, b, aRest, bRest, map) ->
        r = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch map[elCmp(a[i], b[j])]
                when -1 then i++
                when -2 then j++
                when 1 then r.push(a[i++])
                when 2 then r.push(b[j++])
                when 0
                    r.push(a[i++])
                    j++

        if aRest
            while i < a.length
                r.push(a[i++])

        if bRest
            while j < b.length
                r.push(b[j++])

        return r
    
    # Define these operations in terms of the above element operations to reduce code size
    sel.union = (a, b) -> combine a, b, true, true, {'0': 0, '-1': 1, '1': 2}
    sel.intersection = (a, b) -> combine a, b, false, false, {'0': 0, '-1': -1, '1': -2}
    sel.difference = (a, b) -> combine a, b, true, false, {'0': -1, '-1': 1, '1': -2}

