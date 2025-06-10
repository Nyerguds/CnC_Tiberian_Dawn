; Fix for the fact the radar minimap is always zoomed in by default.

; ===========================================================
; Source code equivalent:
; ===========================================================

; RADAR.CPP -> void RadarClass::Init_Clear(void)
; Change "IsZoomed = false;" to "IsZoomed = true;"
; The following call to "Zoom_Mode" toggles it, so it initialises it with zoom disabled.

; ===========================================================
; English
; ===========================================================

#eip=00494754 ; 84B54
or     dl, byte 80h ; enable zoomed mode so Zoom_Mode call after it disables it.

; ===========================================================
; German
; ===========================================================

#eip=00495084 ; 85484
or     dl, byte 80h ; enable zoomed mode so Zoom_Mode call after it disables it.

; ===========================================================
; French
; ===========================================================

#eip=00495194 ; 85594
or     dl, byte 80h ; enable zoomed mode so Zoom_Mode call after it disables it.

; ===========================================================
; Japanese
; ===========================================================

#eip=00495B54 ; 85F54
or     dl, byte 80h ; enable zoomed mode so Zoom_Mode call after it disables it.
