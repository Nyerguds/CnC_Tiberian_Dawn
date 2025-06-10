; Fix for grenade sound not working because it is called TOSS1, not TOSS

; ===========================================================
; Source code equivalent:
; ===========================================================

; AUDIO.CPP -> SoundEffectName[VOC_COUNT]
; Replace "TOSS" by "TOSS1"

; ===========================================================
; English
; ===========================================================
#eip=004F068D ; D848D
db 00
grenade_toss:
ds      "TOSS1"

#eip=005027C5 ; EA5C5
dd     .grenade_toss

; ===========================================================
; German
; ===========================================================

#eip=004F068D ; D8E8D
db 00
grenade_toss:
ds      "TOSS1"

#eip=005028B5 ; EB0B5
dd     .grenade_toss

; ===========================================================
; French
; ===========================================================

#eip=004F068D ; D908D
db 00
grenade_toss:
ds      "TOSS1"

#eip=00502915 ; EB315
dd     .grenade_toss

; ===========================================================
; Japanese
; ===========================================================

#eip=004F068D ; D968D
db 00
grenade_toss:
ds      "TOSS1"

#eip=00502985 ; EB985
dd     .grenade_toss
