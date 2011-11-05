(($) ->
    sel = require('sel')

    $._select = sel.sel

    methods =
        find: (s) -> $(s, this)
        union: (s, r) -> $(sel.union(this, sel.sel(s, r)))
        difference: (s, r) -> $(sel.difference(this, sel.sel(s, r)))
        intersection: (s, r) -> $(sel.intersection(this, sel.sel(s, r)))
    
    # Method synonyms (these are the names jQuery uses)
    methods.and = methods.union
    methods.not = methods.difference

    $.pseudos = sel.pseudos
    $.ender(methods, true)

)(ender)