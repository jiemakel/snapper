require! gulp
$ = require("gulp-load-plugins")!
wiredep = require("wiredep").stream

gulp.task \wiredep:styles, ->
	gulp.src("app/styles/*.styl")
		.pipe(wiredep(
			directory: "app/bower_components"
			fileTypes:
				styl:
					block: /(([ \t]*)\/\/\s*bower:*(\S*))(\n|\r|.)*?(\/\/\s*endbower)/gi
					detect:
						css: /@import\s['"](.+)['"]/gi
						styl: /(@import|@require)\s['"](.+)['"]/gi
					replace:
						css: '@import "{{filePath}}"'
						styl: '@require "{{filePath}}"'
		))
		.pipe(gulp.dest("app/styles"))

gulp.task \wiredep:scripts, ->
	gulp.src("app/*.jade")
		.pipe(wiredep(directory: "app/bower_components"))
		.pipe(gulp.dest("app"))

gulp.task \wiredep, <[wiredep:styles wiredep:scripts]>