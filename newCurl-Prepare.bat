:: Name:     newCurl-Prepare.bat
:: Purpose:  Download and build curl
:: Author:   Sergej Jovanovic
:: Email:	 sergej@gnedo.com
:: Revision: September 2016 - initial version

@ECHO off

SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

::paths
set powershell_path=%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe
set basepath="%CD%"

::URLs
SET downloadURL_7Zip=http://7-zip.org/a/7za920.zip
SET zipFileName=7za920.zip
SET downloadCurlBaseURL=https://curl.haxx.se/download/
SET curlFileName=curl-7.50.3
SET curlFileExtension=.zip
SET curlFullFileName=%curlFileName%%curlFileExtension%
SET downloadCurlURL=%downloadCurlBaseURL%%curlFileName%%curlFileExtension%

SET taskFailed=0
SET isCurlReady=0

::input arguments
SET supportedInputArguments=;logLevel;					
SET platform=all
SET help=0
SET logLevel=2
SET diagnostic=0

::log variables
SET globalLogLevel=2											

SET error=0														
SET info=1														
SET warning=2													
SET debug=3														
SET trace=4	

::build variables
set msVS_Path=""
set msVS_Version=""
set x86BuildCompilerOption=amd64_x86
set x64BuildCompilerOption=amd64
set armBuildCompilerOption=amd64_arm
set currentBuildCompilerOption=amd64

ECHO.
CALL:print %info% "Running Curl prepare script ..."
CALL:print %info% "================================="
::ECHO.

:parseInputArguments
IF "%1"=="" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
		SET nome=""
		
	) ELSE (
		GOTO:main
	)
)
SET aux=%1
IF "%aux:~0,1%"=="-" (
	IF NOT "%nome%"=="" (
		SET "%nome%=1"
	)
   SET nome=%aux:~1,250%
   SET validArgument=0
   CALL:checkIfArgumentIsValid !nome! validArgument
   IF !validArgument!==0 CALL:error 1 %errorMessageInvalidArgument%
) ELSE (
	IF NOT "%nome%"=="" (
		SET "%nome%=%1"
	) else (
		CALL:error 1 %errorMessageInvalidArgument%
	)
   SET nome=
)

SHIFT
GOTO parseInputArguments

::===========================================================================
:: Start execution of main flow (if parsing input parameters passed without issues)

:main
CALL:checkCurl
IF %isCurlReady% EQU 1 GOTO:done

CALL:download7a
CALL:downloadCurl
CALL:prepareCurl
CALL:cleanup
CALL:done
GOTO:EOF

REM check if entered valid input argument
:checkIfArgumentIsValid
IF "!supportedInputArguments:;%~1;=!" neq "%supportedInputArguments%" (
	::it is valid
	SET %2=1
) ELSE (
	::it is not valid
	SET %2=0
)
GOTO:EOF

:download7a

IF EXIST %BASEPATH%\7za\7za.exe GOTO:EOF
CALL:print %debug% "Downloading 7-zip"

CALL:download %downloadURL_7Zip% %zipFileName%
IF !taskFailed!==1 CALL:error 1 "Failed downloading 7-zip."

if NOT EXIST %BASEPATH%\zipjs.bat CALL:error 1 "Could not find unzip script"

::echo %BASEPATH%\zipjs.bat unzip -source 7za920.zip -destination 7za
CALL:print %trace% "Running %BASEPATH%\zipjs.bat unzip -source %zipFileName% -destination 7za"

CALL:print %debug% "Extracting 7-zip"
CALL %BASEPATH%\zipjs.bat unzip -source %zipFileName% -destination 7za
if !ERRORLEVEL! EQU 1 CALL:error 1 "Could not extract 7za.exe"

GOTO:EOF

:downloadCurl

CALL:download %downloadCurlURL% %curlFullFileName%
IF !taskFailed!==1 CALL:error 1 "Failed downloading curl"

GOTO:EOF

:prepareCurl

:: Extract curl to download folder
CALL:extract  %curlFullFileName% download
IF !taskFailed!==1 CALL:error 1 "Could not extract %~1 into %~2"

:: Create junction for include folder
CALL:makeLink . include download\%curlFileName%\include

IF EXIST current\NUL RMDIR current
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Unable to delete current folder"

CALL:makeLink . current download\%curlFileName%

CALL:determineVisualStudioPath

CALL:build x86
CALL:makeLibLinks x86

CALL:build x64
CALL:makeLibLinks x64

GOTO:EOF

:cleanup

IF EXIST %curlFullFileName% DEL %curlFullFileName%
IF !ERRORLEVEL! EQU 1 CALL:error 0 "Unable to delete %curlFullFileName%"
IF EXIST %zipFileName% DEL %zipFileName%
IF !ERRORLEVEL! EQU 1 CALL:error 0 "Unable to delete %zipFileName%"

CALL:deleteCurlObjectFiles x86
CALL:deleteCurlObjectFiles x64
GOTO:EOF

