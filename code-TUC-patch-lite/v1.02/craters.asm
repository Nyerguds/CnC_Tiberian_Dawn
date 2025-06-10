; Fix for crater type and size from mission getting ignored for all but CR1.

; ===========================================================
; Source code equivalent:
; ===========================================================

; 1. Make sure only CR1 handles the "spot index" code, because CR1 is the center anyway, and
; the default crater type used for spawning from animations is CR1. See void AnimClass::Middle(void)
; SMUDGE.CPP -> bool SmudgeClass::Mark(MarkType mark)
; Inside the "if (Class->IsCrater)" check should be an additional check:
; if (Class->Type == SMUDGE_CRATER1) {
;   cell->Smudge = (SmudgeType)(SMUDGE_CRATER1 + CellClass::Spot_Index(Coord));
; } else {
;   cell->Smudge = (SmudgeType)Class->Type;
; }

; 2. Remove call to "Coord_Scatter" in building debris, since the randomised crater type makes it pointless.
; This allows the unused crater CR6 to occasionally spawn from destroyed buildings.
; BUILDING.CPP -> void BuildingClass::Drop_Debris(TARGET source)
; Find line: 
;   new SmudgeClass(Random_Pick(SMUDGE_CRATER1, SMUDGE_CRATER6), Coord_Scatter(Cell_Coord(newcell), 0x0080, false));
; Replace with:
;   new SmudgeClass(Random_Pick(SMUDGE_CRATER1, SMUDGE_CRATER6), Cell_Coord(newcell));

; ===========================================================
; English
; ===========================================================

; 1. Make sure only CR1 handles the "spot index" code
; In SmudgeClass::Mark: jump to extra check
#eip=004A7DD9 ; 981D9
jmp 004A7C13
nop
nop
; if crater is CR1, use normal logic, otherwise force current given crater.
#eip=004A7C13 ; 98013
mov     al, byte [eax+20h]
cmp     al, 00h         ; crater is CR1
jnz     004A7C29 ; .apply
mov     eax, [esi]
jmp     004A7C24 ; .select_index
#eip=004A7C24 ; 98024
select_index:
call    004279B0 ; CellClass::Spot_Index(ulong) ; select crater type
apply:
jmp     004A7DE5 ; go to line "mov [ecx+8], al"

; ===========================================================
; German
; ===========================================================

; 1. Make sure only CR1 handles the "spot index" code
; In SmudgeClass::Mark: jump to extra check
#eip=004A86F9 ; 98AF9
jmp 004A8533
nop
nop
; if crater is CR1, use normal logic, otherwise force current given crater.
#eip=004A8533 ; 98933
mov     al, byte [eax+20h] ; smudge type to place
cmp     al, 00h         ; crater is CR1
jnz     004A8549 ; .apply
mov     eax, [esi]
jmp     004A8544 ; .select_index
#eip=004A8544 ; 98944
select_index:
call    004279B0 ; CellClass::Spot_Index(ulong) ; select crater type
apply:
jmp     004A8705 ; go to line "mov [ecx+8], al"

; ===========================================================
; French
; ===========================================================

; 1. Make sure only CR1 handles the "spot index" code
; In SmudgeClass::Mark: jump to extra check
#eip=004A8809 ; 98C09
jmp 004A8643
nop
nop
; if crater is CR1, use normal logic, otherwise force current given crater.
#eip=004A8643 ; 98A43
mov     al, byte [eax+20h] ; smudge type to place
cmp     al, 00h         ; crater is CR1
jnz     004A8659 ; .apply
mov     eax, [esi]
jmp     004A8654 ; .select_index
#eip=004A8654 ; 98A54
select_index:
call    004279B0 ; CellClass::Spot_Index(ulong) ; select crater type
apply:
jmp     004A8815 ; go to line "mov [ecx+8], al"


; ===========================================================
; Japanese
; ===========================================================

; 1. Make sure only CR1 handles the "spot index" code
; In SmudgeClass::Mark: jump to extra check
#eip=004A8FC9 ; 993C9
jmp 004A8E03
nop
nop
; if crater is CR1, use normal logic, otherwise force current given crater.
#eip=004A8E03 ; 99203
mov     al, byte [eax+20h] ; smudge type to place
cmp     al, 00h         ; crater is CR1
jnz     004A8E19 ; .apply
mov     eax, [esi]
jmp     004A8E14 ; .select_index
#eip=004A8E14 ; 99214
select_index:
call    004279B0 ; CellClass::Spot_Index(ulong) ; select crater type
apply:
jmp     004A8FD5 ; go to line "mov [ecx+8], al"

; ===========================================================
; English / German / French / Japanese
; ===========================================================

; 2. Remove call to "Coord_Scatter" in building debris, since the randomised crater type makes it pointless.
; This is a surgical removal of the "Coord_Scatter(..., 0x0080, false)" call while retaining the "Cell_Coord(newcell)"
; operation inside it. Since "Cell_Coord(newcell)" is a macro, it's a bit of a mess to filter out.
#eip=0041ED4D ; F14D
nop ; removed: arg "amount to scatter" (mov edx, 80h)
nop
nop
nop
nop
or      eax, ebx ; bytes 09 D8 remain.
nop ; removed: arg "lock" (xor ebx, ebx)
nop
nop ; removed: call to 0042EE74 Coord_Scatter(ulong,uint,int)
nop
nop
nop
nop

