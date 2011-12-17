    ### eval.coffee ###

    evaluate = (e, roots, matchRoots) ->
        els = []

        if roots.length
            switch e.type
                when ' ', '>'
                    # We only need to search from the outermost roots
                    outerRoots = filterDescendants(roots)
                    els = find(e, outerRoots, matchRoots)

                    if e.type == '>'
                        roots.forEach (el) ->
                            el._sel_mark = true
                            return
                        
                        els = els.filter((el) -> el._sel_mark if (el = el.parentNode))

                        roots.forEach (el) ->
                            el._sel_mark = undefined
                            return
                    
                    if e.child
                        if e.subject
                            # Need to check each element individually
                            els = els.filter((el) -> evaluate(e.child, [el]).length)
                        else
                            els = evaluate(e.child, els)

                when '+', '~', ',', '/'
                    if e.children.length == 2
                        sibs = evaluate(e.children[0], roots, matchRoots)
                        els = evaluate(e.children[1], roots, matchRoots)
                    else
                        sibs = roots
                        els = evaluate(e.children[0], outerParents(roots), matchRoots)
            
                    if e.type == ','
                        # sibs here is just the result of the first selector
                        els = union(sibs, els)
                        
                    else if e.type == '/'
                        ids = sibs.map((el) -> getAttribute(el, e.idref).replace(/^#/, ''))
                        els = els.filter((el) -> el.id in ids)
                    
                    else if e.type == '+'
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = true 
                                
                            return
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = undefined
                                
                            return
                    
                    else if e.type == '~'
                        sibs.forEach (el) ->
                            while (el = nextElementSibling(el)) and not el._sel_mark
                                el._sel_mark = true
                                
                            return
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            while (el = nextElementSibling(el)) and el._sel_mark
                                el._sel_mark = undefined
                                
                            return

        return els
