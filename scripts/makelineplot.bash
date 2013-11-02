#!/bin/bash
# generates plots corresponding to csv file in results directory
# the idea is this:
#   we generate temporal directory $tmpDir for our stuff
#   first line of csv file contains labels for x and y separated by comman
#   second line contains names of columns
#   all other line are made as "x val,col1 data,col2 data,...,coln data"
#   we translate this file into format "col number,x,data" (ordered by column number) and put to $tmpResults
#   then we generate gnuplot script that takes $tmpResults and produces eps file

tmpDir=$(mktemp -d -t $(basename "$0"))
if [ "$?" -ne "0" ]; then
	tmpDir=$(mktemp -d -t "$(basename "$0")XXXX")
fi
tmpScript="$tmpDir/gnuplot.bash"
tmpResults="$tmpDir/results.csv"
inputFile="$1"
outputEpsFile="$2"

function finish {
	# clean tmp directory
	rm -r "$tmpDir"
}
trap finish EXIT

echo > "$tmpScript"
chmod a+x "$tmpScript"

echo "Working on ${inputFile}"

axis=$(head -n 1 "$inputFile")
columns=$(head -n 2 "$inputFile" | tail -n 1)

# Translation step
# type (column),x,y
echo -n > "$tmpResults"

i=1
oldIFS="$IFS"
IFS=','
for column in $columns; do
	awk -- "BEGIN{FS=\",\";OFS=\",\"}NR>2{print ${i}, \$1, \$$((i + 1))}" "$inputFile" >> "$tmpResults"
	i=$((i + 1))
done
IFS="$oldIFS"

# Generate and run gnuplot script
other="$(echo "$axis" | cut -d',' -f3-)"

cat > "$tmpScript" <<EOF
set term pdfcairo color enhanced ${other}
set output "${outputEpsFile}"

set xlabel "$(echo "$axis" | cut -d',' -f1)"
set ylabel "$(echo "$axis" | cut -d',' -f2)"
set datafile separator ","
plot \\
EOF

i=1
oldIFS="$IFS"
IFS=','
for column in $columns; do
	if [ "$i" != 1 ]; then
		echo -n ', ' >> "$tmpScript"
	fi

	echo -n "'${tmpResults}' using 2:(\$1==${i}?\$3:1/0) with lines title '${column}'" >> "$tmpScript"
	i=$((i + 1))
done
IFS="$oldIFS"

echo '' >> "$tmpScript"

gnuplot $tmpScript

# Fix colors and other things in eps file
# sed -i '' -e 's/Color false def/Color true def/g' "$outputEpsFile"
# sed -i '' -e 's/Solid false def/Solid true def/g' "$outputEpsFile"
