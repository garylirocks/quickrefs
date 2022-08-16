# Video & Audio processing

## Video/Audio basics

- different file formats(`.mov`, `.mp4`) are just containers, containing video/audio streams and metadata;
- the streams contained may have the same codecs;
- so for `sample.mov` and `sample.mp4`, the contained video/audio streams may use the same codecs;

## ffmpeg general

- show info of a video file

  ```bash
  # -hide_banner option hides build info of ffmpeg
  # -i specifies a input file
  ffmpeg -hide_banner -i gary_frontcourt.mp4
  ```

- codecs supported by ffmpeg

  ```bash
  ffmpeg -codecs
  ```

## Transcoding

- Trim a video

  ```sh
  # keep the same codecs and metadata
  ffmpeg -i input.mp4 -ss "00:00:02" -to "00:00:06" -c:v copy -c:a copy -map_metadata 0 out.mp4
  ```

- update file format (change extensions), keep codecs

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

## Refs

[How to Get Started Using FFmpeg for Transcoding](https://www.youtube.com/watch?v=1ymYwSQFodU)
