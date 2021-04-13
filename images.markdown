# Work with images

- [image info](#image-info)
- [resize image](#resize-image)
- [create fixed size thumbnails for images](#create-fixed-size-thumbnails-for-images)
- [rotate an image](#rotate-an-image)
- [show/edit/remove EXIF data](#showeditremove-exif-data)
- [convert image format](#convert-image-format)
- [composite, add overlay to an image](#composite-add-overlay-to-an-image)

## image info

    $ identify demo.jpg
    demo.jpg JPEG 1660x600 1660x600+0+0 8-bit DirectClass 339KB 0.000u 0:00.000

    // show image size
    $ identify -ping -format "%f | %wx%h \n" red_chair_709x1000.jpg
    red_chair_709x1000.jpg | 709x1000

refer to: [ImageMagick format option][imagemagick-format-options]

## resize image

    $ convert demo.jpg  -resize 500x200 demo_resized.jpg
    $ identify demo_resized.jpg // maintain aspect ratio
    demo_resized.jpg JPEG 500x181 500x181+0+0 8-bit DirectClass 46.3KB 0.000u 0:00.000

**bulk resize**:

    $ ls iphone_*
    iphone_1102.png  iphone_1103.png  iphone_1104.png  iphone_1105.png

    $ for f in `ls iphone*`; do echo $f; convert $f -resize 600 ${f%.*}_resized.${f##*.}; done
    iphone_1102.png
    iphone_1103.png
    iphone_1104.png
    iphone_1105.png

    $ identify *resized*
    iphone_1102_resized.png PNG 600x1067 600x1067+0+0 8-bit DirectClass 98.8KB 0.000u 0:00.000
    iphone_1103_resized.png[1] PNG 600x1067 600x1067+0+0 8-bit DirectClass 210KB 0.000u 0:00.000
    iphone_1104_resized.png[2] PNG 600x1067 600x1067+0+0 8-bit DirectClass 116KB 0.000u 0:00.000
    iphone_1105_resized.png[3] PNG 600x1067 600x1067+0+0 8-bit DirectClass 268KB 0.000u 0:00.000

## create fixed size thumbnails for images

[Create fixed size thumbnails with ImageMagick](http://cubiq.org/create-fixed-size-thumbnails-with-imagemagick)

![Demo](./images/imagemagick-create-fixed-size-thumbnails.jpeg)

```shell
mogrify -resize 80x80 -background white -gravity center -extent 80x80 -format jpg -quality 75 -path thumbs *.jpg

# for single image, the same as
convert -resize 80x80 -background white -gravity center -extent 80x80 apple.png apple-new.png
```

`-path thumbs`: output the result images to `thumbs` folder

## rotate an image

when you rotate an image in Shotwell, seems like it just add an tag `Exif.Image.Orientation` to the image, does not actually do anything with the pixel matrix, and this tag is not consistently honored by all programs handling images, the following command can actually work on the pixels

    convert apple.jpg -rotate 90 apple-after.jpg

## show/edit/remove EXIF data

```sh
# show metadata:
exiv2 -p a print apple.jpg

# delete all metadata:
exiv2 -d a delete apple.jpg

# add/modify a field (datetime)
exiv2 -M 'set Exif.Image.DateTime Ascii "2021:01:01 20:20:20"' modify apple.jpg

# delete a field
exiv2 -M 'del Exif.Image.Copyright' modify apple.jpg
```

## convert image format

convert `png` to `jpg`:

    for f in *png; do echo $f; convert -flatten -background white $f ${f%.*}.jpg; done;

convert and compress:

    convert -strip -interlace Plane -quality 85% banner.png banner-no-blur.jpg

with Gaussian blur:

    convert -strip -interlace Plane -gaussian-blur 0.05 -quality 85% banner.png banner.jpg

## composite, add overlay to an image

    composite overlay.png background.png result.png

[imagemagick-format-options]: http://www.imagemagick.org/script/escape.php
