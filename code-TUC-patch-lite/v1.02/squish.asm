; Fix the logic to spawn squish marks when vehicles crush infantry,
; to not mess up all overlay spawning.
; Also fix the squish mark being impossible to use in any way without
; activating the corpse spawn logic, and adjust squish mark object to
; be 100% unobtrusive for gameplay.

; ===========================================================
; Source code equivalent:
; ===========================================================

; 1. Remove the fact overlay placement itself checks the option.
; OVERLAY.CPP -> bool OverlayClass::Mark(MarkType mark)
; find "if (!Special.IsGross && Class->Type != OVERLAY_SQUISH)" check
; Remove the entire check, keeping the code inside the block.

; 2. Add the check on the option to the actual crushing code.
; DRIVE.CPP -> void DriveClass::Overrun_Square(CELL cell, bool threaten)
; find "new OverlayClass(OVERLAY_SQUISH, Coord_Cell(Coord));"
; Add if-check around it: "if (Special.IsGross) { ... }"

; 3. Make squish mark an unobtrusive object by allowing tiberium to spread on it.
; MAP.CPP -> void MapClass::Logic(void)
; Find "&& newcell->Overlay == OVERLAY_NONE"
; Replace by "&& (newcell->Overlay == OVERLAY_NONE || newcell->Overlay == OVERLAY_SQUISH)"

; 4. Allow multiplayer crates to replace squish marks.
; MAP.CPP -> bool MapClass::Place_Random_Crate(void)
; Find "&& ptr->Overlay == OVERLAY_NONE"
; Replace by "&& (ptr->Overlay == OVERLAY_NONE || ptr->Overlay == OVERLAY_SQUISH)"

; ===========================================================
; English
; ===========================================================

; 1. Remove the fact overlay placement itself checks the option
#eip=0048F42B ; 7F82B
dd 90909090 ; 4*NOP
dd 90909090 ; 4*NOP
nop
; Three bytes left alone in between; 8B 46 1A (mov eax, [esi+1Ah])
#eip=0048F437 ; 7F837
dd 90909090 ; 4*NOP
dd 90909090 ; 4*NOP
nop
nop
nop

; 2. Add the check on the option to the actual crushing code.
#eip=0053E4A3 ; SpecialOpts_4
SpecialOpts_4:
#eip=00436D4F ; 2714F
jmp     00436741
#eip=00436741 ; 26B41
test    byte :SpecialOpts_4, 4 ; SpecialOpts_4
jz      00436D81
jmp     00436753
#eip=00436753 ; 26B53
mov     eax, 1Eh
jmp     00436D54

; 3. Allow tiberium to spread over squish mark
#eip=00468D43 ; 59143
mov     al, byte ptr [ecx+6]
jmp     004714D3 ; check_overlay_empty
nop
nop
#eip=004714D3 ; 618D3 ; check_overlay_empty
cmp     al, byte 0ffh
jz     .is_allowed
jmp     004714E1 ; check_overlay_squish
#eip=004714E1 ; 618E1 ; check_overlay_squish
cmp     al, byte 13h
jz     .is_allowed
jmp     00468C91 ; abort_spread
is_allowed:
jmp     00468D4D ; bridge_check

; 4. Allow random crates to replace squish marks
#eip=00468E6A ; 5926A
mov     al, byte ptr [ecx+6]
jmp     004522C2
; extra space is above Set_Scenario_Name, which references string "SC%c%02d%c%c.INI"
#eip=004522C2 ; 426C2 ; check_overlay_empty
cmp     al, byte 0ffh
jz      004522E2 ; allow
cmp     al, byte 13h
jz      004522E2 ; allow
jmp     00468E8E ; denied
#eip=004522E2 ; 426E2 ; allow
mov     eax, ecx
jmp     00468E72

; ===========================================================
; German
; ===========================================================

; 1. Remove the fact overlay placement itself checks the option
#eip=0048FC2B ; 8002B
dd 90909090 ; 4*NOP
dd 90909090 ; 4*NOP
nop
; Three bytes left alone in between; 8B 46 1A (mov eax, [esi+1Ah])
#eip=0048FC37 ; 80037
dd 90909090 ; 4*NOP
dd 90909090 ; 4*NOP
nop
nop
nop

; 2. Add the check on the option to the actual crushing code.
#eip=0053E4A3 ; SpecialOpts_4
SpecialOpts_4:
#eip=00436DFF ; 271FF
jmp     004367F1
#eip=004367F1 ; 26BF1
test    byte :SpecialOpts_4, 4
jz      00436E31
jmp     00436803
#eip=00436803 ; 26C03
mov     eax, 1Eh
jmp     00436E04

; 3. Allow tiberium to spread over squish mark
#eip=00468F73 ; 59373
mov     al, byte ptr [ecx+6]
jmp     00471C43 ; check_overlay_empty
nop
nop
#eip=00471C43 ; 62043 ; check_overlay_empty
cmp     al, byte 0ffh
jz     .is_allowed
jmp     004714E1 ; check_overlay_squish
#eip=00471C51 ; 62051 ; check_overlay_squish
cmp     al, byte 13h
jz     .is_allowed
jmp     00468EC1 ; abort_spread
is_allowed:
jmp     00468F7D ; bridge_check

