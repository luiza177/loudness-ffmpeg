#!/bin/bash

SAVEIFS="${IFS}"
IFS=$(echo -en "\n\b")
if [ -d "$1" ]; then
  echo "$1:"
  files=$(find -E "$1" -maxdepth 1 -type f -regex '.*(.wav|m4a)$')
else
  files="$(ls "$@" | awk '/.wav|.m4a$/ { print $0 }')"
fi
for file in $files; do
  temp_file="$(mktemp)"
  base="$(basename "$file")"
  dir="$(dirname "$file")"
  dir=$(basename "$dir")
  echo "${dir}/${base}:"

  ffmpeg -i "$file" -af loudnorm=I=-16:TP=-3.0:dual_mono=false:print_format=summary -f null - 2> $temp_file

  integrated="$(awk '/Input Integrated:/ { print $3, $4 }' "$temp_file")"
  lra="$(awk '/Input LRA:/ { print $3, $4 }' $temp_file)"
  truepeak="$(awk '/Input True Peak:/ { print $4, $5 }' $temp_file)"
  
  echo -e "  Integrated  =  ${integrated}\n  True Peak   =  ${truepeak}\n  LRA         =   ${lra}"

  rm "$temp_file"
done