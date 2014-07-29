'use strict';

var gulp = require('gulp');

var browserSync = require('browser-sync');

function browserSyncInit(baseDir, files, browser) {
  browser = browser === undefined ? 'default' : browser;

  browserSync.instance = browserSync.init(files, {
    startPath: '/',
//    ghostMode: false,
    server: {
      baseDir: baseDir
    },
    browser: browser
  });

}

gulp.task('serve', ['watch'], function () {
  browserSyncInit([
    'app',
    '.tmp'
  ], [
    'app/*.html',
    '.tmp/*.html',
    '.tmp/styles/**/*.css',
    'app/scripts/**/*.js',
    '.tmp/scripts/**/*.js',
    'app/partials/**/*.html',
    '.tmp/partials/**/*.html',
    '.tmp/partials/**/*.js',
    'app/images/**/*'
  ]);
});

gulp.task('serve:dist', function () {
  browserSyncInit('dist');
});

gulp.task('serve:e2e', function () {
  browserSyncInit(['app', '.tmp'], null, []);
});

gulp.task('serve:e2e-dist', ['watch'], function () {
  browserSyncInit('dist', null, []);
});
