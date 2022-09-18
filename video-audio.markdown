# Video & Audio processing

- [Video/Audio basics](#videoaudio-basics)
- [`ffmpeg`](#ffmpeg)
- [Transcoding](#transcoding)
- [Composing](#composing)
- [Refs](#refs)

## Video/Audio basics

- Different file formats(`.mov`, `.mp4`) are just containers, containing video/audio streams and metadata
- Each file format (container) supports certain audio/video codecs
- So for `sample.mov` and `sample.mp4`, the contained video/audio streams may use the same codecs

## `ffmpeg`

- Order of options matter, they apply to the following input/output file

Examples:

```bash
# Show properties of a file
#
# -i specifies a input file
# -hide_banner option hides build info of ffmpeg
ffmpeg -hide_banner -i gary_frontcourt.mp4

# Show codecs supported by ffmpeg
ffmpeg -codecs
```

## Transcoding

- Trim a video

  ```sh
  # keep the same codecs and metadata
  ffmpeg -i input.mp4 -ss "00:00:02" -to "00:00:06" -c:v copy -c:a copy -map_metadata 0 out.mp4
  ```

- Convert file format (change extensions), keeping codecs

  ```bash
  ffmpeg -i gary.mp4 -vcodec copy -acodec copy gary.mov
  ```

- use specified codecs

  ```bash
  # -crf can be used to control the output file quality,
  #   the higher the value, the lower the output bitrate
  #   and the smaller the output file (the value is usually between 18 to 24)
  ffmpeg -i gary.mp4 -crf 28 -vcodec h264 -acodec copy gary-compressed.mp4
  ```

- rotate video

  ```bash
  # transpose:
  #   0: 90 counter clockwise and vertical flip
  #   1: 90 clockwise
  #   2: 90 counter clockwise
  #   3: 90 clockwise and vertical flip

  # -map_metadata 0 : keep first input file's metadata
  ffmpeg -i in.mp4 -vf "transpose=2" -map_metadata 0 out.mp4
  ```

## Composing

- Make a video from a single image

  See details: https://trac.ffmpeg.org/wiki/Slideshow and https://superuser.com/a/1041818

  ```sh
  ffmpeg \
    -loop 1 -framerate 1 -i coverart-1280p.jpg \     # input image, `-loop 1` means infinite loop, `-framerate 1` a low frame rate makes processing faster
    -i test-audio.mp3 \                              # audio file
    -c:a copy -r 1 -vcodec libx264 \                 # copy audio codec, set framerate, video codec
    -vf scale=1280:720 \                             # set video format
    -pix_fmt yuv420p \                               # for compatibility
    -shortest \                                      # end after the audio stream ends
    test-video.mp4
  ```

## Refs

[How to Get Started Using FFmpeg for Transcoding](https://www.youtube.com/watch?v=1ymYwSQFodU)
