(($) ->
    sel = require('sel')

    $._select = sel.sel

    methods =
        find: (s) -> $(s, this)
        union: (s, r) -> $(sel.union(this, sel.sel(s, r)))
        difference: (s, r) -> $(sel.difference(this, sel.sel(s, r)))
        intersection: (s, r) -> $(sel.intersection(this, sel.sel(s, r)))
        matching: (s) -> $(sel.matching(sel.extend([], this), s))
        is: (s) -> sel.matching(sel.extend([], this), s).length > 0
    
    # Method synonyms (these are the names jQuery uses)
    methods.and = methods.union
    methods.not = methods.difference
    methods.matches = methods.matching

    $.pseudos = sel.pseudos
    $.ender(methods, true)

)(ender)