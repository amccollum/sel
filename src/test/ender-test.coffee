assert = require('assert')
vows = require('vows')

# Force using Sel as the selector library
$._select = sel.sel

vows.add 'Ender Tests',
    'basic tests':
        '`.parent .child`':
            topic: -> $('.parent .child')
            'should return 4 elements': (result) -> assert.equal result.length, 4
            'should return the h1 first': (result) -> assert.equal result[0].tagName.toLowerCase(), 'h1'
            'should return the h2 second': (result) -> assert.equal result[1].tagName.toLowerCase(), 'h2'
            'should return the h3 third': (result) -> assert.equal result[2].tagName.toLowerCase(), 'h3'
            'should return the h4 fourth': (result) -> assert.equal result[3].tagName.toLowerCase(), 'h4'

            'and using the result as roots':
                topic: (roots) -> $('.grandchild')
                'we should find the grandchild': (result) -> assert.equal result[0].className, 'grandchild'
                'and nothing else': (result) -> assert.equal result.length, 1
                
            'and passing the result as a new selector':
                topic: (s) -> $(s, document)
                'should return the same elements': (result) -> assert.equal result.length, 4