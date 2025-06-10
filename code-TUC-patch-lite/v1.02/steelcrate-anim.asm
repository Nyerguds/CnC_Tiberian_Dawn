; Fix for the Steel Crate not animating when picked up by GDI.

; ===========================================================
; Source code equivalent:
; ===========================================================

; CELL.CPP -> bool CellClass::Goodie_Check(FootClass * object)
; Find "new AnimClass(ANIM_CRATE_EMPULSE, Cell_Coord());"
; Move it two lines lower, outside of the HOUSE_BAD check.

; ===========================================================
; English / German / French / Japanese
; ===========================================================

#eip=00427DDE ; 181DE
jnz     00427DF4 ; not nuke piece
nop
nop
nop
nop
