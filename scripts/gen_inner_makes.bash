#!/bin/bash

rootDirectories='../src'

for root in $rootDirectories; do
	for dir in `find "$root" -type d`; do
		depth=`echo -n "$dir" | grep -o '/' | tr -d '\n' | wc -m`

		toTopDir='../'
		for (( i = 0; i < depth - 1; i++ )); do
			toTopDir="${toTopDir}../"
		done

		cat << EOF > "${dir}/Makefile"
.PHONY: all clean run

all:
	make -C "$toTopDir" all

clean:
	make -C "$toTopDir" clean

run:
	make -C "$toTopDir" run
EOF

	done
done
