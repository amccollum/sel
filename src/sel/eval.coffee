    ### eval.coffee ###

    evaluate = (m, roots) ->
        els = []

        if roots.length
            switch m.type
                when ' ', '>'
                    # Normally, we're searching all descendents anyway
                    outerRoots = filterDescendents(roots)
                    els = find(outerRoots, m)

                    if m.type == '>'
                        roots.forEach (el) ->
                            el._sel_mark = true
                            return
                            
                        els = els.filter((el) -> el._sel_mark if (el = el.parentNode))

                        roots.forEach (el) ->
                            el._sel_mark = false
                            return
                            
                    if m.not
                        els = sel.difference(els, find(outerRoots, m.not))
            
                    if m.child
                        els = evaluate(m.child, els)

                when '+', '~', ','
                    sibs = evaluate(m.children[0], roots)
                    els = evaluate(m.children[1], roots)
            
                    if m.type == ','
                        # sibs here is just the result of the first selector
                        els = sel.union(sibs, els)
                    
                    else if m.type == '+'
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = true 
                                
                            return # prevent useless return from forEach
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            if (el = nextElementSibling(el))
                                el._sel_mark = undefined
                                
                            return # prevent useless return from forEach
                    
                    else if m.type == '~'
                        sibs.forEach (el) ->
                            while (el = nextElementSibling(el)) and not el._sel_mark
                                el._sel_mark = true
                                
                            return # prevent useless return from forEach
                            
                        els = els.filter((el) -> el._sel_mark)
                        
                        sibs.forEach (el) ->
                            while (el = nextElementSibling(el)) and el._sel_mark
                                el._sel_mark = undefined
                                
                            return # prevent useless return from forEach

        return els

