#!/bin/bash

input="$1"
output="$2"
before="$3"
after="$4"

language=$(head -n 1 "$input" | awk -F' ' '{print $NF}')

cat "$before" > "$output"
echo "\\begin{${language}}" >> "$output"
sed '1d' "$input" >> "$output"
echo "\\end{${language}}" >> "$output"
cat "$after" >> "$output"
