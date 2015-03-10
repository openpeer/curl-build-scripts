#!/bin/bash

set -e

echo
echo Preparing curl...
echo

preparelink()
{
	if [ ! -d "$1" ]; then
		echo ERROR: Path to link does not exist \"$1\" !
	fi
	pushd $1 > /dev/null
	if [ ! -d "$3" ]; then
		echo ERROR: Link destination is not found \"$3\" inside \"$1\" !
		popd > /dev/null
		exit -1
	fi
	if [ ! -h "$2" ]; then
		echo
		echo In path \"$1\" creating symbolic link \"$2\" pointing to \"$3\"...
		echo
		ln -s $3 $2
		if [ $? -ne 0 ]; then
			failure=$?
			echo Faield to create symbolic link
			popd > /dev/null
			exit $failure
		fi
	fi
	popd > /dev/null
}

./build_curl

mkdir -p curl/curl
cp -f curl.h.template curl/curl/curl.h

echo
echo Curl ready.
echo
