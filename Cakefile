fs = require('fs')
sys = require('sys')
{spawn, exec} = require('child_process')

package = JSON.parse(fs.readFileSync('package.json', 'utf8'))

execCmds = (cmds) ->
    exec cmds.join(' && '), (err, stdout, stderr) ->
        output = (stdout + stderr).trim()
        console.log(output + '\n') if (output)
        throw err if err

task 'build', 'Build the library', ->
    execCmds [
        'pushd src/sel',
        'cat _pre.coffee util.coffee find.coffee parser.coffee eval.coffee select.coffee pseudos.coffee > sel.coffee',
        'popd',
        'coffee --compile --bare --output lib src/sel/sel.coffee',
        'coffee --compile --bare --output lib src/extras/ender.coffee',
    ]

task 'test', 'Build the test suite', ->
    execCmds [
        'coffee --compile --bare --output test src/test/*.coffee',
        
        'cat src/test/_pre.html src/test/template.html src/test/_post.html > test/index.html',
        'cp src/test/package.json test',

        'pushd test',
        '(npm install ender || true)',
        'npm install ..',
        'node_modules/.bin/ender build es5-basic domready node-compat ender-vows sel',
        'popd',
    ]
