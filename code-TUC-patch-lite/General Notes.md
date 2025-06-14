# C&C95 TUC Quick Fix Patch

General notes about this code

## 1. Context

These are all hacks applied to the four existing different-language executables from the Windows 95 edition of the first "Command & Conquer" game. The base files for these hacks are the "C&C95.exe" executables distributed in "Command & Conquer: The Ultimate Collection" bundle on Steam (though I guess the Origin versions will be the same).

The folder "TUC" has raw diff dumps (the result of the "fc /b" command) that give the differences between the original CD executables and the TUC versions. At this moment, they are clearly not rebuilt from code, but do have some hacks applied to them to remove CD-reading code and some obsolete hardware checks.

Note that some of the code in this folder (such as the zounds.mix fix and the fix for remix-only music not showing) rely on these pre-existing hacks, as they recycle areas of "dead code" caused by them.


## 2. Assembly quirks

The way this code is applied is by utilising a tool that converts assembler instructions to raw bytes, which are then copied into the executable at the correct location. However, the tool used to produce these bytes, "pd's x86 Assembler", is not public, and will not be supplied with the code.

Additionally, the tool has some quirks and bugs, which seems to make it unable to process certain instructions. Because of that, you may see certain instructions emulated as raw "db" byte instructions, often with an address or value argument supplied separately as "dd" value for ease of programming, like this:

    db A9 ; test eax, dword 0FF000000h
    dd      0FF000000h

Other tools might handle these better, but that's what I'm using, so I'm not going to explicitly filter these out for this repository.
