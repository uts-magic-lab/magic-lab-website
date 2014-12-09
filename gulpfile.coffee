gulp = require('gulp')
gutil = require('gulp/node_modules/gulp-util')
cached = require('gulp-cached')
remember = require('gulp-remember')
es = require('event-stream')
del = require('del')
_ = require('lodash')
sysPath = require('path')

config = require('./config')
paths = config.paths

gulp.task('default', ['build'])

gulp.task('build', ['assets', 'css', 'content'])

gulp.task('clean', (done)->
    del(paths.dest, done)
)

gulp.task('assets', ->
    gulp.src(paths.assets)
        .pipe(cached('assets'))
        .pipe(gulp.dest(paths.dest))
)

gulp.task('css', ->
    sourcemaps = require('gulp-sourcemaps')
    postcss = require('gulp-postcss')
    processors = [
        require('autoprefixer-core')({
            browsers: '> 0.1%'
        }),
        require('postcss-import')({
            path: sysPath.dirname(paths.stylesheets)
        }),
        # require('csswring')
    ]
    gulp.src(paths.stylesheets)
        .pipe(sourcemaps.init())
            .pipe(postcss(processors))
        .pipe(sourcemaps.write('.'))
        .pipe(cached('css'))
        .pipe(gulp.dest(paths.dest+'/style'))
)

templates = []
gulp.task('templates', ->
    jade = require('jade')
    gulp.src(paths.templates)
        .pipe(cached('templates'))
        .pipe(es.mapSync((file)->
            template = jade.compile(file.contents, {
                filename: file.path
                pretty: "  "
            })
            templates[file.relative] = template
        ))
        .pipe(remember('templates'))
)

gulp.task('collections', (done)->
    done() # TBD
)

gulp.task('content', ['collections', 'templates'], ->
    frontMatter = require('gulp-front-matter')
    marked = require('gulp-marked')

    gulp.src(paths.content)
        .pipe(cached('content'))
            .pipe(frontMatter({}))
            .pipe(marked({}))
            .pipe(es.mapSync((file)->
                tmplName = file.frontMatter?.template
                if tmplName
                    template = templates[tmplName]
                    locals = file.frontMatter
                    locals.stat = file.stat
                    locals.contents = file.contents.toString()
                    context = _.extend({}, config.globals, locals)
                    text = template(context)
                    file.contents = new Buffer(text)
                return file
            ))
        .pipe(remember('content'))
        .pipe(gulp.dest(paths.dest))
)

gulp.task('watch', ['server', 'build'], (done)->
    gulp.watch(paths.source, ['build']).on('change', (event)->
        if event.type is 'deleted'
            for domain, val of cached.caches
                delete cached.caches[domain][event.path]
                remember.forget(domain, event.path)
            # TODO: delete from dest
    )
)

gulp.task('serve', ['build'], (ready)->
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

gulp.task('fetch-data', (done)->
    GoogleSpreadsheet = require("google-spreadsheet")

    spreadsheet = new GoogleSpreadsheet(process.env.GSS_ID)
    spreadsheet.getInfo((err, info)->
        if err then return done(err)

        for worksheet in info.worksheets then do (worksheet)->
            spreadsheet.getRows(worksheet.id, (err, rows)->
                if err then return done(err)

                console.log("#{worksheet.title}: #{rows.length} rows")
            )
    )
)
