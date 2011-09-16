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

    ) ( [+~>\s]+ )? (,)? # combinator
///

selectorGroups = {
    all: 0, tag: 1, id: 2, classes: 3,
    attrsAll: 4, pseudosAll: 8,
    combinator: 11, comma: 12
}

attrGroups = ['attrName', 'attrOp', 'attrVal']
pseudoGroups = ['pseudoName', 'pseudoVal']

parseChunk = (state) ->
    rest = state.selector.substr(state.selector.length - state.left)
    if not (m = selectorPattern.exec(rest))
         throw new Error('Parse error.')

    for name, group of selectorGroups
        m[name] = m[group]

    state.left -= m.all.length
    
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
            
    if not state.left
        m.combinator = '$'
    else if m.comma
        m.combinator = ','
    else
        m.combinator = m.combinator.trim() or ' '

    return m

parseSimple = (type, state) ->
    m = parseChunk(state)
    m.type = type

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