; 4. Allow random crates to replace squish marks
#eip=0046909A ; 5949A
mov     al, byte ptr [ecx+6]
jmp     00452462
; extra space is above Set_Scenario_Name, which references string "SC%c%02d%c%c.INI"
#eip=00452462 ; 42862 ; check_overlay_empty
cmp     al, byte 0ffh
jz      00452482 ; allow
cmp     al, byte 13h
jz      00452482 ; allow
jmp     004690BE ; denied
#eip=00452482 ; 42882 ; allow
mov     eax, ecx
jmp     004690A2 ; allowed

; ===========================================================
; French
; ===========================================================

; 1. Remove the fact overlay placement itself checks the option
#eip=0048FD3B ; 8013B
dd 90909090 ; 4*NOP
dd 90909090 ; 4*NOP
nop
; Three bytes left alone in between; 8B 46 1A (mov eax, [esi+1Ah])
#eip=0048FD47 ; 80147
dd 90909090 ; 4*NOP
dd 90909090 ; 4*NOP
nop
nop
nop

; 2. Add the check on the option to the actual crushing code.
#eip=0053E4A3 ; SpecialOpts_4
SpecialOpts_4:
#eip=00436DBF ; 271BF
jmp    004367B1
#eip=004367B1 ; 26BB1
test    byte :SpecialOpts_4, 4
jz      00436DF1 ; abort placement
jmp     004367C3
#eip=004367C3 ; 26BC3
mov     eax, 1Eh
jmp     00436DC4 ; continue placement

; 3. Allow tiberium to spread over squish mark
#eip=00468FC3 ; 593C3
mov     al, byte ptr [ecx+6]
jmp     00471CB3 ; check_overlay_empty
nop
nop
#eip=00471CB3 ; 620B3 ; check_overlay_empty
cmp     al, byte 0ffh
jz     .is_allowed
jmp     00471CC1 ; check_overlay_squish
#eip=00471CC1 ; 620C1 ; check_overlay_squish
cmp     al, byte 13h
jz     .is_allowed
jmp     00468F11 ; abort_spread
is_allowed:
jmp     00468FCD ; bridge_check

; 4. Allow random crates to replace squish marks
#eip=004690EA ; 594EA
mov     al, byte ptr [ecx+6]
jmp     004524D2
; extra space is above Set_Scenario_Name, which references string "SC%c%02d%c%c.INI"
#eip=004524D2 ; 428D2 ; check_overlay_empty
cmp     al, byte 0ffh
jz      004524F2 ; allow
cmp     al, byte 13h
jz      004524F2 ; allow
jmp     0046910E ; denied
#eip=004524F2 ; 428F2 ; allow
mov     eax, ecx
jmp     004690F2 ; allowed

; ===========================================================
; Japanese
; ===========================================================

; find specialops_4 at 0049CC27
; 1. Remove the fact overlay placement itself checks the option
#eip=004906AB ; 80AAB
dd 90909090 ; 4*NOP
dd 90909090 ; 4*NOP
nop
; Three bytes left alone in between; 8B 46 1A (mov eax, [esi+1Ah])
#eip=004906B7 ; 80AB7
dd 90909090 ; 4*NOP
dd 90909090 ; 4*NOP
nop
nop
nop

; 2. Add the check on the option to the actual crushing code.
#eip=0053E4A7 ; SpecialOpts_4
SpecialOpts_4:
#eip=00436DBF ; 271BF
jmp     004367B1
#eip=004367B1 ; 26BB1
test    byte :SpecialOpts_4, 4
jz      00436DF1 ; abort placement
jmp     004367C3
#eip=004367C3 ; 26BC3
mov     eax, 1Eh
jmp     00436DC4 ; continue placement

; 3. Allow tiberium to spread over squish mark
#eip=00469923 ; 59D23
mov     al, byte ptr [ecx+6]
jmp     004721A3 ; check_overlay_empty
nop
nop
#eip=004721A3 ; 625A3 ; check_overlay_empty
cmp     al, byte 0ffh
jz     .is_allowed
jmp     004721B1 ; check_overlay_squish
#eip=004721B1 ; 625B1 ; check_overlay_squish
cmp     al, byte 13h
jz     .is_allowed
jmp     00469871 ; abort_spread
is_allowed:
jmp     0046992D ; bridge_check

; 4. Allow random crates to replace squish marks
#eip=00469A4A ; 59E4A
mov     al, byte ptr [ecx+6]
jmp     00452D22
; extra space is above Set_Scenario_Name, which references string "SC%c%02d%c%c.INI"
#eip=00452D22 ; 43122 ; check_overlay_empty
cmp     al, byte 0ffh
jz      00452D42 ; allow
cmp     al, byte 13h
jz      00452D42 ; allow
jmp     00469A6E ; denied
#eip=00452D42 ; 43142 ; allow
mov     eax, ecx
jmp     00469A52 ; allowed

