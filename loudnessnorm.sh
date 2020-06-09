#!/bin/bash

# TODO: --option for copying to folder even if not normalized
# TODO: --option to specify output folder
# TODO: handle multiple folders


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
  temp_file="$(mktemp)"
  base="$(basename "$file")"
  dir="$(dirname "$file")"
  dir_display=$(basename "$dir")
  echo "${dir_display}/${base}:"

  output_folder="${dir}/${OUTPUT_FOLDER_NAME}/"
  output="${output_folder}/${base}"
  if [ ! -d "${output_folder}" ]; then
    mkdir "${output_folder}"
  fi


  ffmpeg -i "$file" -hide_banner -af loudnorm=I=-16:TP=-3.0:dual_mono=true:print_format=summary -f null - 2> "$temp_file"

  integrated="$(awk '/Input Integrated:/ { print $3 }' "$temp_file")"
  lra="$(awk '/Input LRA:/ { print $3 }' "$temp_file")"
  truepeak="$(awk '/Input True Peak:/ { print $4 }' "$temp_file")"
  thresh="$(awk '/Input Threshold:/ { print $3 }' "$temp_file")"
  channels="$(awk -F', ' '/Stream #0:0/ { print $3; exit }' "$temp_file")"

  if [ "$channels" == "mono" ]; then
    echo -e "    Integrated  =  ${integrated} LUFS (dual mono)"
  else
    echo -e "    Integrated  =  ${integrated} LUFS"
  fi 
  echo -e "    True Peak   =  ${truepeak} dBTP"
  # echo -e "    LRA         =   ${lra}"

  # bc -l returns 0 or 1
  if [ $(echo "$integrated > -15.1" | bc -l) -eq 1 ] || [ $(echo  "$integrated < -16.9" | bc -l) -eq 1 ] || [ $(echo  "$truepeak > -2.5" | bc -l) -eq 1 ]; then 
    COMMAND="ffmpeg -i \"$file\" -hide_banner -loglevel warning -af \"loudnorm=I=-16:TP=-3.0:dual_mono=true:measured_I=${integrated}:measured_TP=${truepeak}:measured_LRA=${lra}:measured_thresh=${thresh}:linear=true:print_format=summary\" -ar 44100 "
    if [ ${file:(-3)} == "m4a" ]; then 
      COMMAND+="-ab 128000 "
    fi
    COMMAND+="\"$output\""
    # ffmpeg -i "$file" -hide_banner -loglevel warning -af "loudnorm=I=-16:TP=-3.0:dual_mono=true:measured_I=${integrated}:measured_TP=${truepeak}:measured_LRA=${lra}:measured_thresh=${thresh}:linear=true:print_format=summary" -ar 44100 "$output"  #2> "$temp_file"
    eval "$COMMAND" 
    echo -e "    --> done."
  else
    echo "    --> ${base} is already within tolerance of -16 LUFS (+/-1 LU) and -3.0 (+0.5) dBTP"
    #? cp "$file" "$output"
  fi

  rm "$temp_file"
  # removes empty folder
  if [ -z "$(ls ${output_folder})"]; then
    rm -r "$output_folder"
  fi

done