; Fix for Hospital's name not showing to enemies despite it being a special building.

; ===========================================================
; Source code equivalent:
; ===========================================================

; BDATA.CPP -> int BuildingTypeClass::Full_Name(void) const
; To the list of exceptions, add  " || Type == STRUCT_HOSPITAL"

; BDATA.CPP -> static BuildingTypeClass const ClassHospital
; Change the option "Always use the given name for the building?" to "true".

; ===========================================================
; English
; ===========================================================

; in BuildingTypeClass const ClassHospital:
#eip=0041A18F ; A58F
push    1 ; IsNominal

; Note: code is identical, just the values at the top, and the special "prison" and "Civilian Building" string indices differ.
#eip=0041A18F ; A58F
#eip=0053E4A8
nScenario_number:
#eip=0053CB60
debug_map:
#eip=0053E4A0
SpecialOpts_1:
#eip=004120A8 ; int const AbstractTypeClass::Full_Name(void)
AbstractTypeClass_Full_Name:

; int const BuildingTypeClass::Full_Name(void)
#eip=0041C330 ; C730
push    edx
mov     edx, [eax+51h]
sar     edx, 18h
cmp     :nScenario_number, 3
jnz    .not_mission_3
cmp     edx, 16h        ; Tech Center
jnz    .not_mission_3
mov     eax, 2BAh       ; "Prison"
pop     edx
retn
not_mission_3:
test    byte ptr [eax+20h], 4 ; IsNominal
jz     .call_Full_Name
test    byte :SpecialOpts_1, 40h ; Special.IsNamed
jnz    .call_Full_Name
test    byte ptr [eax+47h], 2 ; IsWall
jnz    .call_Full_Name
cmp     :debug_map, 0
jnz    .call_Full_Name
cmp     edx, 2Dh        ; STRUCT_V23
jz     .call_Full_Name
cmp     edx, 34h        ; STRUCT_V30
jz     .call_Full_Name
cmp     edx, 16h        ; STRUCT_MISSION
jz     .call_Full_Name
cmp     edx, 12h        ; STRUCT_BIO_LAB
jz     .call_Full_Name
cmp     edx, 0Eh        ; STRUCT_HOSPITAL
jnz    .override_civ_name
call_Full_Name:
call   .AbstractTypeClass_Full_Name
pop     edx
retn
override_civ_name:
mov     eax, 289h       ; "Civilian Building"
pop     edx
retn
db 0

; ===========================================================
; German
; ===========================================================

; in BuildingTypeClass const ClassHospital:
#eip=0041A18F ; A58F
push    1 ; IsNominal

#eip=0053E4A8
nScenario_number:
#eip=0053CB60
debug_map:
#eip=0053E4A0
SpecialOpts_1:
#eip=004120A8 ; int const AbstractTypeClass::Full_Name(void)
AbstractTypeClass_Full_Name:

; int const BuildingTypeClass::Full_Name(void)
#eip=0041C330 ; C730
push    edx
mov     edx, [eax+51h]
sar     edx, 18h
cmp     :nScenario_number, 3
jnz    .not_mission_3
cmp     edx, 16h        ; Tech Center
jnz    .not_mission_3
mov     eax, 2BCh       ; "Prison"
pop     edx
retn
not_mission_3:
test    byte ptr [eax+20h], 4 ; IsNominal
jz     .call_Full_Name
test    byte :SpecialOpts_1, 40h ; Special.IsNamed
jnz    .call_Full_Name
test    byte ptr [eax+47h], 2 ; IsWall
jnz    .call_Full_Name
cmp     :debug_map, 0
jnz    .call_Full_Name
cmp     edx, 2Dh        ; STRUCT_V23
jz     .call_Full_Name
cmp     edx, 34h        ; STRUCT_V30
jz     .call_Full_Name
cmp     edx, 16h        ; STRUCT_MISSION
jz     .call_Full_Name
cmp     edx, 12h        ; STRUCT_BIO_LAB
jz     .call_Full_Name
cmp     edx, 0Eh        ; STRUCT_HOSPITAL
jnz    .override_civ_name
call_Full_Name:
call   .AbstractTypeClass_Full_Name
pop     edx
retn
override_civ_name:
mov     eax, 28Ah       ; "Civilian Building"
pop     edx
retn
db 0

