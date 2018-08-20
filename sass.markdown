Sass
==============

## two formats

`.scss` is superset of CSS, every valid CSS is valid SCSS

    #main {
      color: blue;
      font-size: 0.3em;
    }

`.sass` uses indentation instead of brackets and semicolons

    #main
      color: blue
      font-size: 0.3em

## Sass maps

sass map:

	$map: (
	  key: value,
	  other-key: other-value
	);


## bootstrap-sass

when you work with bootstrap-sass, use the following structure in your main .scss file (copied from roots sage project)

your custom variables come first, then import `_bootstrap.scss`, then any other files

	@import "common/variables";

	// bower:scss
	@import "../../bower_components/bootstrap-sass/assets/stylesheets/_bootstrap.scss";
	// endbower

	@import "common/global";
	@import "components/buttons";
	@import "components/comments";
	@import "components/forms";
	@import "components/grid";
	@import "components/wp-classes";
	@import "layouts/header";
	@import "layouts/sidebar";
	@import "layouts/footer";
	@import "layouts/pages";
	@import "layouts/posts";
	@import "layouts/tinymce";








