    ### parser.coffee ###

    attrPattern = ///
        \[
            \s* ([-\w]+) \s*
            (?: ([~|^$*!]?=) \s* (?: ([-\w]+) | ['"]([^'"]*)['"] ) \s* )?
        \]
    ///g

    pseudoPattern = ///
        ::? ([-\w]+) (?: \( ( \( [^()]+ \) | [^()]+ ) \) )?
    ///g
    
    combinatorPattern = /// ^ \s* ([,+~]) ///
    
    selectorPattern = /// ^ 
        
        (?: \s* (>) )? # child selector
        
        \s*
        
        # tag
        (?: (\* | \w+) )?

        # id
        (?: \# ([-\w]+) )?

        # classes
        (?: \. ([-\.\w]+) )?

        # attrs
        ( (?: #{attrPattern.source} )* )

        # pseudos
        ( (?: #{pseudoPattern.source} )* )

    ///

    selectorGroups = {
        type: 1, tag: 2, id: 3, classes: 4,
        attrsAll: 5, pseudosAll: 10
    }

    parse = (selector) ->
        result = last = parseSimple(selector)
        
        if last.compound
            last.children = []
        
        while last[0].length < selector.length
            selector = selector.substr(last[0].length)
            e = parseSimple(selector)
            
            if e.compound
                e.children = [result]
                result = e
                
            else if last.compound
                last.children.push(e)
                
            else
                last.child = e
                
            last = e

        return result

    parseSimple = (selector) ->
        if e = combinatorPattern.exec(selector)
            e.compound = true
            e.type = e[1]
            
        else if e = selectorPattern.exec(selector)
            e.simple = true

            for name, group of selectorGroups
                e[name] = e[group]

            e.type or= ' '
        
            e.tag = e.tag.toLowerCase() if e.tag
            e.classes = e.classes.toLowerCase().split('.') if e.classes

            if e.attrsAll
                e.attrs = []
                e.attrsAll.replace attrPattern, (all, name, op, val, quotedVal) ->
                    e.attrs.push({name: name, op: op, val: val or quotedVal})
                    return ""

            if e.pseudosAll
                e.pseudos = []
                e.pseudosAll.replace pseudoPattern, (all, name, val) ->
                    if name == 'not'
                        e.not = parse(val)
                    else
                        e.pseudos.push({name: name, val: val})
        
                    return ""
            
        else
            throw new Error("Parse error at: #{selector}")

        return e
