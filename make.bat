@echo off

echo ==============================
echo Set main paths
:: Retrieve folder of the batch file, regardless of launch directory.
SET CCROOT=%~dp0
:: Currently, this batch file is set up to expect all tool and compiler
:: folders one folder down from where thia code folder is located.
SET ROOT=%~dp0..\
:: Simplified path for the build; doesn't seem like Watcom needs anything more.
SET PATH=C:\Windows\;C:\Windows\System32

echo ==============================
echo Set compilers and utilities
:: Watcom 10.6
SET WATCOM=%ROOT%WATCOM
:: TASM 4.0
SET TASM=%ROOT%TASM
:: MASM 6.11
SET MASM=%ROOT%MASM611\BIN
:: MS-DOS Player for Win32-x64 console
SET DOSEMU=%ROOT%msdos
:: DirectX 5 SDK
SET DXSDK=%ROOT%DXSDK

echo ==============================
echo Define Westwood libraries
SET WIN32LIB=%CCROOT%WIN32LIB
SET WIN32VCS=%CCROOT%WIN32LIB
SET WWFLAT=%CCROOT%WIN32LIB
SET VQDIR=%CCROOT%WINVQ
SET CODEDIR=%CCROOT%CODE
SET CDDIR=%CCROOT%

echo ==============================
echo Set 3rd party libraries
SET PATH=%WATCOM%\BINNT;%WATCOM%\BIN;%WATCOM%\BINW;%WATCOM%\H;%WATCOM%\H\NT;%PATH%
SET PATH=%MASM%;%TASM%\BIN;%DOSEMU%;%PATH%
echo ==============================

echo.
echo ==============================
echo Creating paths and cleaning
echo ==============================
if exist RUN\conquer.exe del /q RUN\*.exe 2>nul >nul
if not exist RUN\. md RUN
del /q /s code\*.err 2>nul >nul
if exist CODE\OBJ\*.obj del /q CODE\OBJ\*.obj 2>nul >nul
if not exist CODE\OBJ\. md CODE\OBJ
if exist WINVQ\VQM32\O\*.obj del /q WINVQ\VQM32\O\*.obj 2>nul >nul
if not exist WINVQ\VQM32\O\. md WINVQ\VQM32\O
if exist WINVQ\VQA32\O\*.obj del /q WINVQ\VQA32\O\*.obj 2>nul >nul
if not exist WINVQ\VQA32\O\. md WINVQ\VQA32\O
del /q /s WIN32LIB\*.obj 2>nul >nul
del /q /s WIN32LIB\*.lbc 2>nul >nul
if exist WIN32LIB\LIB\*.lib del /q WIN32LIB\LIB\*.lib 2>nul >nul
if not exist WIN32LIB\LIB\. md WIN32LIB\LIB
if not exist WIN32LIB\INCLUDE\. md WIN32LIB\INCLUDE
if not exist WIN32LIB\SRCDEBUG\. md WIN32LIB\SRCDEBUG

echo.
echo ==============================
echo Compiling: VQA
echo ==============================
cd winvq
cd vqm32
WMAKE
cd ..
cd vqa32
WMAKE
cd ..
cd ..

echo.
echo ==============================
echo Compiling: WWLIB
echo ==============================
cd win32lib
WMAKE
cd ..

echo.
echo ==============================
echo Compiling: IPX
echo ==============================
cd ipx
WMAKE
cd ..

echo.
echo ==============================
echo Compiling: Main game
echo ==============================
cd code
WMAKE WIN32=1
cd ..

echo ==============================
echo Finished.
echo ==============================

pause