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
        'cat _pre.coffee util.coffee find.coffee pseudos.coffee parser.coffee eval.coffee select.coffee _post.coffee > sel.coffee',
        'popd',
        'coffee --compile --bare --output lib src/sel/sel.coffee',
        'coffee --compile --bare --output lib src/extras/ender.coffee',
    ]

task 'test', 'Build the test suite', ->
    execCmds [
        'rm -rf test',
        'coffee --compile --bare --output test src/test/*.coffee',
        
        'cp src/test/index.html test',
        'cp src/test/template.html test',
        'cp src/test/vows.css test',

        'npm install --dev',

        'ln -s .. node_modules/sel',
        'node_modules/.bin/ender build es5-basic domready node-compat ender-vows sel qwery sizzle',
        'unlink node_modules/sel',

        'mv ender.js ender.min.js test',
    ]
