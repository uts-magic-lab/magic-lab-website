#!/usr/bin/env coffee

express = require('express')
morgan = require('morgan')
bodyParser = require('body-parser')
paths = require('./config.json').paths
child_process = require('child_process')
_ = require('lodash')
es = require('event-stream')
ansi_up = require('ansi_up')
basicAuth = require('basic-auth')

app = express()

# top-level middleware

app.use(morgan('common'))
admin = express.Router()
app.use('/admin', admin)
app.use('/preview', express.static(paths.preview))
app.use('/', express.static(paths.public))

# admin functions
# TODO: basic auth

admin.use((req, res, next)->
    user = basicAuth(req) or {}
    if user.pass is process.env.ADMIN_PASSWORD
        return next()
    else
        res.set('WWW-Authenticate', 'Basic realm=Authorization Required')
        res.sendStatus(401)
)
admin.use(bodyParser.urlencoded({ extended: false }))

admin.use((req, res, next)->
    res.runCommand = (cmd, args=[], env={})->
        res.type('html')
        res.writeContinue()
        for i in [1..20]
            res.write("                                                  \n")
        res.write('<!DOCTYPE html><html><body><pre>')
        res.write("<b>$ #{cmd} #{args.join(' ')}\n</b>")

        childEnv = _.defaults(env, process.env, {
            DEBUG: 'gulp-spreadsheets,gulp-drive'
            DEBUG_COLORS: true
        })
        child = child_process.spawn(cmd, args, {env: childEnv})
        es.merge([child.stdout, child.stderr])
        .pipe(es.through((text)->
            process.stderr.write(text)
            html = ansi_up.ansi_to_html(ansi_up.escape_for_html(''+text))
            @emit('data', html)
        , (end)->
            @emit('data', '</pre><a href="admin.html">Back to Admin Panel</a>')
            @emit('end')
        ))
        .pipe(res)

        # support stopping the build if res.connection closes
        unless req.body.nohup
            res.on('close', ->
                child.kill('SIGHUP')
            )

    next()
)

admin.post('/rebuild', (req, res, next)->
    res.runCommand('gulp', ['build', '--color'])
)

admin.post('/commit', (req, res, next)->
    res.status(501)
    res.runCommand('echo', ["not implemented"])
)

admin.post('/publish', (req, res, next)->
    res.status(501)
    env = {}
    if req.body.commit_author?
        env.GIT_AUTHOR_NAME = req.body.commit_author
    res.runCommand('./publish.sh', [req.body.commit_message], env)
)

module.exports = app

# support running this file directly
if module is require.main
    host = process.env.OPENSHIFT_NODEJS_IP || '0.0.0.0'
    port = process.env.OPENSHIFT_NODEJS_PORT || 8000
    server = app.listen(port, host, ->
        console.log("HTTP server started on port", this.address().port)
    )
