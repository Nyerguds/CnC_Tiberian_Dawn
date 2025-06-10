; Fix for damaged states being wrong on power plants and Oil Pump.

; ===========================================================
; Source code equivalent:
; ===========================================================

; A. Fix for both power plant types not animating when damaged:
; BDATA.CPP -> static BuildingTypeClass const ClassPower
; Change the option "Simple (one frame) damage imagery?" to "false".
; BDATA.CPP -> static BuildingTypeClass const ClassAdvancedPower
; Change the option "Simple (one frame) damage imagery?" to "false".

; B. Fix ARCO damaged frame not working, by taking the halfway point as damaged anim, rather than "amount minus 2":
; BUILDING.CPP -> void BuildingClass::Draw_It(int x, int y, WindowNumberType window)
; find "shapenum = Get_Build_Frame_Count(shapefile) - 2;"
; replace with "shapenum = Get_Build_Frame_Count(shapefile) / 2;"

; ===========================================================
; English / French / German / Japanese
; ===========================================================

; Power Plant "simple damage imagery" option
#eip=0041A082 ; A482
push    0
; Advanced Power Plant "simple damage imagery" option
#eip=0041A105 ; A505
push    0
; Take halfway-frame as damaged state rather than "amount of frames - 2"
#eip=0041CC30 ; D030
nop
shr     edi, 1
