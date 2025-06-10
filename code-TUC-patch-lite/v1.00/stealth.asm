; Fix for the stealth animation crashing on the bottom line of pixels on the right side of the screen.
; Original fix designed by Komfr.

; ===========================================================
; Source code equivalent:
; ===========================================================

; KEYBUFF.ASM -> PROC Buffer_Frame_To_Page C near
; In all the "BF_Predator" blocks, before the "shr ebx , 5", this should be added:

; dec edx
; jnz ??pr_boundary_ok
; epilogue
; ret
; ??pr_boundary_ok:

; Note that all parts have their own label naming; the above is for the "BF_Predator" part,
; but for "BF_Predator_Fading", the internal label will be "pr_f_boundary_ok"

; ===========================================================
; English
; ===========================================================

#eip=00411C94
stealth_fix:
jz      00411CA4
shr     ebx, 5
shr     ecx, 5
retn
#eip=00411CA4
mov     dword ptr [esp+0], 0045E219
retn

#eip=0045FD4D ; 5014D
dec  edx
call 00411C94
#eip=00460614 ; 50A14
dec  edx
call 00411C94
#eip=00460F5B ; 5135B
dec  edx
call 00411C94
#eip=00461B42 ; 51F42
dec  edx
call 00411C94
#eip=004627A9 ; 52BA9
dec  edx
call 00411C94
#eip=004631F9 ; 535F9
dec  edx
call 00411C94
#eip=00463CC9 ; 540C9
dec  edx
call 00411C94
#eip=00464A39 ; 54E39
dec  edx
call 00411C94

; ===========================================================
; German
; ===========================================================

#eip=00411C94
stealth_fix:
jz      00411CA4
shr     ebx, 5
shr     ecx, 5
retn
#eip=00411CA4
mov     dword ptr [esp+0], 0045E449
retn

#eip=0045FF7D ; 5037D
dec  edx
call 00411C94
#eip=00460844 ; 50C44
dec  edx
call 00411C94
#eip=0046118B ; 5158B
dec  edx
call 00411C94
#eip=00461D72 ; 52172
dec  edx
call 00411C94
#eip=004629D9 ; 52DD9
dec  edx
call 00411C94
#eip=00463429 ; 53829
dec  edx
call 00411C94
#eip=00463EF9 ; 542F9
dec  edx
call 00411C94
#eip=00464C69 ; 55069
dec  edx
call 00411C94

; ===========================================================
; French
; ===========================================================

#eip=00411C94
stealth_fix:
jz      00411CA4
shr     ebx, 5
shr     ecx, 5
retn
#eip=00411CA4
mov     dword ptr [esp+0], 0045E499
retn

#eip=0045FFCD ; 503CD
dec  edx
call 00411C94
#eip=00460894 ; 50C94
dec  edx
call 00411C94
#eip=004611DB ; 515DB
dec  edx
call 00411C94
#eip=00461DC2 ; 521C2
dec  edx
call 00411C94
#eip=00462A29 ; 52E29
dec  edx
call 00411C94
#eip=00463479 ; 53879
dec  edx
call 00411C94
#eip=00463F49 ; 54349
dec  edx
call 00411C94
#eip=00464CB9 ; 550B9
dec  edx
call 00411C94

; ===========================================================
; Japanese
; ===========================================================

#eip=00411C94
stealth_fix:
jz      00411CA4
shr     ebx, 5
shr     ecx, 5
retn
#eip=00411CA4
mov     dword ptr [esp+0], 0045EDC9
retn

#eip=004608FD ; 50CFD
dec     edx
call    00411C94
#eip=004611C4 ; 515C4
dec     edx
call    00411C94
#eip=00461B0B ; 51F0B
dec     edx
call    00411C94
#eip=004626F2 ; 52AF2
dec     edx
call    00411C94
#eip=00463359 ; 53759
dec     edx
call    00411C94
#eip=00463DA9 ; 541A9
dec     edx
call    00411C94
#eip=00464879 ; 54C79
dec     edx
call    00411C94
#eip=004655E9 ; 559E9
dec     edx
call   00411C94
