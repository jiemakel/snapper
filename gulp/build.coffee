gulp = require("gulp")
$ = require("gulp-load-plugins")()

gulp.task "styles", ->
  gulp.src("app/styles/main.styl")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.stylus()).pipe($.autoprefixer("last 1 version"))
    .pipe(gulp.dest(".tmp/styles"))

gulp.task "scripts", ->
  gulp.src("app/scripts/**/*.coffee")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.cached())
    .pipe($.sourcemaps.init())
    .pipe($.coffee(bare: false))
    .pipe($.sourcemaps.write("./tmp/maps"))
    .pipe(gulp.dest(".tmp/scripts"))

gulp.task "templates", ->
  gulp.src("app/**/*.jade")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.cached())
    .pipe($.sourcemaps.init())
    .pipe($.jade(pretty: true))
    .pipe($.sourcemaps.write("./tmp/maps"))
    .pipe(gulp.dest(".tmp"))

gulp.task "partials", [ "templates" ], ->
  gulp.src(".tmp/partials/**/*.html")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.ngHtml2js(
      moduleName: "fi.seco.aether"
      prefix: "partials/"
    ))
    .pipe(gulp.dest(".tmp/partials"))

gulp.task "clean", ->
  gulp.src([ ".tmp", "dist" ],{ read: false }).pipe($.rimraf())

runSequence = require("run-sequence")

gulp.task "build", (cb) ->
  runSequence("clean", [ "wiredep", "templates", "styles", "scripts", "partials" ], cb)