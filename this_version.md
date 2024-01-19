# Changelog

v1.14.34:

- Fix Vigor showing up sometimes when it shouldn't.

v1.14.33:

- Update TOC for Dragonflight to 10.2.5

v1.14.32:

- Enable GlobalCoolDown module in Classic Era 1.15.0+
- Enable tracking target buffs/debuffs in Classic Era 1.15.0+

v1.14.31:

- Fix nil concatenation error (wowace ticket #351)

v1.14.30:

- Update Classic-era TOC for 1.15.0
- Enable TargetCastBar module on Classic-era 1.15+

v1.14.29:

- Fix Stagger bar error for 10.2.0 (wowace ticket #348)

v1.14.28:

- Update TOC for Dragonflight to 10.2.0

v1.14.27:

- Update TOC for Dragonflight to 10.1.7

v1.14.26:

- Update TOC for classic-era to 1.14.4

v1.14.25:

- Fixed lua error that would appear when targetting webwrapped players in heroic alpha/beta titan rune dungeons.
- Added ability to adjust strata globally.

v1.14.24:

- Fixed an error when targeting a player and right-clicking a module that should show a menu in 10.1.5.

v1.14.23:

- Update Dragonflight TOC for 10.1.5

v1.14.22:

- Fixed reported issue with a Lua error on Wrath Classic clients. https://www.wowace.com/projects/ice-hud/issues/344
- Fixed Vigor module not working when riding Grotto Netherwing Drake (and theoretically all future Dragonriding mount types).
- Updated TOC for Wrath-Classic.

v1.14.21:

- Increased maximum scale/zoom to 400%, by request.
- Fixed TargetCC/FocusCC modules on Wrath Classic.
- Fixed disabled Buff/Debuff Watchers showing a static gray bar when set to When Missing or Always display modes.
- Fixed Buff/Debuff Watchers showing an empty bar when set to Missing mode. If the background was disabled, this looked like just a floating spell icon.
- Fixed spell icons sometimes not showing up for custom bars until the tracked spell had been cast once.

v1.14.20:

- Added Winding Slitherdrake as recognized for the Dragonriding Vigor module

v1.14.19:

- Updated TOCs for 10.1.0
- Added addon icon for 10.1.0 clients
- Fixed Dragonriding Vigor charges not showing up in 10.1.0
- Fixed Vigor not always updating correctly when loading into the game or a new zone

v1.14.18:

- Fixed Runic Power showing on a scale of 0-1000+ instead of 0-100+ with DogTags off
- Added option (enabled by default) to hide mod during cataloging.
- Fixed "Hide Blizzard Buffs" option on PlayerInfo causing errors and "?" icons when toggling off.
- Also hide Debuff frame if it exists (Dragonflight+) when enabling "Hide Blizzard Buffs" in the PlayerInfo module.

v1.14.17:

- Updated TOCs for 10.0.7

v1.14.16:

- Exposed the option in the Totems module to hide the Blizzard Totems frame or not, and changed the default value to not hide when on a version of the game that doesn't support right-clicking to destroy totems (any version after Wrath). This enables using the default Totems frame to cancel totems early.
- Fixed a reported error when playing Darkmoon Faire games.
- Added a few more Polymorph ranks to TargetCC for Classic. I'm sure there are more missing.

v1.14.15:

- Updated TOCs for 10.0.5

v1.14.14:

- Fixed PlayerAlternatePower bar showing up when it shouldn't have, such as when casting Power Word: Shield before ever having done anything to trigger a game-level "alternate power" event, such as mounting a Dragonriding mount.

v1.14.13:

- Fixed Vigor module hiding default Climbing, Film, etc. UIs. (wowace ticket #336)

v1.14.12:

- Added a module for showing Dragonriding Vigor points.

v1.14.11:

- Packaged a new version of LibDogTag-Unit to fix the Guild roster resetting its scroll position every 20 seconds.

v1.14.10:

- Fix an error in TargetTargetHealth/Mana and CustomHealth when Low Threshold Color was checked and Scale by Health % was un-checked.

v1.14.9:

- Fix Low Threshold to be usable even when Color By Health/Mana % is disabled. (ticket #334)

v1.14.8:

- Fix Color By Health % to work with Low Threshold Color option. Previously, if Low Threshold was set, the color was always either MaxHealth/MaxMana or MinHealth/MinMana, it would never be colored by health %. Now if both are set, it will scale by health % until it reaches the low threshold, at which point it will switch to the Min color.
- Fix Low Threshold color and flashing to work at the same percentage. Previously these were slightly different such that it would start flashing at 40% but not turn to the Min color until 39.9999%, for example.

v1.14.7:

- Add option to scale absorb bar by the unit's maximum health.

v1.14.6:

- Add ability for buff/debuff watchers to only display when the specified buff/debuff is missing. This also adds the ability to require that the given unit exists. So if you had Unit set to Target, Display mode set to Missing, and Only if unit exists checked, you'd show the bar if you have a target and they don't have the given buff/debuff.
- Don't flash the castbar for instant-cast spells that the player didn't cast (such as internal quest spells).
- Add DruidEnergy module (disabled by default). This module will show the player's Energy level if they're a Druid and currently shapeshifted to a non-energy-using form (eligible forms are configurable by the user).

v1.14.5:

- Fix castbar flashing. There are controls on the player castbar module for flashing when a spell succeeds or fails, and separate controls for flashing when an instant cast completes. Those were broken, but now work again.
- Add "@" after the number when the Combo Points module is in Numeric mode, "Show Charged points" is enabled, and the current combo point is charged.
- Fix Charged point support in the ComboPointsBar module.

v1.14.4:

- Update TOC for 10.0.2

v1.14.3:

- Add Spell ID support for aura tracking.
- Add Evoker support.
- Add Empowered Casting (hold-to-cast levels) support.

v1.14.2:

- Fix CC and Invuln modules not showing immediately when they should.

v1.14.1:

- Fix Hide Party feature on pre-10.0 clients.

v1.14.0:

- 10.0 compatibility
- Renamed Anima Charged combo points to Charged, and removed specific references to Kyrian.
