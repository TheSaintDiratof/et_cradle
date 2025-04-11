#!/usr/bin/env bash 
root=$1
output=$2
for mode in desktop mobile plain-text; do
  for color in light dark; do
    mkdir -p "$output/$mode/$color"
    find $root -iname "*.txt" -exec ./convert.sh {} $mode $color $output $root \;
  done
done
while IFS= read -r line; do
  abs_path=$(realpath $line)
  output_file="$(echo $abs_path | sed -e "s|$root|$output|" -e "s|pages|images|")"
  mkdir -p "$(dirname $output_file)"
  cp $abs_path $output_file
done <<< "$(find $root -type f ! -iname "*.txt")"
cp $root/logo.png $output/logo.png
cp -r $root/styles $output/
