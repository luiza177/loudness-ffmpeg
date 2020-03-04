#!/bin/bash

OUTPUT_FOLDER_NAME="Normalized"

SAVEIFS="${IFS}"
IFS=$(echo -en "\n\b")
if [ -d "$1" ]; then
  echo "$1:"
  files=$(find -E "$1" -maxdepth 1 -type f -regex '.*(.wav|m4a)$')
else
  files="$(ls "$@" | awk '/.wav|.m4a$/ { print $0 }')"
fi
for file in $files; do
  base="$(basename "$file")"
  dir="$(dirname "$file")"
  dir_display=$(basename "$dir")
  echo "${dir_display}/${base}:"

  output_folder="${dir}/${OUTPUT_FOLDER_NAME}/"
  output="${output_folder}/${base}"
  if [ ! -d "${output_folder}" ]; then
    mkdir "${output_folder}"
  fi

  ffmpeg -hide_banner -loglevel warning -i "$file" -af loudnorm=I=-16:TP=-3.0:dual_mono=true:print_format=summary -ar 44100 "$output"
done
