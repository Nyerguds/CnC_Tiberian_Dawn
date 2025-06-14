
# Command & Conquer Patch Project

This repository contains buildable and working source code for Command & Conquer: Tiberian Dawn; the original first Command & Conquer game. It was [provided by Electronic Arts](https://github.com/electronicarts/CnC_Tiberian_Dawn).

This repository was forked from [a branch made by tomsons26](https://github.com/tomsons26/CnC_Tiberian_Dawn/tree/temp), in which he did most of the work of figuring out exactly how to set this up to get it all building.

The purpose of the Command & Conquer patch project is to fix bugs in the game, and possibly port in some Quality-Of-Life features from the C&C: Remastered source code.

## Compiling and Dependencies

The main game needs the following compilers and tools to function correctly:

Download sources of compiler requirements:

* [Watcom C/C++ (v10.6)](https://winworldpc.com/product/watcom-c-c/106) for C/C++ source files
* [Borland Turbo Assembler (TASM v4.0)](https://winworldpc.com/product/turbo-assembler/4x) for assembly files
* [Microsoft Micro Assembler (MASM v6.11d)](https://winworldpc.com/product/macro-assembler/6x) for assembly files
* [MS-DOS Player](http://takeda-toshiya.my.coocan.jp/msdos/) for invoking 16 bit TASM
* [DirectX 5 SDK](https://archive.org/details/idx5sdk)

The paths to each of these are set in `make.bat`, and can be adapted there. Their currently set values are folders in the `..` folder relative to the location of `make.bat`. All of them are configured there in a way that their main folder is referenced, not the `bin` subfolder that is generally actually used. For the MS-DOS Player, the path of `msdos.exe` should simply be set there.

## Compiling other languages

The game is available in four languages; English, German, French, and Japanese. To build a different-language version, you need to edit `CODE\DEFINES.H` and find the lines that define values for `GERMAN`, `FRENCH` and `JAPANESE`. Uncomment _one_ of the lines to build the game for that language. **Never** uncomment more than one of them; this will inevitably cause problems and duplicate code.

Obviously, the specific files for that language will be required. Each language has its own strings file (`conquer.eng` inside `cclocal.mix`) and videos (in `movies.mix`), and Japanese has some extra files (in `language.mix`) for its image-based briefing texts. The game is technically freeware, but the easiest way to get access to all these different-language files is probably to get [Command & Conquer: The Ultimate Collection on Steam](https://store.steampowered.com/bundle/39394/Command__Conquer_The_Ultimate_Collection/), which contains Command & Conquer 1 in all four languages, and allows users to freely switch between the different-language releases in the game's Steam settings.

## Contributing

Right now, I'm not really looking into making this a joint project. Specific bug reports and suggestions are always welcome though, but post them as issues.

## License

This repository and its contents are licensed under the GPL v3 license, with additional terms applied. Please see [LICENSE.md](LICENSE.md) for details.
