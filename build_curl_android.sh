#!/bin/sh
#Note [TBD] : There is no check for ndk-version
#Please use the ndk-version as per host machine for now

#Get the machine type
PROCTYPE=`uname -m`

if [ "$PROCTYPE" = "i686" ] || [ "$PROCTYPE" = "i386" ] || [ "$PROCTYPE" = "i586" ] ; then
        echo "Host machine : x86"
        ARCHTYPE="x86"
else
        echo "Host machine : x86_64"
        ARCHTYPE="x86_64"
fi

#Get the Host OS
HOST_OS=`uname -s`
case "$HOST_OS" in
    Darwin)
        HOST_OS=darwin
        ;;
    Linux)
        HOST_OS=linux
        ;;
esac

#NDK-path
if [[ $1 == *ndk* ]]; then

	echo "----------------- NDK Path is : $1 ----------------"
	Input=$1;
else
	echo "Please enter your android ndk path:"
	echo "For example:/home/astro/android-ndk-r10c"
	read Input
	echo "You entered:$Input"
fi

#Set path
echo "----------------- Exporting the android-ndk path ----------------"
#export PATH=$PATH:$Input:$Input/toolchains/llvm-3.5/prebuilt/$HOST_OS-$ARCHTYPE/bin

#create install directories
mkdir -p ./../build
mkdir -p ./../build/android

#curl shared/static module build
echo "--------Building curl 7.38.0 shared lib for ANDROID platform -------"
pushd `pwd`
mkdir -p ./../build/android/curl

/usr/bin/curl -L -o ./../build/android/curl/curl-7.38.0.zip http://curl.haxx.se/download/curl-7.38.0.zip

rm -rf curl
unzip -a ./../build/android/curl/curl-7.38.0.zip -d ./../build/android/curl/


$Input/build/tools/make-standalone-toolchain.sh --ndk-dir=$Input --system=darwin-x86_64 --toolchain=arm-linux-androideabi-clang3.5 --llvm-version=3.5 --install-dir=/tmp/my-android-toolchain
popd


pushd ./../build/android/curl/curl-7.38.0
export PATH=/tmp/my-android-toolchain/bin:$PATH
./configure CC=clang CXX=clang++ --host=arm-linux-androideabi

make

echo "----- Installing curl lib-----"
cp -r ./lib/.libs/libcurl.a ./../
cp -r ./include  ./../
popd

pushd ./../build/android/curl
rm -rf curl-7.38.0
rm curl-7.38.0.zip
popd
rm -rf /tmp/my-android-toolchain

echo "--------curl 7.38.0 shared lib for ANDROID platform successfully built———"

