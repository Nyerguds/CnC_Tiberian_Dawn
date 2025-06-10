; Fix for the fact Area Guard orders can be given to aircraft through the
; [Ctrl]+[Alt]+Click function, while player Aircraft can't actually receive
; Area Guard orders at all.

; ===========================================================
; Source code equivalent:
; ===========================================================

; TECHNO.CPP -> ActionType TechnoClass::What_Action(CELL cell) const
; After retrieving altdown / ctrldown / shiftdown, add the following code:
; if (What_Am_I() == RTTI_AIRCRAFT && ctrldown && altdown) return ACTION_SELECT

; TECHNO.CPP -> ActionType TechnoClass::What_Action(ObjectClass * object) const
; After retrieving altdown / ctrldown / shiftdown, add the following code:
; if (What_Am_I() == RTTI_AIRCRAFT && ctrldown && altdown) return ACTION_NONE

; ===========================================================
; English
; ===========================================================

#eip=004CD0C0
keyboard_Down:

; TECHNO.CPP -> ActionType TechnoClass::What_Action(ObjectClass * object) const
; Length should be 6D
#eip=004B1B01 ; A1F01
mov     eax, 1012h      ; Alt (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_alt_disabled
mov     edx, 1
jmp    .obj_alt_enabled
obj_alt_disabled:
xor     edx, edx
obj_alt_enabled:
mov     eax, 1011h      ; Ctrl (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_ctrl_disabled
mov     ebx, 1
jmp    .obj_ctrl_enabled
obj_ctrl_disabled:
xor     ebx, ebx
obj_ctrl_enabled:
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_store_shift
mov     eax, 1
obj_store_shift:
mov     ebp, eax
; New code: check if type is Aircraft, and both ctrl and alt are pressed.
mov     edi, [ecx+8]
mov     eax, ecx
call    dword ptr [edi+18h] ; What_Am_I()
cmp     al, 5           ; RTTI_AIRCRAFT
jnz    .obj_not_aircraft_area_guard
test    ebx, ebx
jz     .obj_not_aircraft_area_guard
test    edx, edx ; Alt
jz     .obj_not_aircraft_area_guard
dd 90909090
dd 90909090
nop
nop
nop
mov     eax, 7 ; ACTION_SELECT ; select cursor
pop     ebp
pop     edi
pop     esi
pop     ecx
pop     ebx
retn
obj_not_aircraft_area_guard:

; TECHNO.CPP -> ActionType TechnoClass::What_Action(CELL cell) const
; Should be 7E in length
#eip=004B1CD3 ; A20D3
mov     eax, 1011h      ; Ctrl (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_ctrl_disabled
mov     ebx, 1
jmp    .cell_ctrl_enabled
cell_ctrl_disabled:
xor     ebx, ebx
cell_ctrl_enabled:
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_store_shift
mov     eax, 1
cell_store_shift:
mov     [esp], eax
mov     eax, 1012h      ; Alt (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_store_alt
mov     eax, 1
cell_store_alt:
mov     [esp+4], eax
; Get object type and check for building and aircraft
mov     ebp, [ecx+8]
mov     eax, ecx
call    dword ptr [ebp+18h] ; What_Am_I()
cmp     al, 7           ; RTTI_BUILDING
jnz    .cell_not_building
xor     ebx, ebx        ; if building, don't allow force fire on cells
cell_not_building:
cmp     al, 5           ; RTTI_AIRCRAFT
jnz    .cell_not_aircraft_area_guard
test    ebx, ebx
jz     .cell_not_aircraft_area_guard
mov     eax, [esp+4] ; Alt
test    eax, eax
jz     .cell_not_aircraft_area_guard
dd 90909090 ; nop fillers
dd 90909090
dd 90909090
nop
nop
nop
xor     eax, eax ; ACTION_NONE ; normal cursor
add     esp, 8
pop     ebp
pop     edi
pop     esi
pop     ecx
pop     ebx
retn
cell_not_aircraft_area_guard:
mov     ebp, ebx        ; backup force fire status in ebp; see "v1.02\overlay-force-fire.asm"

; ===========================================================
; German
; ===========================================================

#eip=004CDAA0
keyboard_Down:

; TECHNO.CPP -> ActionType TechnoClass::What_Action(ObjectClass * object) const
; Length should be 6D
#eip=004B2431 ; A2831
mov     eax, 1012h      ; Alt (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_alt_disabled
mov     edx, 1
jmp    .obj_alt_enabled
obj_alt_disabled:
xor     edx, edx
obj_alt_enabled:
mov     eax, 1011h      ; Ctrl (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_ctrl_disabled
mov     ebx, 1
jmp    .obj_ctrl_enabled
obj_ctrl_disabled:
xor     ebx, ebx
obj_ctrl_enabled:
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_store_shift
mov     eax, 1
obj_store_shift:
mov     ebp, eax
; New code: check if type is Aircraft, and both ctrl and alt are pressed.
mov     edi, [ecx+8]
mov     eax, ecx
call    dword ptr [edi+18h] ; What_Am_I()
cmp     al, 5           ; RTTI_AIRCRAFT
jnz    .obj_not_aircraft_area_guard
test    ebx, ebx
jz     .obj_not_aircraft_area_guard
test    edx, edx ; Alt
jz     .obj_not_aircraft_area_guard
dd 90909090
dd 90909090
nop
nop
nop
mov     eax, 7 ; ACTION_SELECT ; select cursor
pop     ebp
pop     edi
pop     esi
pop     ecx
pop     ebx
retn
obj_not_aircraft_area_guard:

; TECHNO.CPP -> ActionType TechnoClass::What_Action(CELL cell) const
; Should be 7E in length
#eip=004B2603 ; A2A03
mov     eax, 1011h      ; Ctrl (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_ctrl_disabled
mov     ebx, 1
jmp    .cell_ctrl_enabled
cell_ctrl_disabled:
xor     ebx, ebx
cell_ctrl_enabled:
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_store_shift
mov     eax, 1
cell_store_shift:
mov     [esp], eax
mov     eax, 1012h      ; Alt (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_store_alt
mov     eax, 1
cell_store_alt:
mov     [esp+4], eax
; Get object type and check for building and aircraft
mov     ebp, [ecx+8]
mov     eax, ecx
call    dword ptr [ebp+18h] ; What_Am_I()
cmp     al, 7           ; RTTI_BUILDING
jnz    .cell_not_building
xor     ebx, ebx        ; if building, don't allow force fire on cells
cell_not_building:
cmp     al, 5           ; RTTI_AIRCRAFT
jnz    .cell_not_aircraft_area_guard
test    ebx, ebx
jz     .cell_not_aircraft_area_guard
mov     eax, [esp+4] ; Alt
test    eax, eax
jz     .cell_not_aircraft_area_guard
dd 90909090 ; nop fillers
dd 90909090
dd 90909090
nop
nop
nop
xor     eax, eax ; ACTION_NONE ; normal cursor
add     esp, 8
pop     ebp
pop     edi
pop     esi
pop     ecx
pop     ebx
retn
cell_not_aircraft_area_guard:
mov     ebp, ebx        ; backup force fire status in ebp; see "v1.02\overlay-force-fire.asm"

; ===========================================================
; French
; ===========================================================

#eip=004CDBB0
keyboard_Down:

; TECHNO.CPP -> ActionType TechnoClass::What_Action(ObjectClass * object) const
; Length should be 6D
#eip=004B2541 ; A2941
mov     eax, 1012h      ; Alt (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_alt_disabled
mov     edx, 1
jmp    .obj_alt_enabled
obj_alt_disabled:
xor     edx, edx
obj_alt_enabled:
mov     eax, 1011h      ; Ctrl (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_ctrl_disabled
mov     ebx, 1
jmp    .obj_ctrl_enabled
obj_ctrl_disabled:
xor     ebx, ebx
obj_ctrl_enabled:
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_store_shift
mov     eax, 1
obj_store_shift:
mov     ebp, eax
; New code: check if type is Aircraft, and both ctrl and alt are pressed.
mov     edi, [ecx+8]
mov     eax, ecx
call    dword ptr [edi+18h] ; What_Am_I()
cmp     al, 5           ; RTTI_AIRCRAFT
jnz    .obj_not_aircraft_area_guard
test    ebx, ebx
jz     .obj_not_aircraft_area_guard
test    edx, edx ; Alt
jz     .obj_not_aircraft_area_guard
dd 90909090
dd 90909090
nop
nop
nop
mov     eax, 7 ; ACTION_SELECT ; select cursor
pop     ebp
pop     edi
pop     esi
pop     ecx
pop     ebx
retn
obj_not_aircraft_area_guard:

; TECHNO.CPP -> ActionType TechnoClass::What_Action(CELL cell) const
; Should be 7E in length
#eip=004B2713 ; A2B13
mov     eax, 1011h      ; Ctrl (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_ctrl_disabled
mov     ebx, 1
jmp    .cell_ctrl_enabled
cell_ctrl_disabled:
xor     ebx, ebx
cell_ctrl_enabled:
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_store_shift
mov     eax, 1
cell_store_shift:
mov     [esp], eax
mov     eax, 1012h      ; Alt (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_store_alt
mov     eax, 1
cell_store_alt:
mov     [esp+4], eax
; Get object type and check for building and aircraft
mov     ebp, [ecx+8]
mov     eax, ecx
call    dword ptr [ebp+18h] ; What_Am_I()
cmp     al, 7           ; RTTI_BUILDING
jnz    .cell_not_building
xor     ebx, ebx        ; if building, don't allow force fire on cells
cell_not_building:
cmp     al, 5           ; RTTI_AIRCRAFT
jnz    .cell_not_aircraft_area_guard
test    ebx, ebx
jz     .cell_not_aircraft_area_guard
mov     eax, [esp+4] ; Alt
test    eax, eax
jz     .cell_not_aircraft_area_guard
dd 90909090 ; nop fillers
dd 90909090
dd 90909090
nop
nop
nop
xor     eax, eax ; ACTION_NONE ; normal cursor
add     esp, 8
pop     ebp
pop     edi
pop     esi
pop     ecx
pop     ebx
retn
cell_not_aircraft_area_guard:
mov     ebp, ebx        ; backup force fire status in ebp; see "v1.02\overlay-force-fire.asm"

; ===========================================================
; Japanese
; ===========================================================

#eip=004CE390
keyboard_Down:

; TECHNO.CPP -> ActionType TechnoClass::What_Action(ObjectClass * object) const
; Length should be 6D
#eip=004B2D21 ; A3121
mov     eax, 1012h      ; Alt (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_alt_disabled
mov     edx, 1
jmp    .obj_alt_enabled
obj_alt_disabled:
xor     edx, edx
obj_alt_enabled:
mov     eax, 1011h      ; Ctrl (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_ctrl_disabled
mov     ebx, 1
jmp    .obj_ctrl_enabled
obj_ctrl_disabled:
xor     ebx, ebx
obj_ctrl_enabled:
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .obj_store_shift
mov     eax, 1
obj_store_shift:
mov     ebp, eax
; New code: check if type is Aircraft, and both ctrl and alt are pressed.
mov     edi, [ecx+8]
mov     eax, ecx
call    dword ptr [edi+18h] ; What_Am_I()
cmp     al, 5           ; RTTI_AIRCRAFT
jnz    .obj_not_aircraft_area_guard
test    ebx, ebx
jz     .obj_not_aircraft_area_guard
test    edx, edx ; Alt
jz     .obj_not_aircraft_area_guard
dd 90909090
dd 90909090
nop
nop
nop
mov     eax, 7 ; ACTION_SELECT ; select cursor
pop     ebp
pop     edi
pop     esi
pop     ecx
pop     ebx
retn
obj_not_aircraft_area_guard:

; TECHNO.CPP -> ActionType TechnoClass::What_Action(CELL cell) const
; Should be 7E in length
#eip=004B2EF3 ; A32F3
mov     eax, 1011h      ; Ctrl (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_ctrl_disabled
mov     ebx, 1
jmp    .cell_ctrl_enabled
cell_ctrl_disabled:
xor     ebx, ebx
cell_ctrl_enabled:
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_store_shift
mov     eax, 1
cell_store_shift:
mov     [esp], eax
mov     eax, 1012h      ; Alt (left and right are identical)
call   .keyboard_Down
test    eax, eax
jz     .cell_store_alt
mov     eax, 1
cell_store_alt:
mov     [esp+4], eax
; Get object type and check for building and aircraft
mov     ebp, [ecx+8]
mov     eax, ecx
call    dword ptr [ebp+18h] ; What_Am_I()
cmp     al, 7           ; RTTI_BUILDING
jnz    .cell_not_building
xor     ebx, ebx        ; if building, don't allow force fire on cells
cell_not_building:
cmp     al, 5           ; RTTI_AIRCRAFT
jnz    .cell_not_aircraft_area_guard
test    ebx, ebx
jz     .cell_not_aircraft_area_guard
mov     eax, [esp+4] ; Alt
test    eax, eax
jz     .cell_not_aircraft_area_guard
dd 90909090 ; nop fillers
dd 90909090
dd 90909090
nop
nop
nop
xor     eax, eax ; ACTION_NONE ; normal cursor
add     esp, 8
pop     ebp
pop     edi
pop     esi
pop     ecx
pop     ebx
retn
cell_not_aircraft_area_guard:
mov     ebp, ebx        ; backup force fire status in ebp; see "v1.02\overlay-force-fire.asm"
