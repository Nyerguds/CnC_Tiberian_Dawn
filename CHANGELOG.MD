# Command & Conquer Patch Project - Version history

Note that the older versions of this project (up to v1.03) were released as edited binaries. They can be found in the 'files' section of the [Command & Conquer Unofficial Patch 1.06 project on ModDb](https://www.moddb.com/mods/command-conquer-unofficial-patch-106/). They are the entries indicated as "C&C95 TUC quick fix patch".

Fixes that were specifically inspired by or copied from the Remaster's code are indicated with \[Remaster\].

## v1.00:

* Fixed the crash that happens when exploring at the top of the map with a unit with a large sight range.
* Fixed the stealth animation corruption on the right half of the lowest line of the screen, which could crash the game.
* Helipads can now be selected as primary building
* Units can now be assigned to team number "0".
* Fixed the bug that causes the deploying of an MCV to add extra power usage that could never be recovered.
* Fixed the bug that made harvesting the lowest stage of tiberium yield no resources.
* Fixed Funpark mode exiting the game when finishing the campaign.
* Removed the funpark mode requirement for making dinosaurs visible.
* Fixed the music not starting on missions added to the New Missions menu, if they contain a "Briefing" video.
* Fixed multiplayer houses used in singleplayer missions showing up as gray on the radar.
* Fixed the order of the main menu when going through it with the arrow keys.

## v1.01:

* Fixed sequence error in engineer death animation from anti-armor-weapon.
* Fixed tech level of the Chem Warrior to make it 98 instead of 99.
* Disabled the behaviour that makes the Chem-Warrior randomly walk around.

## v1.02:

* Fixed tiberium growth not refreshing unless you scroll away from it.
* Fixed craters CR02-CR06 not placing correctly from mission files.
* Fixed crater CR06 never being used as building debris. (it's still not used as projectile impact debris, but that's intentional)
* Fixed crushed infantry remains logic ("Overrun=pancake" in conquer.ini) messing up tiberium spawning.
* Fixed crushed infantry overlay decoration SQUISH not being usable from mission files.
* Fixed tiberium spread not being able to replace SQUISH overlay.
* Fixed crate spawning not being able to replace SQUISH overlay.
* Fixed force-fire modifier getting ignored on overlay.
* Fixed Rocket Launcher leaving refresh error trail when moving.
* Fixed "Right away!" voice not playing.
* Fixed Power Plant and Advanced Power Plant not animating when damaged.
* Fixed Oil Tanker not using its damaged state when below 50% strength.
* Fixed the names of Chan and the Hospital not getting shown to the enemy.
* Fixed multiplayer names exceeding 9 characters getting abbreviated to 10 characters. They can now be 10 characters.
* Fixed German "Abort mission" dialog having an "Abort" option which was actually the "Cancel" one.
* Fixed safe-scrolling ("Scrolling=restricted" in conquer.ini) only restricting half of the top buttons' width.
* Fixed grenade throw sound not working.
* Fixed SAM Site not making any sound when firing.
* Fixed steel crate not giving an animation for GDI. This was originally meant to indicate collecting "nuke pieces" for unlocking the nuke in the final Nod mission, but that system is obsolete anyway.
* Fixed radar minimap always starting as zoomed in.
* Fixed "juvenile" sounds ("Sounds=7th grade" in conquer.ini) not working.
* Fixed the Commando giving two responses at once when given a sabotage order. The "I got a present for ya!" yell on the map is now suppressed for the player owning the Commando, and is given as actual unit response instead.
* Using the mouse scrollwheel now has the same effect as the up and down arrows; it scrolls through the sidebar lists.

## v1.03:

* Fixed harvester giving a "no move" cursor on the minimap when targeting tiberium.
* Fixed aircraft giving a double response when unloading or when docking to a building.
* Fixed high damage weapons doing slightly less damage than intended, because in the damage balancing of weapons versus armor types, "100%" is actually stored as "255/256".
* Fixed the hidden music tracks "Reaching Out" and "Heartbreak" not getting unlocked when enabling the hidden / remix music ("Scores=remix" in conquer.ini).
* Enabled the cut tracks and credits tracks: "C&C 80s Mix", "DIE!", "Enemies To Be Feared", "I AM" (Destructible Times), "Airstrike", and "Ride of the Valkyries".
* The playlist now shows the correct lengths for the alternate versions of music.
* \[Remaster\] Fixed Nod score calculation having a negative impact from GDI's losses.
* Fixed the "Ambush" orders in missions not working. This order is supposed to make an AI-owned unit go to Hunt mode when discovered.
* Fixed the New Missions menu only going up to 98 (59 in the Japanese version). It can now go up to 99.
* Fixed the bug where selecting a team by number when having a structure selected would keep the structure selected.
* Fixed the bug where selecting a team by number would not clear the currently selected units when a unit from that team was the last-added unit in the current selection.
* \[Remaster\] The "Guard Target" ability (\[Ctrl\]+\[Alt\]+click) can now be clicked on the ground as targeted equivalent to the Area Guard function of the "G" button.
* Fixed the "Guard Target" ability not working on the minimap.
* Fixed aircraft showing the "Guard Target" cursor when pressing \[Ctrl\]+\[Alt\] even though they can't execute any Area Guard orders.
* Restored the Stop command for defense buildings (pressing "S"), while properly fixing the cheat that allowed abusing it for cancelling building sales to get free infantry.
* Holding down the \[Shift\] key now allows adding units when making a drag-selection.
* \[Remaster\] Drag-selecting can now select flying aircraft.

## v1.04: (in progress)

* Newly built aircraft will now spawn on available helipads.
* Added support for the laser Orcas in the Playstation "PATSUX" mission. This is enabled by putting "Patsux=1" under \[Basic\] inside a mission file.
* The laser now always shows a beam that's wide at the start and thinner at the end, no matter the direction in which it is fired.
* Allowed the Area Guard functions ("G" and \[Ctrl\]+\[Alt\]+Click) to be used by Harvesters to find nearby tiberium to harvest. The code for this always existed in the game, but the UI never allowed giving such orders to a harvester.
* \[Remaster\] Added "D" as Deploy/Unload hotkey. Unlike in the Remaster, this works even when having multiple units selected, and will only affect the units that can perform the deploy action.
* Added "E" as hotkey to select all units on the screen. This can be combined with the \[Shift\] key.
* Added "T" as shortcut for selecting all units on the screen of the same types as the already-selected units. This can be combined with the \[Shift\] key.
* Added power balance info on the power output and building tooltips. This is enabled by default, but can be disabled by adding the option "NoPowerToolTips=true" in conquer.ini, under \[Options\].
* The keyboard-given orders for Area Guard, Scatter and Deploy will now give unit responses.
* Deploying units by clicking on them now works even if you have multiple units selected. This will not affect the other units in the selection.
* \[Remaster\] Multiple infantry can now be loaded into a transport with a single click.
* \[Remaster\] Infantry can now enter an APC while the APC is busy attacking something.
* Since the deployment change makes it impossible to load passengers into a selected transport that already contains at least one passenger, you can now hold \[Alt\] to override the Deploy cursor to allow passengers to enter.
* When having infantry selected, you can now hold down \[Shift\] and add an unloaded transport to the selection without this getting overridden by the order to load into the transport.
* An "Enter" cursor no longer overrides the \[Ctrl\] force-fire or \[Ctrl\]+\[Alt\] Guard Target cursors. It will still override \[Alt\] force-move though, since that's used to override transports' unloading.
* Survivors from C4 explosions will no longer immediately shoot at the Commando at the moment they are spawned.
* Fixed the bug where survivors from C4 explosions often never bothered pursuing the Commando.
* Holding the \[Shift\] key on the "Select Transmission" screen while clicking the side will now go into the Funpark campaign.
* Fixed dinosaur campaign savegames forgetting their campaign and chosen side.
* Unlinked dinosaur campaign from the "Funpark" mode. All special dinosaur campaign logic is now only checked on the campaign ID. This also means dinosaur campaign savegames will function correctly without "Funpark" mode.
* Units in Sleep or Sticky mode will no longer try to crush nearby infantry in response to being attacked.
* The game will no longer give occasional "insufficient disk space" errors on startup.
* Click orders given on the minimap will show a flash on the targeted cell in the main map view.
* In missions where the player is neither GDI nor Nod, the minimap logo will now always be the Jurassic one.
* Missions where the player is neither GDI nor Nod will now get a functional score screen, showing "You" versus "Enemy" casualties.
* In the Japanese version, if a briefing image is not found, it will now revert to (English) text briefing.
* All language versions now support having a CPS-format image with the filename of a mission as briefing image.
* Helicopters can no longer be given Move and Force-attack orders into the shroud in multiplayer.
* Capturing a building will now refresh all of its cells on the radar to the new color.
* EVA now announces when the player loses a building. The "DeathAnnounce" option now also works for buildings.
* When "DeathAnnounce" is enabled, a destroyed unit or structure in singleplayer that is not GDI or Nod, and is not allied with the player, is now reported as destroyed "enemy".
* EVA now announces when repairs have started on a building or unit.
* Drag-selecting will now show the default cursor instead of keeping an incorrect cursor from where the drag action started.
* Drag-selecting will no longer pop up a tooltip of the thing the mouse was pressed down on.
* The minimap will now only respond to clicks at the moment the mouse is released, like how it works on the main map.
* The minimap will now update its cursor when holding down the left mouse button on it.
* The map number in multiplayer will no longer affect logic regarding difficulty and tooltips that is only meant for singleplayer.
* Fixed the fact the chance of an AI selling a building was affected by the mission number in Covert Ops missions. It is now affected by the set build level, capped at 20.
* Oil Derricks that are preplaced on the map as damaged below 50% will now also get the flame spout animation.
* The Oil Derrick and Flare animations are now truly endless, rather than stopping after 255 loops.
* Fixed the bug that the special GDI ending unlock status would re-lock if another building was destroyed after the Temple, and would linger in memory when starting or loading another mission.
* Fixed the special GDI ending unlock status not getting saved in savegames.
* Fixed the bombing target in GDI mission 6 not getting saved in savegames.
* Infantry code to look for nearby targets no longer reads outside the valid weapons array when checking weapon info for unarmed units.
* The presence of civilian building V21 (Abdul's House) can no longer cause C17 delivery planes to stay on the map indefinitely if no airstrips were found.
* When Aircraft return to base due to lack of ammo, they will no longer face towards their last target.
* Fixed the bug allowing selling units from the sell cursor shown when hovering over a wall.
* If any of the units in a selection can attack a wall, it will now always show an Attack cursor on the wall.
* Fixed bug where owning both an MCV and a Construction Yard and pressing the "H" key would give a voice response from the MCV but select the Construction Yard.
* The 'H' key will no longer act like 'Home' if no MCV or Construction Yard was found.
* The 'H' key will no longer jump to undiscovered construction yards inside the shroud.
* \[Remaster\] Civilian buildings will no longer decay for no reason due to a 0/0 power balance being seen as low power.
* Fixed power output tooltip not showning "low" if the player has power drain but zero power production.
* \[Remaster\] A unit landed on a helipad will no longer block the building placement adjacency checks.
* Theater-illegal tiles on maps will now be drawn black, instead of non-refreshing black holes retaining whatever content last went over it.
* Theater-illegal tiles can no longer crash the radar minimap.
* \[Remaster\] Large-sight units such as the Commando will now properly reveal the area around them when coming out of a transport or a building.
* Added support for the custom Snow theater.
* Added "CCPP" version number on the main menu to indicate the patch version.
* The B variant for the GDI mission 5 East-side map choices now works as it should.
* The B variant of GDI mission 13, which showed the map info of the next mission when clicked, and which was completely identical to the A variant, is no longer accessible.
* \[Remaster\] Helipads no longer vanish without animation when selling them when an aircraft is landed on them.
* Items without icons that are made buildable (e.g. through setting a mission's buildlevel to 99) will now show a dummy icon.
* Icons and other theater-specific graphics overridden by addon mixfiles will no longer corrupt the game when switching theaters.
* \[Remaster\] Buildings that are in the process of selling and have already evacuated their crew will not spawn more infantry when destroyed.
* The map selection's "Click to continue" end screen now filters on specific keyboard input ranges, allowing screen capture keys to still work on this scene.
* Pressing \[Escape\] on the score or map screen will now speed up the animations to rapidly skip to the end state.
* Implemented the Nod-specific map and score screen music. This is enabled by default, but can be disabled by adding the option "NoNodSceneMusic=true" in conquer.ini, under \[Options\].
* Added \[Ctrl\]+\[S\] as in-game screenshot key.
* Added new option to enable the debug option IsBarOn, as "BarOn=harkonnen" ;)
* Added the ability to customize color schemes from mission files.
* Added support for extra destroyable triggers named UUUU, VVVV and WWWW.
* Civilian evacuation triggers in missions can now be looped to detect multiple evacuations.
