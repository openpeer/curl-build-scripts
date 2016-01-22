@echo off
echo.
echo Preparing curl...
echo.
echo Thanks to https://github.com/blackrosezy/build-libcurl-windows for instructions
echo.

set FAILURE=0

set BUILD_X86=1
set BUILD_X64=1

set BASEPATH=%CD%
set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe

call:download7a
if "%FAILURE%" NEQ "0" goto:eof

rem where powershell > NUL 2>&1
rem if ERRORLEVEL 1 call:failure %errorlevel% "Could not local powershell for windows"
rem if "%FAILURE%" NEQ "0" goto:eof

echo Verifying download from https://github.com/peters/curl-for-windows ...

call:download http://curl.haxx.se/download/curl-7.41.0.zip curl-7.41.0.zip
if "%FAILURE%" NEQ "0" goto:eof

call:extract curl-7.41.0.zip download
if "%FAILURE%" NEQ "0" goto:eof

call:dolink . include download\curl-7.41.0\include
if "%failure%" neq "0" goto:eof

if EXIST current\nul rmdir current
if ERRORLEVEL 1 call:failure %errorlevel% "Could not remove previous curl symbolic link"
if "%FAILURE%" NEQ "0" goto:eof

call:dolink . current download\curl-7.41.0
if "%failure%" neq "0" goto:eof


call:dobuild
if "%failure%" neq "0" goto:eof

if %BUILD_X86% == 0 goto:skiplinkx86

call:dolink . x86-release-dll current\builds\libcurl-vc-x86-release-dll-ipv6-sspi-winssl
if "%failure%" neq "0" goto:eof

call:dolink . x86-debug-dll current\builds\libcurl-vc-x86-debug-dll-ipv6-sspi-winssl
if "%failure%" neq "0" goto:eof

call:dolink . x86-release-static current\builds\libcurl-vc-x86-release-static-ipv6-sspi-winssl
if "%failure%" neq "0" goto:eof

call:dolink . x86-debug-static current\builds\libcurl-vc-x86-debug-static-ipv6-sspi-winssl
if "%failure%" neq "0" goto:eof

call:copyfile x86-debug-dll\lib\libcurl_debug.exp x86-debug-dll\lib\libcurl.exp Y
if "%failure%" neq "0" goto:eof
call:copyfile x86-debug-dll\lib\libcurl_debug.lib x86-debug-dll\lib\libcurl.lib Y
if "%failure%" neq "0" goto:eof
call:copyfile x86-debug-dll\lib\libcurl_debug.pdb x86-debug-dll\lib\libcurl.pdb Y
if "%failure%" neq "0" goto:eof

call:copyfile x86-release-static\lib\libcurl_a.lib x86-release-static\lib\libcurl.lib Y
if "%failure%" neq "0" goto:eof
call:copyfile x86-debug-static\lib\libcurl_a_debug.lib x86-debug-static\lib\libcurl.lib Y
if "%failure%" neq "0" goto:eof

:skiplinkx86

if %BUILD_X64% == 0 goto:skiplinkx64

call:dolink . x64-release-dll current\builds\libcurl-vc-x64-release-dll-ipv6-sspi-winssl
if "%failure%" neq "0" goto:eof

call:dolink . x64-debug-dll current\builds\libcurl-vc-x64-debug-dll-ipv6-sspi-winssl
if "%failure%" neq "0" goto:eof

call:dolink . x64-release-static current\builds\libcurl-vc-x64-release-static-ipv6-sspi-winssl
if "%failure%" neq "0" goto:eof

call:dolink . x64-debug-static current\builds\libcurl-vc-x64-debug-static-ipv6-sspi-winssl
if "%failure%" neq "0" goto:eof

call:copyfile x64-debug-dll\lib\libcurl_debug.exp x64-debug-dll\lib\libcurl.exp Y
if "%failure%" neq "0" goto:eof
call:copyfile x64-debug-dll\lib\libcurl_debug.lib x64-debug-dll\lib\libcurl.lib Y
if "%failure%" neq "0" goto:eof
call:copyfile x64-debug-dll\lib\libcurl_debug.pdb x64-debug-dll\lib\libcurl.pdb Y
if "%failure%" neq "0" goto:eof

call:copyfile x64-release-static\lib\libcurl_a.lib x64-release-static\lib\libcurl.lib Y
if "%failure%" neq "0" goto:eof
call:copyfile x64-debug-static\lib\libcurl_a_debug.lib x64-debug-static\lib\libcurl.lib Y
if "%failure%" neq "0" goto:eof


