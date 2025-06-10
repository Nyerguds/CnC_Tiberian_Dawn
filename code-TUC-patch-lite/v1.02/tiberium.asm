; Fix for the bug that tiberium growth does not refresh unless you scroll away from it.

; ===========================================================
; Source code equivalent:
; ===========================================================

; Add cell refresh to tiberium growth (spread uses the OverlayClass constructor, which already refreshes)
; MAP.CPP -> void MapClass::Logic(void)
; Find "newcell->OverlayData++;" and add "newcell->Redraw_Objects();" behind it.

; ===========================================================
; English
; ===========================================================

; Add cell refresh to tiberium growth
; See squish code for nearby empty space.
#eip=00468C09 ; 59009
jmp     004714D9 ; increase_tib
#eip=004714D9 ; 618D9 ; increase_tib
inc     edx ; not sure why original code says "dl" while edx is used before. "inc edx" is smaller.
mov     byte ptr [eax+7], dl
jmp     004714F1 ; refresh_tib
#eip=004714F1 ; 618F1
xor     edx, edx
call    004266F8        ; CellClass::Redraw_Objects(bool forced)
jmp     00468C0E

; ===========================================================
; German
; ===========================================================

; Add cell refresh to tiberium growth
#eip=00468E39 ; 59239
jmp     00471C49 ; increase_tib
#eip=00471C49 ; 62049 ; increase_tib
inc     edx ; not sure why original code says "dl" while edx is used before. "inc edx" is smaller.
mov     byte ptr [eax+7], dl
jmp     00471C61 ; refresh_tib
#eip=00471C61 ; 62061 ; refresh_tib
xor     edx, edx
call    004266F8        ; CellClass::Redraw_Objects(bool forced)
jmp     00468E3E

; ===========================================================
; French
; ===========================================================

; Add cell refresh to tiberium growth
#eip=00468E89 ; 59289
jmp     00471CB9 ; increase_tib
#eip=00471CB9 ; 620B9 ; increase_tib
inc     edx ; not sure why original code says "dl" while edx is used before. "inc edx" is smaller.
mov     byte ptr [eax+7], dl
jmp     00471CD1 ; refresh_tib
#eip=00471CD1 ; 620D1 ; refresh_tib
xor     edx, edx
call    004266F8        ; CellClass::Redraw_Objects(bool forced)
jmp     00468E8E

; ===========================================================
; Japanese
; ===========================================================

; Add cell refresh to tiberium growth
; See squish code for nearby empty space.
#eip=004697E9 ; 59BE9
jmp     004721A9 ; increase_tib
#eip=004721A9 ; 625A9 ; increase_tib
inc     edx ; not sure why original code says "dl" while edx is used before. "inc edx" is smaller.
mov     byte ptr [eax+7], dl
jmp     004721C1 ; refresh_tib
#eip=004721C1 ; 625C1 ; refresh_tib
xor     edx, edx
call    004266F8        ; CellClass::Redraw_Objects(bool forced)
jmp     004697EE
