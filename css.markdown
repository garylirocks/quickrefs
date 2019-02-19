# CSS

- [General](#general)
- [Positioning](#positioning)
- [Flex](#flex)
- [CSS Grid Layout](#css-grid-layout)
- [PostCSS](#postcss)
  - [Difference between PostCSS and CSS pre-processors](#difference-between-postcss-and-css-pre-processors)
- [Custom properties (variables)](#custom-properties-variables)
- [Tricks](#tricks)
  - [Line before and after centered text](#line-before-and-after-centered-text)
  - [Clearfix](#clearfix)
  - [Center an image](#center-an-image)
  - [Vertically center an image in a row](#vertically-center-an-image-in-a-row)
- [Hacks](#hacks)
  - [Firefox only rules](#firefox-only-rules)

## General

Global styling

[HTML vs Body in CSS](https://css-tricks.com/html-vs-body-in-css/)

- `html` vs. `:root`: are the same in a HTML page context, but `:root` has a higher specificity, `:root` can also be used with other document formats, such as SVG and XML;
- `html` and `body`: do not have much difference most of the time, but when setting the base font size for `rem` sizing, you should set it on `html`;
- If there is no `background-color` on `html`, `background-color` of `body` floods the whole viewport, even the body doesn't occupy the whole area (https://codepen.io/anon/pen/dWqKpN);

## Positioning

refer to: http://learnlayout.com/position.html

## Flex

- [CSS Tricks: A complete guide to flexbox](https://css-tricks.com/snippets/css/a-guide-to-flexbox/)
- [Codepen: flexbox demo](http://codepen.io/anon/pen/vxRpyL)

## CSS Grid Layout

- [A Complete Guide to Grid - CSS Tricks](https://css-tricks.com/snippets/css/complete-guide-grid/)
- [CSS Grid Layout - MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Grid_Layout)

Basics

- Two-dimensional grid-based layout system;
- Trying to solve the layout issue we're trying to solve by using all kinds of hacks;
- Can work well with Flexbox (which is intended for one dimensional layout);

## PostCSS

[A List Apart: What Will Save Us from the Dark Side of CSS Pre-Processors](https://alistapart.com/column/what-will-save-us-from-the-dark-side-of-pre-processors)

### Difference between PostCSS and CSS pre-processors

- **In contrast to pre-processors' distinct syntaxes, post-processors typically feed on actual CSS**;
- They can act like polyfills, letting you write to-spec CSS that will work someday and transforming it into something that will work in browsers today. Ideal CSS in, real-life CSS out;

## Custom properties (variables)

A custom property starts with `--`, the value of a property can be any valid CSS value: a color, a string, a layout value, even an expression:

```css
.box {
  --box-color: #002233;
  --box-padding: 0 10px;

  --transition-duration: 0.35s;
  --margin-top: calc(2vh + 20px);

  --suffix: " >>";
}
```

Custom properties cascade in the same way as normal CSS properties, use `var()` to get the value of a custom property:

```css
.box .content-wrap {
  --box-color: gray;

  background-color: var(--box-color);
  margin: var(
    --box-margin,
    10px
  ); /* provide a default value if the custom property is not defined */
}
```

## Tricks

### Line before and after centered text

[http://stackoverflow.com/questions/23584120/line-before-and-after-title-over-image](http://stackoverflow.com/questions/23584120/line-before-and-after-title-over-image)

### Clearfix

```css
.clearfix {
  content: "";
  display: table;
  clear: both;
}
```

### Center an image

Refer to: http://stackoverflow.com/questions/7273338/how-to-vertically-align-an-image-inside-div

HTML:

```html
<div class="frame">
  <img src="foo" />
</div>
```

CSS:

```css
.frame {
  height: 160px; /* can be anything */
  width: 160px; /* can be anything */
  position: relative;
}

/* absolute positioning for the image */
img {
  max-height: 100%;
  max-width: 100%;
  width: auto;
  height: auto;
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
  margin: auto;
}
```

### Vertically center an image in a row

[CodePen: Vertically center an image in a row](http://codepen.io/anon/pen/LWzQwP)

![Center Image](./images/css-center-image.png)

## Hacks

### Firefox only rules

[Firefox only css rules](firefox-only-css)

```css
@-moz-document url-prefix() {
  #button {
    color: red;
  }
}
```

[firefox-only-css]: http://stackoverflow.com/questions/952861/targeting-only-firefox-with-css
