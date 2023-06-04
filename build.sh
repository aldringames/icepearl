#!/bin/bash -e
CURDIR="$(pwd)"
source "${CURDIR}/common/functions.sh"
source "${CURDIR}/common/vars.sh"

rm -rf icepearl
for stage in {1..5}
do
	_msg "Entering stage ${stage[@]}"
	sleep 3
	"stages/${stage[@]}.sh"
	_msg "Leaving stage ${stage[@]}"
	sleep 3
done
