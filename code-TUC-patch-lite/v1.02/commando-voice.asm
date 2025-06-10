; Fix for Commando giving both a map sound and a response when Sabotaging.

; ===========================================================
; Source code equivalent:
; ===========================================================

; See github issue 682 on VanillaConquer:
; https://github.com/TheAssemblyArmada/Vanilla-Conquer/issues/682

; Since adding to the vtable is implausible in assembler, the below fix
; jumps straight to the infantry implementation.

; ===========================================================
; English
; ===========================================================

#eip=00418850 ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
Sound_Effect:
#eip=00447638 ; FixedHeapClass::ID(void *)
FixedHeapClass_ID:
#eip=0050520C ; allow voice
AllowVoice:
#eip=0053CD58 ; TFixedIHeapClass<InfantryClass> Infantry
InfantryHeap:
#eip=0053E6FC ; HouseClass *PlayerPtr
PlayerPtr:

#eip=004E5C58 ; D6058
response_choice_extra:
cmp     dl, 10h
jnz    .defaultvoice
call    004E5C80
retn
defaultvoice:
call    dword ptr [edi+190h] ; 004FDBB4 InfantryClass::Response_Move(void)
retn

#eip=004E5C6C ; D606C
sabotage_map_sound:
cmp     ebx, edx
jz     .skip_bomb_map_sound
mov     ebx, 1       ; voice set ID 0 (irrelevant, for commando voice)
mov     edx, [eax]   ; map location
xor     eax, eax     ; Commando bomb response
call   .Sound_Effect ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
skip_bomb_map_sound:
retn

; W?Response_Sabotage$:InfantryClass$n()v
#eip=004E5C80 ; D6080
response_sabotage:
push    ebx
push    edx
mov     ebx, eax
cmp     :AllowVoice, 0 ; audio_ready
jz     .voc_sabotage_end
mov     eax, .InfantryHeap ; pInfantryClass_Heap
mov     edx, ebx
; Retrieves the actual heap ID of this unit, and determines the voice set based on that.
; Vehicles use negative IDs.
call   .FixedHeapClass_ID ; FixedHeapClass::ID(void *)
; Increment by 1 so the value is never 0?
lea     ebx, [eax+1]
xor     edx, edx
xor     eax, eax
call   .Sound_Effect ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
voc_sabotage_end:
pop     edx
pop     ebx
retn

; in void TechnoClass::Player_Assign_Mission
; found just below InfantryClass::Response_Attack(void) in the vtable.
; plays response to commander
#eip=004B1AA0 ; A1EA0
nop
call   .response_choice_extra

; in void InfantryClass::Assign_Mission
; found about a page up from InfantryClass::Response_Attack(void) in the vtable.
; plays map sound
#eip=00451BEF ; 41FEF
mov     edx, [eax+48h]  ; get owner house ptr
mov     ebx, :PlayerPtr ; get player house ptr
call   .sabotage_map_sound ; eax = infantry object

; ===========================================================
; German
; ===========================================================

#eip=00418850 ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
Sound_Effect:
#eip=004477D8 ; FixedHeapClass::ID(void *)
FixedHeapClass_ID:
#eip=005052FC ; allow voice
AllowVoice:
#eip=0053CD58 ; TFixedIHeapClass<InfantryClass> Infantry
InfantryHeap:
#eip=0053E6FC ; HouseClass *PlayerPtr
PlayerPtr:

#eip=004E6648 ; D6A48
response_choice_extra:
cmp     dl, 10h
jnz    .defaultvoice
call    004E6670 ; InfantryClass::Response_Sabotage()
retn
defaultvoice:
call    dword ptr [edi+190h] ; 004FDBB4 InfantryClass::Response_Move(void)
retn

#eip=004E665C ; D6A5C
sabotage_map_sound:
cmp     ebx, edx
jz     .skip_bomb_map_sound
mov     ebx, 1       ; voice set ID 0 (irrelevant, for commando voice)
mov     edx, [eax]   ; map location
xor     eax, eax     ; Commando bomb response
call   .Sound_Effect ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
skip_bomb_map_sound:
retn

; W?Response_Sabotage$:InfantryClass$n()v
#eip=004E6670 ; D6A70 ; InfantryClass::Response_Sabotage()
response_sabotage:
push    ebx
push    edx
mov     ebx, eax
cmp     :AllowVoice, 0 ; audio_ready
jz     .voc_sabotage_end
mov     eax, .InfantryHeap ; pInfantryClass_Heap
mov     edx, ebx
; Retrieves the actual heap ID of this unit, and determines the voice set based on that.
; Vehicles use negative IDs.
call   .FixedHeapClass_ID ; FixedHeapClass::ID(void *)
; Increment by 1 so the value is never 0?
lea     ebx, [eax+1]
xor     edx, edx
xor     eax, eax
call   .Sound_Effect ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
voc_sabotage_end:
pop     edx
pop     ebx
retn

; in void TechnoClass::Player_Assign_Mission
; found just below InfantryClass::Response_Attack(void) in the vtable.
; plays response to commander
#eip=004B23D0 ; A27D0
nop
call   .response_choice_extra

