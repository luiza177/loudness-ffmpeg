# M4A Conversion Shell Scripts

Shell scripts to analyze or normalize loudness of WAV and M4A files to **EBU R 128** Specs.

> **Only tested on MacOS as of this writing**

### Upcoming:
* Loudness normalize with overriden targets

## Dependencies

[ffmpeg](https://www.ffmpeg.org/) must be installed and in the PATH.

## Usage

### Loudness analysis:

Analyze individual files:
```bash
loudnessinfo.sh foo.wav
loudnessinfo.sh foo/bar.wav bar/baz.m4a
```
Analyze all files in a given directory:
```bash
loudnessinfo.sh ~/Documents/
```
### Loudness normalize:
Supports individual files or directories like `loudnessinfo.sh`, defaults to outputing normalized files to a folder called 'Normalized' in the input file's directory.
```bash
loudnessnorm.sh ~/Documents/
```