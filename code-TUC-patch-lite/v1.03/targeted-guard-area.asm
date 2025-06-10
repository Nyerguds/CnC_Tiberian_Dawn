; Fix for the fact Guard Area can't be targeted on the ground.

; ===========================================================
; Source code equivalent:
; ===========================================================

; FOOT.CPP -> void FootClass::Active_Click_With(ActionType action, CELL cell)
; Add case "ACTION_GUARD_AREA:" (with break) with this code:
; Player_Assign_Mission(MISSION_GUARD_AREA, ::As_Target(cell));
; To make it more fancy, the ANIM_MOVE_FLASH code from ACTION_MOVE could be
; added as well, but the asm hack does not have that due to space constraints.

; NOTE: the remaster code for this has checks on "Can_Player_Fire()" and
; "Can_Player_Move()", but these are pointless, since TechnoClass::What_Action
; already checks that before even allowing the cursor.
; Also, for some reason, the remaster doesn't add the move flash either.

; ===========================================================
; English
; ===========================================================

; To locate FootClass::Active_Click_With, look for a "Queue Add failed Count"
; string with "foot.cpp" above it.

#eip=00440A71
action_abort:

#eip=00440A7E
action_attack_2:

; switch case changes
#eip=00440938 ; 30D38
dd     .action_abort
dd     .action_abort

#eip=00440A95 ; 30E95
jmp    .action_abort
check_guard_area:
cmp     al, 12h ; ACTION_GUARD_AREA is 13, but al was decreased by 1
jnz    .action_abort
; Should be safe; the value is never read as the full edx, and Player_Assign_Mission does a "movsx" on it.
mov     dl, 9
jmp    .action_attack_2 ; Attack case, after assigning edx

#eip=0044095C ; 30D5C
ja     .check_guard_area

; ===========================================================
; German
; ===========================================================

#eip=00440C11
action_abort:

#eip=00440C1E
action_attack_2:

; switch case changes
#eip=00440AD8 ; 30ED8
dd     .action_abort
dd     .action_abort

#eip=00440C35 ; 31035
jmp    .action_abort
check_guard_area:
cmp     al, 12h ; ACTION_GUARD_AREA is 13, but al was decreased by 1
jnz    .action_abort
; Should be safe; the value is never read as the full edx, and Player_Assign_Mission does a "movsx" on it.
mov     dl, 9
jmp    .action_attack_2 ; Attack case, after assigning edx

#eip=00440AFC ; 30EFC
ja     .check_guard_area

; ===========================================================
; French
; ===========================================================

#eip=00440C61
action_abort:

#eip=00440C6E
action_attack_2:

; switch case changes
#eip=00440B28 ; 30F28
dd     .action_abort
dd     .action_abort

#eip=00440C85 ; 31085
jmp    .action_abort
check_guard_area:
cmp     al, 12h ; ACTION_GUARD_AREA is 13, but al was decreased by 1
jnz    .action_abort
; Should be safe; the value is never read as the full edx, and Player_Assign_Mission does a "movsx" on it.
mov     dl, 9
jmp    .action_attack_2 ; Attack case, after assigning edx

#eip=00440B4C ; 30F4C
ja     .check_guard_area

; ===========================================================
; Japanese
; ===========================================================

#eip=004414B1
action_abort:

#eip=004414BE
action_attack_2:

; switch case changes
#eip=00441378 ; 31778
dd     .action_abort
dd     .action_abort

#eip=004414D5 ; 318D5
jmp    .action_abort
check_guard_area:
cmp     al, 12h ; ACTION_GUARD_AREA is 13, but al was decreased by 1
jnz    .action_abort
; Should be safe; the value is never read as the full edx, and Player_Assign_Mission does a "movsx" on it.
mov     dl, 9
jmp    .action_attack_2 ; Attack case, after assigning edx

#eip=0044139C ; 3179C
ja     .check_guard_area
