# Wordpress

- [Child theme](#child-theme)
- [Debug](#debug)
- [WP loading process](#wp-loading-process)
- [Queries and Loops](#queries-and-loops)
  - [`get_posts` example](#getposts-example)
  - [`WP_Query` example](#wpquery-example)
- [Ajax](#ajax)
- [Customizer](#customizer)
- [Images](#images)
  - [Image sizes](#image-sizes)
  - [Use SVG images](#use-svg-images)
- [Template hierarchy](#template-hierarchy)
- [Javascript](#javascript)
- [Caching](#caching)
- [Recommended plugins](#recommended-plugins)
- [Multilanguage Plugins](#multilanguage-plugins)
  - [One post per language](#one-post-per-language)
  - [All languages in one post](#all-languages-in-one-post)
  - [Automatic translation](#automatic-translation)
  - [Multisite solution](#multisite-solution)
- [Translation](#translation)
  - [`.pot`, `.po`, `.mo`](#pot-po-mo)
  - [Woocommerce language file loading order](#woocommerce-language-file-loading-order)
- [Snippets](#snippets)
  - [Get the term object in an archive page:](#get-the-term-object-in-an-archive-page)
  - [Get post content by ID](#get-post-content-by-id)
  - [Enable shortcode for widget text](#enable-shortcode-for-widget-text)
  - [Limit 'prev', 'next' navigation to posts in the same category](#limit-prev-next-navigation-to-posts-in-the-same-category)
- [Quick SQL](#quick-sql)
  - [Find all menu items](#find-all-menu-items)
  - [Check and update links](#check-and-update-links)
  - [Woocommerce](#woocommerce)
- [wp-cli](#wp-cli)
  - [Manage Wordpress container](#manage-wordpress-container)
  - [Install Wordpress core](#install-wordpress-core)
  - [Install and activate plugins](#install-and-activate-plugins)
  - [Search and Replace](#search-and-replace)
  - [Quick sql query](#quick-sql-query)
- [Migrate a site](#migrate-a-site)
- [Migrate the media library](#migrate-the-media-library)
- [Tips](#tips)
  - [Show all options](#show-all-options)
  - [Display content of multiple pages on one page](#display-content-of-multiple-pages-on-one-page)
- [Reference](#reference)

## Child theme

**Always create a child theme when you want to extend a existing theme**

Create a folder in the `themes` folder, create two files:

- `style.css`: reference parent theme in it:

  ```php
  /*
  Theme Name: child-thme-name
  Template: parent-theme-name
  */
  ```

  Parent theme's `style.css` will be overridden, see below to include

- `functions.php`:

  ```php
  <?php
  function theme_enqueue_styles() {
      wp_enqueue_style('parent-style', get_template_directory_uri() . '/style.css');

      // add styles and scripts here
      wp_register_style('bootstrap', get_stylesheet_directory_uri() . '/css/bootstrap.min.css', '', '0.3.2');
      wp_enqueue_style('bootstrap');

      wp_register_script('bootstrap', get_stylesheet_directory_uri() . '/js/bootstrap.min.js', '', '0.3.2' );
      wp_enqueue_script('bootstrap');
  }

  add_action('wp_enqueue_scripts', 'theme_enqueue_styles');
  ```

  Notes:

  - `get_template_directory_uri()` get parent theme directory;
  - `get_stylesheet_directory_uri()` get current theme directory;

## Debug

You can enable debug mode in `wp-config.php` by setting `WP_DEBUG` to `TRUE`, using `WP_DEBUG_DISPLAY` and `WP_DEBUG_LOG` to control whether your error messages are displayed to all the visitors and/or saved to a log file.

Recommended settings for debug:

```php
// Enable WP_DEBUG mode
define( 'WP_DEBUG', true );

// Enable Debug logging to the /wp-content/debug.log file
define( 'WP_DEBUG_LOG', true );

// Disable display of errors and warnings
define( 'WP_DEBUG_DISPLAY', true );
@ini_set( 'display_errors', 1 );

// Use dev versions of core JS and CSS files (only needed if you are modifying these core files)
define( 'SCRIPT_DEBUG', true );
```

## WP loading process

```
index.php -> wp-blog-header.php
                |-> wp-load.php -> wp-config.php -> wp-settings.php
                |-> wp()
                |-> template-loader.php
```

Important hooks in `wp-settings.php`

- load files in `wp-includes`
- load must-use plugins
- load network activated plugins
- fire **`muplugins_loaded`**
- ...
- load active plugins
- fire **`plugins_loaded`**
- set global variables: `wp`, `wp_query`, etc
- fire **`setup_theme`**
- load locale/text_domain
- load child theme (`function.php`) and parent theme
- fire **`after_setup_thme`**
- ...
- set up current user
- fire **`init`** (WP loads widgets, many plugins instantiate themeselves here)
- _(WP, all plugins, the theme are fully loaded and instantiated now)_
- fire **`wp_loaded`**

## Queries and Loops

A good article about this: [WordPress Development for Intermediate Users: Queries and Loops](https://premium.wpmudev.org/blog/wordpress-development-intermediate-users-queries-loops)
[Codex - Query Overview](https://codex.wordpress.org/Query_Overview)

- Wordpress runs a main query depending on what page you are on;
- If you want to customize the main query, use the `pre_get_posts` filter;
- You can create new queries in three ways:
  - `get_posts()` function, fetch all posts;
  - `get_pages()` function, fetch all pages;
  - `WP_Query` class, fetch whatever you like;
- **When using `get_posts()`, `get_pages()`, use `get_the_permalink()`, `get_the_title()` and `get_the_excerpt()` functions in the loop. You can't use `the_permalink()` etc. as those only work in the main loop or one you define with WP_Query**;
- Try avoid using `query_posts()`;

### `get_posts` example

```php
/* arguments */
$args = array(
    'sort_order' => 'desc',
    'sort_column' => 'date',
    'number' => '5',
);

// now run get_posts and check that any are returned
$myposts = get_posts( $args );
if  ( $myposts ) { ?>

    <h2>Latest Posts</h2>

    <?php // output the posts
    foreach( $myposts as $mypost ) {
        $postID = $mypost->ID; ?>

        <article class="post recent <?php echo $postID; ?>">
            <h3>
                <a href="<?php echo get_page_link( $postID ); ?>">
                    <?php echo get_the_title( $postID ); ?>
                </a>
            </h3>
            <section class="entry">
                <?php echo get_the_excerpt( $postID ); ?>
                <a href="<?php echo get_page_link( $postID ); ?>">Read More</a>
            </section>
        </article>

<?php }
```

### `WP_Query` example

Notes:

- **Always use `wp_reset_postdata()` after using `WP_Query`, so Wordpress can reset back to the main query**;
- Use `rewind_posts()` to rewind a custom loop to use it again;

  ```php
  // arguments for query
  $args = array(
      'post_type' => 'project',
      'posts_per_page' => 1
  );

  // run the query
  $query = new WP_query( $args );

  // check the query returns posts
  if ( $query->have_posts() ) { ?>

      <section class="projects">

          <?php while ( $query->have_posts() ) : $query->the_post(); ?>
          <?php //contents of loop ?>

          <h3>Latest Project - <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h3>
          <a href="<?php the_permalink(); ?>"><?php the_post_thumbnail( 'medium' ); ?></a>
          <?php the_excerpt(); ?>

          <?php endwhile; ?>
          <?php wp_reset_postdata(); ?>

      </section>

  <?php } ?>
  ```

## Ajax

[Smashing magazine Wordpress Ajax process](https://www.smashingmagazine.com/2011/10/how-to-use-ajax-in-wordpress/)

## Customizer

[Wordpress Customizer](https://premium.wpmudev.org/blog/wordpress-development-for-intermediate-users-making-your-themes-customizer-ready/)

Include a `customizer.php` in your theme's functions.php

a basic example (add a phone number in the header):

```php
function gary_customize_register( $wp_customize ) {
    // the class should be included inside the hook, WP_Customize_Control only loads in Customizer interface
    class gary_Customize_Textarea_Control extends WP_Customize_Control {
        public $type = 'textarea';

        public function render_content() {
            echo '<label>';
            echo '<span class="customize-control-title">' . esc_html( $this-> label ) . '</span>';
            echo '<textarea rows="2" style ="width: 100%;"';
            $this->link();
            echo '>' . esc_textarea( $this->value() ) . '</textarea>';
            echo '</label>';
        }
    }

    $wp_customize->add_section( 'gary_contact' , array(
            'title' => __( 'Contact Details', 'gary')
    ) );

    $wp_customize->add_setting( 'gary_telephone_setting', array (
            'default' => __( 'Your telephone number', 'gary' )
    ) );
    $wp_customize->add_control( new gary_Customize_Textarea_Control(
            $wp_customize,
            'gary_telephone_setting',
            array(
                    'label' => __( 'Telephone Number', 'gary' ),
                    'section' => 'gary_contact',
                    'settings' => 'gary_telephone_setting'
            )));
}

add_action( 'customize_register', 'gary_customize_register' );

// add a hook to display the info
function gary_display_contact_details_in_header() { ?>
    <div class="phone-number">
        <?php echo get_theme_mod( 'gary_telephone_setting', '0800 GARY' ); ?>
    </div>
<?php }
add_action( 'gary_header', 'gary_display_contact_details_in_header' );
```

A quick alternative to add some theme specific settings: `set_theme_mod()`, `get_theme_mod()`.

## Images

### Image sizes

- [Post Thumbnails](https://codex.wordpress.org/Post_Thumbnails)
- [Responsive Images in WordPress 4.4](https://make.wordpress.org/core/2015/11/10/responsive-images-in-wordpress-4-4/)
- [Using Responsive Images (Now)](http://alistapart.com/article/using-responsive-images-now#section2)
- [get_the_post_thumbnail](https://developer.wordpress.org/reference/functions/get_the_post_thumbnail/)

By default, Wordpress got `thumbnail`, `medium`, `large` and `full` image sizes, a `medium_large` size is added in Wordpress 4.4 (which is 768px wide by default)

When a theme adds `post-thumbnail` support, a special `post-thumbnail` image size is registered, which differs from the default `thumbnail` image size, the `Feature Image` meta box will only be available after this is added

```php
//customize thumbnail size
add_theme_support( 'post-thumbnails' );
set_post_thumbnail_size( 720, 400, true );  // default Post Thumbnail dimensions (cropped)


// add another custom image size
add_image_size('gary_custom', 780, 600, true);

// add the custom image size to the image size dropdown on the popup
function gary_custom_imagesizes ( $sizes ) {
    $sizes['gary_custom'] = __( 'Gary Custom', 'gary_custom' );
    return $sizes;
}

add_filter('image_size_names_choose', 'gary_custom_imagesizes', 11, 1);
```

### Use SVG images

[HOW TO ADD SVG TO WORDPRESS: YOUR GUIDE TO VECTOR IMAGES IN WORDPRESS](https://themeisle.com/blog/add-svg-to-wordpress/)

By default Wordpress doesn't support uploading SVG images, there are two ways to enable it:

1. Use _SVG Support_ plugin;
2. Add `.svg` as a supported filetype in your custom code;

## Template hierarchy

[The WordPress Template Hierarchy](https://wphierarchy.com/)

![wordpress template hirerarchy map](images/wordpress_template-hierarchy.png)

## Javascript

A list of default JS files and libraries in Wordpress:

- [wp_register_script](https://developer.wordpress.org/reference/functions/wp_register_script/)
- [wp_enqueue_script](https://developer.wordpress.org/reference/functions/wp_enqueue_script/)

## Caching

1. By default, WP's Object Cache is non-persistent, it only keeps data during one HTTP request, persistent caching can be enabled
   by install some plugin (Memcached, Redis, etc), which will create a new `wp-content/object-cache.php` file to overwrite
   default functions;

2. All MySQL queries use the Object Cache, to reduce DB queries;

3. The Transient API will use Object Cache if persistent cache is enabled, otherwise it will save data in the `wp-options` table;

4. The Options API always use the options table, since all MySQL queries use Object Cache, so it uses Object Cache as well.

## Recommended plugins

```
custom-post-type-ui
advanced-custom-fields
shortcodes-ultimate
post-duplicator
post-types-order

contact-form-7
contact-form-7-honeypot

theme-my-login

user-role-editor
adminimize

popup-maker

# WP Logo Showcase Responsive Slider
wp-logo-showcase-responsive-slider-slider

# Enable Media Replace
enable-media-replace

# encoding email addresses
email-address-encoder

# for customizing Woothemes child theme
https://github.com/woothemes/theme-customisations/archive/master.zip
```

You may need to add this to `wp-config.php` to install plugins automatically:

```php
define('FS_METHOD', 'direct');
```

## Multilanguage Plugins

Ref: [4 WAYS TO TURN WORDPRESS INTO A MULTILINGUAL WEBSITE](http://torquemag.io/2014/05/4-ways-to-turn-wordpress-into-a-multilingual-website/)

### One post per language

WPML (Premium)

Pros:

- no change to DB
- clean url
- support WooCommerce, WordPress SEO

Cons:

- complex architecture, needs many hook and filter

Alternatives: Polylang, xili-language, Bogo

### All languages in one post

qTranslate (free)

Pros:

- easy side-by-side editing for posts and pages
- no additional tables

Cons:

- menus and widgets need to be translated via inserting language tags
- need extra plugin for individual URL for each language
- uninstall can be complicated

Alternatives: qTranslate-X, WPGlobus

### Automatic translation

### Multisite solution

Multilingual Press

Pros:

- each site is a regular WordPress install and continues to work on its own
- language alternatives can have their own URLs and link structure

Cons:

- higher needs for management

Alternatives: Multisite Language Switcher, Zanto

## Translation

### `.pot`, `.po`, `.mo`

Ref: [Wiki gettext](https://en.wikipedia.org/wiki/Gettext)

### Woocommerce language file loading order

WooCommerce includes the following lines when including language files:

```php
load_textdomain( 'woocommerce', WP_LANG_DIR . '/woocommerce/woocommerce-' . $locale . '.mo' );
load_plugin_textdomain( 'woocommerce', false, plugin_basename( dirname( __FILE__ ) ) . '/i18n/languages' );
```

So it loads in the following order:

1. `WP_LANG_DIR/woocommerce/woocommerce-en_US.mo`
2. `WP_LANG_DIR/plugins/woocommerce-en_US.mo` <- `load_plugin_textdomain` try to load this file first, will not load anything else if this file is found
3. `wp-content/plugins/woocommerce/i18n/woocommerce-en_US.mo`

`WP_LANG_DIR` points to `wp-content/languages/` by default

## Snippets

### Get the term object in an archive page:

```php
$term_slug = get_query_var('term');

$term = get_term_by('slug', $term_slug, 'custom_category');
$page_title = $term->name;
```

### Get post content by ID

```php
echo apply_filters('the_content', get_post_field('post_content', $post_id));
```

### Enable shortcode for widget text

```php
add_filter('widget_text','do_shortcode');
```

### Limit 'prev', 'next' navigation to posts in the same category

<script src="https://gist.github.com/garylirocks/105823094fd21f47cbe4189a6f18ff44.js"></script>

## Quick SQL

### Find all menu items

```sql
SELECT * FROM `wp_posts` WHERE post_type = 'nav_menu_item';
SELECT * FROM  `wp_postmeta` WHERE meta_key LIKE '%_menu_item_%';
```

### Check and update links

Update any devleopment links before put the site alive:

```sql
SELECT * FROM `wp_options` where option_value like '%dev.example.com%';
SELECT *
    FROM  `wp_posts`
    WHERE post_status =  'publish'
    AND post_content LIKE  '%dev.example.com%'
    LIMIT 0 , 30;
SELECT * FROM `wp_postmeta` where meta_value like '%dev.example.com%';

UPDATE `wp_posts` SET post_content = REPLACE( post_content,  'http://dev.example.com/',  '/' ) WHERE post_status = 'publish';
UPDATE `wp_postmeta` set meta_value = REPLACE( meta_value, 'XXX', 'YYY' ) WHERE meta_key = '_menu_item_url' AND meta_value LIKE '%dev.example.com%';
```

### Woocommerce

- get products id from a category

        select tr.object_id from wp_term_taxonomy tt, wp_term_relationships tr, wp_terms t where t.name = 'CATEGORY_NAME' and tt.term_id = t.term_id and tr.term_taxonomy_id = tt.term_taxonomy_id;

- find product variations

        select * from wp_posts where post_parent = 15182 and post_type = 'product_variation';
        select * from wp_posts where (ID = 15182 and post_type = 'product') OR (post_parent = 15182 and post_type = 'product_variation');

- find product price (need to specify product variations' ids to find variation prices)

        select * from wp_postmeta where post_id = 15601 and meta_key like '%price';

- update product price (need to specify product variations' ids to update variation prices)

  **when bulk editing products in the admin page, there is an option to update prices, but seems like it doest not work as expected if either regular price or sale price is absent**

        update wp_postmeta set meta_value = meta_value+15 where post_id = 15601 and meta_key like '%price' and meta_value != '';

* disable attribute archive page

  ```sql
  update `wp_woocommerce_attribute_taxonomies` set attribute_public = 0;
  ```

## wp-cli

### Manage Wordpress container

```sh
# use the --ssh option to manage Wordpress running in a container
wp db tables --ssh=docker:wordpress
```

### Install Wordpress core

```sh
mkdir wp
cd wp
wp core download
wp core config --dbname=wpdemo --dbuser=wpdemo --dbpass=wpdemo
wp core install \
            --url=http://wpdemo.local/ \
            --title=wpdemo \
            --admin_user=admin \
            --admin_password=admin \
            --admin_email=admin@example.com
```

### Install and activate plugins

```sh
wp plugin install <plugin-name-here> --activate
```

### Search and Replace

```sh
# testing:
wp search-replace --dry-run 'dev.example.com' 'www.example.com'

# actually run:
wp search-replace 'dev.example.com' 'www.example.com'
```

**It can even search and replace text in serialized PHP values, do the unserializing and serailizing automatically**

### Quick sql query

```sh
wp db query "select * from wp_options where option_name in ('siteurl', 'home')"
```

## Migrate a site

1. Dump db;
2. Import db, change urls in `wp_options` table where `option_name` is `siteurl` or `home`;
   ```sql
   select * from wp_options where option_name in ('siteurl', 'home');
   update wp_options set option_value = 'http://xxx.xxx' where option_name in ('siteurl', 'home');
   ```
3. Change db settings in `wp-config.php`;
4. Goto admin area, `settings` -> `permalink`, don't change anything, just save;

## Migrate the media library

If you want to import media library from another wp install, do this

1. Download the `upload` folder and merge to the new site;
2. Export the `attachment` post type from the old site's `posts` and `postmeta` tables and import them to the new site;

refer: [Importing WordPress attachments into Media Library](https://timersys.com/importing-wordpress-attachments-media-library/)

Steps:

- Export data for the following two sqls

  ```sql
  SELECT * FROM wp_posts WHERE post_type = 'attachment' AND post_parent != '0';
  SELECT * FROM wp_postmeta WHERE post_id IN ( SELECT ID FROM wp_posts WHERE post_type = 'attachment' AND post_parent != '0' );
  ```

- For `wp_posts.sql`

  - Remove all unnecessary SQL code such as `ALTER TABLE` and `INSERT TABLE` and just keep `INSERT INTO`;
  - Change all the `INSERT INTO` sentences to `INSERT IGNORE INTO` in case duplicate keys exist;
  - Modify all image urls to match new domain (not always needed, depending where you are importing from);
  - Import into new site db;

- For `wp_postmeta.sql`

  - Remove all the unnecessary SQL code such as `ALTER TABLE` and `INSERT TABLE` and just keep `INSERT INTO`;
  - Chang all the `INSERT INTO wp_postmeta (meta_id, post_id, meta_key, meta_value) VALUES` to `INSERT INTO wp_postmeta (post_id, meta_key, meta_value) VALUES`;
  - Get rid of th `meta_id` values, using regex, replace `\( ([0-9]+),` with `(`;
  - Import;

## Tips

### Show all options

This page `http://xx.xx/wp-admin/options.php` will display all setting options

### Display content of multiple pages on one page

Theme: SCRN

## Reference

- [Wordpress Caching](https://premium.wpmudev.org/blog/wordpress-caching/)
- [Wordpress Customizer](https://premium.wpmudev.org/blog/wordpress-development-for-intermediate-users-making-your-themes-customizer-ready/)
