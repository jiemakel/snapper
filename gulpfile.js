'use strict';
// Note the new way of requesting CoffeeScript since 1.7.x
require('coffee-script/register');
// This bootstraps your Gulp's main file
require('require-dir')('./gulp');

require("gulp").task("default", [ "build" ]);
