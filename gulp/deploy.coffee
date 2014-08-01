gulp = require("gulp")
$ = require("gulp-load-plugins")()

gulp.task "deploy", [ "dist" ], ->
  gulp.src("./dist/**/*")
  	.pipe($.ghPages())