:deleteCurlObjectFiles
SET prefix=%~1
CALL:deleteFolder current\builds\libcurl-vc14-%prefix%-release-dll-ipv6-sspi-winssl-obj-lib 
CALL:deleteFolder current\builds\libcurl-vc14-%prefix%-release-dll-ipv6-sspi-winssl-obj-curl 
CALL:deleteFolder current\builds\libcurl-vc14-%prefix%-release-static-ipv6-sspi-winssl-obj-lib
CALL:deleteFolder current\builds\libcurl-vc14-%prefix%-release-static-ipv6-sspi-winssl-obj-curl
CALL:deleteFolder current\builds\libcurl-vc14-%prefix%-debug-dll-ipv6-sspi-winssl-obj-lib
CALL:deleteFolder current\builds\libcurl-vc14-%prefix%-debug-dll-ipv6-sspi-winssl-obj-curl
CALL:deleteFolder current\builds\libcurl-vc14-%prefix%-debug-static-ipv6-sspi-winssl-obj-lib
CALL:deleteFolder current\builds\libcurl-vc14-%prefix%-debug-static-ipv6-sspi-winssl-obj-curl
GOTO:EOF

:deleteFolder
IF EXIST %~1\NUL RMDIR /S /Q %~1
IF !ERRORLEVEL! EQU 1 CALL:error 0 "Unable to delete %~1"
GOTO:EOF

:build
CALL:print %warning% "Building curl for %~1"

PUSHD current\winbuild > NUL

CALL:setCompilerOption %~1
CALL:print %debug% "Building with compiler option %currentBuildCompilerOption%"

CALL %msVS_Path%\VC\vcvarsall.bat %currentBuildCompilerOption%
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Could not setup %~1 compiler"


IF %logLevel% GEQ %trace% (
	nmake /f Makefile.vc mode=dll VC=%msVS_Version% DEBUG=yes MACHINE=%~1
) ELSE (
	nmake /f Makefile.vc mode=dll VC=%msVS_Version% DEBUG=yes MACHINE=%~1 >NUL
)
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Curl %~1 debug DLL build failed"

IF %logLevel% GEQ %trace% (
	nmake /f Makefile.vc mode=dll VC=%msVS_Version% DEBUG=no GEN_PDB=yes MACHINE=%~1
) ELSE (
	nmake /f Makefile.vc mode=dll VC=%msVS_Version% DEBUG=no GEN_PDB=yes MACHINE=%~1 >NUL
)
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Curl %~1 release DLL build failed"

IF %logLevel% GEQ %trace% (
	nmake /f Makefile.vc mode=static VC=%msVS_Version% DEBUG=yes MACHINE=%~1
) ELSE (
	nmake /f Makefile.vc mode=static VC=%msVS_Version% DEBUG=yes MACHINE=%~1 >NUL
)
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Curl %~1 debug static lib build failed"

IF %logLevel% GEQ %trace% (
	nmake /f Makefile.vc mode=static VC=%msVS_Version% DEBUG=no MACHINE=%~1
) ELSE (
	nmake /f Makefile.vc mode=static VC=%msVS_Version% DEBUG=no MACHINE=%~1 >NUL
)
IF !ERRORLEVEL! EQU 1 CALL:error 1 "Curl %~1 release static lib build failed"

POPD > NUL
GOTO:EOF

:makeLibLinks
SET prefix=%~1
CALL:makeLink . %prefix%-release-dll current\builds\libcurl-vc14-%prefix%-release-dll-ipv6-sspi-winssl
CALL:makeLink . %prefix%-debug-dll current\builds\libcurl-vc14-%prefix%-debug-dll-ipv6-sspi-winssl
CALL:makeLink . %prefix%-release-static current\builds\libcurl-vc14-%prefix%-release-static-ipv6-sspi-winssl
CALL:makeLink . %prefix%-debug-static current\builds\libcurl-vc14-%prefix%-debug-static-ipv6-sspi-winssl

CALL:rename %prefix%-debug-dll\lib\libcurl_debug.exp %prefix%-debug-dll\lib\libcurl.exp
CALL:rename %prefix%-debug-dll\lib\libcurl_debug.lib %prefix%-debug-dll\lib\libcurl.lib Y
CALL:rename %prefix%-debug-dll\lib\libcurl_debug.pdb %prefix%-debug-dll\lib\libcurl.pdb Y
CALL:rename %prefix%-release-static\lib\libcurl_a.lib %prefix%-release-static\lib\libcurl.lib Y
CALL:rename %prefix%-debug-static\lib\libcurl_a_debug.lib %prefix%-debug-static\lib\libcurl.lib Y

GOTO:EOF

:setCompilerOption

REG Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && SET CPU=x86 || SET CPU=x64

echo CPU arhitecture is %CPU%

if %CPU% == x86 (
	set x86BuildCompilerOption=x86
	set x64BuildCompilerOption=x86_amd64
	set armBuildCompilerOption=x86_arm
)

