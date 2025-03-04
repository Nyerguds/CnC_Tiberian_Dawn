set include >temp.txt
set include=c:\wat\h;c:\wat\h\win
copy setinc.bat+temp.txt setinc2.bat
wpp -s -ml -bd -zu -bt=windows -0 ipx16c.cpp
tasm /ml ipx16a.asm
wlink @ipx16.lnk
wlib -c -n wwipx16.lib +wwipx16.dll
call setinc2.bat
