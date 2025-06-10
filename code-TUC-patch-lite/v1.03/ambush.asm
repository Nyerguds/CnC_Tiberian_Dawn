; Fix for the fact the "Ambush" order does not work. Units that have this set
; in a mission are supposed to go to Hunt mode when they are first discovered
; by the player.

; ===========================================================
; Source code equivalent:
; ===========================================================

; TECHNO.CPP -> bool TechnoClass::Revealed(HouseClass * house)
; Find "if (!house->IsHuman && Mission == MISSION_AMBUSH)"
; Replace "house" with "House".
; Explanation: The check should be whether the discovered object is AI-owned.
; "house" is the "who discovered me?" argument. "House" is the owner of the
; discovered object.

; ===========================================================
; English
; ===========================================================

#eip=004AF7E6
first_epilogue:

#eip=004AF7F7 ; 9FBF7
jz     .first_epilogue ; replace long jump with short jump to free space
nop
mov     edx, [ecx+48h] ; current object house
test    byte ptr [edx+5], 2 ; House->IsHuman

; note: the actual bytes produced for all 4 languages are identical.

; ===========================================================
; German
; ===========================================================

#eip=004B0116
first_epilogue:

#eip=004B0127 ; A0527
jz     .first_epilogue ; replace long jump with short jump to free space
nop
mov     edx, [ecx+48h] ; current object house
test    byte ptr [edx+5], 2 ; House->IsHuman

; ===========================================================
; French
; ===========================================================

#eip=004B0226
first_epilogue:

#eip=004B0237 ; A0637
jz     .first_epilogue ; replace long jump with short jump to free space
nop
mov     edx, [ecx+48h] ; current object house
test    byte ptr [edx+5], 2 ; House->IsHuman

; ===========================================================
; Japanese
; ===========================================================

#eip=004B0A06
first_epilogue:

#eip=004B0A17 ; A0E17
jz     .first_epilogue ; replace long jump with short jump to free space
nop
mov     edx, [ecx+48h] ; current object house
test    byte ptr [edx+5], 2 ; House->IsHuman

