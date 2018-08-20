Sass
==============

## two formats

`.scss` is superset of CSS, every valid CSS is valid SCSS

```scss
#main {
    color: blue;
    font-size: 0.3em;
}
```

`.sass` uses indentation instead of brackets and semicolons

```sass
#main
    color: blue
    font-size: 0.3em
```


## maps

sass map:

```scss
$map: (
    key: value,
    other-key: other-value
);
```


##  `for` loop

you can create a color scale based on the `for` loop

```scss
// create '.color-scale-x' classes with background color changing from red to green
$base: hsl(0, 41%, 66%);
$redHue: 0;
$greenHue: 128;

@for $i from 0 through 10 {
  $amount: $redHue + $i * ($greenHue - $redHue) / 10;
  
  .color-scale-#{$i} {
    background-color: change-color($base, $hue: $amount);
  }
}
```

## bootstrap-sass

when you work with bootstrap-sass, use the following structure in your main .scss file (copied from roots sage project)

your custom variables come first, then import `_bootstrap.scss`, then any other files

```scss
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
```
