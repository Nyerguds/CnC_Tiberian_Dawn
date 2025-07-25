# Command & Conquer Patch Project - Manual

<p align="center">version 1.04<br/>
Created by Nyerguds<br/>
Release date: Nope-ember 0, 20XX</p>

## About this patch

This patch contains a number of fixes for the Ultimate Collection version of C&C95. It addresses the most common crash issues, as well as a number of smaller annoyances.

Additionally, it includes some quality-of-life upgrades, such as allowing drag-selecting to add more units to the current selection by holding the Shift key, drag-selecting flying aircraft, targeting the Guard Target cursor on the ground, and using the scrollwheel to go through the sidebar options.

This patch is specifically designed to match the way the game is packaged in Command & Conquer: The Ultimate Collection, so it will not have any customisable no-CD functionality; it always assumes to be running on a no-CD install. It does not contain any more elaborate upgrades like high resolution support, since that requires additional edits to the game files.

Note that unlike the "v1.06" project, this is not a full game patch including peripheral files; it only contains fixes on the exe file.

## Installation

To use this patch, overwrite the "C&C95.exe" in your game folder with the correct one from one of the "game-" subfolders, depending on the language in which you installed the game.

## Added or modified controls

These hotkeys have been added or changed:

* \[D\]: Deploy any unit inside the current selection that has a deploy or unload ability.
* \[E\]: Select all units on the current screen. This can be combined with the \[Shift\] key to add these to the selection.
* \[G\]: This hotkey (Area Guard) already existed, but can now be used to make harvesters seek out nearby tiberium.
* \[T\]: Select all units on the current screen of the type(s) you already have selected. This can be combined with the \[Shift\] key to add these to the selection.
* \[Ctrl\]+\[Alt\]: This modifier key combination for mouse clicks already existed to target objects, but can now be targeted at the ground, as targeted version of the Area Guard command. As with the hotkey, this also works for harvesters. Note that some units, such as Commandos and Helicopters, do not support Area Guard orders at all.
* \[Alt\]+\[Shift\]+\[0-9\]: Adds the numbered team to the selection and then centers on the selection.
* \[Ctrl\]+\[S\]: Saves a screenshot to the game folder, in PCX format.

General upgrades to selection and giving orders:

* Drag-selection now supports holding down the \[Shift\] key to add units to the current selection.
* Drag-selection can now be used to select aircraft in mid-air.
* Deploying a unit by clicking on it now works even if other units are selected along with it. To override this behaviour to load infantry into a partially-loaded transport, the \[Alt\] key can be used.
* Multiple infantry units can now load into a transport with a single click.
* If an APC is busy firing at an enemy, this will no longer obstruct the loading of infantry.
* When targeting a wall, you will always get an Attack cursor if any of the selected units can attack the wall.
* Harvesting and Area Guard orders now work on the minimap.

Other control upgrades:

* You can now press \[Escape\] to fast-forward the animations on the map selection screen and the score screen.
* You can use the scroll wheel to go through the sidebar items.

## Added features that can be disabled

This patch adds a number of extra features into the game. These are generally unobtrusive, but if you absolutely don't want them, you can disable them.

### Sidebar building power tooltips

On the sidebar, the building tooltips will now give extra info behind the price, in the format "~+##/-##", with the ## parts indicating respectively the amount of power the building produces and drains. Additionally, " (!)" will be added to the end of this if adding this building to your base would cause a blackout.

This behaviour is enabled by default, but can be disabled by adding the option "NoPowerToolTips=true" in conquer.ini, under \[Options\].

### Nod-specific map and score screen music

The game contains two unused music tracks that were intended to be Nod-specific music for the mission selection map and the score screen. These tracks always existed in the game, but were never enabled. This patch implements that music as it was intended.

This behaviour is enabled by default, but can be disabled by adding the option "NoNodSceneMusic=true" in conquer.ini, under \[Options\].

## Extra usage notes

### "Funpark" dinosaur campaign

The game has a secret mini-campaign involving dinosaurs, which is normally unlocked by starting the game with the command line argument "funpark". However, command line arguments are tedious to work with in a Windows environment, and this option switched the entire game into a special mode, rather than just unlocking the campaign, which had some really odd side effects when loading existing savegames or starting expansion missions.

To resolve all this, the secret missions can now be accessed in a much simpler way: click "Start New Game", and **on the "Select Transmission" screen, hold down the \[Shift\] key** while clicking on the GDI or Nod logo.

### Console "Special Ops" missions

The "**extras**" folder contains the two files "**sc-n64-tuc.mix**" and "**sc-psx-tuc.mix**". These are, respectively, the originally console-exclusive Nintendo 64 and Playstation "Special Ops" missions, which were also included in the remaster. Add them into your game folder, and you can access these missions in the "New Missions" menu.

As an added bonus, with the upgrades in v1.04 of this patch, the Orca's LASER weapon in the "PATSUX" mission is fully functional.

Note that the Nintendo 64 missions do not completely match the original console versions; they were tweaked to fix some issues with base power and lack of rebuilding. To align the tech with how it was on the Nintendo 64 console, all missions with base building have their tech levels increased to be equivalent to GDI mission 15.

Also note that these missions only have mission briefings in English.

### Extra remix tracks

In the official soundtrack of the game, a bunch of the tracks have extra voices mixed into them. If the special CONQUER.INI option "**Scores=remix**" is enabled, the game will unlock these original mixes, making them replace the standard in-game versions. However, there are three tracks with such alternate soundtrack versions which are not included in the game, namely, "Just Do It Up!", "No Mercy" and "Deception" (aka, "We Will Stop Them"). In fact, in the Ion Cannon video, you can hear a short fragment of this version of "No Mercy".

The "**extras**" folder contains a file called "**sc-remix.mix**" which can be added into the game folder to amend this. The game itself is already adapted to recognise these tracks as possibly having a remix, so it will substitute them automatically when found, and show the correct length for the alternate version in the playlist.

### Grenade sound

As part of the fixes done in this patch, the previously unused grenade throw sound is now played. If this bothers anyone, the sound can be disabled by taking the file "**ssnogren.mix**" from the "**extras**" folder and putting it in the game folder.

### Special CONQUER.INI options

In the "**extras**" folder, you can find "**special-options.txt**", which contains a set of secret developer switches that can be activated in the game by putting them in your CONQUER.INI file, under the \[Options\] section. A few of these are generally neat, such as the music remixes and showing true civilian names, but be warned that others, like disabling the "bib" pieces of buildings, can seriously mess up the game. Use these at your own risk.

## Full list of changes

See [CHANGELOG.MD](CHANGELOG.MD)
