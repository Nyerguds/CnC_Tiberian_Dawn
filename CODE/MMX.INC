.486P

DefineMMxRegs Macro
	mm0	TEXTEQU	<EAX>
	mm1	TEXTEQU	<ECX>
EndM

UnDefineMMxRegs Macro
	mm0	TEXTEQU	<mm0>
	mm1	TEXTEQU	<mm1>
EndM

emms     macro
	db	0fh, 077h
endm

movq   macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
IF (OPATTR(dst)) AND 00010000y ; register
x:
        cmpxchg   src, dst
y:
        org     x+1
        byte    06fh
        org     y
ELSE
x:
        cmpxchg   dst, src
y:
        org     x+1
        byte    07fh
        org     y
ENDIF
		UnDefineMMxRegs
        endm

pand    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        byte    0dbh
        org     y
		UnDefineMMxRegs
        endm

pcmpeqb    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        byte    074h
        org     y
		UnDefineMMxRegs
        endm

por    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        byte    0ebh
        org     y
		UnDefineMMxRegs
        endm

pxor    macro   dst:req, src:req
        local   x, y
		DefineMMxRegs
x:
        cmpxchg   src, dst
y:
        org     x+1
        byte    0efh
        org     y
		UnDefineMMxRegs
        endm
