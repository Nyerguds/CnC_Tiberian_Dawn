# C&C95 TUC Quick Fix Patch - Manual

<p align="center">version 1.03<br/>
Created by Nyerguds<br/>
Release date: Nope-ember 0, 20XX</p>

## About this patch

This patch contains a number of fixes for the Ultimate Collection version of C&C95. It addresses the most common crash issues, as well as a number of smaller annoyances.

Additionally, it includes some quality-of-life upgrades, such as allowing drag-selecting to add more units to the current selection by holding the Shift key, drag-selecting flying aircraft, targeting the Guard Target cursor on the ground, and using the scrollwheel to go through the sidebar options.

This patch is specifically customised to match the way the game is packaged in Command & Conquer: The Ultimate Collection, so it will not have any customisable no-CD functionality; it always assumes to be running on a no-CD install. It does not contain any more elaborate upgrades like high resolution support, since that requires additional edits to the game files.

Note that unlike the "v1.06" project, this is not a full game patch including peripheral files; it only contains fixes on the exe file.

## Installation

To use this patch, overwrite the "C&C95.exe" in your game folder with the correct one from one of the "game-" subfolders, depending on the language in which you installed the game.

## Extra usage notes:

### Grenade sound:

As part of the fixes done in this patch, the previously unused grenade throw sound is now played. If this bothers anyone, the sound can be disabled by taking the file "ssnogren.mix" from the "extras" folder and putting it in the game folder.

### Special CONQUER.INI options:

In the "extras" folder, you can find "special-options.txt", which contains a set of secret developer switches that can be activated in the game by putting them in your CONQUER.INI file. A few of these are generally neat, such as the music remixes and showing true civilian names, but be warned that others, like disabling the "bib" pieces of buildings, can seriously mess up the game. Use these at your own risk.

### "Funpark" dinosaur campaign:

The game has a secret mini-campaign involving dinosaurs, which is normally unlocked by starting the game with the command line argument "funpark". However, command line arguments are tedious to work with in a Windows environment, and this option switched the entire game into a special mode, rather than just unlocking the campaign, which had some really odd side effects when loading existing savegames or starting expansion missions..

To resolve all this, the secret missions can now be accessed in a much simpler way: click "Start New Game", and on the "Select Transmission" screen, hold down the [Shift] key while clicking on the GDI or Nod logo.

### Console "Special Ops" missions:

The "extras" folder contains the two files "sc-n64-tuc.mix" and "sc-psx-tuc.mix". These are, respectively, the originally console-exclusive Nintendo 64 and Playstation "Special Ops" missions, which were also included in the remaster. Add them into your game folder, and you can access these missions in the "New Missions" menu.

As an added bonus, with the upgrades in v1.04 of this patch, the Orca's LASER weapon in the "PATSUX" mission is fully functional.

Note that these are not the 100% original versions; the Nintendo 64 missions were tweaked to fix some issues with base power and lack of rebuilding, and to align the tech with how it was on the Nintendo 64 console, all missions with base building have their tech levels increased to be equivalent to GDI mission 15.

Also note that these missions only have mission briefings in English.

### Extra remix tracks:

In the official soundtrack of the game, a bunch of the tracks have extra voices mixed into them. If the special CONQUER.INI option "Scores=remix" is enabled, the game will unlock these original mixes, making them replace the standard in-game versions. However, there are three tracks with such alternate soundtrack versions which are not included in the game, namely, "Just Do It Up!", "No Mercy" and "Deception" (aka, "We Will Stop Them"). In fact, in the Ion Cannon video, you can hear a short fragment of this version of "No Mercy".

The "extras" folder contains a file called "sc-remix.mix" which can be added into the game folder to amend this. The game itself is already adapted to recognise these tracks as possibly having a remix, so it will substitute them automatically when found, and show the correct length for the alternate version in the playlist.

### Full list of changes:

See [CHANGELOG.MD](CHANGELOG.MD)
