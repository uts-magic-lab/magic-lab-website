gulp = require('gulp')
_ = require('lodash')
$ = require('gulp-load-plugins')()
es = require('event-stream')
sysPath = require('path')
del = require('del')

config = require('./config')
paths = config.paths

# High-level tasks

gulp.task('default', ['start'])

gulp.task('start', ['build', 'serve-static'])

gulp.task('build', ['assets', 'css', 'content'])

gulp.task('watch', ['build', 'serve-with-reload'], (done)->
    gulp.watch([paths.source, paths.data+'/**/*.json'], ['local-assets', 'local-content', 'css']).on('change', (event)->
        if event.type is 'deleted'
            for domain, val of $.cached.caches
                delete $.cached.caches[domain][event.path]
                $.remember.forget(domain, event.path)
            # TODO: delete from dest
    )
)

gulp.task('clean', (done)->
    del(paths.dest, done)
)

# Assets

gulp.task('assets', ['local-assets', 'cloud-assets'])

gulp.task('local-assets', ->
    gulp.src(paths.assets)
        .pipe($.cached('local-assets'))
        .pipe(gulp.dest(paths.dest))
)

gulp.task('cloud-assets', ->
    options = {
        clientId: process.env.OAUTH_CLIENT_ID
        clientSecret: process.env.OAUTH_CLIENT_SECRET
        refreshToken: process.env.OAUTH_REFRESH_TOKEN
    }
    drive = require("gulp-google-drive")(options)
    drive.src(process.env.GOOGLE_DRIVE_FOLDER_ID)
    .pipe($.cached('cloud-assets'))
    .pipe(drive.fetch)
    .pipe($.remember('cloud-assets'))
    .pipe(gulp.dest(paths.dest + '/assets'))
)

# Stylesheets

gulp.task('css', ->
    processors = [
        require('autoprefixer-core')({
            browsers: '> 0.1%'
        }),
        require('postcss-import')({
            path: sysPath.dirname(paths.stylesheets)
        })
    ]
    if process.env.MINIFY
        processors.push(require('csswring'))

    gulp.src(paths.stylesheets)
        .pipe($.sourcemaps.init())
            .pipe($.postcss(processors))
            # .pipe($.concat('style/main.css'))
        .pipe($.sourcemaps.write('.'))
        .pipe($.cached('css'))
        .pipe(gulp.dest(paths.dest))
)

# Content

templates = []
gulp.task('templates', ->
    jade = require('jade')
    if process.env.MINIFY
        pretty = false
    else
        pretty = "  "

    gulp.src(paths.templates)
        .pipe($.cached('templates'))
        .pipe(es.map((file, callback)->
            template = jade.compile(file.contents, {
                filename: file.path
                pretty: pretty
            })
            templates[file.relative] = template
            callback()
        ))
        # .pipe($.remember('templates'))
)

renameFile = (file, newExtname)->
    dirname = sysPath.dirname(file.path)
    extname = sysPath.extname(file.path)
    basename = sysPath.basename(file.path, extname)
    if newExtname
        extname = newExtname
    basename = config.rename[basename] or basename
    return sysPath.join(dirname, basename + extname)

renderFile = (file, callback)->
    helpers = {
        _: _
        marked: require('marked')
    }
    locals = JSON.parse(file.contents)
    context = _.extend(helpers, config.globals, file, locals)

    tmplName = context.template || 'page.jade'
    template = templates[tmplName]
    text = template(context)
    file.contents = new Buffer(text)
    file.path = renameFile(file, '.html')

    callback(null, file)

gulp.task('cloud-data', ->
    $.googleSpreadsheets(process.env.GSS_ID)
    .pipe(gulp.dest(paths.data))
)

gulp.task('local-content', ['templates'], ->
    gulp.src(paths.data+'/**/*.json')
    .pipe(es.map(renderFile))
    .pipe(gulp.dest(paths.dest))
)

gulp.task('content', ['templates', 'cloud-data'], ->
    gulp.src(paths.data+'/**/*.json')
    .pipe(es.map(renderFile))
    .pipe(gulp.dest(paths.dest))
)

# Servers

gulp.task('serve-with-reload', (ready)->
    browserSync = require('browser-sync')

    browserSync({
        port: process.env.PORT or 8000
        server: {
            baseDir: paths.dest
        }
        files: paths.dest+"/**/*.*"
        online: false
        open: false
    }, ready)
)

gulp.task('serve-static', (ready)->
    express = require('express')
    morgan = require('morgan')
    app = express().use([
        morgan('common'),
        express.static(paths.dest)
    ])
    host = process.env.OPENSHIFT_NODEJS_IP || '0.0.0.0'
    port = process.env.OPENSHIFT_NODEJS_PORT || 3000
    server = app.listen(port, host, ->
        console.log("HTTP server started on port", this.address().port)
        ready()
    )
)

gulp.task('save-snapshots', ['build'], ->
    # for each page:
        # load it in phantomJS
        # render it to an image
        # save it for archival
    # see http://phantomjs.org/api/webpage/method/render.html
    # see http://phantomjs.org/screen-capture.html
    # see https://gist.github.com/crazy4groovy/3160121
)
