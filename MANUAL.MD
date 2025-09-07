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

* **\[D\]**: Deploy any unit inside the current selection that has a deploy or unload ability, at their currect location. Transport helicopters are not allowed to do this while flying over unrevealed terrain.
* **\[E\]**: Select all units on the current screen. This can be combined with the \[Shift\] key to add these to the selection.
* **\[G\]**: This hotkey (Area Guard) already existed, but can now be used to make harvesters seek out nearby tiberium.
* **\[S\]**: This hotkey (Stop) already existed, but now works for stopping defense buildings, as it was in early DOS versions. This can be useful if they were ordered to force-fire on something.
* **\[T\]**: Select all units on the current screen of the type(s) you already have selected. This can be combined with the \[Shift\] key to add these to the selection. If no units of the selected types were found on the screen, the old selection is retained.
* **\[Ctrl\]+\[Alt\]**: This modifier key combination for mouse clicks already existed to target objects, but can now be targeted at the ground, as targeted version of the Area Guard command. As with the hotkey, this also works for harvesters. Note that some units, such as Commandos and Helicopters, do not support Area Guard orders at all.
* **\[Alt\]+\[Shift\]+\[0-9\]**: Adds the numbered team to the selection and then centers on the selection.
* **\[Ctrl\]+\[S\]**: Saves a screenshot to the game folder, in PCX format. A "click" sound will indicate that a screenshot was taken, and a message will show what filename it was saved to. The message can be disabled by adding "NoScreenshotMessage=true" into conquer.ini, under \[Patch\].

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
* You can use the mouse scroll wheel to go through the sidebar items. This will scroll the specific strip you're hovering the mouse over.
* Item lists such as the New Missions menu and the music list now support PageUp, PageDown, Home, End, and the mouse scroll wheel.

## Added features that can be disabled

This patch adds a number of extra features into the game. These are generally unobtrusive, but if you absolutely don't want them, you can disable them.

### Sidebar building power tooltips

On the sidebar, the building tooltips will now give extra info behind the price, in the format "~+##/-##", with the ## parts indicating respectively the amount of power the building produces and drains. Additionally, " (!)" will be added to the end of this if adding this building to your base would cause a blackout.

This behaviour is enabled by default, but can be disabled by adding the option "NoPowerToolTips=true" in conquer.ini, under \[Patch\].

### Nod-specific map and score screen music

The game contains two unused music tracks that were intended to be Nod-specific music for the mission selection map and the score screen. These tracks always existed in the game, but were never enabled. This patch implements that music as it was intended.

This behaviour is enabled by default, but can be disabled by adding the option "NoNodSceneMusic=true" in conquer.ini, under \[Patch\].

### Rocket Launcher targeting

The Rocket Launcher vehicle contains two stages for its launcher; collapsed onto the flatbed, and popped up to fire. However, the second stage is never used in the PC version of the game. In console versions, this was amended by making it always use the popped up stage. I thought an actual logic would be more interesting, so now, the Rocket Launcher will specifically pop up its launcher if it is in range of a target it wants to fire at.

This behaviour is enabled by default, but can be disabled by adding the option "NoLauncherPopup=true" in conquer.ini, under \[Patch\].

### Turret recoil

In beta footage of the game, gun turrets and vehicles with rotating cannon or machinegun turrets had a small one-frame recoil animation when firing. This logic is also seen in Red alert, but it is broken in the retail version of Tiberian Dawn. This has now been fixed.

This behaviour is enabled by default, but can be disabled by adding the option "NoTurretRecoil=true" in conquer.ini, under \[Patch\].

### Grenade sound

As part of the fixes done in this patch, the previously unused grenade throw sound is now played. If this bothers anyone, the sound can be disabled by adding the option "NoGrenadeToss=true" in conquer.ini, under \[Patch\].

## Extra usage notes

### "Funpark" dinosaur campaign

