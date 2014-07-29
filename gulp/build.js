'use strict';

var gulp = require('gulp');
var mainBowerFiles = require('main-bower-files');

var $ = require('gulp-load-plugins')();
var saveLicense = require('uglify-save-license');

gulp.task('styles', function () {
  return gulp.src('app/styles/main.styl')
    .pipe($.plumber({errorHandler: $.notify.onError("<%= error.stack %>")}))
//    .pipe($.sourcemaps.init())
    .pipe($.stylus())
//    .pipe($.less())
    .pipe($.autoprefixer('last 1 version'))
//    .pipe($.sourcemaps.write('./tmp/maps'))
    .pipe(gulp.dest('.tmp/styles'))
    .pipe($.size());
});

gulp.task('coffee', function () {
  return gulp.src('app/scripts/**/*.coffee')
        .pipe($.plumber({errorHandler: $.notify.onError("<%= error.stack %>")}))
        .pipe($.cached())
        .pipe($.sourcemaps.init())
        .pipe($.coffee({bare: false}))
        .pipe($.sourcemaps.write('./tmp/maps'))
        .pipe(gulp.dest('.tmp/scripts'))
        .pipe($.size());
});

gulp.task('templates', function() {
  return gulp.src('app/**/*.jade')
    .pipe($.plumber({errorHandler: $.notify.onError("<%= error.stack %>")}))
    .pipe($.cached())
    .pipe($.sourcemaps.init())
    .pipe($.jade({
      pretty: true
    }))
    .pipe($.sourcemaps.write('./tmp/maps'))
    .pipe(gulp.dest('.tmp'))
    .pipe($.size());
});

gulp.task('scripts', function () {
  return gulp.src('app/scripts/**/*.js')
    .pipe($.plumber({errorHandler: $.notify.onError("<%= error.stack %>")}))
    .pipe($.cached())
    .pipe($.jshint())
    .pipe($.jshint.reporter('jshint-stylish'))
    .pipe($.size());
});

gulp.task('partials', ['templates'], function () {
  return gulp.src('.tmp/partials/**/*.html')
    .pipe($.plumber({errorHandler: $.notify.onError("<%= error.stack %>")}))
    .pipe($.ngHtml2js({
      moduleName: "snapper",
      prefix: "partials/"
    }))
    .pipe(gulp.dest(".tmp/partials"))
    .pipe($.size());
});

gulp.task('html', ['templates', 'styles', 'coffee', 'partials'], function () {
  var jsFilter = $.filter('**/*.js');
  var cssFilter = $.filter('**/*.css');

  return gulp.src(['app/*.html','.tmp/*.html'])
    .pipe($.plumber({errorHandler: $.notify.onError("<%= error.stack %>")}))
    .pipe($.inject(gulp.src('.tmp/partials/**/*.js'), {
      read: false,
      starttag: '<!-- inject:partials-->',
      endtag: '<!-- endinject-->',
      addRootSlash: false,
      addPrefix: '..'
    }))
    .pipe($.useref.assets())
    .pipe($.rev())
    .pipe(jsFilter)
    .pipe($.ngAnnotate())
    .pipe($.uglify({preserveComments: saveLicense}))
    .pipe(jsFilter.restore())
    .pipe(cssFilter)
//    .pipe($.replace('bower_components/bootstrap-sass-official/vendor/assets/fonts/bootstrap','fonts'))
    .pipe($.csso())
    .pipe(cssFilter.restore())
    .pipe($.useref.restore())
    .pipe($.useref())
    .pipe($.revReplace())
    .pipe($.filelog())
    .pipe(gulp.dest("dist"))
    .pipe($.size());
});

gulp.task('images', function () {
  return gulp.src('app/images/**/*')
    .pipe($.plumber({errorHandler: $.notify.onError("<%= error.stack %>")}))
    .pipe($.cache($.imagemin({
      optimizationLevel: 3,
      progressive: true,
      interlaced: true
    })))
    .pipe(gulp.dest('dist/images'))
    .pipe($.size());
});

gulp.task('fonts', function () {
  return gulp.src(mainBowerFiles())
    .pipe($.plumber({errorHandler: $.notify.onError("<%= error.stack %>")}))
    .pipe($.filter('**/*.{eot,svg,ttf,woff}'))
    .pipe($.flatten())
    .pipe(gulp.dest('dist/fonts'))
    .pipe($.size());
});

gulp.task('clean', function () {
  return gulp.src(['.tmp', 'dist'], { read: false }).pipe($.rimraf());
});

gulp.task('build', ['html', 'images', 'fonts']);
