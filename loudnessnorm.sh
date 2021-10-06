#!/bin/bash

# TODO: handle multiple folders

MANUAL="loudnessnorm.sh script manual:

    FFMPEG-based EBU-R128 batch loudness normalization to -16 LUFS (+/- 1 LU), -3.0 dBTP for WAV and M4A files.

    USAGE:

        loudnessnorm.sh [options...] [folder or files...]

    OPTIONS:
        { -c | --copy } COPY UN-NORMALIZED FILES
            Copies files that are already within tolerance to output folder

        { -o | --output-folder } OUTPUT FOLDER
            Overrides default output folder name of \"Normalized\"

        { -h | --help } MANUAL
            Shows this info.
    
    EXAMPLES:
        loudnessnorm.sh . --- to convert whole current folder to a subfolder named \"Normalized\" (default)
        loudnessnorm.sh 0.wav 1.wav --- to convert individual files to subfolder called \"Normalized\" within each file's folder
        loudnessnorm.sh --output-folder Norm --copy WAV --- to normalize all files inside WAV/ folder to a subfolder named \"Norm\" and copy any untouched files
        loudnessnorm.sh -o ~/output -c BiBs --- to convert all files inside BiBs/ to ~/output and copy any untouched files"

COPY=0
OUTPUT_FOLDER_NAME="Normalized"

while true; do
    case "$1" in
        -c|--copy)
            # shift
            COPY=1
            shift
            ;;
        -o|--output-folder)
            shift
            OUTPUT_FOLDER="$1"
            shift
            ;;
        -h|--help|help)
            echo "$MANUAL"
            exit 1
            ;;
        *)
            break
    esac
done



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
  
  output_folder=""
  output=""

  if [ -n "$OUTPUT_FOLDER" ]; then
    output_folder="${OUTPUT_FOLDER}/"
    output="${OUTPUT_FOLDER}/${base}"
  else
    output_folder="${dir}/${OUTPUT_FOLDER_NAME}/"
    output="${output_folder}/${base}"
  fi

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

  if [ ${truepeak:0:1} == "+" ]; then
    truepeak=${truepeak##+}
  fi

  # bc -l returns 0 or 1
  if [ $(echo "$integrated > -15.2" | bc -l) -eq 1 ] || [ $(echo  "$integrated < -16.8" | bc -l) -eq 1 ] || [ $(echo  "$truepeak > -2.5" | bc -l) -eq 1 ]; then 
    COMMAND="ffmpeg -i \"$file\" -hide_banner -loglevel fatal -af \"loudnorm=I=-16:TP=-3.0:dual_mono=true:measured_I=${integrated}:measured_TP=${truepeak}:measured_LRA=${lra}:measured_thresh=${thresh}:linear=true:print_format=summary\" -ar 44100 "
    if [ ${file:(-3)} == "m4a" ]; then 
      COMMAND+="-ab 128000 -movflags +faststart"
    fi
    COMMAND+="\"$output\""
    # ffmpeg -i "$file" -hide_banner -loglevel warning -af "loudnorm=I=-16:TP=-3.0:dual_mono=true:measured_I=${integrated}:measured_TP=${truepeak}:measured_LRA=${lra}:measured_thresh=${thresh}:linear=true:print_format=summary" -ar 44100 "$output"  #2> "$temp_file"
    eval "$COMMAND" 
    echo "    --> done."
    echo ""
  else
    echo "    --> ${base} is already within tolerance of -16 LUFS (+/-1 LU) and -3.0 (+0.5) dBTP"
    if [ $COPY -eq 1 ]; then
      cp "$file" "$output_folder"
      echo "    --> ${base} was copied to ${output_folder}"
    fi
    echo ""
  fi

  rm "$temp_file"
  # removes empty folder
  if [ -z "$(ls ${output_folder})" ]; then
    rm -r "$output_folder"
  fi

done