if %~1%==x86 (
	set currentBuildCompilerOption=%x86BuildCompilerOption%
) else (
	if %~1%==ARM (
		set currentBuildCompilerOption=%armBuildCompilerOption%
	) else (
		set currentBuildCompilerOption=%x64BuildCompilerOption%
	)
)

echo Selected compiler option is %currentBuildCompilerOption%

GOTO:EOF

:determineVisualStudioPath
SET progfiles=%ProgramFiles%
IF NOT "%ProgramFiles(x86)%" == "" SET progfiles=%ProgramFiles(x86)%

REM Check if Visual Studio 2015 is installed
SET msVS_Path="%progfiles%\Microsoft Visual Studio 14.0"
SET msVS_Version=14

IF NOT EXIST %msVS_Path% (
	REM Check if Visual Studio 2013 is installed
	SET msVS_Path="%progfiles%\Microsoft Visual Studio 12.0"
	SET msVS_Version=12
)

IF NOT EXIST %msVS_Path% CALL:error 1 "Visual Studio 2015 or 2013 is not installed"

CALL:print %debug% "Visual Studio path is %MSVCDIR%"

goto:eof

REM Download file (first argument) to desired destination (second argument)
:download
IF EXIST %~2 GOTO:EOF
CALL:print %debug% "Downloading %~1 t0 %~2"
%powershell_path% "Start-BitsTransfer %~1 -Destination %~2"
IF !ERRORLEVEL! EQU 1 SET taskFailed=1

GOTO:EOF

:extract
CALL:print %trace% "Extracting 7z %~1 into %~2 ..."


%BASEPATH%\7za\7za x -aos -o%~2 %~1
IF !ERRORLEVEL! EQU 1 SET taskFailed=1
if ERRORLEVEL 1 call:failure %errorlevel% "Could not extract %~1 into %~2"


GOTO:EOF

:makeLink
IF NOT EXIST %~1\NUL CALL:error 1 "%folderStructureError:"=% %~1 does not exist!"

PUSHD %~1
IF EXIST .\%~2\NUL GOTO:alreadyexists
IF NOT EXIST %~3\NUL CALL:error 1 "%folderStructureError:"=% %~3 does not exist!"

CALL:print %trace% In path "%~1" creating symbolic link for "%~2" to "%~3"

MKLINK /J %~2 %~3
IF %ERRORLEVEL% NEQ 0 CALL:ERROR 1 "COULD NOT CREATE SYMBOLIC LINK TO %~2 FROM %~3"

:alreadyexists
POPD

GOTO:EOF

:rename
CALL:print %trace% "Renaming %1 to %~2"
IF NOT EXIST %~1 CALL:error 1 "Curl folder structure is corrupted"
MOVE /Y %~1 %~2
IF !ERRORLEVEL! NEQ 0 CALL:error 1 "Could not rename file from %~1 to %~2"
GOTO:EOF

:checkCurl

CALL:checkIsCurlReady x86
IF !isCurlReady! EQU 1 CALL:checkIsCurlReady x64

GOTO:EOF

:checkIsCurlReady
SET prefix=%~1
SET isCurlReady=0
IF NOT EXIST  %prefix%-debug-dll\lib\libcurl.lib GOTO:EOF
IF NOT EXIST  %prefix%-release-dll\lib\libcurl.lib GOTO:EOF
IF NOT EXIST  %prefix%-release-static\lib\libcurl.lib GOTO:EOF
IF NOT EXIST  %prefix%-debug-static\lib\libcurl.lib GOTO:EOF

CALL:print %debug% "Curl is ready for %prefix%"
SET isCurlReady=1
GOTO:EOF

REM Print logger message. First argument is log level, and second one is the message
:print
SET logType=%1
SET logMessage=%~2

if %logLevel% GEQ  %logType% (
	if %logType%==0 ECHO [91m%logMessage%[0m
	if %logType%==1 ECHO [92m%logMessage%[0m
	if %logType%==2 ECHO [93m%logMessage%[0m
	if %logType%==3 ECHO %logMessage%
	if %logType%==4 ECHO %logMessage%
)

GOTO:EOF

REM Print the error message and terminate further execution if error is critical.Firt argument is critical error flag (1 for critical). Second is error message
:error
SET criticalError=%~1
SET errorMessage=%~2

IF %criticalError%==0 (
	ECHO.
	CALL:print %warning% "WARNING: %errorMessage%"
	ECHO.
) ELSE (
	ECHO.
	CALL:print %error% "CRITICAL ERROR: %errorMessage%"
	ECHO.
	ECHO.
	CALL:print %error% "FAILURE:Preparing curl has failed!"
	ECHO.
	::terminate batch execution
	CALL ..\..\..\bin\batchTerminator.bat
)
GOTO:EOF

:done
CALL:print %info% "Curl is ready"
exit /b 0