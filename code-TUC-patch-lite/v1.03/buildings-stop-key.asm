; Fix for the 'S' command being disabled on buildings. This was disabled to
; remove the Sell-Stop cheat, but it also disables the ability to stop force-
; fire commands. This code restores the Stop ability but not the cheat.

; ===========================================================
; Source code equivalent:
; ===========================================================

; CONQUER.CPP -> void Keyboard_Process(KeyNumType &input)
; Find "tech->What_Am_I() != RTTI_BUILDING"
; Replace by
; (tech->What_Am_I() != RTTI_BUILDING || (((BuildingClass *)tech)->BState != BSTATE_CONSTRUCTION))
; Conveniently, "BSTATE_CONSTRUCTION" encompasses both building up and selling,
; which were the two problematic cases.

; ===========================================================
; English, German
; ===========================================================

#eip=0042B9E9
loop_stop_selected:

; this should be 2F bytes long
#eip=0042BA0E ; 1BE0E
mov     esi, [edx+8]
mov     eax, edx
call    [esi+48h] ; tech->Can_Player_Move()
test    eax, eax
jnz    .stop_current_selected

mov     eax, edx
call    [esi+44h] ; tech->Can_Player_Fire()
test    eax, eax
jz     .loop_stop_selected
mov     eax, edx
call    [esi+18h] ; tech->What_Am_I()

cmp     al, 7           ; RTTI_BUILDING
jnz    .stop_current_selected

mov     al, [edx+75h]   ; ((BuildingClass *)tech)->BState
test    al, al          ; 0 = BSTATE_CONSTRUCTION
jz     .loop_stop_selected

stop_current_selected:
mov     eax, edx
call    [esi+0BCh]
nop
nop

; ===========================================================
; French, Japanese
; ===========================================================

#eip=0042B9F9
loop_stop_selected:

#eip=0042BA1E; 1BE1E
; (actual code is identical to English/German, just using a different eip and loop_stop_selected label)
