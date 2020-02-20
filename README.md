# M4A Conversion Shell Scripts

Shell scripts to analyze and output **EBU R 128** Loudness information of WAV and M4A files. 

> **Only tested on MacOS as of this writing**

### Upcoming:
* Loudness normalize audio files.
* Loudness normalize with overriden targets

## Dependencies

[ffmpeg](https://www.ffmpeg.org/) must be installed and in the PATH.

## Usage

Analyze individual files:
```bash
loudnessinfo.sh foo.wav
loudnessinfo.sh foo/bar.wav bar/baz.m4a
```
Analyze all files in a given directory:
```bash
loudnessinfo.sh ~/Documents/
```