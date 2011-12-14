assert = require('assert')
vows = require('vows')
sel = require('sel')

detached = '''
    <div id="a" class="parent">
        <ul id="b" class="child">
            <li id="c" class="odd"><a href="#foo">foo</a></li>
            <li id="d" class="even"><a href="#bar">bar</a></li>
            <li id="e" class="odd">
                <ul class="nested">
                    <!-- Comment -->
                    <li class="descendant"></li>
                    <li class="descendant"></li>
                    <li class="descendant"></li>
                </ul>
            </li>
            <li id="f" class="even"></li>
            <li id="g" class="odd"></li>
        </ul>
        <ul class="child">
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
                topic: (els) -> sel.sel('> ul', els)
                'should return 2 elements': (result) -> assert.equal result.length, 2

        'ignore comments':
            '`#e *`':
                topic: (els) -> sel.sel('#e *', els)
                'should find only 4 elements': (result) -> assert.equal result.length, 4
                
        'using the li elements':
            topic: (els) -> sel.sel('li', els)

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
