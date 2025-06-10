; Fixes for the funpark end quitting the game, for dinos being invisible,
; and for the dino units' animations not working outside Funpark mode.

; ===========================================================
; Source code equivalent:
; ===========================================================

; Funpark campaign end returns like Covert Ops missions do:
; SCENARIO.CPP -> void Do_Win(void)
; Find "if (Scenario >= 20)"
; Change to "if (Scenario >= 20 || (Special.IsJurassic && AreThingiesEnabled && Scenario == 5))"

; No Funpark mode needed to load dino graphics:
; UDATA.CPP -> void UnitTypeClass::One_Time(void)
; Find "_makepath(fullname, NULL, NULL, uclass.IniName, ".SHP");"
; Remove the "if" check around the block, and its "else" case.

; No Funpark mode needed for walk animations:
; UNIT.CPP -> void UnitClass::AI(void)
; Find "if (Class->IsPieceOfEight && Special.IsJurassic && AreThingiesEnabled)"
; Replace by "if (Class->IsPieceOfEight)"

; ===========================================================
; English
; ===========================================================

; Funpark campaign end returns like Covert Ops missions do:
#eip=0049B7E0 ; 8BBE0
jmp 0049B603 ; normal mission end for Covert Ops

; No Funpark mode needed to load dino graphics:
#eip=004B76F2 ; A7AF2
jmp 004B7705 ; ignore result from check; always jump to load code.

; No Funpark mode needed for walk animations:
#eip=004B7F98 ; A8398
jmp 004B7FAB ; ignore result from check on IsJurassic; always jump to handling code
dd 90909090h ; four NOPs (cleanup)

; ===========================================================
; German
; ===========================================================

; Funpark campaign end returns like Covert Ops missions do:
#eip=0049C101 ; 8C501
jmp 0049BF1F ; normal mission end for Covert Ops

; No Funpark mode needed to load dino graphics:
#eip=004B8022 ; A8422
jmp 004B8035 ; ignore result from check; always jump to load code.

; No Funpark mode needed for walk animations:
#eip=004B88C8 ; A8CC8
jmp 004B88DB ; ignore result from check on IsJurassic; always jump to handling code
dd 90909090h ; four NOPs (cleanup)

; ===========================================================
; French
; ===========================================================

; Funpark campaign end returns like Covert Ops missions do:
#eip=0049C211 ; 8C611
jmp 0049C02F ; normal mission end for Covert Ops

; No Funpark mode needed to load dino graphics:
#eip=004B8132 ; A8532
jmp 004B8145 ; ignore result from check; always jump to load code.

; No Funpark mode needed for walk animations:
#eip=004B89D8 ; A8DD8
jmp 004B89EB ; ignore result from check on IsJurassic; always jump to handling code
dd 90909090h ; four NOPs (cleanup)

; ===========================================================
; Japanese
; ===========================================================

; Funpark campaign end returns like Covert Ops missions do:
#eip=0049CC27 ; 8D027
jmp 0049CA4E ; normal mission end for Covert Ops

; No Funpark mode needed to load dino graphics:
#eip=004B8912 ; A8D12
jmp 004B8925 ; ignore result from check; always jump to load code.

; No Funpark mode needed for walk animations:
#eip=004B91B8 ; A95B8
jmp 004B91CB ; ignore result from check on IsJurassic; always jump to handling code
dd 90909090h ; four NOPs (cleanup)

