#!/bin/bash

output_info() {
  integrated="$(awk '/Input Integrated:/ { print $3 }' "$1")"
  lra="$(awk '/Input LRA:/ { print $3 }' "$1")"
  truepeak="$(awk '/Input True Peak:/ { print $4 }' "$1")"
  
  
  echo -e "    Integrated  =  ${integrated} LUFS"
  echo -e "    True Peak   =  ${truepeak} dBTP"
  echo -e "    LRA         =   ${lra}"
}

OUTPUT_FOLDER="Normalized"
if [ ! -d "${OUTPUT_FOLDER}" ]; then
    mkdir "${OUTPUT_FOLDER}"
fi

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
  dir_display=$(basename "$dir")
  echo "${dir_display}/${base}:"

  output="${OUTPUT_FOLDER}/${base}"

  ffmpeg -i "$file" -af loudnorm=I=-16:TP=-3.0:dual_mono=false:print_format=summary -f null - 2> $temp_file

  echo "  Input:"
  # ouput_info "$file"

  # TODO: replace with function
  integrated="$(awk '/Input Integrated:/ { print $3 }' "$temp_file")"
  lra="$(awk '/Input LRA:/ { print $3 }' $temp_file)"
  truepeak="$(awk '/Input True Peak:/ { print $4 }' $temp_file)"
  
  echo -e "    Integrated  =  ${integrated} LUFS"
  echo -e "    True Peak   =  ${truepeak} dBTP"
  echo -e "    LRA         =   ${lra}"

  # what is log level panic?
  ffmpeg -i "$file" -loglevel panic -af loudnorm=I=-16:TP=-3.0:LRA=11:measured_I=${integrated}:measured_TP=${truepeak}:measured_LRA=${lra}:offset=-0.3:linear=true:print_format=summary "$output" 2> $temp_file

  # echo "  Output:"
  # output_info "$ouput"

  rm "$temp_file"
done