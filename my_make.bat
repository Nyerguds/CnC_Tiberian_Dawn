SET ROOT=%cd%

SET PATH=%windir%;%windir%\System32

REM Compilers and utilities
SET WATCOM=D:\WATCOM
SET TASM=D:\Projects\TASM
SET UTILS=D:\Projects\utils\utils
SET MASM=D:\Projects\utils\utils

REM Define Westwood libraries
SET WIN32LIB=%ROOT%\WIN32LIB
SET WIN32VCS=%ROOT%\WIN32LIB
SET WWFLAT=%ROOT%\WIN32LIB
SET VQDIR=%ROOT%\WINVQ
SET CODEDIR=%ROOT%\CODE
SET CDDIR=%ROOT%

REM 3rd party libraries

SET PATH=%WATCOM%\BINNT;%WATCOM%\BIN;%WATCOM%\BINW;%WATCOM%\H;%WATCOM%\H\NT;%PATH%
SET PATH=%TASM%\BIN;%PATH%

md CODE\OBJ
md CODE\OBJ\WIN32\ENGLISH
md CODE\OBJ\WIN32\FRENCH
md CODE\OBJ\WIN32\GERMAN
md RUN
md RUN\ENGLISH
md RUN\FRENCH
md RUN\GERMAN

md WINVQ\VQM32\O
md WINVQ\VQA32\O
md WIN32LIB\LIB

::copy /Y %IPX%\IPXREAL.IBN .\OBJ\WIN32\


echo Compiling VQA

cd winvq

cd vqm32

WMAKE

cd ..

cd vqa32

WMAKE

cd ..
cd ..

echo Compiling WWLIB

cd win32lib

WMAKE

cd ..


cd code

echo Compiling IPX

cd ipx

WMAKE

cd ..

echo Compiling Game

WMAKE WIN32=1

:: manual linking to avoid a link path corruption issue
::%UTILS%\nwlink name ra95.exe @win95.lnk

pause