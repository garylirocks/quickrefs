Gulp Workflow
================

## basic workflow

1. npm init

		$ cd ~/code
		$ mkdir myapp
		$ cd myapp/
		$ pwd
		/home/lee/code/myapp

		# create package.json
		$ npm init

2. create folder sturcture

3. git up

		$ vi .gitignore
		$ git init
		$ git add .
		$ git commit 

4. install packages

		$ npm install --save-dev gulp gulp-util


## gulp-sass

[A Simple Gulp'y Workflow For Sass](https://www.sitepoint.com/simple-gulpy-workflow-sass/)

init and install

	$ npm init
	$ npm install gulp gulp-sass gulp-sourcemaps gulp-autoprefixer --save-dev

a simple Gulp task to compile sass files with sourcemaps, autoprefixer etc.

	var gulp = require('gulp');
	var sass = require('gulp-sass');
	var sourcemaps = require('gulp-sourcemaps');
	var autoprefixer = require('gulp-autoprefixer');

	var autoprefixerOptions = {
		browsers: ['last 2 versions', '> 5%', 'Firefox ESR']
	};

	var input = './assets/sass/**/*.scss';
	var output = './styles';

	gulp.task('sass', function() {
		return gulp
				.src(input)
				.pipe(sourcemaps.init())
				.pipe(sass())
				.pipe(sourcemaps.write())
				.pipe(gulp.dest(output));
	});

	gulp.task('watch', function() {
		return gulp
				.watch(input, ['sass'])
				.on('change', function(event) {
					console.log('File ' + event.path + ' was ' + event.type + ', running tasks...');
				});
	});

	gulp.task('default', ['sass', 'watch']);
	gulp.task('prod', [], function () {
		return gulp
				.src(input)
				.pipe(sass({outputStyle: 'compressed' }))
				.pipe(autoprefixer(autoprefixerOptions))
				.pipe(gulp.dest(output));
	});


## browser-sync

[Browsersync + Gulp.js](https://www.browsersync.io/docs/gulp/)

	npm init
	npm install browser-sync gulp --save-dev

create a basic gulp config

	var gulp        = require('gulp');
	var browserSync = require('browser-sync').create();
	var less		= require('gulp-less');

	gulp.task('serve', [], function() {
		browserSync.init({
			files: ['*.php', '**/*.php'],	// watch these php files
			proxy: "aircon.local"
		});

		gulp.watch('*.less', [], browserSync.reload); // watch *.less files
	});



## tips

### copy files task

useful for copying third party assets to a public folder, with the `base` option, original path structures will be preserved as well:

	gulp.task('copy-thirdparty', function() {
		let files = [
						'./bower_components/jquery/dist/jquery.min.js',
						'./bower_components/bootstrap/dist/css/bootstrap.min.css',
					];
				
		return gulp.src(files, {base: './bower_components'})
					.pipe(gulp.dest('./public/thirdparty/'));
	});


the files will be copied to 

`./public/thirdparty/jquery/dist/jquery.min.js`
`./public/thirdparty/bootstrap/dist/css/bootstrap.min.css`



