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
                    <li class="descendant"><li>
                    <li class="descendant"><li>
                    <li class="descendant"><li>
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

vows.add 'Sel tests',
    'with detached elements,': 
        topic: () -> sel.sel(detached)
            
        '"> ul"':
            topic: (els) -> sel.sel('> ul', els)

            'should return 2 elements': (result) -> assert.equal result.length, 2
