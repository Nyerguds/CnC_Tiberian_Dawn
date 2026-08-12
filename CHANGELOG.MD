# Command & Conquer Patch Project - Version history

Note that the older versions of this project (up to v1.03) were released as edited binaries. They can be found in the 'files' section of the [Command & Conquer Unofficial Patch 1.06 project on ModDb](https://www.moddb.com/mods/command-conquer-unofficial-patch-106/). They are the entries indicated as "C&C95 TUC quick fix patch".

Fixes that were specifically inspired by or copied from the Remaster's code are indicated with \[Remaster\]. Fixes that already existed in the 1.06 patch are indicated as \[v1.06\].

Changes that reflect internal behavior but which have no gameplay impact are marked as \[Internal\].

## v1.00:

* \[v1.06\] Fixed the crash that happens when exploring at the top of the map with a unit with a large sight range.
* \[v1.06\] Fixed the stealth animation corruption on the right half of the lowest line of the screen, which could crash the game.
* \[v1.06\] Helipads can now be selected as primary building.
* \[v1.06\] Units can now be assigned to team number "0".
* Fixed the bug that causes the deploying of an MCV to add extra power usage that could never be recovered.
* Fixed the bug that made harvesting the lowest stage of tiberium yield no resources.
* \[v1.06\] Fixed Funpark mode exiting the game when finishing the campaign.
* \[v1.06\] Removed the funpark mode requirement for making dinosaurs visible.
* \[v1.06\] Fixed the music not starting on missions added to the New Missions menu, if they contain a "Briefing" video.
* \[v1.06\] Fixed multiplayer houses used in singleplayer missions showing up as gray on the radar.
* \[v1.06\] Fixed the order of the main menu when going through it with the arrow keys.

## v1.01:

* Fixed sequence error in engineer death animation from anti-armor-weapon.
* Fixed tech level of the Chem Warrior to make it 98 instead of 99.
* \[v1.06\] Disabled the behavior that makes the Chem-Warrior randomly walk around.

## v1.02:

* Fixed tiberium growth not refreshing unless you scroll away from it.
* Fixed craters CR02-CR06 not placing correctly from mission files.
* Fixed crater CR06 never being used as building debris. (It's still not used as projectile impact debris, but that's intentional.)
* Fixed \[v1.06\] crushed infantry remains logic ("Overrun=pancake" in conquer.ini, under \[Options\]) messing up tiberium spawning. \[Revised to animation in 1.04\]
* Fixed crushed infantry overlay decoration SQUISH not being usable from mission files.
* Fixed tiberium spread and crate spawning not being able to replace SQUISH overlay. \[Removed in 1.04, since it's now an animation\]
* Fixed force-fire modifier getting ignored on overlay.
* Fixed \[v1.06\] Rocket Launcher leaving refresh error trail when moving.
* Fixed \[v1.06\] "Right away!" voice not playing.
* Fixed Power Plant and Advanced Power Plant not animating when damaged.
* \[v1.06\] Fixed Oil Tanker not using its damaged state when below 50% strength.
* \[v1.06\] Fixed the names of Chan and the Hospital not getting shown to the enemy.
* \[v1.06\] Fixed multiplayer names that are 10 characters long getting abbreviated to 9 characters followed by a dot. They can now be 10 characters before getting abbreviated.
* \[v1.06\] Fixed German "Abort mission" dialog having an "Abort" option which was actually the "Cancel" one.
* \[v1.06\] Fixed safe-scrolling ("Scrolling=restricted" in conquer.ini, under \[Options\]) only restricting half of the top buttons' width.
* \[v1.06\] Fixed grenade throw sound not working.
* Fixed SAM Site not making any sound when firing.
* \[v1.06\] Fixed steel crate not giving an animation for GDI. This was originally meant to indicate collecting "nuke pieces" for unlocking the nuke in the final Nod mission, but that system is obsolete anyway.
* \[v1.06\] Fixed radar minimap always starting as zoomed in.
* \[v1.06\] Fixed "juvenile" sounds ("Sounds=7th grade" in conquer.ini, under \[Options\]) not working.
* Fixed the Commando giving two responses at once when given a sabotage order. The "I got a present for ya!" yell on the map is now suppressed for the player owning the Commando, and is given as actual unit response instead.
* Using the mouse scrollwheel now has the same effect as the up and down arrows; it scrolls through the sidebar lists. \[Replaced by true scroll support in 1.04, scrolling the specific list your mouse is on\]

## v1.03:

* Fixed harvester giving a "no move" cursor on the minimap when targeting tiberium.
* Fixed aircraft giving a double response when unloading or when docking to a building.
* \[v1.06\] Fixed high damage weapons doing slightly less damage than intended, because in the damage balancing of weapons versus armor types, "100%" is actually stored as "255/256".
* \[v1.06\] Fixed the hidden music tracks "Reaching Out" and "Heartbreak" not getting unlocked when enabling the hidden / remix music ("Scores=remix" in conquer.ini, under \[Options\]).
* \[v1.06\] Enabled the cut tracks and credits tracks: "C&C 80s Mix", "DIE!", "Enemies To Be Feared", "I AM" (Destructible Times), "Airstrike", and "Ride of the Valkyries".
* \[v1.06\] The playlist now shows the correct lengths for the alternate versions of music.
* \[Remaster\] Fixed Nod score calculation having a negative impact from GDI's losses.
* Fixed the "Ambush" orders in missions not working. This order is supposed to make a computer-owned unit go to Hunt mode when discovered.
* \[v1.06\] Fixed the New Missions menu only going up to 98 (59 in the Japanese version). It can now go up to 99.
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
* \[v1.06\] Fixed dinosaur campaign savegames forgetting their campaign and chosen side.
* Unlinked dinosaur campaign from the "Funpark" mode. All special dinosaur campaign logic is now only checked on the campaign ID. This also means dinosaur campaign savegames will function correctly without "Funpark" mode.
* Units in Sleep or Sticky mode will no longer try to crush nearby infantry in response to being attacked.
* The game will no longer give occasional "insufficient disk space" errors on startup.
* Click orders given on the minimap will show a flash on the targeted cell in the main map view.
* \[v1.06\] In missions where the player is neither GDI nor Nod, the minimap logo will now always be the Jurassic one.
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
* \[v1.06\] The map number in multiplayer will no longer affect logic regarding difficulty and tooltips that is only meant for singleplayer.
* Fixed the fact the chance of a computer player selling a building was affected by the mission number in Covert Ops missions. It is now affected by the set build level, capped at 20.
* Oil Derricks that are preplaced on the map as damaged below 50% will now also get the flame spout animation.
* The Oil Derrick's flame spout animation now properly overlaps objects next to it.
* The Oil Derrick and Flare animations are now truly endless, rather than stopping after 255 loops.
* Fixed the bug that the special GDI ending unlock status would re-lock if another building was destroyed after the Temple, and would linger in memory when starting or loading another mission.
* Fixed the special GDI ending unlock status not getting saved in savegames.
* Fixed the bombing target in GDI mission 6 not getting saved in savegames.
* Infantry code to look for nearby targets no longer reads outside the valid weapons array when checking weapon info for unarmed units.
* \[Remaster\] Units without weapons that somehow try to attack things will now be completely blocked from firing, instead of attacking with a weapon composed of junk data.
* The presence of civilian building V21 (Abdul's House) can no longer cause C17 delivery planes to stay on the map indefinitely if no airstrips were found.
* When Aircraft return to base due to lack of ammo, they will no longer face towards their last target.
* Fixed the bug allowing selling units from the sell cursor shown when hovering over a wall.
* If any of the units in a selection can attack a wall, it will now always show an Attack cursor on the wall. This does not affect any behaviour; just the cursor.
* Fixed bug where owning both an MCV and a Construction Yard and pressing the "H" key would give a voice response from the MCV but select the Construction Yard.
* The 'H' key will no longer act like 'Home' if no MCV or Construction Yard was found.
* The 'H' key will no longer jump to undiscovered construction yards inside the shroud.
* \[Remaster\] Civilian buildings will no longer decay for no reason due to a 0/0 power balance being seen as low power.
* Fixed power output tooltip not showning "low" if the player has power drain but zero power production.
* \[Remaster\] A unit landed on a helipad will no longer block the building placement adjacency checks.
* Theater-illegal tiles on maps will now be drawn black, instead of non-refreshing black holes retaining whatever content last went over it.
* Theater-illegal tiles can no longer crash the radar minimap.
* \[Remaster\] Large-sight units such as the Commando will now properly reveal the area around them when coming out of a transport or a building.
* \[v1.06\] Added support for the custom Snow theater.
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
* \[v1.06\] Implemented the Nod-specific map and score screen music. This is enabled by default, but can be disabled by adding the option "NoNodSceneMusic=true" in conquer.ini, under \[Patch\].
* Added \[Ctrl\]+\[S\] as in-game screenshot key, writing a .pcx file into the game folder. This does not work on menus or between missions, though. You can disable the UI message of the saved filename by adding the option "NoScreenshotMessage=true" in conquer.ini, under \[Patch\].
* Added new ini key to enable the debug option IsBarOn, as "BarOn=harkonnen" ;)
* \[v1.06\] Added the ability to customize color schemes from mission files using the "ColorScheme" / "SecondaryScheme" / "RadarScheme" options under the House ini sections.
* \[v1.06\] Added support for extra destroyable triggers named UUUU, VVVV and WWWW.
* Civilian evacuation triggers in missions can now be looped to detect multiple evacuations.
* Added proper mouse scroll wheel support to the sidebar; it now scrolls the list you hover over.
* Item lists such as the New Missions menu and the music list now support PageUp, PageDown, Home, End, and the mouse scroll wheel.
* The prefix shown on items in the New Missions menu now always automatically matches the player set in the mission file.
* Items in the New Missions menu now load missions for campaign side "J" too, from SCJ20EA to SCJ99EA.
* Added proper constraint checks on the fetching of translated text from the loaded strings file; any unknown text indices now return "&lt;&lt;UNKNOWN STRING&gt;&gt;".
* The behavior for computer controlled units to run from incoming threats is now enabled at BuildLevel 8, rather than at Scenario 8, making it equivalent to other difficulty increase tweaks that happen at that level.
* Units that are damaged below 50% will not start smoking again when attacked by a weapon that deals no damage to them (e.g. tank vs Technician gun or Blossom Tree).
* Clicking to place down a building, activating Repair or Sell mode, or clicking the icon of a charged superweapon, will now always properly cancel any other such special targeting mode if it was active, rather than setting the mouse in a strange state where multiple such modes are active at the same time. This bug caused strange behavior where you had to right-click multiple times to cancel the targeting.
* In the Save menu, when clicking on a savegame from a previous game version to overwrite it, the "(old)" status at the start will no longer be included in the savegame description.
* \[Remaster\] After unloading in a Refinery, Harvesters will now return to the first spot where they started harvesting the previous time, rather than the last one, reducing harvester drifting.
* \[Remaster\] Harvesters will randomize their starting point when scanning for tiberium, removing top-left harvester drifting issues.
* \[Remaster\] Harvesters will prefer higher-value cells when scanning around themselves looking for tiberium.
* Changes in discovered terrain, walls and tiberium will now immediately get updated correctly on the minimap.
* Engineers and Commandos are now able to enter buildings from the north even if the buildings' northern cells are unoccupied.
* Fixed "wall armor" bug, where buildings with an unoccupied northern cell become practically invulnerable to certain weapons if a wall is placed on that open cell.
* \[v1.06\] The sidebar radar logo in a mission can now be overridden by specifying the extension for the HRADAR.??? file to load. This can be done by adding RadarLogo=??? under \[Basic\].
* \[v1.06\] For the purpose of checking build prerequisites, owning an Advanced Communication Center will now act as if you own a normal Communications Center.
* \[v1.06\] The Advanced Communications Center can now detect stealth units, since its non-advanced variant can do that too.
* \[v1.06\] Build levels can now be customized in the campaign missions.
* \[v1.06\] The "New Missions" menu only shows mission variants with the EA suffix, but these missions will now attempt to continue to other variants to act as campaign up to 15 missions. The order is EA/EB/EC/ED/EE, WA/WB/WC/WD/WE, XA/XB/XC/XD/XE.
* \[v1.06\] Added "RemoveBuildExceptions" option for missions. This will remove all singleplayer-specific build rules, such as disallowing construction of the Helipad and APC for Nod, and the building of superweapons from captured Construction Yards.
* Fixed double-firing on aircraft getting disrupted by other orders, causing the aircraft to always fire per single shot from that moment on.
* Fixed Mammoth Tank showing its muzzle flashes on the wrong barrel.
* Rocket Launchers will now pop up their launcher when they are in range of their target. You can disable this behavior by adding the option "NoLauncherPopup=true" in conquer.ini, under \[Patch\].
* Re-enabled broken turret recoil logic. This was always in the game, but didn't get drawn correctly. You can disable this behavior by adding the option "NoTurretRecoil=true" in conquer.ini, under \[Patch\].
* \[Remaster\] Infantry in Area Guard mode no longer freezes in place, but will instead animate normally.
* \[Remaster\] Fixed range checks to be independent from the direction the unit/building is currently facing.
* Fixed unarmed civilians giving an Attack cursor when targeting enemies.
* \[Remaster\] Any building will now be considered capturable in singleplayer if it has a trigger attached that activates when it is captured. This applies to both the "Cap=Win/Des=Lose" action, and the "Player Enters" event.
* \[Remaster\] Fixed bug where pressing \[S\] on an aircraft that was already returning to its helipad would make it land on an incorrect spot on the pad.
* Reduced the behavior where helicopters return home after barely attacking because they find no place to shuffle to. If the air is too crowded, they will consider staying in place, and if the target is too close to the map edge or shroud and that limits the available airspace, they are now allowed to come closer to compensate.
* Aircraft will now always immediately return to base when they run out of ammo mid-salvo, instead of waiting for a second shot they don't have.
* Fixed the infantry squish sound increasing in volume if multiple infantry units are on the same squished cell.
* Fixed ability to crush light vehicles, and tweaked it so this doesn't play the infantry squish sound, but instead plays the destroyed unit's normal death animation, along with a little "roadkill bump" sound.
* The game now generates translucency effect filters in memory, rather than reading them from .MRF files. This allowed several minor bugs in the translucency effects to be corrected.
* Enabled translucent colors on the vehicle smoke, oil derrick smoke and rocket exhaust smoke puff animations, so they can be enhanced to semitransparent smoke.
* Enabled translucent colors on the SAM Site launch smoke animations, so the hard-baked Nod colors on the animation can be fixed.
* Fixed misalignment on SAM Site launch smoke animations.
* The grenade throw sound can now be disabled by enabling the option "NoGrenadeToss=true" in conquer.ini, under \[Patch\].
* \[Remaster\] Fixed the issue where capturing tiberium storage would try to transfer the contained tiberium to the player before the storage capacity itself was added to the player's storage pool, often resulting in an unintuitive loss of the captured money.
* When selling a building, the infantry will now always come out of an actual cell that was part of the building.
* Selling an APC or transport helicopter on the Repair Bay will no longer make the passengers vanish; they will get dumped out and walk off the platform. This also removes an exploit allowing mission-critical infantry to be removed without the game noticing their disappearance.
* A unit sold on a repair bay will now be marked as "destroyed" internally, as it happens with sold buildings, meaning destruction triggers on such units can't be circumvented by selling them. As with buildings, this does not count towards the losses on the score screen.
* Selling a Harvester on a Repair Bay now refunds 50% of the tiberium stored inside. Before, this was divided twice, giving only 25%.
* When a loaded APC is destroyed while on the Repair Bay, its passengers now get properly ejected and walk off the path, rather than them all vanishing and be considered dead.
* When a landed Transport Helicopter gets destroyed, the passengers don't simply all get killed off; they now get ejected and scatter instead. They can get heavily damaged though, and might die if not at full health. This also functions correctly when it is docked to a Repair Bay or helipad.
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
* Fixed load/unload mechanism of APC not working in certain directions. Even directions without door animation will now work if no others are available.
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
* Fixed ballistic and homing projectiles limiting their range to the range of the fired weapon, without taking the bonus range against buildings into account.
* Fixed the Temple being able to fire a missile while selling, aborting the sale but leaving the infantry.
* Losing the Nuclear Missile or Ion Cannon ability while you are targeting the superweapon in question will now disable the targeting mode.
* Any House can now collect steel crates for "nuke pieces" to get additional nukes from the Temple of Nod. Before, this was limited to Nod, but now the Temple can be made capturable by mission triggers, this was expanded.
* Firing a nuclear missile will now subtract the consumed amount of "nuke pieces" from the player's collected amount, rather than resetting the amount to 0.
* The amount of "nuke pieces" required to unlock a single nuke can now be set in a mission by putting "RequiredNukePieces" in the mission's \[Basic\] section. This defaults to 3, as per the game's original behavior.
* The player in a mission can now start with a specific amount of nuke pieces by putting "PlayerNukePieces" in the mission's \[Basic\] section. This defaults to 3, as per the game's original behavior, normally giving access to one nuke.
* Custom campaigns can enable the Steel Crate Collect-a-Thon logic by setting "PlayerNukeInherit=true" in a mission's \[Basic\] section, overriding the "PlayerNukePieces" option.
* Added ini key to reactivate the Nod campaign's Steel Crate Collect-a-Thon logic, by setting "NodCrateCollectNuke=true" in conquer.ini, under \[Patch\]. This overrides the three mission-specific nuke crate settings for all Nod campaign missions.
* Fixed amount of collected crates resetting when restarting a mission. It is now reverted to the value the player had at the start of the mission.
* Fixed the TeamTypes "Unload" order using its value both as waypoint and as timeout, making it necessary to always add a "Move" order to the same waypoint first.
* The TeamTypes "Unload" order can now be used to deploy an MCV.
* Fixed trees remaining on fire forever until they died, because the damage taken from the burning always set them on fire again.
* Fixed trees being immune to non-fire damage while they are burning.
* Fixed trees not getting properly cleaned up when dying from fire damage, and remaining as dead but damage-immune husks.
* Fixed buildings on fire spawning increasingly more fire when they get repaired above the halfway point but then get reduced below it again by the fire damage.
* Superweapon triggers ("Ion Cannon" and "Nuclear Missile") for the owner's native superweapon will now produce a one-time shot that works regardless of owned superweapon building, and which does not consume nuke pieces.
* Computer player superweapon strikes from triggers will now be blocked if they do not own the required superweapon building. This behavior can be disabled by adding "AllowDetachedAISupers=true" in a mission's \[Basic\] section. This affects both the Ion Cannon and the Nuclear Strike.
* The Ion Cannon is no longer restricted to players identifying as GDI. This allows captured Advanced Communications Centers to give the player access to the Ion Cannon.
* Added new "Money" trigger event, to fix the fact the existing "Credits" event only counts cash money, without tiberium.
* Computer-owned MCVs ordered to "Unload" will now seek out a valid place if they can't deploy on their current spot.
* Since the Nuclear Missile superweapon has no "charging" voice, a "New Construction Options" voice now announces when it is added to the build list.
* Animations now remember which object caused them, meaning buildings burning down from fire damage, and objects damaged by superweapons, will now know where the damage originated, and possibly what to retaliate against.
* Damage caused by infantry exploding on death is now attributed to the one who killed the infantry, since this is the way it works for Flame Tank and SSM death explosions.
* The money carried over from the previous scenario is now actually the full amount of money, not just the non-tiberium credits.
* \[v1.06\] Added "PassiveHelis" option that can be used in missions to make computer-owned helicopters passive.
* Fixed the game not being able to parse the last line of an ini file if it doesn't end on a line break.
* Fixed small misalignment on the click position of the Deploy cursor.
* Fixed scrolling logic being tied to the game's frame rate. It is now capped at 60fps, making it consistent on any machine.
* Added middle mouse button scrolling.
* Fixed Scatter logic not working for units docked to a repair bay.
* Fixed Scatter logic giving multiple move orders because it doesn't stop looking for locations after finding a valid spot to scatter to.
* Fixed Scatter logic for vehicles always simply making them drive forward in the direction they're already facing.
* Fixed bug where Airstrip deliveries lock up when looping map scripts keep creating teams that never get filled up with units due to the computer player losing the required factories.
* Fixed Primary Building logic malfunctioning for Airstrip deliveries.
* Fixed bug where revealing a cell containing multiple infantry would only mark one of them as Revealed, preventing the selection and auto-targeting of the others.
* Fixed the logic to take threat priorities and distance from target into account when scanning for a target to attack.
* Removed logic to stop scanning after finding nearby targets, since it was a hotfix for the non-working distance factor in the target priority.
* Changed "Overrun=pancake" effect to create animations of the SQUISH.SHP graphic for each crushed infantry unit, rather than placing down a permanent single-corpse Overlay object.
* Fixed defense buildings getting a muzzle flash, which was drawn under the building.
* Fixed the broken pattern logic of the isometric CONC pavement, making it look much nicer. It will now also always place the tiles in pairs, forming full isometric diamond shapes.
* Fixed ROAD pavement not always giving the speed boost it is supposed to have.
* Fixed tree targeting option ("TreeTarget=lightning" in conquer.ini, under \[Options\]) giving an attack cursor over indestructible trees.
* \[Internal\] Full map template blocks (map cell terrain pieces) made up of multiple cells are no longer limited to only using two different land types (which determine passability / buildability behavior).
* Fixed the destroyed Desert bridge (NE-SW) having an impassable tile at the south-west end of the road.
* Implemented wider bridges and river crossings, mimicking their behavior in the Playstation and Saturn versions.
* The logic to make the Tech Center spawn special infantry with a trigger attached is now configurable in the mission, using the "MissionTargetSpawn" and "MissionTargetTrigger" options, with the "MissionTargetHouse" option able to change the House of the spawned unit. If the building is captured, the infantry will run out of the building.
* Added explicit "Difficulty" setting in the \[Patch\] section in conquer.ini, which accepts values "easy" and "hard".
* Fixed issue where dragging the mouse to select units would give an extra click order at the point where the mouse was released.
* Fixed APC door animation not using all of its frames.
* If a computer-constructed building can't be placed, it will now scan for other locations in its build plan where a building of that type can be placed down.
* Rebuild entries in a mission's \[Base\] section now support wall types, meaning they can be scripted to be built or rebuilt in missions.
* Computer-owned Construction Yards now animate when placing down a building, just like the player-owned one does.
* Computer-owned units will no longer scatter to make place for placing a building if enemies are also obstructing the buiding and it can't be placed down anyway.
* To make place for placing a building, computer-owned units will now specifically scatter away from the building's center.
* If a computer player attempts to place a building, this will no longer make units owned by another computer player scatter to make space for it, if the two are not allies. This could also affect human-owned unit if the IsScatter option ("CombatIQ=sergent" in conquer.ini, under \[Options\]) was enabled.
* Fixed dinosaur graphics corrupting when firing while moving.
* The Transport Helicopter now opens its door to unload troops.
* The Transport Helicopter's passengers will now wait until its door is open before going inside.
* Fixed logic to make the Transport Helicopter and APC immediately close their door when the passenger hold is full.
* Fixed bug that artillery type units could get their rearm delay significantly shortened when the game perceived them as "arriving on a cell".
* Fixed GDI occasionally getting SSM Launchers as multiplayer starting units.
* There is now a special different Attack cursor depending on whether the target is in range or out of range. If multiple units are selected, targets are only shown as "in range" if they are in range of all selected units.
* Fixed errors in selection box sizes, and health bar length not matching the selection box size.
* \[Internal\] Fixed "IsNominal" setting so it is used for its original intended purpose of showing the object's real name, rather than to trigger the civilian name overrides. These are now controlled by "IsCivilian" as they should be, removing the need for exceptions.
* Enemy helicopters will now also show "Enemy vehicle" instead of their real name. The Transport Helicopter will still show its true name, since this needs to serve as player hint if they need to be captured in a mission. The "PassiveHelis" behavior will also show helicopter names.
* \[Remaster\] The computer player can no longer sell the Temple of Nod in the final GDI mission.
* \[Internal\] Generalized the fact Delphi is ignored by targeting to a general "IsSpy" property.
* Mission files now support a "Prefix=" key in the \[Basic\] section to override the House prefix shown in the New Missions menu. This prefix can only be 1-3 characters.
* Enemy aircraft will now also show "Enemy vehicle" when hovering over them.
* Fixed a bug causing the tooltip to show the wrong color when moving the mouse cursor between adjacent objects that would show the same tooltip text but in a different color. (e.g. two harvesters of different Houses parked next to each other.)
* \[Internal\] Units and Aircraft will now obey their "can be repaired" property, and be unable to dock with the Repair Facility if it is disabled. Not that this is now set to True on all units and aircraft, to reflect the original state of the game.
* Sell mode will no longer be disabled if the player has no structures on the map, since it could still be used for selling walls.
* Fixed civilians becoming unselectable when they are put on the map before the units revealing them.
* Base nodes can now have an owner, so multiple Computer players can each build their own base. This is done either by specifying "Player=" on the Base section, or by suffixing the existing base node lines with an extra comma-separated part containing the node's house.
* Computer-owned Construction Yards will now only pick buildings to build if other Construction Yards of their House aren't already building them.
* \[Internal\] Added better checks when reading Teamtypes to avoid possible memory corruption.
* \[Internal\] The secret "Bibs" option had special exceptions for the placement of the Barracks and Refinery, to enforce leaving space at the bottom of their passable area when placing. This behaviour was migrated to a new IsBibReserved property on buildings.
* \[Remaster\] Units assigned to group numbers will now show their group number when selecting them.
* \[Internal\] Any building type can now be marked as Primary if it has the "IsFactory" option set.
* Objects with multiple pieces of pip information (e.g. cargo pips and group or primary building indicator) will now automatically stack these.
* \[Internal\] The "IsFlammable" option on buildings will now determine whether a building gets set on fire when receiving heavy damage.
* The building placement grid will now be updated when nearby buildings are destroyed.
* Stealth units blocking the building placement grid will now no longer explicitly show where they are; the entire grid will turn yellow.
* Command line parameters to set a specific game resolution will now override the Resolution setting in conquer.ini.
* The 640x480 resolution will now use the entire screen size. This will fill the remaining space under the sidebar area with the standard sidebar pattern.
* Fixed the bug that a viewport height that does not match an exact number of cells will make it impossible to place buildings on the lowest row of the map.
* A 712x400 widescreen resolution is now available, either with command line parameter "-wide", or by setting "Resolution=2." in conquer.ini, under \[Options\].
* Fixed the power bar being drawn four pixels too low.
* The game can now play the mmg1.aud "A most remarkable Metasequoia Glyptostroboides" clip if it is present.
* \[Internal\] The special behavior to make the MCV and Harvester use the building color rather than the unit color is now an option in the unit type properties.
* \[Internal\] Made everything superweapon-related use the specific "SpecialWeaponType" enum, rather than often using IDs as bare numbers.
* \[Internal\] The code that determines how to remap a unit and its cameo is now centralized in TechnoTypeClass and its subclasses.
* \[Internal\] The code that paints the objects in a list in Map Editor mode was vastly simplified, and is now mostly centralized In TechnoTypeClass.
* Fixed theater-specific graphics corrupting and crashing the map editor mode "Add game object" window.
* Made several fixes to the map editor mode "Add game object" window to display objects more intuitively.
* Unlocked aircraft in map editor mode "Add game object" window
* Fixed the bib placement preview in map editor mode repeating the same tile.
* The preview for placing a Blossom Tree now shows the Blossom Tree frame.
* The debug keys to spawn helicopters (O, B and T) now only work when no unit is selected and when the terrain under the mouse is clear for placement.
* Disabled the Monochrome Screen debug key since it just crashes the game.
* Fixed computer-owned Commandos constantly stopping to shoot at their target when on their way to bomb it.
* The 'B' hotkey will restart construction of the last built building. If a building is finished, the key will activate the building placement.
* Players can now build walls on top of damaged existing walls they own, to repair them. This will refund half of the old wall's cost, making it equivalent to the player selling the old wall first.
* Clicks on greyed out sidebar items will now count as if you clicked on the currently building item of that type, allowing easier cancelling and placement.
* Fixed Gunboats remaining passive when reinforced.
* Being in placement mode will no longer block the Sell and Repair buttons from working. Pressing these buttons will now abort the placement mode.
* Infantry in the process of dying will no longer be selected as a result of drag-select and select hotkeys.
* Infantry in the process of dying will no longer give responses when selected and ordered to do things.
* When a unit is finished being serviced on a Service Depot or Helipad (repairing or reloading), a beep sound will alert the player that they are ready again. If the unit is selected at that moment, it will simply tell the player it is ready and awaiting orders.
* \[Internal\] Death animations for infantry are now configured in the warheads information.
* Infantry gored or eaten by dinosaurs will now show a previously-unused messy death animation.
* \[v1.06\] Added "NoEgoScreen" option that can be used in missions to make it skip the score screen.
* Dinosaur missions will now get a score screen, with the score level based on the scenario number times three.
* Mission 8A (Vienna) will now correctly show its Point of Conflict as "Salzburg" instead of "Jelgava".
* \[Remaster\] Civilians in GDI mission 8B will now always avoid tiberium. This option can be used in missions by adding the "NoTiberiumWandering" option into a mission.
