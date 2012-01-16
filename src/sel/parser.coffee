    ### parser.coffee ###

    attrPattern = ///
        \[
            \s* ([-\w]+) \s*
            (?: ([~|^$*!]?=) \s* (?: ([-\w]+) | ['"]([^'"]*)['"] \s* (i)) \s* )?
        \]
    ///g

    pseudoPattern = ///
        ::? ([-\w]+) (?: \( ( \( [^()]+ \) | [^()]+ ) \) )?
    ///g
    
    combinatorPattern = /// ^ \s* ([,+~] | /([-\w]+)/) ///
    
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
        
        # subject marker
        (!)?

    ///

    selectorGroups = {
        type: 1, tag: 2, id: 3, classes: 4,
        attrsAll: 5, pseudosAll: 11, subject: 14
    }

    parse = (selector) ->
        if selector of parse.cache
            return parse.cache[selector]
            
        result = last = e = parseSimple(selector)
        
        if e.compound
            e.children = []
        
        while e[0].length < selector.length
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

        return (parse.cache[selector] = result)

    parse.cache = {}
    
    parseSimple = (selector) ->
        if e = combinatorPattern.exec(selector)
            e.compound = true
            e.type = e[1].charAt(0)
            
            if e.type == '/'
                e.idref = e[2]
            
        else if (e = selectorPattern.exec(selector)) and e[0].trim()
            e.simple = true

            for name, group of selectorGroups
                e[name] = e[group]

            e.type or= ' '
            e.tag and= e.tag.toLowerCase()
            e.classes = e.classes.toLowerCase().split('.') if e.classes

            if e.attrsAll
                e.attrs = []
                e.attrsAll.replace attrPattern, (all, name, op, val, quotedVal, ignoreCase) ->
                    name = name.toLowerCase()
                    val or= quotedVal
                    
                    if op == '='
                        # Special cases...
                        if name == 'id' and not e.id
                            e.id = val
                            return ""
                            
                        else if name == 'class'
                            if e.classes
                                e.classes.append(val)
                            else
                                e.classes = [val]

                            return ""
                    
                    if ignoreCase
                        val = val.toLowerCase()
                
                    e.attrs.push({name: name, op: op, val: val, ignoreCase: ignoreCase})
                    return ""

            if e.pseudosAll
                e.pseudos = []
                e.pseudosAll.replace pseudoPattern, (all, name, val) ->
                    name = name.toLowerCase()
                    e.pseudos.push({name: name, val: val})
                    return ""
            
        else
            throw new Error("Parse error at: #{selector}")

        return e