:skiplinkx64


if EXIST include\curl\curlbuild.h goto:skipcopybuild

if NOT EXIST include\curl\curlbuild.h.dist call:failure 1 "Could not find curl build distribution header !"
if "%failure%" neq "0" goto:eof

call:copyfile include\curl\curlbuild.h.dist include\curl\curlbuild.h
if "%failure%" neq "0" goto:eof

:skipcopybuild


goto:done

:copyfile
if "%~3" == "Y" goto:copyfilereplace
goto copyfilenoreplace

:copyfilereplace
if EXIST %~2 del %~2

:copyfilenoreplace
if EXIST %~2 goto:eof
echo.
echo Copying file from %~1 to %~2 ...
echo.
copy %~1 %~2 > NUL 2>&1
if ERRORLEVEL 1 call:failure %errorlevel% "Could not copy file %~1 to %~2"
if "%FAILURE%" NEQ "0" goto:eof
goto:eof

:download
if EXIST %~2 goto:eof

%powershell_path% "Start-BitsTransfer %~1 -Destination %~2"
if ERRORLEVEL 1 call:failure %errorlevel% "Could not download %~2"
if "%FAILURE%" NEQ "0" goto:eof
echo.
echo Downloaded %~1
echo.
goto:eof

:extract
echo.
echo Extracting 7z %~1 into %~2 ...
echo.

rem python -c "import zipfile,os.path;zipfile.ZipFile('%Z~1').extractall('%~2');"

%BASEPATH%\7za\7za x -aos -o%~2 %~1
if ERRORLEVEL 1 call:failure %errorlevel% "Could not extract %~1 into %~2"
if "%FAILURE%" NEQ "0" goto:eof

goto:eof

:download7a

if EXIST %BASEPATH%\7za\7za.exe goto:eof

call:download http://7-zip.org/a/7za920.zip 7za920.zip
if "%FAILURE%" NEQ "0" goto:eof

if NOT EXIST %BASEPATH%\zipjs.bat call:failure 1 "Could not find unzip script"
if "%FAILURE%" NEQ "0" goto:eof

echo %BASEPATH%\zipjs.bat unzip -source 7za920.zip -destination 7za
call %BASEPATH%\zipjs.bat unzip -source 7za920.zip -destination 7za
if ERRORLEVEL 1 call:failure %errorlevel% "Could not extract 7za.exe"

goto:eof

:dolink
if NOT EXIST %~1\nul call:failure 1 "%~1 does not exist!"
if "%failure%" neq "0" goto:eof

pushd %~1 > NUL

IF EXIST .\%~2\nul goto:alreadyexists

IF NOT EXIST %~3\nul call:failure 1 "%~3 does not exist!"
if "%failure%" neq "0" popd
if "%failure%" neq "0" goto:eof

echo In path "%~1" creating symbolic link for "%~2" to "%~3"
mklink /J %~2 %~3
if ERRORLEVEL 1 call:failure %errorlevel% "Could not create symbolic link to %~2 from %~3"
popd > NUL
if "%failure%" neq "0" goto:eof

goto:eof

:alreadyexists
popd
goto:eof


:dobuild
setlocal EnableDelayedExpansion

set PROGFILES=%ProgramFiles%
if not "%ProgramFiles(x86)%" == "" set PROGFILES=%ProgramFiles(x86)%

REM Check if Visual Studio 2015 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 14.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2014"
	goto setup_env
)

REM Check if Visual Studio 2013 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 12.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2013"
	goto setup_env
)

REM Check if Visual Studio 2012 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 11.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2012"
	goto setup_env
)

REM Check if Visual Studio 2010 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 10.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2010"
	goto setup_env
)

REM Check if Visual Studio 2008 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 9.0"
if exist %MSVCDIR% (
    set COMPILER_VER="2008"
	goto setup_env
)

REM Check if Visual Studio 2005 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio 8"
if exist %MSVCDIR% (
	set COMPILER_VER="2005"
	goto setup_env
) 

REM Check if Visual Studio 6 is installed
set MSVCDIR="%PROGFILES%\Microsoft Visual Studio\VC98"
if exist %MSVCDIR% (
	set COMPILER_VER="6"
	goto setup_env
) 

call:failure 1 "No compiler : Microsoft Visual Studio (6, 2005, 2008, 2010, 2012, 2013 or 2015) is not installed.""
goto:eof

:setup_env

echo Setting up environment ...

