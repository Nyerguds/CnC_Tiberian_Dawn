; Fix for minimap showing a "no move" cursor for the harvester when hovering
; over tiberium, and for the Guard Area function.

; ===========================================================
; Source code equivalent:
; ===========================================================

; RADAR.CPP -> int RadarClass::TacticalClass::Action(unsigned flags, KeyNumType & key)
; Find "switch (action)", and add "ACTION_HARVEST:" and "ACTION_GUARD_AREA:"
; to the cases that do not clear the information.

; ===========================================================
; English
; ===========================================================

#eip=0049740F ; 8780F
test    al, al
jz     .clear
cmp     al, 3 ; 1=ACTION_MOVE, 2=ACTION_NOMOVE, 3=ACTION_ENTER
jbe    .allow
cmp     al, 5 ; ACTION_ATTACK
jz     .allow
cmp     al, 6 ; ACTION_HARVEST
jz     .allow
cmp     al, 9 ; ACTION_CAPTURE
jz     .allow
cmp     al, 0Fh ; ACTION_SABOTAGE
jz     .allow
cmp     al, 13h ; ACTION_GUARD_AREA
jz     .allow
clear:
xor     al, al
xor     esi, esi
db 88 ; mov [ebp-4], al
db 45
db FC
nop
nop
; should be 25h bytes in length.
allow:

; ===========================================================
; German
; ===========================================================

#eip=00497D3F ; 8813F
; (actual code is identical to English, just using a different eip)

; ===========================================================
; French
; ===========================================================

#eip=00497E4F ; 8824F
; (actual code is identical to English, just using a different eip)

; ===========================================================
; Japanese
; ===========================================================

#eip=0049880F ; 88C0F
; (actual code is identical to English, just using a different eip)
