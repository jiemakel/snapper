require!{
  gulp
  \main-bower-files
  \uglify-save-license
}
$ = require("gulp-load-plugins")!

gulp.task \dist:html, <[build]>, ->
  jsFilter = $.filter("**/*.js")
  cssFilter = $.filter("**/*.css")
  gulp.src(".tmp/*.html")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.inject(gulp.src(".tmp/partials/**/*.js"),
      read: false
      starttag: "<!-- inject:partials-->"
      endtag: "<!-- endinject-->"
      addRootSlash: false
      addPrefix: ".."
    ))
    .pipe($.useref.assets())
    .pipe($.rev())
    .pipe(jsFilter)
    .pipe($.ngAnnotate())
    .pipe($.uglify(preserveComments: uglifySaveLicense))
    .pipe(jsFilter.restore())
    .pipe(cssFilter)
    .pipe($.csso())
    .pipe(cssFilter.restore())
    .pipe($.useref.restore())
    .pipe($.useref())
    .pipe($.revReplace())
    .pipe($.size())
    .pipe(gulp.dest("dist"))

gulp.task \dist:images, <[clean]>, ->
  gulp.src("app/images/**/*")
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.cache($.imagemin(
      optimizationLevel: 3
      progressive: true
      interlaced: true
    )))
    .pipe($.size())
    .pipe(gulp.dest("dist/images"))

gulp.task \dist:fonts, <[clean]>, ->
  gulp.src(mainBowerFiles())
    .pipe($.plumber(errorHandler: $.notify.onError("<%= error.stack %>")))
    .pipe($.filter("**/*.{eot,svg,ttf,woff}"))
    .pipe($.flatten())
    .pipe($.size())
    .pipe(gulp.dest("dist/fonts"))

gulp.task \dist, <[dist:html dist:images dist:fonts]>
