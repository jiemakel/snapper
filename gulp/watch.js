'use strict';

var gulp = require('gulp');

var browserSync = require('browser-sync');

var $ = require('gulp-load-plugins')();

gulp.task('watch', ['wiredep', 'styles'] ,function () {
  gulp.watch('app/styles/**/*.styl', ['styles']);
  gulp.watch('app/scripts/**/*.js', ['scripts']);
  gulp.watch('app/scripts/**/*.coffee', ['coffee']);
  gulp.watch('app/**/*.jade', ['templates']);
  gulp.watch('app/images/**/*', ['images']);
  gulp.watch('bower.json', ['wiredep']);
});
