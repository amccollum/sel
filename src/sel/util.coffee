    ### util.coffee ###

    html = document.documentElement

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

    # Return the outer-most ancestors of the element array
    subsume = (arr) -> arr.filter((el, i) -> el and not (i and (arr[i-1] == el or contains(arr[i-1], el))))

    sel.union = (a, b) ->
        arr = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch elCmp(a[i], b[j])
                when -1 then arr.push(a[i++])
                when 1 then arr.push(b[j++])
                when 0
                    arr.push(a[i++])
                    j++

        while i < a.length
            arr.push(a[i++])

        while j < b.length
            arr.push(b[j++])

        return arr

    sel.intersection = (a, b) ->
        arr = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch elCmp(a[i], b[j])
                when -1 then i++
                when 1 then j++
                when 0 then arr.push(a[i++])

        return arr

    sel.difference = (a, b) -> 
        arr = []
        i = 0
        j = 0

        while i < a.length and j < b.length
            switch elCmp(a[i], b[j])
                when -1 then arr.push(a[i++])
                when 1 then j++
                when 0 then i++

        while i < a.length
            arr.push(a[i++])

        return arr
