gulp = require("gulp")
$ = require("gulp-load-plugins")()

gulp.task "wiredep", ->
  wiredep = require("wiredep").stream
  gulp.src("app/styles/*.styl").pipe(wiredep(directory: "app/bower_components")).pipe gulp.dest("app/styles")
  gulp.src("app/*.jade").pipe(wiredep(
    exclude: "bower_components/bootstrap/dist/js/bootstrap.js"
    directory: "app/bower_components"
  )).pipe gulp.dest("app")
