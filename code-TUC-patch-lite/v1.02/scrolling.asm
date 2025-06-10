; Fix for the fact the "Scrolling=restricted" secret option only restricts scrolling
; on the first half of the Options button and the last half of the sidebar button.
; This is a hardcoded DOS value, which should be replaced by the existing dynamic one.

; ===========================================================
; Source code equivalent:
; ===========================================================

; SCROLL.CPP -> void ScrollClass::AI(KeyNumType &input, int x, int y)
; In "noscroll" check, replace hardcoded 80-pixel "EVA_WIDTH" with "Eva_Width"
; The correct Eva_Width is inherited from TabClass, and filled in in TabClass::One_Time.

; ===========================================================
; English
; ===========================================================

#eip=00541C04
SeenBuff_Width:

#eip=004A43E4 ; 947E4
jmp     004A4331 ; check_first_button_end (fetches Eva_Width in ecx)
check_first_button_start:
cmp     ebx, 3
ja     .scroll_block
check_second_button:

mov     edx, :SeenBuff_Width
mov     ebx, edx
sub     ebx, ecx ; screen minus eva_width
db 8B ; mov ecx, [ebp-4] ; Mouse_X ; (bytes [8B 4D FC]; my asm tool doesn't seem to handle this one well.)
db 4D
db FC
cmp     ecx, ebx  ; mouse_X < screen minus eva_width -> no block
jle    .not_scroll_block
sub     edx, 3
cmp     edx, ecx  ; screen minus 3 > mouse_X -> block
jle    .not_scroll_block
scroll_block:
inc     eax
nop
nop
nop
not_scroll_block:

#eip=004A4331 ; 94731 ; check_first_button_end
mov     ecx, [esi+64Ch] ; Eva_width
cmp     ebx, ecx
jle     004A4329 ; jump to check_first_button_start
jmp    .check_second_button

#eip=004A4329 ; 94729
jmp    .check_first_button_start

; ===========================================================
; German
; ===========================================================

#eip=00541C04
SeenBuff_Width:

#eip=004A4D04 ; 95104
jmp     004A4C51 ; check_first_button_end (fetches Eva_Width in ecx)
check_first_button_start:
cmp     ebx, 3
ja     .scroll_block
check_second_button:

mov     edx, :SeenBuff_Width
mov     ebx, edx
sub     ebx, ecx ; screen minus eva_width
db 8B ; mov ecx, [ebp-4] ; Mouse_X ; (bytes [8B 4D FC]; my asm tool doesn't seem to handle this one well.)
db 4D
db FC
cmp     ecx, ebx  ; mouse_X < screen minus eva_width -> no block
jle    .not_scroll_block
sub     edx, 3
cmp     edx, ecx  ; screen minus 3 > mouse_X -> block
jle    .not_scroll_block
scroll_block:
inc     eax
nop
nop
nop
not_scroll_block:

#eip=004A4C51 ; 95051 ; check_first_button_end
mov     ecx, [esi+64Ch] ; Eva_width
cmp     ebx, ecx
jle     004A4C49 ; jump to check_first_button_start
jmp    .check_second_button

#eip=004A4C49 ; 95049
jmp    .check_first_button_start

; ===========================================================
; French
; ===========================================================

#eip=00541C04
SeenBuff_Width:

#eip=004A4E14 ; 95214
jmp     004A4D61 ; check_first_button_end (fetches Eva_Width in ecx)
check_first_button_start:
cmp     ebx, 3
ja     .scroll_block
check_second_button:

mov     edx, :SeenBuff_Width
mov     ebx, edx
sub     ebx, ecx ; screen minus eva_width
db 8B ; mov ecx, [ebp-4] ; Mouse_X ; (bytes [8B 4D FC]; my asm tool doesn't seem to handle this one well.)
db 4D
db FC
cmp     ecx, ebx  ; mouse_X < screen minus eva_width -> no block
jle    .not_scroll_block
sub     edx, 3
cmp     edx, ecx  ; screen minus 3 > mouse_X -> block
jle    .not_scroll_block
scroll_block:
inc     eax
nop
nop
nop
not_scroll_block:

#eip=004A4D61 ; 95161 ; check_first_button_end
mov     ecx, [esi+64Ch] ; Eva_width
cmp     ebx, ecx
jle     004A4D59 ; jump to check_first_button_start
jmp    .check_second_button

#eip=004A4D59 ; 95159
jmp    .check_first_button_start

; ===========================================================
; Japanese
; ===========================================================

#eip=00541C08
SeenBuff_Width:

#eip=004A55D4 ; 959D4
jmp     004A5521 ; check_first_button_end (fetches Eva_Width in ecx)
check_first_button_start:
cmp     ebx, 3
ja     .scroll_block
check_second_button:

mov     edx, :SeenBuff_Width
mov     ebx, edx
sub     ebx, ecx ; screen minus eva_width
db 8B ; mov ecx, [ebp-4] ; Mouse_X ; (bytes [8B 4D FC]; my asm tool doesn't seem to handle this one well.)
db 4D
db FC
cmp     ecx, ebx  ; mouse_X < screen minus eva_width -> no block
jle    .not_scroll_block
sub     edx, 3
cmp     edx, ecx  ; screen minus 3 > mouse_X -> block
jle    .not_scroll_block
scroll_block:
inc     eax
nop
nop
nop
not_scroll_block:

#eip=004A5521 ; 95921 ; check_first_button_end
mov     ecx, [esi+64Ch] ; Eva_width
cmp     ebx, ecx
jle     004A5519 ; jump to check_first_button_start
jmp    .check_second_button

#eip=004A5519 ; 95919
jmp    .check_first_button_start