; in void InfantryClass::Assign_Mission
; found about a page up from InfantryClass::Response_Attack(void) in the vtable.
; plays map sound
#eip=00451D8F ; 4218F
mov     edx, [eax+48h]  ; get owner house ptr
mov     ebx, :PlayerPtr ; get player house ptr
call   .sabotage_map_sound ; eax = infantry object

; ===========================================================
; French
; ===========================================================

#eip=00418850 ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
Sound_Effect:
#eip=00447848 ; FixedHeapClass::ID(void *)
FixedHeapClass_ID:
#eip=0050535C ; allow voice
AllowVoice:
#eip=0053CD58 ; TFixedIHeapClass<InfantryClass> Infantry
InfantryHeap:
#eip=0053E6FC ; HouseClass *PlayerPtr
PlayerPtr:

#eip=004E6748 ; D6B48
response_choice_extra:
cmp     dl, 10h
jnz    .defaultvoice
call    004E6770
retn
defaultvoice:
call    dword ptr [edi+190h] ; 004FDBB4 InfantryClass::Response_Move(void)
retn

#eip=004E675C ; D6B5C
sabotage_map_sound:
cmp     ebx, edx
jz     .skip_bomb_map_sound
mov     ebx, 1       ; voice set ID 0 (irrelevant, for commando voice)
mov     edx, [eax]   ; map location
xor     eax, eax     ; Commando bomb response
call   .Sound_Effect ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
skip_bomb_map_sound:
retn

#eip=004E6770 ; D6B70
response_sabotage:
push    ebx
push    edx
mov     ebx, eax
cmp     :AllowVoice, 0 ; audio_ready
jz     .voc_sabotage_end
mov     eax, .InfantryHeap ; pInfantryClass_Heap
mov     edx, ebx
; Retrieves the actual heap ID of this unit, and determines the voice set based on that.
; Vehicles use negative IDs.
call   .FixedHeapClass_ID ; FixedHeapClass::ID(void *)
; Increment by 1 so the value is never 0?
lea     ebx, [eax+1]
xor     edx, edx
xor     eax, eax
call   .Sound_Effect ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
voc_sabotage_end:
pop     edx
pop     ebx
retn

; in void TechnoClass::Player_Assign_Mission
; found just below InfantryClass::Response_Attack(void) in the vtable.
; plays response to commander
#eip=004B24E0 ; A28E0
nop
call   .response_choice_extra

; in void InfantryClass::Assign_Mission
; found about a page up from InfantryClass::Response_Attack(void) in the vtable.
; plays map sound
#eip=00451DFF ; 421FF
mov     edx, [eax+48h]  ; get owner house ptr
mov     ebx, :PlayerPtr ; get player house ptr
call   .sabotage_map_sound ; eax = infantry object

; ===========================================================
; Japanese
; ===========================================================

; open space: 004E6E98
#eip=00418850 ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
Sound_Effect:
#eip=00448098 ; FixedHeapClass::ID(void *)
FixedHeapClass_ID:
#eip=005053E0 ; allow voice
AllowVoice:
#eip=53CD5C ; TFixedIHeapClass<InfantryClass> Infantry
InfantryHeap:
#eip=0053E700 ; HouseClass *PlayerPtr
PlayerPtr:

#eip=004E6E98 ; D7298
response_choice_extra:
cmp     dl, 10h
jnz    .defaultvoice
call    004E6EC0
retn
defaultvoice:
call    dword ptr [edi+190h] ; 004FDBB4 InfantryClass::Response_Move(void)
retn

#eip=004E6EAC ; D72AC
sabotage_map_sound:
cmp     ebx, edx
jz     .skip_bomb_map_sound
mov     ebx, 1       ; voice set ID 0 (irrelevant, for commando voice)
mov     edx, [eax]   ; map location
xor     eax, eax     ; Commando bomb response
call   .Sound_Effect ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
skip_bomb_map_sound:
retn

#eip=004E6EC0 ; D72C0
response_sabotage:
push    ebx
push    edx
mov     ebx, eax
cmp     :AllowVoice, 0 ; audio_ready
jz     .voc_sabotage_end
mov     eax, .InfantryHeap ; pInfantryClass_Heap
mov     edx, ebx
; Retrieves the actual heap ID of this unit, and determines the voice set based on that.
; Vehicles use negative IDs.
call   .FixedHeapClass_ID ; FixedHeapClass::ID(void *)
; Increment by 1 so the value is never 0?
lea     ebx, [eax+1]
xor     edx, edx
xor     eax, eax
call   .Sound_Effect ; Sound_Effect(eax = VocType, edx = coord, ebx = variation)
voc_sabotage_end:
pop     edx
pop     ebx
retn

; in void TechnoClass::Player_Assign_Mission
; found just below InfantryClass::Response_Attack(void) in the vtable.
; plays response to commander
#eip=004B2CC0 ; A30C0
nop
call   .response_choice_extra

; in void InfantryClass::Assign_Mission
; found about a page up from InfantryClass::Response_Attack(void) in the vtable.
; plays map sound
#eip=0045264F ; 42A4F
mov     edx, [eax+48h]  ; get owner house ptr
mov     ebx, :PlayerPtr ; get player house ptr
call   .sabotage_map_sound ; eax = infantry object
