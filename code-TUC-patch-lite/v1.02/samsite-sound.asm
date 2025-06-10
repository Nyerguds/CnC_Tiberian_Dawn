; Fix for the SAM Site not playing a sound when firing

; ===========================================================
; Source code equivalent:
; ===========================================================

; BUILDING.CPP -> BulletClass * BuildingClass::Fire_At(TARGET target, int which)
; Move the "Sound_Effect" line (and its comment) to above the STRUCT_SAM check

; ===========================================================
; English / German / French / Japanese
; ===========================================================

#eip=00417938 ; AnimClass_New
AnimClass_New:
#eip=0041796C ; AnimClass_AnimClass
AnimClass_AnimClass:
#eip=00417DE4 ; AnimClass_Attach_To
AnimClass_Attach_To:
#eip=00418850 ; Sound_Effect
Sound_Effect:

; length should be 7F
#eip=0041D0BD ; D4BD
; this chunk of code was at the bottom, and has been moved up here.
db 8B ; mov eax, [ebp-14h]
db 45
db EC
mov     ebx, 1
mov     eax, [eax+4]
mov     edx, [esi]
sar     eax, 18h
call   .Sound_Effect

mov     eax, [esi+60h]
mov     al, [eax+54h]
lea     edx, [esi+55h]
movsx   eax, al
db 89 ; mov [ebp-18h], edx
db 55
db E8
cmp     eax, 0Ah ; SAM Site
jnz    .not_SAM

mov     eax, 2Eh
call   .AnimClass_New

mov     edi, eax
test    eax, eax
jz     .check_anim
push    0
mov     edx, [esi+8]
push    1
mov     eax, esi
db 8B ; mov ebx, [ebp-18h]
db 5D
db E8
call    dword ptr [edx+8]

mov     edx, 10h
mov     bl, [ebx]
add     dl, bl
and     edx, 0FFh
mov     ebx, eax
sar     edx, 5
xor     ecx, ecx
add     dl, 2Ah
mov     eax, edi
movsx   edx, dl
call   .AnimClass_AnimClass
check_anim:
test    eax, eax
jz      0041D4A1 ; end
mov     edx, esi
call   .AnimClass_Attach_To
jmp     0041D4A1 ; end

not_SAM:
