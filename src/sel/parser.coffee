    ### parser.coffee ###

    attrPattern = ///
        (?:
            \[
                \s* ([-\w]+) \s*
                (?: ([~|^$*!]?=) \s* ( [-\w]+ | ['"][^'"]*['"] ) \s* )?
            \]
        )
    ///g

    pseudoPattern = ///
        (?:
            ::? ([-\w]+) (?: \( ( \( [^()]+ \) | [^()]+ ) \) )?
        )
    ///g

    selectorPattern = ///
        ^ \s*
        (?:
            # tag
            (?: (\* | \w+) )?

            # id
            (?: \# ([-\w]+) )?

            # classes
            (?: \. ([-\.\w]+) )?

            # attributes
            ( #{attrPattern.source}* )
    
            # pseudo
            ( #{pseudoPattern.source}* )

        ) ( \s*, | [+~>\s]+ )? # combinator
    ///

    selectorGroups = {
        tag: 1, id: 2, classes: 3,
        attrsAll: 4, pseudosAll: 8,
        combinator: 11
    }

    parseSimple = (type, state) ->
        rest = state.selector.substr(state.selector.length - state.left)
        if not (m = selectorPattern.exec(rest))
             throw new Error("Parse error: #{rest}")

        state.left -= m[0].length
    
        for name, group of selectorGroups
            m[name] = m[group]

        m.type = type
        m.tag = m.tag.toLowerCase() if m.tag
        m.classes = m.classes.toLowerCase().split('.') if m.classes

        if m.attrsAll
            m.attrs = []
            m.attrsAll.replace attrPattern, (all, name, op, val) ->
                m.attrs.push({name: name, op: op, val: val})
                return ""
        
        if m.pseudosAll
            m.pseudos = []
            m.pseudosAll.replace pseudoPattern, (all, name, val) ->
                if name == 'not'
                    m.not = parse(val)
                else
                    m.pseudos.push({name: name, val: val})
                
                return ""
        
        # The combinator determines the next type being parsed
        m.combinator = if not state.left then '$' else (m.combinator.trim() or ' ')

        switch m.combinator
            # descending selectors
            when ' ', '>'
                m.child = parseSimple(m.combinator, state)
    
            # combining selectors
            when '+', '~', ','
                state.rewind = m.combinator
        
            # end of input
            when '$'
                state.rewind = null
        
        return m

    parse = (selector) ->
        state = {
            selector: selector,
            left: selector.length,
        }

        m = parseSimple(' ', state)
        while state.rewind
            m = {
                type: state.rewind,
                children: [m, parseSimple(' ', state)],
            }

        return m

