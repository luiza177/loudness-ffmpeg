# EBU R 128 Loudness Shell Scripts

Shell scripts to analyze or normalize loudness of WAV and M4A files to **EBU R 128** Specs.

Will only normalize files that fall out of the tolerances [-16 LUFS (+/- 1 LU) and -3.0 (+0.5 dBTP)]

> **Only tested on MacOS as of this writing**

### Upcoming:

- Loudness normalize with overriden targets

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
loudnessnorm.sh -c ~/Documents         # Copies files that are already normalized (won't be touched) to output folder
loudnessnorm.sh -o ~/norm ~/Documents  # Overrides default relative 'Normalized' folder to a folder called '~/norm'
```
