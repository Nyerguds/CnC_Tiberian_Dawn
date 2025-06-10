; Fix for the bug where deploying an MCV makes the used power get added twice.
; see https://github.com/TheAssemblyArmada/Vanilla-Conquer/issues/747

; ===========================================================
; Source code equivalent:
; ===========================================================

; UNIT.CPP -> bool UnitClass::Try_To_Deploy(void)
; Find "BuildingClass * building = new BuildingClass(STRUCT_CONST, House->Class->House);"
; In the "if (building)" block below that, add these two lines before the unlimbo call:
; building->Assign_Mission(MISSION_CONSTRUCTION);
; building->Commence();

; ===========================================================
; English
; ===========================================================

#eip=004B9642 ; A9A42
; deploy_fix_1
jmp     004B7B49
jmpback:
nop
nop
nop

#eip=004B7B49 ; A7F49
; deploy_fix_2
test    esi, esi
jz      004B7B53
jmp     004B7B58

#eip=004B7B53 ; A7F53
; deploy_fix_3
jmp      004B9726 ; end

#eip=004B7B58 ; A7F58
; deploy_fix_4
mov     ebx, [esi+8]
jmp     004E79E4 ; deploy_fix_5

#eip=004E79E4 ; D7DE4
; deploy_fix_5
mov     eax, esi
mov     edx, 11h ; MISSION_CONSTRUCTION
call    dword ptr [ebx+0F4h] ; __vt_BuildingClass+0F4h - Assign_Mission()
mov     eax, esi
call    dword ptr [ebx+0F8h] ; __vt_BuildingClass+0F8h - Commence()
jmp    .jmpback

; ===========================================================
; German
; ===========================================================

#eip=004B9F72
; deploy_fix_1
jmp     004B7B49
jmpback:
nop
nop
nop

#eip=004B7B49 ; A7F49
; deploy_fix_2
test    esi, esi
jz      004B7B53
jmp     004B7B58

#eip=004B7B53 ; A7F53
; deploy_fix_3
jmp      004B9726 ; end

#eip=004B7B58 ; A7F58
; deploy_fix_4
mov     ebx, [esi+8]
jmp     004E79E4 ; deploy_fix_3

#eip=004E79E4 ; D7DE4
; deploy_fix_5
mov     eax, esi
mov     edx, 11h ; MISSION_CONSTRUCTION
call    dword ptr [ebx+0F4h] ; __vt_BuildingClass+0F4h - Assign_Mission()
mov     eax, esi
call    dword ptr [ebx+0F8h] ; __vt_BuildingClass+0F8h - Commence()
jmp    .jmpback

; ===========================================================
; French
; ===========================================================

#eip=004BA082 ; AA482
jmp     004E84E4
jmpback:
nop
nop
nop

; Amazingly, the French exe has like 300 bytes free at the end of the code segment. No fragmentation needed!
#eip=004E84E4 ; D88E4
assign_mission:
test    esi, esi
jz      004BA166 ; end

mov     ebx, [esi+8]
mov     eax, esi
mov     edx, 11h ; MISSION_CONSTRUCTION
call    dword ptr [ebx+0F4h] ; __vt_BuildingClass+0F4h - Assign_Mission()
mov     eax, esi
call    dword ptr [ebx+0F8h] ; __vt_BuildingClass+0F8h - Commence()
jmp    .jmpback

; ===========================================================
; Japanese
; ===========================================================

#eip=004BA862 ; AAC62
; deploy_fix_1
jmp     004B8D69
jmpback:
nop
nop
nop

#eip=004B8D69 ; A9169
; deploy_fix_2
test    esi, esi
jz      004B8D73
jmp     004B8D78

#eip=004B8D73 ; A9173
; deploy_fix_3
jmp      004BA946 ; end

#eip=004B8D78 ; A9178
; deploy_fix_4
mov     ebx, [esi+8]
jmp     004E8BE4 ; deploy_fix_5

#eip=004E8BE4 ; D8FE4
; deploy_fix_5
mov     eax, esi
mov     edx, 11h ; MISSION_CONSTRUCTION
call    dword ptr [ebx+0F4h] ; __vt_BuildingClass+0F4h - Assign_Mission()
mov     eax, esi
call    dword ptr [ebx+0F8h] ; __vt_BuildingClass+0F8h - Commence()
jmp    .jmpback