The game has a secret mini-campaign involving dinosaurs, which is normally unlocked by starting the game with the command line argument "funpark". However, command line arguments are tedious to work with in a Windows environment, and this option switched the entire game into a special mode, rather than just unlocking the campaign, which had some really odd side effects when loading existing savegames or starting expansion missions.

To resolve all this, the secret missions can now be accessed in a much simpler way: click "Start New Game", and **on the "Select Transmission" screen, hold down the \[Shift\] key** while clicking on the GDI or Nod logo.

### Console "Special Ops" missions

The "**extras**" folder contains the two files "**sc-n64-tuc.mix**" and "**sc-psx-tuc.mix**". These are, respectively, the originally console-exclusive Nintendo 64 and Playstation "Special Ops" missions, which were also included in the remaster. Add them into your game folder, and you can access these missions in the "New Missions" menu.

As an added bonus, with the upgrades in v1.04 of this patch, the Orca's LASER weapon in the "PATSUX" mission is fully functional.

Note that the Nintendo 64 missions do not completely match the original console versions; they were tweaked to fix some issues with base power and lack of rebuilding. To align the tech with how it was on the Nintendo 64 console, all missions with base building have their tech levels increased to be equivalent to GDI mission 15.

Also note that these missions only have mission briefings in English.

### Transparent smoke

One of the interesting bits I noticed when digging into the code was the existence of options to use "translucent colors" on animations. This system turned out to be incredibly versatile, but in the retail game, it is only used for a very slight darkening effect around the tank barrel flash animation, and for a brightening filter on the circles shown when clicking to give a Move order. So I decided to expand that.

This system works by taking certain reserved colours on the graphics, and instead of painting these, it applies a special effect, such as brightening, darkening, or recolouring, to whatever graphics are under these parts of the animation. This same system can already be seen in action in other parts of the game, such as the shadows under units, and the gradual darkening on the shroud edges. Although the amount of filters in the game is fairly limited, I managed to use the available ones to vastly upgrade all smoke animations in the game to become more transparent.

However, these changes won't activate just by tweaking the code; they need edits on the actual game sprites, to make them use these special reserved colours. In the "**extras**" folder, you can find a file called "**sc-smoky.mix**" Add that into your folder to replace the smoke effects with versions that use these translucent colors. These include rocket exhaust, the smoke shown on damaged vehicles, and oil derricks on fire. Note that this will make the smoke coming from vehicles considerably darker than before.

### Extra remix tracks

In the official soundtrack of the game, a bunch of the tracks have extra voices mixed into them. If the special CONQUER.INI option "**Scores=remix**" is enabled, the game will unlock these original mixes, making them replace the standard in-game versions. However, there are three tracks with such alternate soundtrack versions which are not included in the game, namely, "Just Do It Up!", "No Mercy" and "Deception" (aka, "We Will Stop Them"). In fact, in the Ion Cannon video, you can hear a short fragment of this version of "No Mercy".

The "**extras**" folder contains a file called "**sc-remix.mix**" which can be added into the game folder to amend this. The game itself is already adapted to recognise these tracks as possibly having a remix, so it will substitute them automatically when found, and show the correct length for the alternate version in the playlist.

### Special CONQUER.INI options

In the "**extras**" folder, you can find "**special-options.txt**", which contains a set of secret developer switches that can be activated in the game by putting them in your CONQUER.INI file, under the \[Options\] section. A few of these are generally neat, such as the music remixes and showing true civilian names, but be warned that others, like disabling the "bib" pieces of buildings, can seriously mess up the game. Use these at your own risk.


## Mission making upgrades

These are mostly features that were originally implemented in the 1.06 patch.

### House colors

New options are available in the house sections in missions ([Goodguy], [Badguy], [Neutral], etc.) that allow tweaking their colors.

The following keys are available. Each more specific one will override parts of the more general ones:

