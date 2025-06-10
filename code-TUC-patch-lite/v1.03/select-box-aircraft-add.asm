; Fix for Aircraft not getting selected when dragging a selection box.
; This also adds additive selection by holding shift at the moment the mouse
; cursor is released.

; ===========================================================
; Source code equivalent:
; ===========================================================

; DISPLAY.CPP -> void DisplayClass::Select_These(COORDINATE coord1, COORDINATE coord2)
;
; 1. Additive selection:
; Find "Unselect_All();" call and add this check around it:
; 	if (!Keyboard::Down(KN_LSHIFT) && !Keyboard::Down(KN_RSHIFT))
; Note that technically KN_LSHIFT and KN_RSHIFT are the same value, so the
; call actually only needs to be done once. The asm code only does it once.
;
; 2. Between "AllowVoice = true" and the loop over LAYER_GROUND objects, add this:
;	for (int air_index = 0; air_index < Aircraft.Count(); air_index++) {
;		AircraftClass * aircraft = Aircraft.Ptr(air_index);
;		COORDINATE acoord = aircraft->Center_Coord();
;		int x = Coord_X(acoord);
;		int y = Coord_Y(acoord) - Pixel_To_Lepton(aircraft->Altitude);
;		if (aircraft->Owner() == PlayerPtr->Class->House && aircraft->Class_Of().IsSelectable
;				&& x >= x1 && x <= x2 && y >= y1 && y <= y2) {
;			if (aircraft->Select(true)) {
;				AllowVoice = false;
;			}
;		}
;	}

; ===========================================================
; English
; ===========================================================

#eip=0042D3AC
Unselect_All:
#eip=004CD0C0
keyboard_Down:
#eip=0050520C
AllowVoice:
#eip=0053E6FC
HouseClass_PlayerPtr:
; #eip=0053CE88
; Heap_Aircraft_Main:
#eip=0053CE94 ; Heap_Aircraft_Main + 0Ch
Heap_Aircraft_Count:
#eip=0053CEBC ; Heap_Aircraft_Main + 34h
Heap_Aircraft_ActivePointers:

#eip=00434BAB ; 24FAB
mov     ebx, 1
mov     :AllowVoice, ebx
jmp     00413C40
jumpback:
xor     ecx, ecx
xor     ebx, ebx

#eip=00413C38 ; 4038
dd C3 ; leave dummy function for AircraftClass::Write_INI
dd 0
select_aircraft:
; cool little extra: additive selecting.
mov     eax, 1010h      ; Shift (left and right are identical)
call   .keyboard_Down
test    eax, eax
jnz    .skip_unselect
call   .Unselect_All
skip_unselect:

; init loop
xor     ecx, ecx ; loop counter
xor     edi, edi ; loop object pointer (loop counter * 4)
jmp    .enter_loop

continue_loop:
add     edi, 4
inc     ecx

enter_loop:
mov     eax, :Heap_Aircraft_Count
cmp     ecx, eax
jge    .exit_loop

mov     edx, :Heap_Aircraft_ActivePointers
mov     edx, [edx+edi] ; edx = obj
mov     esi, [edx+8]   ; esi = vtable for obj
mov     eax, edx ; put obj in eax for call
call    dword ptr [esi+4] ; obj->Owner()
movsx   eax, al ; get byte value
mov     ebp, eax ; store obj house in ebp
mov     eax, :HouseClass_PlayerPtr
mov     eax, [eax]      ; PlayerPtr->Class
movsx   eax, byte [eax] ; PlayerPtr->Class->House
cmp     eax, ebp        ; is player owned unit?
jnz    .continue_loop

mov     eax, edx ; put obj in eax for call
call    dword ptr [esi+34h] ; obj->Class_Of()

test    byte ptr [eax+11h], 4 ; obj->Class_Of().IsSelectable
jz     .continue_loop

