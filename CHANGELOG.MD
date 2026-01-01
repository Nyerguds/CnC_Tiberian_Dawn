# Command & Conquer Patch Project - Version history

Note that the older versions of this project (up to v1.03) were released as edited binaries. They can be found in the 'files' section of the [Command & Conquer Unofficial Patch 1.06 project on ModDb](https://www.moddb.com/mods/command-conquer-unofficial-patch-106/). They are the entries indicated as "C&C95 TUC quick fix patch".

Fixes that were specifically inspired by or copied from the Remaster's code are indicated with \[Remaster\].

## v1.00:

* Fixed the crash that happens when exploring at the top of the map with a unit with a large sight range.
* Fixed the stealth animation corruption on the right half of the lowest line of the screen, which could crash the game.
* Helipads can now be selected as primary building.
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
* Fixed crater CR06 never being used as building debris. (It's still not used as projectile impact debris, but that's intentional.)
* Fixed crushed infantry remains logic ("Overrun=pancake" in conquer.ini) messing up tiberium spawning. \[Revised to animation in 1.04\]
* Fixed crushed infantry overlay decoration SQUISH not being usable from mission files.
* Fixed tiberium spread and crate spawning not being able to replace SQUISH overlay. \[Removed in 1.04, since it's now an animation\]
* Fixed force-fire modifier getting ignored on overlay.
* Fixed Rocket Launcher leaving refresh error trail when moving.
* Fixed "Right away!" voice not playing.
* Fixed Power Plant and Advanced Power Plant not animating when damaged.
* Fixed Oil Tanker not using its damaged state when below 50% strength.
* Fixed the names of Chan and the Hospital not getting shown to the enemy.
* Fixed multiplayer names that are 10 characters long getting abbreviated to 9 characters followed by a dot. They can now be 10 characters before getting abbreviated.
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
* \[Remaster\] The "Guard Target" ability (\[Ctrl\]+\[Alt\]+Click) can now be clicked on the ground as targeted equivalent to the Area Guard function of the "G" button.
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
* Added "T" as shortcut for selecting all units on the screen of the same types as the already-selected units. This can be combined with the \[Shift\] key. If the current screen contains no units of these types to select, the original selection is retained.
* Added power balance info on the power output and building tooltips. This is enabled by default, but can be disabled by adding the option "NoPowerToolTips=true" in conquer.ini, under \[Patch\].
* The keyboard-given orders for Area Guard, Scatter, Deploy and Stop will now give unit responses.
* Deploying units by clicking on them now works even if you have multiple units selected. This will not affect the other units in the selection.
* \[Remaster\] Multiple infantry can now be loaded into a transport with a single click.
* \[Remaster\] Infantry can now enter an APC while the APC is busy attacking something.
* Since the deployment change makes it impossible to load passengers into a selected transport that already contains at least one passenger, you can now hold \[Alt\] to override the Deploy cursor to allow passengers to enter.
* When having infantry selected, you can now hold down \[Shift\] and add a transport to the selection without this getting overridden by the order to load into the transport.
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
* EVA now announces when repairs have started on a building or unit. This is enabled by default, but can be disabled by adding the option "NoRepairAnnounce=true" in conquer.ini, under \[Patch\]. If repairs on the same vehicle get halted and restarted due to lack of funds, this will not be announced multiple times.
* Drag-selecting will now show the default cursor instead of keeping an incorrect cursor from where the drag action started.
* Drag-selecting will no longer pop up a tooltip of the thing the mouse was pressed down on.
* The minimap will now only respond to clicks at the moment the mouse is released, like how it works on the main map.
* The minimap will now update its cursor when holding down the left mouse button on it.
* The map number in multiplayer will no longer affect logic regarding difficulty and tooltips that is only meant for singleplayer.
* Fixed the fact the chance of an AI selling a building was affected by the mission number in Covert Ops missions. It is now affected by the set build level, capped at 20.
* Oil Derricks that are preplaced on the map as damaged below 50% will now also get the flame spout animation.
* The Oil Derrick's flame spout animation now properly overlaps objects next to it.
* The Oil Derrick and Flare animations are now truly endless, rather than stopping after 255 loops.
* Fixed the bug that the special GDI ending unlock status would re-lock if another building was destroyed after the Temple, and would linger in memory when starting or loading another mission.
* Fixed the special GDI ending unlock status not getting saved in savegames.
* Fixed the bombing target in GDI mission 6 not getting saved in savegames.
* Infantry code to look for nearby targets no longer reads outside the valid weapons array when checking weapon info for unarmed units.
* [Remaster] Units without weapons that somehow try to attack things will now be completely blocked from firing, instead of attacking with a weapon composed of junk data.
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
* \[Remaster\] Helipads no longer vanish without animation if they are sold when an aircraft is landed on them.
* Items without icons that are made buildable (e.g. through setting a mission's buildlevel to 99) will now show a dummy icon.
* Icons and other theater-specific graphics overridden by addon mixfiles will no longer corrupt the game when switching theaters.
* \[Remaster\] Buildings that are in the process of selling and have already evacuated their crew will not spawn more infantry when destroyed.
* The map selection's "Click to continue" end screen now filters on specific keyboard input ranges, allowing screen capture keys to still work on this scene.
* Pressing \[Escape\] on the score or map screen will now speed up the animations to rapidly skip to the end state.
* After selecting a location on the map screen, both the \[Escape\] key and clicking the mouse will make the text animation speed up.
* Implemented the Nod-specific map and score screen music. This is enabled by default, but can be disabled by adding the option "NoNodSceneMusic=true" in conquer.ini, under \[Patch\].
* Added \[Ctrl\]+\[S\] as in-game screenshot key, writing a .pcx file into the game folder. This does not work on menus or between missions, though. You can disable the UI message of the saved filename by adding the option "NoScreenshotMessage=true" in conquer.ini, under \[Patch\].
* Added new ini key to enable the debug option IsBarOn, as "BarOn=harkonnen" ;)
* Added the ability to customize color schemes from mission files using the "ColorScheme" / "SecondaryScheme" / "RadarScheme" options under the House ini sections.
* Added support for extra destroyable triggers named UUUU, VVVV and WWWW.
* Civilian evacuation triggers in missions can now be looped to detect multiple evacuations.
* Added proper mouse scroll wheel support to the sidebar; it now scrolls the list you hover over.
* Item lists such as the New Missions menu and the music list now support PageUp, PageDown, Home, End, and the mouse scroll wheel.
* The prefix shown on items in the New Missions menu now always automatically matches the player set in the mission file.
* Items in the New Missions menu now load missions for campaign side "J" too, from SCJ20EA to SCJ99EA.
* Added constraint checks on strings file reading, with any unknown string returning "&lt;&lt;UNKNOWN STRING&gt;&gt;".
* The AI behaviour to run from incoming threats is now enabled at BuildLevel 8, rather than at Scenario 8, making it equivalent to other difficulty increase tweaks that happen at that level.
* Units that are damaged below 50% will not start smoking again when attacked by a weapon that deals no damage to them (e.g. tank vs Technician gun or Blossom Tree).
* Clicking to place down a building, activating Repair or Sell mode, or clicking the icon of a charged superweapon, will now always properly cancel any other such special targeting mode if it was active, rather than setting the mouse in a strange state where multiple such modes are active at the same time. This bug caused strange behaviour where you had to click multiple times to cancel the targeting.
* In the Save menu, when clicking on a savegame from a previous game version to overwrite it, the "(old)" status at the start will no longer be included in the savegame description.
* \[Remaster\] After unloading in a Refinery, Harvesters will now return to the first spot where they started harvesting the previous time, rather than the last one, reducing harvester drifting.
* \[Remaster\] Harvesters will randomize their starting point when scanning for tiberium, removing top-left harvester drifting issues.
* \[Remaster\] Harvesters will prefer higher-value cells when scanning around themselves looking for tiberium.
* Changes in discovered terrain, walls and tiberium will now immediately get updated correctly on the minimap.
* Engineers and Commandos are now able to enter buildings from the north even if the buildings' northern cells are unoccupied.
* Fixed "wall armor" bug, where buildings with an unoccupied northern cell become practically invulnerable to certain weapons if a wall is placed on that open cell.
* The sidebar radar logo in a mission can now be overridden by specifying the extension for the HRADAR.??? file to load. This can be done by adding RadarLogo=??? under \[Basic\].
* For the purpose of checking build prerequisites, owning an Advanced Communication Center will now act as if you own a normal Communications Center.
* The Advanced Communications Center can now detect stealth units, since its non-advanced variant can do that too.
* Build levels can now be customized in the campaign missions.
* The "New Missions" menu only shows mission variants with the EA suffix, but these missions will now attempt to continue to other variants to act as campaign up to 15 missions. The order is EA/EB/EC/ED/EE, WA/WB/WC/WD/WE, XA/XB/XC/XD/XE.
* Added "RemoveBuildExceptions" option for missions. This will remove all singleplayer-specific build rules, such as disallowing construction of the Helipad and APC for Nod, and the building of superweapons from captured Construction Yards.
* Fixed double-firing on aircraft getting disrupted by other orders, causing the aircraft to always fire per single shot.
* Fixed Mammoth Tank showing its muzzle flashes on the wrong barrel.
* Rocket Launchers will now pop up their launcher when they are in range of their target. You can disable this behaviour by adding the option "NoLauncherPopup=true" in conquer.ini, under \[Patch\].
* Re-enabled broken turret recoil logic. This was always in the game, but didn't get drawn correctly. You can disable this behaviour by adding the option "NoTurretRecoil=true" in conquer.ini, under \[Patch\].
* \[Remaster\] Infantry in Area Guard mode no longer freezes in place, but will instead animate normally.
* \[Remaster\] Fixed range checks to be independent from the direction the unit/building is currently facing.
* Fixed unarmed civilians giving an Attack cursor when targeting enemies.
* \[Remaster\] Any building will now be considered capturable in singleplayer if it has a trigger attached that activates when it is captured. This applies to both the "Cap=Win/Des=Lose" action, and the "Player Enters" event.
* \[Remaster\] Fixed bug where pressing \[S\] on an aircraft that was already returning to its helipad would make it land on an incorrect spot on the pad.
* Reduced the behaviour where helicopters return home after barely attacking because they find no place to shuffle to. If the air is too crowded, they will consider staying in place, and if the target is too close to the map edge or shroud and that limits the available airspace, they are now allowed to come closer to compensate.
* Aircraft will now always immediately return to base when they run out of ammo mid-salvo, instead of waiting for a second shot they don't have.
* Fixed the infantry squish sound increasing in volume if multiple infantry units are on the same squished cell.
* Fixed ability to crush light vehicles, and tweaked it so this doesn't play the infantry squish sound, but instead plays the destroyed unit's normal death animation, along with a little "roadkill bump" sound.
* The game now generates translucent effects in memory, rather than reading them from .MRF files. This allowed several minor bugs in the translucency effects to be corrected.
* Enabled translucent colors on the vehicle smoke and oil derrick smoke animations, so they can be enhanced to semitransparent smoke.
* Enabled translucent colors on rocket exhaust smoke puff, so it can be enhanced to semitransparent smoke.
* Enabled translucent colors on the SAM Site launch smoke animations, so the hard-baked Nod colours on the animation can be fixed.
* Fixed misalignment on SAM Site launch smoke animations.
* The grenade throw sound can now be disabled by enabling the option "NoGrenadeToss=true" in conquer.ini, under \[Patch\].
* Fixed the issue where capturing tiberium storage would try to transfer the contained tiberium to the player before the storage capacity itself was added to the player's storage pool, often resulting in an unintuitive loss of the captured money.
* When selling a building, the infantry will now always come out of an actual cell that was part of the building.
* Selling an APC or transport helicopter on the Repair Bay will no longer make the passengers vanish; they will get dumped out and walk off the platform. This also removes an exploit allowing mission-critical infantry to be removed without the game noticing their disappearance.
* A unit sold on a repair bay will now be marked as "destroyed" internally, as it happens with sold buildings, meaning destruction triggers on such units can't be circumvented by selling them. As with buildings, this does not count towards the losses on the score screen.
* Selling a Harvester on a Repair Bay now refunds 50% of the tiberium stored inside. Before, this was divided twice, giving only 25%.
* When a loaded APC is destroyed while on the Repair Bay, it now properly ejects its passengers, rather than them all vanishing and be considered dead.
* When a landed Transport Helicopter gets destroyed, the passengers don't simply all get killed off. They can get heavily damaged though, and might die if not at full health. This also functions correctly when it is docked to a Repair Bay or helipad.
* Craters and scorch marks can now appear on spots occupied by units.
* Aircraft are now placeable from missions. Helicopters will be placed down on the ground, fixed-wing airplanes will start in the air.
* Pressing \[N\] or \[Shift\]+\[N\] to select a previous or next unit while in Sell or Repair mode, or having superweapon targeting active, will now properly cancel these modes.
* When a building is captured while the building placement grid is shown, the placement grid will automatically update with the ownership change.
* Improved the alignment of cargo / ammo indicator pips inside selection box.
* Fixed "Sticky" orders; in the original implementation it acted like "Sleep until attacked", but its intended purpose was always to have units that acted like player units in Guard mode, never moving from their position but attacking anything in range.
* Fixed units in "Sleep" or "Sticky" mode still being able to scatter under certain conditions, e.g. to evade incoming damage.
* Construction no longer starts as "On Hold" if no money is available.
* Construction in "On Hold" status can now be told to continue even if the player currently has no money.
* Impatient clicks while lacking money will now make EVA explain to players the basic principle that they cannot construct things if they are broke.
* Clicking to repair a building while lacking money will now make EVA explain to players the basic principle that they cannot repair things if they are broke. Note that the "NoRepairAnnounce" ini option disables this.
* If you own a refinery, losing your last harvester will now give a "Need Harvester" announcement instead of the usual "Unit Lost".
* Restricted the amount of units rendered on a Hovercraft to five, to avoid the game using out-of-bounds program data to determine the locations for further units.
* Stealth units placed in missions no longer need to cloak on mission start; they now start fully cloaked.
* Removed extra tendency of APCs to load from the south-east or south-west, which would make them never load units from the north-west unless the south-west cell was blocked.
* \[Remaster\] The Hospital can no longer be sold. This fixes a bug that had been in the game since the release of C&C95; in the DOS version it was indeed unsellable.
* \[Remaster\] Selling a wall now gives a sell sound.
* Enabled Juvenile version of the sound volume test sound.
* Re-enabled unused "Over and out!" infantry voice.
* Double-barreled units such as the Mammoth Tank and Flame Tank have their firing offsets adjusted to perspective, so the shots no longer look too far apart when firing towards east-west direction.
* The distance between the barrels on double-barreled units no longer affects their weapon range calculations. Barrel length still affects it, but the sideways offset doesn't.
* Fixed all south advantage bugs caused by turrets and firing positions being cosmetically shifted to the north. These northward shifts are no longer applied to perform weapon range checks.
* Added 1/4th of a cell of range to the artillery, to compensate for the fact it was only ever viable against Advanced Guard Towers due to the south advantage bug.
* Fixed targets in range not getting detected because the scanned radius started at the tip of the barrel, making it ignore objects located exactly opposite from the barrel's facing.
* Fixed targets in range not getting detected due to the barrel length not being included in the scan range.
* Fixed targets in range not getting detected because the cell to detect was a building cell that wasn't part of its solid occupied cells.
* Fixed ballistic and homing projectiles limiting their range to the range of the firing unit, without taking the bonus range against buildings into account.
* Fixed the Temple being able to fire a missile while selling, aborting the sale but leaving the infantry.
* Losing the Nuclear Missile or Ion Cannon ability while you are targeting the superweapon in question will now disable the targeting mode.
* Any House can now collect steel crates for "nuke pieces" to get additional nukes from the Temple of Nod. Before, this was limited to Nod, but now the Temple can be made capturable by mission triggers, this was expanded.
* Firing a nuclear missile will now subtract the consumed "nuke pieces" from the player's collected amount, rather than resetting the amount to 0.
* The amount of "nuke pieces" required to unlock a single nuke can now be set in a mission by putting "RequiredNukePieces" in the mission's \[Basic\] section. This defaults to 3, as per the game's original behavior.
* The player in a mission can now start with a specific amount of nuke pieces by putting "PlayerNukePieces" in the mission's \[Basic\] section. This defaults to 3, as per the game's original behavior, normally giving access to one nuke.
* Custom campaigns can enable the Steel Crate Collect-a-Thon logic by setting "PlayerNukeInherit=true" in a mission's \[Basic\] section, overriding the "PlayerNukePieces" option.
* Added ini key to reactivate the Nod campaign's Steel Crate Collect-a-Thon logic, by setting "NodCrateCollectNuke=true" in conquer.ini, under \[Patch\]. This overrides the three mission-specific nuke crate settings for all Nod campaign missions.
* Fixed amount of collected crates resetting when restarting a mission. It is now reverted to the value the player had at the start of the mission.
* Fixed the TeamTypes "Unload" order using its value both as waypoint and as timeout, making it necessary to always add a "Move" order to the same waypoint first.
* The TeamTypes "Unload" order can now be used to deploy an MCV.
* Fixed trees remaining on fire forever until they died, because the damage taken from the burning always set them on fire again.
* Fixed trees being immune to non-fire damage while they were burning.
* Fixed trees not getting properly cleaned up when dying from fire damage, and remaining as dead but damage-immune husks.
* Fixed buildings on fire spawning increasingly more fire when they get repaired above the halfway point but then get reduced below it again by the fire damage.
* Superweapon triggers ("Ion Cannon" and "Nuclear Missile") for the owner's native superweapon will now produce a one-time shot that works regardless of owned superweapon building, and which does not consume nuke pieces.
* Computer player superweapon strikes from triggers will now be blocked if they do not own the required superweapon building. This behaviour can be disabled by adding "AllowDetachedAISupers=true" in a mission's \[Basic\] section. This affects both the Ion Cannon and the Nuclear Strike.
* The Ion Cannon is no longer restricted to players identifying as GDI. This allows captured Advanced Communications Centers to give the player access to the Ion Cannon.
* Added new "Money" trigger event, to fix the fact the existing "Credits" event only counts cash money, without tiberium.
* Computer-owned MCVs ordered to "Unload" will now seek out a valid place if they can't deploy on their current spot.
* Since the Nuclear Missile superweapon has no "charging" voice, a "New Construction Options" voice now announces when it is added to the build list.
* Animations now remember which object caused them, meaning buildings burning down from fire damage, and objects damaged by superweapons, will now know where the damage originated, and possibly what to retaliate against.
* Damage caused by infantry exploding on death is now attributed to the one who killed the infantry, since this is the way it works for Flame Tank and SSM death explosions.
* The money carried over from the previous scenario is now actually the full amount of money, not just the non-tiberium credits.
* Added "PassiveHelis" option that can be used in missions to make AI helicopters passive.
* Fixed the game not being able to parse the last line of an ini file if it doesn't end on a line break.
* Fixed small misalignment on the click position of the Deploy cursor.
* Fixed scrolling logic being tied to the game's frame rate. It is now capped at 60fps, making it consistent on any machine.
* Added middle mouse button scrolling.
* Fixed Scatter logic not working for units docked to a repair bay.
* Fixed Scatter logic giving multiple move orders because it doesn't stop looking for locations after finding a valid spot to scatter to.
* Fixed Scatter logic for vehicles simply making them drive forward in the direction they're already facing.
* Fixed bug where Airstrip deliveries lock up when looping map scripts keep creating teams that never get filled up with units due to the AI losing the required factories.
* Fixed Primary Building logic malfunctioning for Airstrip deliveries.
* Fixed bug where revealing a cell containing multiple infantry would only mark one of them as Revealed, preventing the selection and auto-targeting of the others.
* Fixed the logic to take threat priorities and distance from target into account when scanning for a target to attack.
* Removed logic to stop scanning after finding nearby targets, since it was a hotfix for the non-working distance factor in the target priority.
* Changed "Overrun=pancake" effect to create animations of the SQUISH.SHP graphic for each crushed infantry unit, rather than placing down a single-corpse overlay.
* Fixed defense buildings getting a muzzle flash, which was drawn under the building.
* Fixed the broken pattern logic of the "isometric" CONC pavement, making it look much nicer. It is not normally used, but can be placed in maps.
