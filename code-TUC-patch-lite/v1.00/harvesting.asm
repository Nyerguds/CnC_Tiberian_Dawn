; Fix for the bug that the lowest stage of tiberium is never counted when harvesting.

; ===========================================================
; Source code equivalent:
; ===========================================================

; CELL.CPP -> int CellClass::Reduce_Tiberium(int levels)
; "if (OverlayData > levels)" should be changed to ">=" (because overlaydata "0" is still 1 level)
; in the "else" case, "reducer = OverlayData" should be changed to "reducer = OverlayData + 1";

; ===========================================================
; English / German / French / Japanese
; ===========================================================

; Fix for harvesting bug
#eip=0042786B
jl     0042787B ; case where overlay (tiberium) needs to be cleared
#eip=0042787F
inc     ebx ; increase overlay frame by 1 so last stage doesn't yield nothing.
nop
nop
nop
nop