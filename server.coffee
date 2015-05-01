#!/usr/bin/env coffee

express = require('express')
morgan = require('morgan')
paths = require('./config.json').paths
child_process = require('child_process')

app = express()

app.use([
    morgan('common'),
    express.static(paths.dest)
])

app.post('/rebuild', (req, res, next)->
    res.type('html')
    res.status(200)
    res.writeContinue()
    for i in [1..20]
        res.write("                                                  \n")
    res.write("""
        <!DOCTYPE html>
        <html>
        <body>
        <pre>
    """)

    child = child_process.spawn('gulp', ['build'])
    for fd in [child.stdout, child.stderr]
        fd.on('data', (data)->
            res.write(data)
        )

    child.on('close', (code)->
        res.end()
    )

)

module.exports = app

if module is require.main
    host = process.env.OPENSHIFT_NODEJS_IP || '0.0.0.0'
    port = process.env.OPENSHIFT_NODEJS_PORT || 8000
    server = app.listen(port, host, ->
        console.log("HTTP server started on port", this.address().port)
    )
