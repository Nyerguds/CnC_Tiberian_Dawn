; Fix for high damage weapons not doing all their damage due to the fact
; warheads store "100%" as "255/256".

; ===========================================================
; Source code equivalent:
; ===========================================================

; The proper fix is the one done in the 1.06 patch and the remaster: to make the
; Modifier values on the Warheads into 2-byte ints so 256 can be stored in them.
; TYPE.H -> class WarheadTypeClass
; Change "unsigned char Modifier[ARMOR_COUNT];" to "unsigned Modifier[ARMOR_COUNT];"
; CONST.CPP -> WarheadTypeClass const Warheads[WARHEAD_COUNT]
; Change all "255" values to "256"

; The actual fix done here is a bit of a hotfix, due to the fact I can't easily
; modify the size of the WarheadTypeClass struct. It simply skips applying the
; modifier if it is "255".
; COMBAT.CPP -> int Modify_Damage(int damage, WarheadType warhead, ArmorType armor, int distance)
; After fetching whead, replace the line applying "Fixed_To_Cardinal" with these:
;	int modifier = whead->Modifier[armor];
;	if (modifier != 255) {
;		damage = Fixed_To_Cardinal(damage, modifier);
;	}

; ===========================================================
; English
; ===========================================================

#eip=005035BC ; array_warheads
array_warheads:

#eip=00429A36 ; 19E36
jnz    .continue
xor     eax, eax
jmp     00429AA3 ; end
continue:
movsx   edx, dl
mov     eax, edx
shl     eax, 2
add     eax, edx
shl     eax, 2
mov     ecx, .array_warheads
add     eax, edx
add     ecx, eax
movsx   eax, bl
xor     edx, edx
mov     dl, [ecx+eax+10h]
mov     eax, esi
cmp     dl, byte 0FFh
jz     .skip

mul     edx
add     eax, 80h
db      A9 ; test    eax, 0FF000000h
dd      0FF000000h
jz     .divide

mov     eax, 0FFFFFFh
divide:
shr     eax, 8
skip:

; ===========================================================
; German
; ===========================================================

#eip=005036AC ; array_warheads
array_warheads:

#eip=00429A36 ; 19E36
; (actual code is identical to English, just using a different array_warheads offset)

; ===========================================================
; French
; ===========================================================

#eip=0050370C ; array_warheads
array_warheads:

#eip=00429A36 ; 19E36
; (actual code is identical to English, just using a different array_warheads offset)

; ===========================================================
; Japanese
; ===========================================================

#eip=0050377C ; array_warheads
array_warheads:

#eip=00429A36 ; 19E36
; (actual code is identical to English, just using a different array_warheads offset)