* **ColorScheme**: Makes this house use a different color scheme (see list below). Each color scheme is a complete set of unit color, building color, unit radar color and building radar color. All the following keys will add exceptions to that basic profile.
* **SecondaryScheme**: Takes the primary color of a different scheme and uses it for its buildings, like Nod does. You can use 'None' to disable Nod's secondary color, but do note that the (blue/grey) Nod will still have red radar colors then. It's probably better to just put the normal ColorScheme to Blue or Red.
* **RadarScheme**: Makes this house use the radar colors from a different color scheme.
* **UnitRadarColor**: Specify a specific palette index to use as unit radar color.
* **BuildingRadarColor**: Specify a specific palette index to use as building radar color.

Here is the list of color schemes. A color scheme includes the general remap color, the secondary color used for buildings, and the radar colors.

Multiplayer colors:

* **Yellow**: Multiplayer yellow.
* **Red**: Multiplayer red.
* **BlueGreen**: Multiplayer aqua (blue/greenish). Also works as **Aqua** or **Teal**.
* **Orange**: Multiplayer orange.
* **Green**: Multiplayer green.
* **Blue**: Multiplayer metallic blue/grey. Also works as **Grey** or **Gray**.

Campaign house colors:

* **GDI**: GDI yellow. Has slightly different radar colors than the multiplayer yellow.
* **Nod**: Nod's scheme, with blue/grey units, red buildings and red radar colors. Note that specifying this as SecondaryScheme will take its primary blue/grey for that, not the red.
* **Neutral**: Standard yellow, but with grey radar colors. Used by [Neutral] and [Special].
* **Jurassic**: Standard yellow, but with red radar colors. Used by the [Special] side dinosaurs in the Funpark missions.

Extra colors:

* **DarkGrey**: Dark grey scheme. Also works as **DarkGray**.
* **Brown**: Brown scheme.
* **Fire**: Yellow/orange scheme.
* **WarmSilver**: Pale brown scheme.

### Trigger upgrades

#### Destroying triggers

Triggers can normally be destroyed with a trigger action of the type **Dstry Trig 'XXXX'**. Unfortunately, the name given in that trigger isn't variable. Only three trigger actions of this type exist, to destroy triggers called **XXXX**, **YYYY** and **ZZZZ**. With this update, three clones of this type have been added, to also allow destruction of triggers called **UUUU**, **VVVV** and **WWWW**.

These three triggers were mainly added for multiplayer purposes: when experimenting with multiplayer scripting, it turned out that giving the multiplayer houses timed benefits (like reinforcements) could be used to create nice multiplayer enhancements. However, these reinforcements should obviously only happen for the players that are actually on the map. The only way to do this is to check with the All Destroyed trigger on each of the houses, and make that trigger remove the reinforcing trigger. But since there are 6 multiplayer-houses, this obviously only works if 6 triggers can be destroyed.

#### Civilian evacuation

The **Civ. Evac.** trigger can now be looped to detect multiple evacuations. Before, such triggers would activate endlessly, since the internal "was a civilian evacuated?" status wasn't reset after the triggers were handled.

#### Capture triggers

There are two trigger types in the game that can check for a building being captured; the special **Cap=Win/Des=Lose** trigger Action, and the **Player Enters** trigger Event. Both of these, when used in a trigger attached to a building, will now cause that specific building to become capturable, regardless of whether the building type can normally be captured.

### Map decoration upgrades

### Craters

Craters (CR1-RC6) can be added to a mission in the \[Smudge\] section, and this system normally allows setting the size of the crater. However, due to a bug in the game, only CR1 worked correctly; all other craters would revert to the smallest size of CR1. With this bug fixed, all sizes of all six crater types are now available for use.

### Crushed corpse

There is a map decoration called SQUISH in the game, representing a crushed corpse. This is an item like tiberium and walls, which can be added under the \[Overlay\] section. Originally, access to this overlay was completely blocked unless a special option was enabled to show corpses when crushing infantry with tanks. This has now been unlinked, meaning the item is available to place on maps.

## Full list of changes

See [CHANGELOG.MD](CHANGELOG.MD)

