#!/bin/bash -e
CURDIR="$(pwd)"

source "${CURDIR}/common/functions.sh"
source "${CURDIR}/common/vars.sh"

case $1 in
	standard)
		;;
	llvm)
		;;
	*)
		_err "Invalid build type: $1"
		_err
		_err "Available build types:"
		_err "  standard"
		_err "  llvm"
		exit 1
		;;
esac

case $2 in
	x86_64)
		;;
	aarch64)
		;;
	*)
		_err "$2 is not supported to build the image for Icepearl"
		exit 1
		;;
esac

rm -rf icepearl
for stage in {1..5}
do
	_msg "Entering stage ${stage[@]}"
	sleep 3
	"stages/$1/${stage[@]}.sh"
	_msg "Leaving stage ${stage[@]}"
	sleep 3
done
