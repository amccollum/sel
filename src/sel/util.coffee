    ### util.coffee ###

    html = document.documentElement

    _hasDuplicates = null
    elCmp = (a, b) ->
        if not a then return -1
        if not b then return 1
    
        if a == b
            _hasDuplicates = true;
            return 0;

        return (if comparePosition(a, b) & 4 then -1 else 1)

    uniq = (arr) ->
        _hasDuplicates = false
        arr.sort(elCmp)

        if _hasDuplicates
            i = arr.length - 1
            while i
                if arr[i] == arr[i-1]
                    arr.splice(i, 1)
                else
                    i--

        return arr

    sel.union = (a, b) -> uniq(a.concat(b))

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

        while i < a.length
            if j >= b.length
                arr.push(a[i++])
            else
                switch elCmp(a[i], b[j])
                    when -1 then arr.push(a[i++])
                    when 1 then j++
                    when 0 then i++

        return arr
    
    contains =
        if html.compareDocumentPosition?
            (a, b) -> (a.compareDocumentPosition(b) & 16) == 16
    
        else if html.contains?
            (a, b) ->
                a = html if a in [document, window]
                return a != b and a.contains(b)
        else
            (a, b) ->
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

