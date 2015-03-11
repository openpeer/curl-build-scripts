@echo off
echo.
echo Preparing curl...

set FAILURE=0

where 7za > NUL 2>&1
if ERRORLEVEL 1 call:failure %errorlevel% "Could not 7za (see 7-zip.org and download command line version)"
if "%FAILURE%" NEQ "0" goto:eof

where powershell > NUL 2>&1
if ERRORLEVEL 1 call:failure %errorlevel% "Could not local powershell for windows"
if "%FAILURE%" NEQ "0" goto:eof

echo Verifying download from https://github.com/peters/curl-for-windows ...

call:download http://iweb.dl.sourceforge.net/project/curlforwindows/curl-7.40.0-openssl-libssh2-zlib-x86.7z curl-7.40.0-openssl-libssh2-zlib-x86.7z
if "%FAILURE%" NEQ "0" goto:eof
call:download http://iweb.dl.sourceforge.net/project/curlforwindows/curl-7.40.0-openssl-libssh2-zlib-x64.7z curl-7.40.0-openssl-libssh2-zlib-x64.7z
if "%FAILURE%" NEQ "0" goto:eof

call:download https://github.com/bagder/curl/archive/curl-7_40_0.zip curl-7_40_0.zip
if "%FAILURE%" NEQ "0" goto:eof

call:extract curl-7.40.0-openssl-libssh2-zlib-x86.7z 7.40.0\x86
if "%FAILURE%" NEQ "0" goto:eof
call:extract curl-7.40.0-openssl-libssh2-zlib-x64.7z 7.40.0\x64
if "%FAILURE%" NEQ "0" goto:eof

call:extract curl-7_40_0.zip 7.40.0
if "%FAILURE%" NEQ "0" goto:eof

call:dolink . include 7.40.0\curl-curl-7_40_0\include
if "%failure%" neq "0" goto:done_with_error

call:dolink . x86 7.40.0\x86
if "%failure%" neq "0" goto:done_with_error

call:dolink . x64 7.40.0\x64
if "%failure%" neq "0" goto:done_with_error

if NOT EXIST include\curl\curlbuild.h.dist call:failure 1 "Could not find curl build distribution header !"
if "%failure%" neq "0" goto:done_with_error

call:copyfile include\curl\curlbuild.h.dist include\curl\curlbuild.h
if "%failure%" neq "0" goto:done_with_error

goto:done

:copyfile
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

powershell.exe "Start-BitsTransfer %~1 -Destination %~2"
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

7za x -aos -o%~2 %~1
if ERRORLEVEL 1 call:failure %errorlevel% "Could not extract %~1 into %~2"
if "%FAILURE%" NEQ "0" goto:eof

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
