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
        'cd src/sel',
        'cat _pre.coffee util.coffee find.coffee pseudos.coffee parser.coffee eval.coffee select.coffee _post.coffee > sel.coffee',
        'cd ../..',
        'coffee --compile --bare --output lib src/sel/sel.coffee',
        'coffee --compile --bare --output lib src/extras/ender.coffee',
    ]

task 'test', 'Build the test suite', ->
    execCmds [
        'cake build',

        'coffee --compile --bare --output test src/test/*.coffee',
        'ln -sf ../src/test/index.html test',
        'ln -sf ../src/test/template.html test',
        'ln -sf ../src/test/vows.css test',

        'npm install --dev',
        'ln -sfn ender-vows node_modules/vows',

        'cd test',
        'ln -sfn ../node_modules node_modules',
        'node_modules/.bin/ender build ender-vows ..',
        'cd ..',
    ]
