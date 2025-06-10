; Fix for the fact the Nod score calculation acts as if GDI stuff getting killed is a bad thing.

; ===========================================================
; Source code equivalent:
; ===========================================================

; SCORE.CPP -> void ScoreClass::Presentation(void)
; Find "leadership = Cardinal_To_Fixed(GKilled+GBKilled+leadership, leadership);"
; Change to:
; leadership = Cardinal_To_Fixed(PlayerPtr->UnitsLost + PlayerPtr->BuildingsLost + leadership, leadership);

; ===========================================================
; English
; ===========================================================

#eip=0053E6FC ; HouseClass *PlayerPtr
HouseClass_PlayerPtr:

; ScoreClass::Presentation(void)
; look for "BEEPY6.AUD" reference
; This code should come at a jump destination, just after "inc     edi"
#eip=0049DC2E ; 8E02E
mov     eax, :HouseClass_PlayerPtr
mov     edx, [eax+17Ch] ; Player->UnitsLost
add     edx, [eax+1A8h] ; Player->BuildingsLost
lea     ebx, [edx+edi]
; original code, just shifted down
mov     eax, edi
or      ebx, ebx
jz     .CardinalToFixed_notzero
shl     eax, 8
xor     edx, edx
div     ebx
CardinalToFixed_notzero:
mov     edx, eax
mov     eax, 64h
mul     edx
add     eax, 80h

db A9 ; test eax, dword 0FF000000h
dd      0FF000000h
jz     .FixedToCardinal_no_overflow
mov     eax, 0FFFFFFh
FixedToCardinal_no_overflow:
shr     eax, 8
mov     edi, eax
cmp     eax, 64h
jbe    .below_100
mov     edi, 64h
dd      90909090 ; padding NOPs
nop
below_100:

; ===========================================================
; German
; ===========================================================

#eip=0053E6FC ; HouseClass *PlayerPtr
HouseClass_PlayerPtr:

; ScoreClass::Presentation(void)
; look for "BEEPY6.AUD" reference
; This code should come at a jump destination, just after "inc     edi"
#eip=0049E54E ; 8E94E
; (actual code is identical to English, just using a different eip)

; ===========================================================
; French
; ===========================================================

#eip=0053E6FC ; HouseClass *PlayerPtr
HouseClass_PlayerPtr:

; ScoreClass::Presentation(void)
; look for "BEEPY6.AUD" reference
; This code should come at a jump destination, just after "inc     edi"
#eip=0049E65E ; 8EA5E
; (actual code is identical to English, just using a different eip)

; ===========================================================
; Japanese
; ===========================================================

#eip=0053E700 ; HouseClass *PlayerPtr
HouseClass_PlayerPtr:

; ScoreClass::Presentation(void)
; look for "BEEPY6.AUD" reference
; This code should come at a jump destination, just after "inc     edi"
#eip=0049EE1E ; 8F21E
; (actual code is identical to English, just using a different eip and PlayerPtr offset)
