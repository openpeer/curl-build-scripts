#!/bin/bash

set -e

echo
echo Preparing curl...
echo

sdkpath() {
	platform=$1
	echo Discovering ${platform} SDK...

	major_start=13
	major_stop=4

	minor_start=15
	minor_stop=0

	subminor_start=5
	subminor_stop=0

    root="/Applications/Xcode.app/Contents/Developer/Platforms/${platform}.platform/Developer"
    oldRoot="/Developer/Platforms/${platform}.platform/Developer"

    if [ ! -d "${root}" ]
    then
        root="${oldRoot}"
    fi

    if [ ! -d "${root}" ]
    then
        echo " "
        echo "Oopsie.  You don't have an SDK root in either of these locations: "
        echo "   ${root} "
        echo "   ${oldRoot}"
        echo " "
        echo "If you have 'locate' enabled, you might find where you have it installed with:"
        echo "   locate iPhoneOS.platform | grep -v 'iPhoneOS.platform/'"
        echo " "
        echo "and alter the 'root' variable in the script -- or install XCode if you can't find it... "
        echo " "
        exit 1
    fi

    SDK="unknown"

    for major in `seq ${major_start} ${major_stop}`
    do
      for minor in `seq ${minor_start} ${minor_stop}`
      do
	      for subminor in `seq ${subminor_start} ${subminor_stop}`
	      do
		      #echo Checking "${root}/SDKs/${platform}${major}.${minor}.${subminor}.sdk"
		      if [ -d "${root}/SDKs/${platform}${major}.${minor}.${subminor}.sdk" ]
		      then
		      	SDK="${major}.${minor}.${subminor}"
			    echo Found SDK in location "${root}/SDKs/${platform}${SDK}.sdk"
		        return
		      fi
	      done
	      #echo Checking "${root}/SDKs/${platform}${major}.${minor}.sdk"
	      if [ -d "${root}/SDKs/${platform}${major}.${minor}.sdk" ]
	      then
	      	SDK="${major}.${minor}"
		    echo Found SDK in location "${root}/SDKs/${platform}${SDK}.sdk"
	        return
	      fi
      done
      #echo Checking "${root}/SDKs/${platform}${major}.sdk"
      if [ -d "${root}/SDKs/${platform}${major}.sdk" ]
      then
      	SDK="${major}"
	    echo Found SDK in location "${root}/SDKs/${platform}${SDK}.sdk"
        return
      fi
    done

    if [ "${SDK}" == "unknown" ]
    then
        echo " "
        echo "Unable to determine the SDK version to use."
        echo " "
        echo "If you have 'locate' enabled, you might find where you have it installed with:"
        echo "   locate iPhoneOS.platform | grep -v 'iPhoneOS.platform/'"
        echo " "
        echo "and alter the SDKCheck variables in the script -- or install XCode if you can't find it... "
        echo " "
        exit 1
    fi
}

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

sdkpath iPhoneOS
IOSSDK="${SDK}"
echo Discovered iPhoneOS  ${IOSSDK} SDK ...
echo
sdkpath MacOSX
MACSDK="${SDK}"
echo Discovered MacOSX ${MACSDK} SDK ...
echo

echo ./build_curl --sdk-version ${IOSSDK} --osx-sdk-version ${MACSDK}
./build_curl --sdk-version ${IOSSDK} --osx-sdk-version ${MACSDK}

mkdir -p curl/curl
cp -f curl.h.template curl/curl/curl.h

echo
echo Curl ready.
echo
