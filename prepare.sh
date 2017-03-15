#!/bin/bash

set -e

logLevel=2

#log levels
error=0
info=1
warning=2
debug=3
trace=4

isCurlReady=0
iOSCurlReleasePath=./curl/ios-appstore/lib
iOSCurlDebugPath=./curl/ios-dev/lib
macOSCurlReleasePath=./curl/osx/lib

print()
{
  logType=$1
  logMessage=$2

  if [ $logLevel -eq  $logType ] || [ $logLevel -gt  $logType ]
  then
  	if [ $logType -eq 0 ]
    then
      printf "\e[0;31m $logMessage \e[m\n"
    fi
    if [ $logType -eq 1 ]
    then
      printf "\e[0;32m $logMessage \e[m\n"
    fi
    if [ $logType -eq 2 ]
    then
      printf "\e[0;33m $logMessage \e[m\n"
    fi
    if [ $logType -gt 2 ]
    then
      echo $logMessage
    fi
  fi
}

error()
{
  criticalError=$1
  errorMessage=$2

  if [ $criticalError -eq 0 ]
  then
  	echo
  	print $warning "WARNING: $errorMessage"
  	echo
  else
  	echo
    print $error "CRITICAL ERROR: $errorMessage"
  	echo
  	echo
  	print $error "FAILURE:Preparing WebRtc environment has failed!"
  	echo
    popd > /dev/null
  	exit 1
  fi
}

checkCurl() 
{
	print $warning "Checking if curl is ready ..."

	if [ ! -f $iOSCurlReleasePath/libcurl.a ]; 
	then
		return
	fi

	if [ ! -f $iOSCurlDebugPath/libcurl.a ]; 
	then
		return
	fi

	if [ ! -f $macOSCurlReleasePath/libcurl.a ]; 
	then
		return
	fi

	isCurlReady=1
}

sdkpath() 
{
	platform=$1
	print $warning "Discovering ${platform} SDK ..."

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
        print $warning "Oopsie.  You don't have an SDK root in either of these locations: "
        print $warning "   ${root} "
        print $warning "   ${oldRoot}"
        echo " "
        print $warning "If you have 'locate' enabled, you might find where you have it installed with:"
        print $warning "   locate iPhoneOS.platform | grep -v 'iPhoneOS.platform/'"
        echo " "
        print $warning "and alter the 'root' variable in the script -- or install XCode if you can't find it... "
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
			    	print $debug "Found SDK in location ${root}/SDKs/${platform}${SDK}.sdk"
		        return
		      fi
	      done
	      #echo Checking "${root}/SDKs/${platform}${major}.${minor}.sdk"
	      if [ -d "${root}/SDKs/${platform}${major}.${minor}.sdk" ]
	      then
	      	SDK="${major}.${minor}"
		    	print $debug "Found SDK in location ${root}/SDKs/${platform}${SDK}.sdk"
	        return
	      fi
      done
      #echo Checking "${root}/SDKs/${platform}${major}.sdk"
      if [ -d "${root}/SDKs/${platform}${major}.sdk" ]
      then
      	SDK="${major}"
	    	print $debug "Found SDK in location ${root}/SDKs/${platform}${SDK}.sdk"
        return
      fi
    done

    if [ "${SDK}" == "unknown" ]
    then
        echo " "
        print $error "Unable to determine the SDK version to use."
        echo " "
        print $error "If you have 'locate' enabled, you might find where you have it installed with:"
        print $error "   locate iPhoneOS.platform | grep -v 'iPhoneOS.platform/'"
        echo " "
        print $error "and alter the SDKCheck variables in the script -- or install XCode if you can't find it... "
        echo " "
        exit 1
    fi
}

setPath()
{
	sdkpath $1
	if [ $1 == "iPhoneOS" ];
	then
	  IOSSDK="${SDK}"
	  print $debug "Discovered iPhoneOS  ${IOSSDK} SDK ..."
	else
	  MACSDK="${SDK}"
	  print $debug "Discovered MacOSX ${MACSDK} SDK ..."
	fi
}

buildCurl()
{
  print $warning "Building Curl ..."
  
  if [ $logLevel -gt $debug ];
  then
		./build_curl --sdk-version ${IOSSDK} --osx-sdk-version ${MACSDK}
	else
		./build_curl --sdk-version ${IOSSDK} --osx-sdk-version ${MACSDK} > /dev/null
	fi
	
	if [ $? -ne 0 ]; 
	then
    error 1 "Failed building Curl"
  fi
      
	mkdir -p curl/curl
	cp -f curl.h.template curl/curl/curl.h
}

finished()
{
  echo
  print $info "Success: Curl is ready."
  	
}

#;logLevel;
while getopts ":p:l:" opt; do
  case $opt in
    l)
        logLevel=$OPTARG
        ;;
    esac
done

echo
print $info "Running Curl prepare script ..."

#Main flow
checkCurl

if [ $isCurlReady -eq 0 ]; 
then
	setPath iPhoneOS
	setPath MacOSX
	buildCurl

	#echo ./build_curl --sdk-version ${IOSSDK} --osx-sdk-version ${MACSDK}
	#./build_curl --sdk-version ${IOSSDK} --osx-sdk-version ${MACSDK}

	#mkdir -p curl/curl
	#cp -f curl.h.template curl/curl/curl.h
fi

finished	
