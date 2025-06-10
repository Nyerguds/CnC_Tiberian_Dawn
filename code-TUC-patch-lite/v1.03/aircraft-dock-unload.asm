; Fix for aircraft giving double audio response when ordered to dock or unload.

; ===========================================================
; Source code equivalent:
; ===========================================================

; AIRCRAFT.CPP -> void AircraftClass::Active_Click_With(ActionType action, ObjectClass * object)
; Move the call to "FootClass::Active_Click_With(action, object);" to the "default:" case.

; ===========================================================
; English / German / French / Japanese
; ===========================================================

#eip=00415810 ; 5C10
jmp     004157E6
#eip=00415824 ; 5C24
jmp     004157E6
