Video & Audio processing
==========================

## Video/Audio basics

* different file formats(`.mov`, `.mp4`) are just containers, containing video/audio streams and metadata;
* the streams contained may have the same codecs;
* so for `sample.mov` and `sample.mp4`, the contained video/audio streams may use the same codecs;


## ffmpeg general

* show info of a video file

    ```bash
    # -hide_banner option hides build info of ffmpeg
    # -i specifies a input file
    ffmpeg -hide_banner -i gary_frontcourt.mp4
    ```

* codecs supported by ffmpeg

    ```bash
    ffmpeg -codecs
    ```

## Transcoding

* update file format (change extensions), keep codecs

    ```bash
    ffmpeg -i gary.mp4 -vcodec copy -acodec copy gary.mov
    ```

* use specified codecs

    ```bash
    # -crf can be used to control the output file quality, the higher the value, the lower the output bitrate, and the smaller the output file (the value is usually between 18 to 24)
    ffmpeg -i gary.mp4 -crf 28 -vcodec h264 -acodec copy gary-compressed.mp4
    ```


## Refs

[How to Get Started Using FFmpeg for Transcoding](https://www.youtube.com/watch?v=1ymYwSQFodU)