require! gulp
$ = require("gulp-load-plugins")!

gulp.task \watch, <[build]>, !->
  gulp.watch "app/styles/**/*.styl", <[styles]>
  gulp.watch "app/scripts/**/*.ls", <[scripts]>
  gulp.watch "app/**/*.jade", <[templates]>
  gulp.watch "app/images/**/*", <[images]>
  gulp.watch "bower.json", <[wiredep]>
