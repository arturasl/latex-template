#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function findDia () {
	if command -v 'dia'; then
		echo 'dia'
	elif [ -x '/Applications/Dia.app/Contents/Resources/bin/dia' ]; then
		echo '/Applications/Dia.app/Contents/Resources/bin/dia'
	else
		echo 'Could not find dia executable' 1>&2
		exit 1
	fi
}

function findInkscape () {
	if command -v 'inkscape'; then
		echo 'inkscape'
	elif [ -x '/Applications/Inkscape.app/Contents/Resources/bin/inkscape' ]; then
		echo '/Applications/Inkscape.app/Contents/Resources/bin/inkscape'
	else
		echo 'Could not find inkscape executable' 1>&2
		exit 1
	fi
}

# converts dot file to ps handling virtual commands
# $1 - cmd, $2 - type, $3 - input
# outputs to $tmpFilePs
function convertDotWithCmd () {
	if [ "$1" = tree ]; then
		dot "$3" | gvpr -c "-f${SCRIPT_DIR}/tree.gvpr" | neato -n "-T${2}" -o "$tmpFilePs" 2>&1
	else
		"$1" "-T${2}" -o "$tmpFilePs" "$3" 2>&1
	fi
}

#tmpFile=$(mktemp -t $(basename "$0"))
tmpFile=$(mktemp -t $(basename "$0").XXXX)
tmpFileEps=${tmpFile}.eps
tmpFilePs=${tmpFile}.ps
tmpFileSvg=${tmpFile}.svg
function finish {
	rm -f "$tmpFile"
	rm -f "$tmpFileEps"
	rm -f "$tmpFilePs"
	rm -f "$tmpFileSvg"
}
trap finish EXIT

inputFileName="$1"
mkdir -p "$(dirname ${inputFileName})"
inputFileExt=${inputFileName##*.}

case "$inputFileExt" in
	dia)
		$(findDia) --nosplash "--export=${tmpFileEps}" "$1"
		"$0" "$tmpFileEps" "$2"
		;;

	eps)
		#gs -dSAFER -dNOPAUSE -dBATCH -q -dCompatibilityLevel=1.4 -sDEVICE=pdfwrite -sstdout=%stderr -sOutputFile=test.pdf test.eps
		epstopdf "$1" "--outfile=${2}"
		;;

	ps)
		epstopdf "$1" "--outfile=${2}"
		;;

	svg)
		if [ "$3" = "inkscape" ]; then
			$(findInkscape) --without-gui "--export-ps=${tmpFilePs}" "$1"
			"$0" "$tmpFilePs" "$2"
		else
			convert "$1" "$2"
		fi
		;;

	uxf)
		umlet -action=convert -format=pdf "-filename=$1" "-output=$tmpFile"
		mv "${tmpFile}.pdf" "$2"
		;;

	dot)
		cmd=dot
		if [ ! -z "$3" ]; then
			cmd="$3"
		fi

		output=$(convertDotWithCmd "$cmd" 'ps:cairo' "$1")
		echo "$output"
		cairoerr=$(echo "$output" | grep 'Format: "ps:cairo" not recognized')
		if [ -n "$cairoerr" ]; then
			echo "using different dot driver" 1>&2
			convertDotWithCmd "$cmd" 'ps' "$1"
		fi

		"$0" "$tmpFilePs" "$2"
		;;

	csv)
		$(dirname "$0")/makelineplot.bash "$1" "$2"
		# $(dirname "$0")/makelineplot.bash "$1" "$tmpFileEps"
		# "$0" "$tmpFileEps" "$2"
		;;

	*)
		echo "Could not convert" 1>&2
		exit 1
		;;
esac
