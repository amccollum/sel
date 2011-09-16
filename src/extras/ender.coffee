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

    $.pseudos = sel.pseudos
    $.ender({
        find: (s) -> sel.sel(s, this)
        and: (s, r) -> 
            for el in $(s, r)
                this.push(el)

            return this

    }, true)

)(ender)