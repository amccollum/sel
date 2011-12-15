assert = require('assert')
vows = require('vows')
sel = require('sel')

detached = '''
    <div id="a" class="parent">
        <ul id="b" class="child">
            <li id="c" ref="d" class="odd">
                <a id="local-link" href="#foo">foo</a>
            </li>
            <li id="d" class="even">
                <a id="external-link" href="http://www.google.com">bar</a>
            </li>
            <li id="e" class="odd">
                <ul class="nested">
                    <!-- Comment -->
                    <li id="foo" class="descendant"></li>
                    <li id="bar" class="descendant"></li>
                    <li class="descendant"></li>
                </ul>
            </li>
            <li id="f" class="even"></li>
            <li id="g" class="odd"></li>
        </ul>
        <ul id="h" class="child">
            <li class="odd"></li>
            <li class="even"></li>
            <li class="odd"></li>
            <li class="even"></li>
            <li class="odd"></li>
        </ul>
    </div>
'''

vows.add 'Miscellaneous Tests',
    'with detached elements,': 
        topic: () -> sel.sel(detached)
            
        'relative selectors':
            '`> ul`':
                topic: (root) -> sel.sel('> ul', root)
                'should return 2 elements': (result) -> assert.equal result.length, 2

        'ignore comments':
            '`#e *`':
                topic: (root) -> sel.sel('#e *', root)
                'should find only 4 elements': (result) -> assert.equal result.length, 4
                
        'using the li elements':
            topic: (root) -> sel.sel('li', root)

            'matching':
                '`.even`':
                    topic: (els) -> sel.matching(els, '.even')
                    'should return 4 elements': (result) -> assert.equal result.length, 4

                '`#a #b #e li`':
                    topic: (els) -> sel.matching(els, '#a #b #e li')
                    'should return 3 elements': (result) -> assert.equal result.length, 3

                '`#a, li`':
                    topic: (els) -> sel.matching(els, '#a, li')
                    'should return 13 elements': (result) -> assert.equal result.length, 13

                '`.even li, .odd li`':
                    topic: (els) -> sel.matching(els, '.even li, .odd li')
                    'should return 3 elements': (result) -> assert.equal result.length, 3

vows.add 'CSS4 Tests',
    'with detached elements,': 
        topic: () -> sel.sel(detached)
            
        'overriding subjects':
            '`.child! #foo`':
                topic: (root) -> sel.sel('.child! #foo', root)
                'should return the #b element': (result) -> assert.equal result[0].id, 'b'

            '`ul li! ul li`':
                topic: (root) -> sel.sel('ul li! ul li', root)
                'should return the #e element': (result) -> assert.equal result[0].id, 'e'
                    
        'idrefs':
            '`#c /ref/ li`':
                topic: (root) -> sel.sel('#c /ref/ li', root)
                'should return the #d element': (result) -> assert.equal result[0].id, 'd'
                
        ':local-link':
            '`a:local-link`':
                topic: (root) -> sel.sel('a:local-link', root)
                'should return the local link': (result) -> assert.equal result[0].id, 'local-link'
        
