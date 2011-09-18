!(($) ->
    sel = require('sel')

    nodeMap = {
        thead: 'table',
        tbody: 'table',
        tfoot: 'table',
        tr: 'tbody',
        th: 'tr',
        td: 'tr',
        fieldset: 'form',
        option: 'select',
    }
    
    tagPattern = /^\s*<([^\s>]+)/

    create = (html, root) ->
        tag = tagPattern.exec(html)[1]
        parent = (root or document).createElement(nodeMap[tag] or 'div')
        parent.innerHTML = html
        return (el for el in parent.childNodes when el.nodeType == 1)

    $._select = (s, r) -> if /^\s*</.test(s) then create(s, r) else sel.sel(s, r)

    methods =
        find: (s) -> sel.sel(s, this)
        union: (s, r) -> sel.union(this, $(s, r))
        intersection: (s, r) -> sel.intersection(this, $(s, r))
        difference: (s, r) -> sel.difference(this, $(s, r))
    
    methods.and = methods.union
    methods.not = methods.difference
    methods.filter = methods.intersection

    $.pseudos = sel.pseudos
    $.ender(methods, true)

)(ender)