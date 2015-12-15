require!{
  gulp 
  nib
}
$ = require("gulp-load-plugins")!

gulp.task \styles, ->
  gulp.src("app/styles/main.styl")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.stylus(use: [nib!])).pipe($.autoprefixer("last 1 version"))
    .pipe(gulp.dest(".tmp/styles"))

gulp.task "scripts", ->
  gulp.src("app/scripts/**/*.ls")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.cached!)
    .pipe($.sourcemaps.init!)
    .pipe($.livescript(bare: false))
    .pipe($.sourcemaps.write("./tmp/maps"))
    .pipe(gulp.dest(".tmp/scripts"))

gulp.task "templates", ->
  gulp.src("app/**/*.jade")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.cached!)
    .pipe($.sourcemaps.init!)
    .pipe($.jade(pretty: true))
    .pipe($.sourcemaps.write("./tmp/maps"))
    .pipe(gulp.dest(".tmp"))

gulp.task "partials", <[templates]>, ->
  gulp.src(".tmp/partials/**/*.html")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.ngHtml2js(
      moduleName: "app"
      prefix: "partials/"
    ))
    .pipe(gulp.dest(".tmp/partials"))

gulp.task "clean", (cb) ->
  require('del') <[.tmp dist]>, cb

gulp.task "build", (cb) ->
  require("run-sequence") \clean, <[wiredep templates styles scripts partials]>, cb
