v1.00:

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

v1.01:

* Fixed sequence error in engineer death animation from anti-armor-weapon.
* Fixed tech level of the Chem Warrior to make it 98 instead of 99.
* Disabled the behaviour that makes the Chem-Warrior randomly walk around.

v1.02:

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

v1.03:

* Fixed harvester giving a "no move" cursor on the minimap when targeting tiberium.
* Fixed aircraft giving a double response when unloading or when docking to a building.
* Fixed high damage weapons doing slightly less damage than intended, because in the damage balancing of weapons versus armor types, "100%" is actually stored as "255/256".
* Fixed the hidden music tracks "Reaching Out" and "Heartbreak" not getting unlocked when enabling the hidden / remix music ("Scores=remix" in conquer.ini).
* Enabled the cut tracks and credits tracks: "C&C 80s Mix", "DIE!", "Enemies To Be Feared", "I AM" (Destructible Times), "Airstrike", and "Ride of the Valkyries".
* The playlist now shows the correct lengths for the alternate versions of music.
* Fixed Nod score calculation having a negative impact from GDI's losses.
* Fixed the "Ambush" orders in missions not working. This order is supposed to make an AI-owned unit go to Hunt mode when discovered.
* Fixed the New Missions menu only going up to 98 (59 in the Japanese version). It can now go up to 99.
* Fixed the bug where selecting a team by number when having a structure selected would keep the structure selected.
* Fixed the bug where selecting a team by number would not clear the currently selected units when a unit from that team was the last-added unit in the current selection.
* The "Guard Target" ability ([Ctrl]+[Alt]+click) can now be clicked on the ground as targeted equivalent to the Area Guard function of the "G" button.
* Fixed the "Guard Target" ability not working on the minimap.
* Fixed aircraft showing the "Guard Target" cursor when pressing [ctrl]+[alt] even though they can't execute any Area Guard orders.
* Restored the Stop command for defense buildings (pressing "S"), while properly fixing the cheat that allowed abusing it for cancelling building sales to get free infantry.
* Holding down the Shift key now allows adding units when making a drag-selection.
* Drag-selecting can now select flying aircraft.

v1.04:

* The game will no longer give occasional "insufficient disk space" errors.
* If click orders given on the minimap are in the currently viewed area, a flash will be shown on the clicked cell.
* Missions where the player is neither GDI nor Nod will now always skip the score screen, to avoid a crash.
* In the Japanese version, if a briefing image is not found, it will now revert to text briefing.
* A CPS image with the filename of the mission file can now be used as briefing on all language versions.
* Helicopters can no longer be given Move and Force-attack orders into the shroud in any situation.
