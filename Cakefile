fs = require('fs')
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
        'cake build',

        'coffee --compile --bare --output test src/test/*.coffee',
        'ln -sf ../src/test/index.html test',
        'ln -sf ../src/test/template.html test',
        'ln -sf ../src/test/vows.css test',

        'npm install --dev',
        'ln -sfh ender-vows node_modules/vows',

        'pushd test',
        'ln -sfh ../node_modules node_modules',
        'node_modules/.bin/ender build ender-vows ..',
        'popd test',
    ]
