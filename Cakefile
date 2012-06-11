fs = require('fs')
{spawn, exec} = require('child_process')

execCmds = (cmds) ->
    exec cmds.join(' && '), (err, stdout, stderr) ->
        output = (stdout + stderr).trim()
        console.log(output + '\n') if (output)
        throw err if err

task 'build', 'Build the library', ->
    execCmds [
        'cd src/sel',
        'cat _pre.coffee util.coffee parser.coffee find.coffee pseudos.coffee eval.coffee select.coffee matching.coffee _post.coffee > sel.coffee',
        'cd ../..',
        'coffee --compile --bare --output lib src/sel/sel.coffee',
        'coffee --compile --bare --output lib src/extras/ender.coffee',
    ]

task 'size', 'Print the size of the compressed library', ->
    execCmds [
        'cake build',
        'cat lib/sel.js | uglifyjs | gzip -9f  | wc -c',
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
        'rm -rf node_modules/sel',
        'node_modules/.bin/ender build ender-vows ..',
        'cd ..',
    ]
