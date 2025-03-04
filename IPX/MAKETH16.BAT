set include >temp.txt
set include=c:\wat\h;c:\wat\h\win
copy setinc.bat+temp.txt setinc2.bat
thunk Thipx.thk
wpp -ml -bd -zu -bt=windows -0 thipx16c.cpp
ml /c /W3 ipx16a.asm
ml /DIS_16 /c /W3 /Fothipx16a.obj thipx.asm
ml /c /W3 thmap16.asm
wlink @thipx16.lnk
rc -40 thipx16.dll
call setinc2.bat
