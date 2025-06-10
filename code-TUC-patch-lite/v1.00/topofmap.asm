; Fix for the crash that happens when scouting too high or low on a large map.
; Original fix designed by VK.

; ===========================================================
; Source code equivalent:
; ===========================================================

; DISPLAY.CPP -> bool DisplayClass::Map_Cell(CELL cell, HouseClass * house)
; after "c = Adjacent_Cell(cell, dir);"
; add "if ((unsigned)c >= MAP_CELL_TOTAL) continue;"
; This is the remaster fix, but I assume it does the same as the hack.

; ===========================================================
; English
; ===========================================================

#eip=00432421
movzx   esi, si
jmp     004E79CC
nop

#eip=004E79CC
cmp     esi, [ecx+4]
jg      00432465
test    byte ptr [eax+ebx], 4
jnz     00432465
jmp     0043242A

; ===========================================================
; German
; ===========================================================

#eip=004324D1
movzx   esi, si
jmp     004E83CC
nop

#eip=004E83CC
cmp     esi, [ecx+4]
jg      00432515
test    byte ptr [eax+ebx], 4
jnz     00432515
jmp     004324DA

; ===========================================================
; French
; ===========================================================

#eip=00432491
movzx   esi, si
jmp     004E84CC
nop

#eip=004E84CC
cmp     esi, [ecx+4]
jg      004324D5
test    byte ptr [eax+ebx], 4
jnz     004324D5
jmp     0043249A

; ===========================================================
; Japanese
; ===========================================================

#eip=00432491
movzx   esi, si
jmp     004E8BCC
nop

#eip=004E8BCC
cmp     esi, [ecx+4]
jg      004324D5
test    byte ptr [eax+ebx], 4
jnz     004324D5
jmp     0043249A
