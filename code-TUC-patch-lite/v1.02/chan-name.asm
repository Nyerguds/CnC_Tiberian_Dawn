; Fix for Chan's name showing up as "Civilian" despite him being a specific mission target.

; ===========================================================
; Source code equivalent:
; ===========================================================

; IDATA.CPP -> int InfantryTypeClass::Full_Name(void) const
; To the list of exceptions, add  " || Type == INFANTRY_CHAN"

; In reality, "isNominal" was kinda mangled into overriding names with "Civilian" / "Civilian Building".
; To fix this properly, IsNominal should be returned to what it truly means, and "IsCivilian" should be
; checked; However, this does not work for civilian buildings, since buildings have no "IsCivilian" property.

; ===========================================================
; English
; ===========================================================

#eip=0053CB60
debug_map:
#eip=0053E4A0
SpecialOpts_1:
#eip=004120A8 ; int const AbstractTypeClass::Full_Name(void)
AbstractTypeClass_Full_Name:

; int const InfantryTypeClass::Full_Name(void)
#eip=0044F088 ; 3F488
push    edx
cmp     :debug_map, 0
jnz     .continue
test    byte ptr [eax+20h], 4
jz      .continue
test    byte ptr :SpecialOpts_1, 40h
jnz     .continue
mov     edx, [eax+48h]
sar     edx, 18h
cmp     edx, 10h ; Nikoomba
jz      .continue
cmp     edx, 12h ; Delphi
jz      .continue
cmp     edx, 11h ; Mobius
jz      .continue
cmp     edx, 13h ; Chan
jnz     .civilian
continue:
call   .AbstractTypeClass_Full_Name
pop     edx
retn
civilian:
mov     eax, 23h ; "Civilian"
pop     edx
retn

; ===========================================================
; German
; ===========================================================

#eip=0053CB60
debug_map:
#eip=0053E4A0
SpecialOpts_1:
#eip=004120A8 ; int const AbstractTypeClass::Full_Name(void)
AbstractTypeClass_Full_Name:

; int const InfantryTypeClass::Full_Name(void)
#eip=0044F228 ; 3F628
; (code is the same as English)

; ===========================================================
; French
; ===========================================================

#eip=0053CB60
debug_map:
#eip=0053E4A0
SpecialOpts_1:
#eip=004120A8 ; int const AbstractTypeClass::Full_Name(void)
AbstractTypeClass_Full_Name:

; int const InfantryTypeClass::Full_Name(void)
#eip=0044F298 ; 3F698
; (code is the same as English)

; ===========================================================
; Japanese
; ===========================================================

#eip=0053CB64
debug_map:
#eip=0053E4A4
SpecialOpts_1:
#eip=004120A8 ; int const AbstractTypeClass::Full_Name(void)
AbstractTypeClass_Full_Name:

; int const InfantryTypeClass::Full_Name(void)
#eip=0044FAE8 ; 3FEE8
; (code is the same as English)
