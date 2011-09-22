    ### util.coffee ###

    html = document.documentElement
    
    extend = (a, b) ->
        for x in b
            a.push(x)
    
        return a
                    
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

    comparePosition = 
        if html.compareDocumentPosition
            (a, b) -> a.compareDocumentPosition(b)
    
        else
            (a, b) ->
                (a != b and a.contains(b) and 16) +
                (a != b and b.contains(a) and 8) +
                (if a.sourceIndex < 0 or b.sourceIndex < 0 then 1 else
                    (a.sourceIndex < b.sourceIndex and 4) +
                    (a.sourceIndex > b.sourceIndex and 2))

    nextElementSibling =
        if html.nextElementSibling
            (el) -> el.nextElementSibling
        else
            (el) ->
                while (el = el.nextSibling)
                    return el if el.nodeType == 1
                
                return null

    elCmp = (a, b) ->
        if not a then return -1
        else if not b then return 1
        else if a == b then return 0
        else if comparePosition(a, b) & 4 then -1
        else 1

    # Return the topmost ancestors of the element array
    filterDescendents = (els) -> els.filter (el, i) -> el and not (i and (els[i-1] == el or contains(els[i-1], el)))

    combine = (a, b, aRest, bRest, fn) ->
        r = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch fn(a[i], b[j])
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
    
    _unionMap = {'0': 0, '-1': 1, '1': 2}
    sel.union = (a, b) -> combine a, b, true, true, (ai, bi) -> _unionMap[elCmp(ai, bi)]

    _intersectionMap = {'0': 0, '-1': -1, '1': -2}
    sel.intersection = (a, b) -> combine a, b, false, false, (ai, bi) -> _intersectionMap[elCmp(ai, bi)]

    _differenceMap = {'0': -1, '-1': 1, '1': -2}
    sel.difference = (a, b) -> combine a, b, true, false, (ai, bi) -> _differenceMap[elCmp(ai, bi)]

