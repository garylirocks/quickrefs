# SVG

## Basic

- SVG is an XML language, it's elements and attributes names are case-sensitive;
- Attributes values must be inside quotes;

## Sizing

### Units:

- Absolute units: `100pt`, `200cm`;
- User units: plain numbers like `100`, `200`;

  ```xml
  <svg width="100" height="100">
  ```

  by default, this means 100x100px

### SVG element size:

- Default size: `300px x 150px`;
- Size can be specified by `width` and `height`:

  ```xml
  <svg width="200px" height="200px">
  <svg width="50%" height="200px">
  <svg width="100vw" height="100vh">
  ```

- Like any other HTML element, you can use CSS to specify the size of a SVG element;

### `viewbox`

```xml
<svg viewbox="0 0 50 50">
    <circle cx="50" cy="50" r="50" fill="#aaa" />
</svg>
```

- Show top left quarter of the circle, `0 0` is the starting coordinates, `50 50` is the width and height, NOT the ending coordinates;
- The `svg` element will take the full width of the page by default;
- When `viewbox` is present, you'd better only specify one of `width` or `height`, the other one can be calculated:
  ```xml
  <svg viewbox="0 0 50 50" width="100">
      <circle cx="50" cy="50" r="50" fill="#aaa" />
  </svg>
  ```
  in the above document, 50 unit is 100px

## CSS

```xml
<svg viewbox="0 0 50 50" width="100">
    <circle cx="50" cy="50" r="50" class="circle" />
</svg>
```

Attributes names are different:

```css
.circle {
  fill: red;
  stroke: blue;
  stroke-width: 5px;
}
```

![SVG CSS attributes](images/svg-css.png)

## Elements

- `<circle>`;
- `<line>`;
- `<polyline>`;
- `<rect>`;
- `<ellipse>`;
- `<polygon>`;
- `<path>`;

  ```xml
  <svg width="300" height="180">
  <path d="
  M 18,3
  L 46,3
  L 46,40
  L 61,40
  L 32,68
  L 3,40
  L 18,40
  Z
  "></path>
  </svg>
  ```

  Specify an action followed by coordinates:

  - `M` moveto;
  - `L` lineto;
  - `Z` close;

- `<text>`

  ```xml
  <svg width="300" height="180">
      <text x="50" y="25">Hello World</text>
  </svg>
  ```

  `x`, `y` specify the baseline of the text;

- `<use>`

  ```xml
  <svg viewBox="0 0 30 10" height="200">
      <circle id="myCircle" cx="5" cy="5" r="4"/>

      <use href="#myCircle" x="10" y="0" fill="blue" />
      <use href="#myCircle" x="20" y="2" fill="white" stroke="purple" />
  </svg>

  <svg viewBox="0 0 10 10" height="200">
      <use href="#myCircle" x="0" y="0" fill="gold" />
  </svg>
  ```

  `href` specifies the source URL (same `svg`, same page or another document), `x` and `y` are relative positions from the original position;

- `<g>`

  Put elements in a group for easy reuse:

  ```xml
  <svg viewBox="0 0 20 10" height="200">
      <g id="myGroup">
          <circle cx="5" cy="5" r="4" />
          <text x="3" y="5" style="font-size: 2px; fill: white">Hello</text>
      </g>

      <use href="#myGroup" x=10 y=0 fill="blue" />
  </svg>
  ```

- `<defs>`

  Just for definition, elements in it are not shown

  ```xml
  <svg viewBox="0 0 20 10" height="200">
      <defs>
          <g id="myGroup">
              <circle cx="5" cy="5" r="4" />
              <text x="3" y="5" style="font-size: 2px; fill: white">Hello</text>
          </g>
      </defs>

      <use href="#myGroup" x=0 y=0 fill="blue" />
  </svg>
  ```

- `<pattern>`
- `<image>`

- `<animate>`

  ```xml
  <svg width="500px" height="500px">
      <rect x="0" y="0" width="100" height="100" fill="#feac5e">
          <animate attributeName="x" from="0" to="500" dur="2s" repeatCount="indefinite" />
      </rect>
  </svg>
  ```

- `<animateTransform>`

## Clipping

![SVG clipping demo](images/svg-clipping.png)

```xml
<svg width="200" height="200">
    <defs>
        <clipPath id="checker">
            <rect x="0" y="0" width="100" height="100" />
            <rect x="100" y="100" width="100" height="100" />
        </clipPath>
    </defs>

    <circle cx="100" cy="100" r="100" clip-path="url(#checker)" />
</svg>
```

- Define all the clipping paths in `clipPath` and then reference it by `clip-path`;
- All areas covered by the clipping path are shown, the rest are hidden;

## Masking

![SVG masking](images/svg-masking.png)

- Define gradient and masks first, then apply them on rectangulars;

```xml
<svg width="300" height="200" >
    <defs>
        <linearGradient id="linear-gradient">
            <stop offset="0" stop-color="white" stop-opacity="0" />
            <stop offset="1" stop-color="white" stop-opacity="1" />
        </linearGradient>

        <radialGradient id="radial-gradient">
            <stop offset="0" stop-color="white" stop-opacity="1" />
            <stop offset="1" stop-color="white" stop-opacity="0" />
        </radialGradient>

        <mask id="mask1">
            <rect id="rectMask" x="0" y="100" width="100" height="100" fill="url(#linear-gradient)"  />
        </mask>

        <mask id="mask2">
            <circle id="radialMask" cx="150" cy="150" r="50" fill="url(#radial-gradient)" />
        </mask>

        <mask id="mask3">
            <ellipse id="ellipseMask" cx="250" cy="150" rx="40" ry="50" fill="url(#radial-gradient)" />
        </mask>
    </defs>

    <!-- backgrounds: black above green -->
    <rect x="0" y="0" width="100%" height="50%" fill="black" />
    <rect x="0" y="100" width="100%" height="50%" fill="green" />

    <!-- rect mask -->
    <use href="#rectMask" x="0" y="-100" />
    <!--a red rect with mask applied -->
    <rect x="0" y="100" width="100" height="100" fill="red" mask="url(#mask1)" />

    <!-- radial mask -->
    <use href="#radialMask" x="0" y="-100" />
    <!-- a rect with radial mask applied -->
    <rect x="100" y="100" width="100" height="100" fill="red" mask="url(#mask2)" />

    <!-- ellipse mask -->
    <use href="#ellipseMask" x="0" y="-100" />
    <!-- a rect with ellipse mask applied -->
    <rect x="200" y="100" width="100" height="100" fill="red" mask="url(#mask3)" />
</svg>
```

## JS

- Get SVG DOM

  ```js
  var svgObject = document.getElementById("object").contentDocument;
  var svgIframe = document.getElementById("iframe").contentDocument;
  var svgEmbed = document.getElementById("embed").getSVGDocument();
  ```

  can't get the DOM if you are using `<img>` tag for a SVG;

- Get the SVG xml string

  ```js
  var svgString = new XMLSerializer().serializeToString(
    document.querySelector("svg")
  );
  ```