; ===========================================================
; French
; ===========================================================

; in BuildingTypeClass const ClassHospital:
#eip=0041A18F ; A58F
push    1 ; IsNominal

#eip=0053E4A8
nScenario_number:
#eip=0053CB60
debug_map:
#eip=0053E4A0
SpecialOpts_1:
#eip=004120A8 ; int const AbstractTypeClass::Full_Name(void)
AbstractTypeClass_Full_Name:

; int const BuildingTypeClass::Full_Name(void)
#eip=0041C330 ; C730
push    edx
mov     edx, [eax+51h]
sar     edx, 18h
cmp     :nScenario_number, 3
jnz    .not_mission_3
cmp     edx, 16h        ; Tech Center
jnz    .not_mission_3
mov     eax, 2BCh       ; "Prison"
pop     edx
retn
not_mission_3:
test    byte ptr [eax+20h], 4 ; IsNominal
jz     .call_Full_Name
test    byte :SpecialOpts_1, 40h ; Special.IsNamed
jnz    .call_Full_Name
test    byte ptr [eax+47h], 2 ; IsWall
jnz    .call_Full_Name
cmp     :debug_map, 0
jnz    .call_Full_Name
cmp     edx, 2Dh        ; STRUCT_V23
jz     .call_Full_Name
cmp     edx, 34h        ; STRUCT_V30
jz     .call_Full_Name
cmp     edx, 16h        ; STRUCT_MISSION
jz     .call_Full_Name
cmp     edx, 12h        ; STRUCT_BIO_LAB
jz     .call_Full_Name
cmp     edx, 0Eh        ; STRUCT_HOSPITAL
jnz    .override_civ_name
call_Full_Name:
call   .AbstractTypeClass_Full_Name
pop     edx
retn
override_civ_name:
mov     eax, 28Ah       ; "Civilian Building"
pop     edx
retn
db 0

; ===========================================================
; Japanese
; ===========================================================

; in BuildingTypeClass const ClassHospital:
#eip=0041A18F ; A58F
push    1 ; IsNominal

#eip=0053E4AC
nScenario_number:
#eip=0053CB64
debug_map:
#eip=0053E4A4
SpecialOpts_1:
#eip=004120A8 ; int const AbstractTypeClass::Full_Name(void)
AbstractTypeClass_Full_Name:

; int const BuildingTypeClass::Full_Name(void)
#eip=0041C330 ; C730
push    edx
mov     edx, [eax+51h]
sar     edx, 18h
cmp     :nScenario_number, 3
jnz    .not_mission_3
cmp     edx, 16h        ; Tech Center
jnz    .not_mission_3
mov     eax, 2BAh       ; "Prison"
pop     edx
retn
not_mission_3:
test    byte ptr [eax+20h], 4 ; IsNominal
jz     .call_Full_Name
test    byte :SpecialOpts_1, 40h ; Special.IsNamed
jnz    .call_Full_Name
test    byte ptr [eax+47h], 2 ; IsWall
jnz    .call_Full_Name
cmp     :debug_map, 0
jnz    .call_Full_Name
cmp     edx, 2Dh        ; STRUCT_V23
jz     .call_Full_Name
cmp     edx, 34h        ; STRUCT_V30
jz     .call_Full_Name
cmp     edx, 16h        ; STRUCT_MISSION
jz     .call_Full_Name
cmp     edx, 12h        ; STRUCT_BIO_LAB
jz     .call_Full_Name
cmp     edx, 0Eh        ; STRUCT_HOSPITAL
jnz    .override_civ_name
call_Full_Name:
call   .AbstractTypeClass_Full_Name
pop     edx
retn
override_civ_name:
mov     eax, 289h       ; "Civilian Building"
pop     edx
retn
db 0