if %COMPILER_VER% == "6" (
	call %MSVCDIR%\Bin\VCVARS32.BAT
	goto begin
)

:begin
set ROOT_DIR="%CD%"

if %COMPILER_VER% == "6" (
	set VCVERSION = 6
	goto buildnow
)

if %COMPILER_VER% == "2005" (
	set VCVERSION = 8
	goto buildnow
)

if %COMPILER_VER% == "2008" (
	set VCVERSION = 9
	goto buildnow
)

if %COMPILER_VER% == "2010" (
	set VCVERSION = 10
	goto buildnow
)

if %COMPILER_VER% == "2012" (
	set VCVERSION = 11
	goto buildnow
)

if %COMPILER_VER% == "2013" (
	set VCVERSION = 12
	goto buildnow
)

if %COMPILER_VER% == "2015" (
	set VCVERSION = 14
	goto buildnow
)

:buildnow

pushd current\winbuild > NUL
if ERRORLEVEL 1 call:failure %errorlevel% "Could not find current curl"
if "%failure%" neq "0" goto:eof

rem msbuild vc6libcurl.vcxproj /p:Configuration="DLL Debug" /t:Rebuild
rem msbuild vc6libcurl.vcxproj /p:Configuration="DLL Release" /t:Rebuild
rem msbuild vc6libcurl.vcxproj /p:Configuration="LIB Debug" /t:Rebuild
rem msbuild vc6libcurl.vcxproj /p:Configuration="LIB Release" /t:Rebuild

if %BUILD_X86% == 0 goto:skipx86

echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo Building x86 ...
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------

call %MSVCDIR%\VC\vcvarsall.bat x86
if ERRORLEVEL 1 call:failure %errorlevel% "Could not setup x86 compiler"
if "%failure%" neq "0" goto:post_build


nmake /f Makefile.vc mode=dll VC=%VCVERSION% DEBUG=yes
if ERRORLEVEL 1 call:failure %errorlevel% "Curl x86 debug DLL build failed"
if "%failure%" neq "0" goto:post_build

nmake /f Makefile.vc mode=dll VC=%VCVERSION% DEBUG=no GEN_PDB=yes
if ERRORLEVEL 1 call:failure %errorlevel% "Curl x86 release DLL build failed"
if "%failure%" neq "0" goto:post_build

nmake /f Makefile.vc mode=static VC=%VCVERSION% DEBUG=yes
if ERRORLEVEL 1 call:failure %errorlevel% "Curl x86 debug static lib build failed"
if "%failure%" neq "0" goto:post_build

nmake /f Makefile.vc mode=static VC=%VCVERSION% DEBUG=no
if ERRORLEVEL 1 call:failure %errorlevel% "Curl x86 release static lib build failed"
if "%failure%" neq "0" goto:post_build

:skipx86

if %BUILD_X64% == 0 goto:skipx64

echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo Building x64
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------
echo -------------------------------------------------------------------------

call %MSVCDIR%\VC\vcvarsall.bat x64
if ERRORLEVEL 1 call:failure %errorlevel% "Could not setup x64 compiler"
if "%failure%" neq "0" goto:post_build

nmake /f Makefile.vc mode=dll VC=%VCVERSION% DEBUG=yes MACHINE=x64
if ERRORLEVEL 1 call:failure %errorlevel% "Curl x64 debug DLL build failed"
if "%failure%" neq "0" goto:post_build

nmake /f Makefile.vc mode=dll VC=%VCVERSION% DEBUG=no GEN_PDB=yes MACHINE=x64
if ERRORLEVEL 1 call:failure %errorlevel% "Curl x64 release DLL build failed"
if "%failure%" neq "0" goto:post_build

nmake /f Makefile.vc mode=static VC=%VCVERSION% DEBUG=yes MACHINE=x64
if ERRORLEVEL 1 call:failure %errorlevel% "Curl x64 debug static lib build failed"
if "%failure%" neq "0" goto:post_build

nmake /f Makefile.vc mode=static VC=%VCVERSION% DEBUG=no MACHINE=x64
if ERRORLEVEL 1 call:failure %errorlevel% "Curl x64 release static lib build failed"
if "%failure%" neq "0" goto:post_build

:skipx64

:post_build

popd > NUL

goto:eof


:failure
set FAILURE=%~1
echo.
echo ERROR: %~2
echo.
echo. Failed to prepare curl...
echo.
goto:eof

:done
echo.
echo Curl is now ready...
echo.
