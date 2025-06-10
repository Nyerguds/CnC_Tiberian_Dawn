; Fix for force-fire being completely ignored on Overlay, making it useless on pavement types.

; ===========================================================
; Source code equivalent:
; ===========================================================

; TECHNO.CPP -> ActionType TechnoClass::What_Action(CELL cell) const
; find "if (!optr || (optr->IsWall && (whead->IsWallDestroyer || (whead->IsWoodDestroyer && optr->IsWooden))))"
; replace by "if (!optr || ctrldown || (optr->IsWall && (whead->IsWallDestroyer || (whead->IsWoodDestroyer && optr->IsWooden))))"

; ===========================================================
; English
; ===========================================================

; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
; NOTE: THIS 'A' SECTION IS OBSOLETE. See "v1.03\aircraft-allowed-actions.asm"
; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
; A. Backup "force fire" status in ebp
; Find "data_OverlayTypeClass" array where "data_overlay_CONC" is referenced as first item.
#eip=004B1D4B ; A214B
nop
jmp     004B32F2        ; test_building
; empty space: above TemplateClass::Read_INI (contains string "TEMPLATE")
#eip=004B32F2 ; A36F2   ; test_building
cmp     al, 7           ; RTTI_BUILDING
jnz    .not_building
xor     ebx, ebx        ; if building, don't allow force fire on cells
not_building:
mov     ebp, ebx        ; backup "force fire" status in ebp
jmp     004B1D51        ; get_overlay


; B. check "force fire" status in overlay checks
; Find "cmp dword ptr [eax+4], 0" and ""cmp dword ptr [eax+8], 0"; this is just above it.
#eip=004B1E0E ; A220E
nop
jmp     004B3301        ; test_force
#eip=004B3301 ; A3701   ; test_force
test    ebp, ebp
jz      004B3311        ; check_isWall
jmp     004B1E26        ; range_check
#eip=004B3311 ; A3711 ; check_isWall
test    byte ptr [edx+2Eh], 2 ; overlay->IsWall
jz      004B1E58        ; not_attack
jmp     004B1E14        ; check_walldestroyer

; ===========================================================
; German
; ===========================================================

; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
; NOTE: THIS 'A' SECTION IS OBSOLETE. See "v1.03\aircraft-allowed-actions.asm"
; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
; A. Backup "force fire" status in ebp
; Find "data_OverlayTypeClass" array where "data_overlay_CONC" is referenced as first item.
#eip=004B267B ; A2A7B
nop
jmp     004B3C22        ; test_building
; empty space: above TemplateClass::Read_INI (contains string "TEMPLATE")
#eip=004B3C22 ; A4022   ; test_buildings
cmp     al, 7           ; RTTI_BUILDING
jnz    .not_building
xor     ebx, ebx        ; if building, don't allow force fire on cells
not_building:
mov     ebp, ebx        ; backup "force fire" status in ebp
jmp     004B2681        ; get_overlay

; B. check "force fire" status in overlay checks
; Find "cmp dword ptr [eax+4], 0" and ""cmp dword ptr [eax+8], 0"; this is just above it.
#eip=004B273E ; A2B3E
nop
jmp     004B3C31        ; test_force
#eip=004B3C31 ; A4031   ; test_force
test    ebp, ebp
jz      004B3C41        ; check_isWall
jmp     004B2756        ; range_check
#eip=004B3C41 ; A4041 ; check_isWall
test    byte ptr [edx+2Eh], 2 ; overlay->IsWall
jz      004B2788        ; not_attack
jmp     004B2744        ; check_walldestroyer

; ===========================================================
; French
; ===========================================================

; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
; NOTE: THIS 'A' SECTION IS OBSOLETE. See "v1.03\aircraft-allowed-actions.asm"
; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
; A. Backup "force fire" status in ebp
; Find "data_OverlayTypeClass" array where "data_overlay_CONC" is referenced as first item.
#eip=004B278B ; A2B8B
nop
jmp     004B3D32        ; test_building
; empty space: above TemplateClass::Read_INI (contains string "TEMPLATE")
#eip=004B3D32 ; A4132   ; test_buildings
cmp     al, 7           ; RTTI_BUILDING
jnz    .not_building
xor     ebx, ebx        ; if building, don't allow force fire on cells
not_building:
mov     ebp, ebx        ; backup "force fire" status in ebp
jmp     004B2791        ; get_overlay

; B. check "force fire" status in overlay checks
; Find "cmp dword ptr [eax+4], 0" and ""cmp dword ptr [eax+8], 0"; this is just above it.
#eip=004B284E ; A2C4E
nop
jmp     004B3D41        ; test_force
#eip=004B3D41 ; A4141   ; test_force
test    ebp, ebp
jz      004B3D51        ; check_isWall
jmp     004B2866        ; range_check
#eip=004B3D51 ; A4151 ; check_isWall
test    byte ptr [edx+2Eh], 2 ; overlay->IsWall
jz      004B2898        ; not_attack
jmp     004B2854        ; check_walldestroyer

; ===========================================================
; Japanese
; ===========================================================

; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
; NOTE: THIS 'A' SECTION IS OBSOLETE. See "v1.03\aircraft-allowed-actions.asm"
; |||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
; A. Backup "force fire" status in ebp
; Find "data_OverlayTypeClass" array where "data_overlay_CONC" is referenced as first item.
#eip=004B2F6B ; A336B
nop
jmp     004B4512        ; test_building
; empty space: above TemplateClass::Read_INI (contains string "TEMPLATE")
#eip=004B4512 ; A4912   ; test_building
cmp     al, 7           ; RTTI_BUILDING
jnz    .not_building
xor     ebx, ebx        ; if building, don't allow force fire on cells
not_building:
mov     ebp, ebx        ; backup "force fire" status in ebp
jmp     004B2F71        ; get_overlay

; B. check "force fire" status in overlay checks
; Find "cmp dword ptr [eax+4], 0" and ""cmp dword ptr [eax+8], 0"; this is just above it.
#eip=004B302E ; A342E
nop
jmp     004B4521        ; test_force
#eip=004B4521 ; A4921   ; test_force
test    ebp, ebp
jz      004B4531        ; check_isWall
jmp     004B3046        ; range_check
#eip=004B4531 ; A4931 ; check_isWall
test    byte ptr [edx+2Eh], 2 ; overlay->IsWall
jz      004B3078        ; not_attack
jmp     004B3034        ; check_walldestroyer