; mov     eax, [edx+0A5h] ; ((AircraftClass *)object)->Altitude
db 8B
db 82
dd A5
mov     esi, edx      ; backup obj ptr
; inline int Pixel_To_Lepton(int pixel) {return ((pixel * ICON_LEPTON_W) + (ICON_PIXEL_W / 2)) / ICON_PIXEL_W;}
mov     edx, eax ; eax = altitude in pixels
mov     ebx, 18h ; 24
shl     edx, 8   ; pixel * 100h
add     edx, 0Ch ; 12 (add half of 24, for rounding)
mov     eax, edx
sar     edx, 1Fh ; sign extend for signed division
idiv    ebx      ; eax = edx:eax / ebx
; end of Pixel_To_Lepton
mov     ebp, eax      ; result in ebp
mov     edx, esi      ; restore backup obj ptr
mov     eax, edx      ; put obj in eax for call
mov     esi, [edx+8]  ; esi = vtable for obj
call    dword ptr [esi+8] ; obj->Center_Coord();

movsx   esi, ax  ; esi = int x
shr     eax, 10h ; get Y coordinate out
movsx   eax, ax  ; clear rest of eax
sub     eax, ebp ; subtract height value from Y coordinate to account for aircraft height being shown farther up.
mov     ebp, eax ; ebp = int y
cmp     esi, [esp+14h] ; coord_x1
jl     .continue_loop
cmp     esi, [esp+20h] ; coord_x2
jg     .continue_loop
cmp     ebp, [esp+1Ch] ; coord_y1
jl     .continue_loop
cmp     ebp, [esp+18h] ; coord_y2
jg     .continue_loop
mov     esi, [edx+8]  ; esi = vtable for obj
mov     eax, edx      ; put obj in eax for call
call    dword ptr [esi+0A8h] ; obj->Select() 004B1548
test    eax, eax
jz     .continue_loop
xor     ebp, ebp
mov     :AllowVoice, ebp
jmp    .continue_loop
exit_loop:
jmp    .jumpback

; ===========================================================
; German
; ===========================================================

#eip=0042D454
Unselect_All:
#eip=004CDAA0
keyboard_Down:
#eip=005052FC
AllowVoice:
#eip=0053E6FC
HouseClass_PlayerPtr:
#eip=0053CE94 ; Heap_Aircraft_Main + 0Ch
Heap_Aircraft_Count:
#eip=0053CEBC ; Heap_Aircraft_Main + 34h
Heap_Aircraft_ActivePointers:

#eip=00434C5B ; 2505B
mov     ebx, 1
mov     :AllowVoice, ebx
jmp     00413C40
jumpback:
xor     ecx, ecx
xor     ebx, ebx

#eip=00413C38 ; 4038
; Code is the same as English.

; ===========================================================
; French
; ===========================================================

#eip=0042D414
Unselect_All:
#eip=004CDBB0
keyboard_Down:
#eip=0050535C
AllowVoice:
#eip=0053E6FC
HouseClass_PlayerPtr:
#eip=0053CE94 ; Heap_Aircraft_Main + 0Ch
Heap_Aircraft_Count:
#eip=0053CEBC ; Heap_Aircraft_Main + 34h
Heap_Aircraft_ActivePointers:

#eip=00434C1B ; 2501B
mov     ebx, 1
mov     :AllowVoice, ebx
jmp     00413C40
jumpback:
xor     ecx, ecx
xor     ebx, ebx

#eip=00413C38 ; 4038
; Code is the same as English.

; ===========================================================
; Japanese
; ===========================================================

#eip=0042D418
Unselect_All:
#eip=004CE390
keyboard_Down:
#eip=005053E0
AllowVoice:
#eip=0053E700
HouseClass_PlayerPtr:

#eip=0053CE98 ; Heap_Aircraft_Main + 0Ch
Heap_Aircraft_Count:
#eip=0053CEC0 ; Heap_Aircraft_Main + 34h
Heap_Aircraft_ActivePointers:

#eip=00434C1B ; 2501B
mov     ebx, 1
mov     :AllowVoice, ebx
jmp     00413C40
jumpback:
xor     ecx, ecx
xor     ebx, ebx

#eip=00413C38 ; 4038
; Code is the same as English.
