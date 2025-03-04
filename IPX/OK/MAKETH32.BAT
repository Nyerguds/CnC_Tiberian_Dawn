thunk Thipx.thk
rem fixthunk
wpp386 -s -mf -3s -bt=nt -bd -zu -4 thipx32c.cpp
ml /DIS_32 /Zf /Fl /c /W3 /Fothipx32a.obj thipx.asm
ml /c /W3 thmap32.asm
wlink @thipx32.lnk
wlib -c -n wwipx32.lib +thipx32.dll
