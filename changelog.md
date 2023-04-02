# Changelog

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

v1.13.17.3:

- Packaged latest LibDogTag-Unit to work around crash in Wrath Classic client.

v1.13.17.2:

- Fixed Runes disappearing for Death Knights on Wrath Classic when using the dual spec feature.

v1.13.17.1:

- Fixed Priests hanging on login on the retail client.

v1.13.17:

- Internal maintainability updates. There are so many versions of the game now, updates need to be as easy and safe as possible.
- Improved reliability of Slice-n-Dice predicted length when changing talents.
- Improved various modules's ability to respond to the player's maximum power type changing (going from 5 max combo points to 6, for example).
- Fixed invalid texture layers specified on a variety of textures (10.0 fix).
- Removed HolyPowerNumeric text from the configuration options of several modules that it didn't belong with.
- Fixed combo points in Classic Era clients.

v1.13.16:

- Enabled Incoming Heal Prediction on Wrath-Classic.
- Added detection for the full Wrath Classic build (not just the pre-patch).

v1.13.15:

- Updated TOC for Retail (9.2.7).
- Added Wrath-Classic compatibility.

v1.13.14.3:

- Restored right-click menus on Info and Health bars when targeting other players.

v1.13.14.2:

- Restored right-click menus on Info and Health bars.

v1.13.14.1:

- Restored guard around array that doesn't exist on Classic clients.

v1.13.14:

- Fixed target health updating infrequently on Classic.
- Fixed compatibility with WoW 9.2.5.
- Updated TOC for all game flavors.

v1.13.13:

- Slight optimization of Zereth Mortis puzzle detection logic.
- Fixed target health updating infrequently on Classic-BC.
- Fixed reported error in TargetInvuln module.

v1.13.12:

- Hide IceHUD during Zereth Mortis puzzles
- Fixed default player and target frames coming back sometimes (github issue #19)
- Updated TOC for 9.2.0 and 1.14.2

v1.13.11:

- Fixed totem bar dismissal for BC-Classic and Classic
- Updated TOC for BC-Clasic

v1.13.10:

- Updated TOCs for 9.1.5 and 1.14.1

v1.13.9:

- Fixed FocusMana modules attempting to register invalid events in Classic builds.
- Add support for multiple anima-charged combo points to display at once.
- Update TOC for Classic 1.14.0

v1.13.8.1:

- Updated TOC for BC-Classic and Classic.

v1.13.8:

- Fixed Paladin GCD not functioning in BC-Classic.

v1.13.7:

- Fixed energy ticker when zoning back into an instance after dying (Classic builds)
- Added newer Fear spell to CC modules.
- Fixed the straight textures (Tanks) not showing the lowest or highest values appropriately (10% could look empty, 90% could look full).

v1.13.6:

- Updated TOC to 9.1
- Packaged an updated DogTag library with a fix for Classic-era `[Class]` tags.

v1.13.5:

- Classic-Burning Crusade support
- Package a community fork of LibRangeCheck with BC-Classic compatibility
- Prevented DogTag strings sometimes cutting off and showing "..." when they shouldn't if the user entered blank lines in the text box for the tags. Also changed the tooltip to not suggest pressing Enter since that could cause this problem. If you already have blank lines in your DogTag strings, you will want to remove them manually, but this fix prevents the problem from occurring in the future.
- Fixed custom buff/debuff bar tracking for targettarget units.

v1.13.4:

- Show Demon Hunter Fury top text as the raw Fury amount instead of a 0-100 scale with DogTags off. (ticket #301)
- Package newer LibDogTag to fix upgrade bug in that library.

v1.13.3:

- Activated Totems module for all classes in Shadowlands. Some class abilities spawn units that live for a specific amount of time, and the game handles these as Totems.
- Fixed an issue where mana bars could use the wrong alpha settings if the player's maximum mana was 0 (such as during the use of Soulshape).
- Update TOC for 9.0.5

v1.13.2:

- Fixed which version of LibDogTag was being packaged. The previous version did not have 9.0 compatibility and was generating errors (ticket #293).

v1.13.1:

- Added support for Anima-charged combo points for Kyrian covenant (ticket #291).
- Updated TOC for 9.0.2

v1.13.0:

- Made compatible with 9.0
- Improved frame naming/debuggability
- Updated TOC for 9.0

v1.12.15:

- (Classic) Fixed reported issue with the Threat bar throwing errors sometimes.

v1.12.14:

- Fixed pet health/mana sometimes using the wrong alpha if the player teleported.

v1.12.13:

- Fixed various class power indicators using the wrong alpha visibility if the player teleported (like with a Hearthstone) when they had a target selected.
- Show Hunter Focus top text as the raw Focus amount instead of a 0-100 scale with DogTags off.

v1.12.12:

- (Classic) Fixed an error when certain spell events fire (like turning in Arathi Basin tokens) with LibClassicCasterino installed.
- Fixed Death Knight Runes using the wrong alpha visibility if the player teleported (like with a Hearthstone) when they had a target selected.

v1.12.11:

- Fixed TargetMana value not showing in the proper color with DogTags off
- Fixed Rage showing on a scale of 0-1000 instead of 0-100 with DogTags off
- Updated TOC for 8.3

v1.12.10:

- (Classic) Temporarily(?) disabled the Totems module as the GetTotemInfo() API was removed.

v1.12.9:

- (Classic) Fixed error in player cast bar if the user didn't have LibClassicCasterino installed.

v1.12.8:

- (Classic) Fixed TargetCast bar to work for users with the LibClassicCasterino library installed. (thanks, Fulzamoth!)

v1.12.7:

- (Classic) Fixed fallout from disabling GCD module (errors in castbar).

v1.12.6:

- (Classic) Disabled Combo modules for non-Rogues/-Druids. They were sometimes showing for other class abilities for some reason.

v1.12.5:

- (Classic) Disabled GCD module as the Classic client doesn't support tracking GCD.
- (Classic) Packaged new LibDogTag-Unit to pick up Happiness tag fixes.

v1.12.4:

- Fixed spellcast failure events on the castbar not being handled properly. (thanks, Fulzamoth!)

v1.12.3:

- (Classic) Added support for RealMobHealth on the TargetHealth module when DogTags are disabled. (thanks, TwentyOneZ!)
- (Classic) Added support for LibClassicDurations on the TargetInfo module to show (de)buff durations when the lib is installed. (thanks, Fulzamoth!)

v1.12.2:

- (Classic) Fixed error when changing profiles or disabling IceHUD

v1.12.1:

- (Classic) Fixed energy ticker resetting when spending energy.
- (Classic) Fixed stack counters throwing errors and generally not functioning.
- (Classic) Disabled target and target-of-target castbars. Added a note to the FAQ as to why.

v1.12.0:

- Initial WoW Classic compatibility

v1.11.11:

- Updated TOC to 8.2

v1.11.10:

- Fixed pet health/power not updating every time it was supposed to.

v1.11.9:

- Fixed player health never quite reaching full (and therefore never adhering to "full" alpha settings). It seems like a WoW client patch caused UNIT_MAXHEALTH to stop firing.

v1.11.8:

- Updated TOC to 8.1

v1.11.7:

- Fixed Warlock shard numeric formatting incorrectly in non-Destruction specs.
- Possibly fixed reported bug with Brewmaster Monks' Stagger bars.
- Added several spells to be tracked in the CC modules.

v1.11.6:

- Only show placeholder icon on custom bars when in configuration mode (fixes placeholder icon showing up for abilities the player hasn't enabled yet, like Survival Hunter's Bombs).
- Fixed Custom Cooldown bars not displaying properly when both "ignore range" and "only show with target" were checked.

v1.11.5:

- Added Rogue's Between the Eyes stun to the CC stun bar list.
- Added option (enabled by default) to hide mod during shell games.
- Packaged new LibDogTag-Unit to fix hostile NPC class names displaying in all caps.

v1.11.4:

- Fixed cast lag indicator updating randomly mid-cast.

v1.11.3:

- Balance druids with Nature's Wrath now treat 50-100 astral power as full for alpha purposes (so the bar will fade to "out of combat" levels when resting around 50%).
- Fixed the GCD and player castbar lag indicator to show up again.
- Fixed a longstanding bug where the castbar lag indicator would sometimes be the size of the full bar if the mod never received the client-side "started casting" notification.
- Improved reliability of castbar lag indicator. Blizzard doesn't offer the necessary events to display this with 100% certainty.
- Fixed an error caused by the Runes module when toggling "Hide Blizzard Frame" off.

v1.11.2:

- Fixed Stagger bar to work in 8.0
- Fixed DK Runes in graphical mode not always correctly showing runes on cooldown (curse ticket 238, thanks ithorazei!)
- Renamed HarmonyPower module to Chi and moved saved settings over

v1.11.1:

- Fixed error when playing as a Monk
- Fixed castbar sometimes showing gibberish text and sometimes disappearing when the cast wasn't complete yet

v1.11.0:

- Updated TOC for 8.0

v1.10.18:

- BfA compatibility
- Added gap setting between upper and lower text (github pull request #1, thanks lrds!)
- Fixed Roll the Bones coloring when gaining 5 buffs.

v1.10.17:

- Fixed Insanity display with DogTags disabled
- Show text on Absorb and AltMana with DogTags disabled

v1.10.16.1:

- Added option to hide the raid icon for Info frames.
- Updated TOC for 7.3

v1.10.16:

- Updated shard texture for Warlocks.

v1.10.15.2:

- Updated shard display for Destro Warlocks (ticket #234, thanks stencil!).

v1.10.15.1:

- Fixed an error in IceHUD's usage of GetLFGProposal()'s return values exposed by the 7.2.5 Chromie quests.

v1.10.15:

- Fixed error on 7.2 due to a CVar being removed.
- Updated TOC for 7.2

v1.10.14:

- Fixed Holy Word: Serenity not being trackable in the Custom Cooldown module (ticket #232).
- Updated Stagger bar to allow the user to set the max to 100% if desired.

v1.10.13.1:

- Fixed "0" showing up for some users after 1.10.13 by adding a "show when zero" checkbox to custom counters (disabled by default). Anyone who has used IceHUD for a very long time has automatically-converted custom counter modules that replaced the old "maelstrom", "lacerate", and "sunder" modules that used to exist, each of which exhibited the behavior after the last update.

v1.10.13:

- Fixed alpha settings for spell charges on custom counter bars and stack counters to treat "full" the same way a Mana or Health bar would. Previously these treated "full" as "empty" for charges because that's how buff/debuff stacking should work (ticket #231).
- Fixed custom counters in numeric mode not hiding the count properly.

v1.10.12:

- Tweaked a few Druid CCs in the CC modules. If you've got a more up-to-date list of any of the CCs, please send them along to icehud@parnic.com
- Fixed a problem that could cause a custom counter to loop forever and cause framerate problems. (ticket #230)
- Updated default text values for Health and Mana modules to show values in shortened form so they're more readable. Anyone who has customized their text will not be affected by this change and the shortened form only kicks in once values reach 10,000.

v1.10.11:

- Updated TOC for IceHUD_Options module
- Fixed custom stack counters in graphical mode tracking spell charges failing to update when the maximum number of charges changes (such as with a talented 2-charge Demon Hunter Throw Glaive)

v1.10.10.1:

- Fixed the old energy ticker showing up in 7.1.

v1.10.10:

- Updated TOC for 7.1
- Re-enabled PlayerAbsorb by default by popular demand.

v1.10.9:

- Added support for the Scale setting on mirror bars and extended the mod-wide scale setting to a range of 20%-200% (ticket #228).
- Fixed Runes module causing a memory leak.
- Added a toggle to cause Runes to display the same way as combo points: show a series of icons that empty and fill back up based on the number of runes available.
- Added a toggle to cause Runes to display as just a number of available runes.
- Added an option to keep Runes displayed on the screen whether you have a target or not if not all runes are recharged.
- Added display of the player's current absorb amount to the top of the health bar. Incoming heals display on top of both. Disabled PlayerAbsorb by default because of this addition.

v1.10.8:

- Fixed combo points sometimes showing a max of 5 when it should show a max of 6.
- Added coloration to the Roll The Bones module for how many RtB buffs the player has active (ticket #227, thanks Zahariel!).

v1.10.7:

- Added an option to PlayerMana to allow scaled mana color gradients to be used on classes that don't use Mana.
- Added a user-submitted Roll The Bones module (ticket #220, thanks Zahariel!).

v1.10.6:

- Fixed TargetInfo debuffs appearing to be spaced differently than buffs
- Added support for the Pain mana type

v1.10.5:

- Added colors for Maelstrom mana
- Fixed TargetMana to use Insanity, Fury, and Maelstrom colors correctly
- Fixed error on startup in 7.0 for users with old MaelstromCount, SunderCount, or LacerateCount modules in their settings.

v1.10.4:

- Fixed Maelstrom using the wrong alpha setting when the bar was empty
- Fixed reliability of visibility of the Absorb modules. They were sometimes showing up when they shouldn't and could be slow (or fail) to actually display when they needed to.

v1.10.3:

- Fixed incorrect texture drawing behind power counters

v1.10.2:

- Fixed errors popping up when playing as tank classes with the Resolve module enabled in 7.0 (Resolve isn't a thing anymore)
- Fixed the castbar disappearing mid-cast sometimes when it shouldn't in 7.0

v1.10.1.1:

- Fixed SliceAndDice error introdued in 1.10.1 that prevented the SnD module from working and the options from opening

v1.10.1:

- Fixed the "low threshold" flash being in the wrong location after rotating a module 90 degrees
- Fixed bar rotation not resetting properly when changing profiles from one with rotation enabled to one without
- Fixed the HarmonyPower and HolyPower Hide Blizzard Frame options generating errors and not working in 7.0
- Fixed the new 7.0 power types (astral power, insanity, fury) using the wrong alpha setting when the bar was empty
- Fixed mana colors on the TargetMana bar for the new 7.0 power types (insanity, fury)

v1.10.0:

- Updated TOC for 7.0

v1.10:

- First release supporting both 6.x and 7.0/Legion. At a high level, this means:
-- Updated all class-specific resources to account for their 7.0 versions (rogues: 6-8 combo points, death knights: homogenized rune types, warlocks: all specs use shards, etc.)
-- Added support for Demon Hunters
-- Accounted for all 7.0 API changes such as UnitIsTapped, UNIT_COMBO_POINTS event, etc.
- Created a PlayerAltMana bar that will always show the player's mana amount regardless of their primary power type (so that Druids and Monks, plus other classes in 7.0, can see mana alongside their other resources)
- Fixed how cooldowns are initialized to help them cooperate better with mods like OmniCC (ticket #205)
- Updated the Stagger bar with the new Stagger support in DogTags so we don't have to figure out and format values ourselves.

v1.9.18:

- Fixed the lag indicator sometimes completely covering the castbar when interacting with certain in-world quest objects
- Improved some debugging tools

v1.9.17:

- Use the GCD spell for calculating GCD time (ticket #204)

v1.9.16:

- Added option to ignore the game's configured custom lag tolerance when displaying IceHUD's lag indicators (ticket #201)
- Fixed "Show during cast" for classes with < 1.5s GCD (ticket #200 - thanks nandchan!)
- Fixed GCD occasionally showing when it shouldn't (ticket #199 - thanks nandchan!)

v1.9.15:

- Added optional lag indicator to the GCD. (ticket #196 - thanks nandchan!)
- Fixed GCD bar appearing on top of other UI elements incorrectly - it now appears at the same level as the rest of the bars.
- Fixed lag indicator on cast bars when they were set to "reverse" - the lag indicator would appear at the wrong end of the bar.
- Channeled spells now respect the "Show during cast" option of the GCD bar. (ticket #197 - thanks nandchan!)
- Hopefully fixed an issue that would cause the GCD to not always fire when it was supposed to. (ticket #198 - thanks nandchan!)

v1.9.14:

- Fixed the Resolve module to work properly (thanks cgsg11!).

v1.9.13.1:

- Fixed an error popping up about missing localization in the CustomCounterBar.

v1.9.13:

- Added optional aura icon to the CustomCounterBar by request.

v1.9.12:

- Added a custom counter bar module by popular demand. Behaves exactly like a stack counter module, but in bar form.

v1.9.11:

- Fixed Anticipation not working in languages other than English. (ticket #194)

v1.9.10.1:

- Fixed error in the Runes module caused by improper usage of SetCooldown (ticket #189)

v1.9.10:

- Fixed CC modules sometimes catching the wrong debuff (thanks rmihalko! ticket #186)
- Added option to hide IceHUD when interacting with barber shops (ticket #190)
- Updated TOC to patch 6.2

v1.9.9.1:

- Fixed a bug causing buff/debuff watchers to not display for (de)buffs that didn't stack.

v1.9.9:

- Made Death Knight rune module cooldown wipes match the shape of the runes.
- Fixed possible divide-by-zero in the custom counter module.
- Added an option to only display a buff/debuff watcher when the tracked aura has more than X stacks (default 0) (ticket #185)
- Added support for tracking spell stacks and charges in the Custom Count module.

v1.9.8:

- Added Paladin Fist of Justice stun to the CC list by request.
- Updated TOC to patch 6.1

v1.9.7:

- Added Resolve module contributed by darkuja_9 and tweaked a bit.
- Added feature to turn burning embers green if the player has the codex of xerrath spell.
- Changed bar low threshold step from 5% increments to 1% increments by request.
- Added Stagger module from user pilonog.

v1.9.6:

- Updated the Chi module (HarmonyPower) to be able to display 6 Chi.
- Fixed errors that were being generated by a few different modules in weapon enchant-related situations due to an API changing in 6.0 that I didn't know about until now. (ticket #183 - thanks slippycheeze!)
- Fixed a bug where Monks with more than 4 Chi would not draw the additional Chi properly on initial load into the world.

v1.9.5:

- Fixed being able to cancel a buff from the PlayerInfo module when the frame's alpha was zero. Unfortunately the mouse click is still eaten, but at least your buffs don't pop off.
- Worked around a bug Blizzard created in 6.0 with cooldown wipes not updating alpha with their parent frame, specifically for Info modules. See <http://www.wowinterface.com/forums/showthread.php?t=49950> for discussion.
- Updated FAQ in the mod's config panel.
- Fixed ComboPointsBar not setting the proper alpha value sometimes.

v1.9.4:

- Inactive mode "Darkened" on class power counters now displays a darkened background behind a full/partially full rune as well as the old behavior of showing empty runes as darkened forms. This aids in class powers like Demonology Warlocks who need to be able to see the full bar.
- Fixed "divide by zero" errors that could happen in class power counters when switching specs.
- Fixed Hide Blizzard Frame option not properly hiding and showing all Warlock Power built-in frames for all specs.
- Info modules now display a random stack count from 1 to 5 when in configuration mode for easier Stack Font Size configuring.
- Fixed error generated by configuration mode with a CC module enabled.
- Allow players to cancel their buffs outside of combat on the PlayerInfo module. (ticket #182 - thanks Thyraxion!)
- Added support for ComboPoints, ComboPointsBar, and SliceAndDice to display with no target selected.

v1.9.3:

- Fixed Vengeance- and Sunder-related 6.0 errors.

v1.9.2:

- Fixed a few more errors popping up for specific classes with specific modules setup.

v1.9.1:

- Fixed a bug with custom cooldown bars that existed prior to v1.9 causing errors when opening the configuration screen.

- Fixed a localization-related issue causing an error for all locales.

v1.9:

- WoW 6.0 TOC and compatibility updates. Rogue combo points will only be displayed when targeting an enemy for now until Blizzard adds an API to get combo points without a target.
- Made the GCD bar respect global bar alpha settings. (ticket #126)
- Added support for tracking inventory item cooldowns on a custom cooldown bar. (ticket #123)
- Fixed CC bars sometimes not updating and displaying when they should. (ticket #142)
- Adjusted min/max icon offset positions for icons on the PlayerHealth bar. (ticket #136)
- Fixed how class power counters (warlock power, holy power, shadow orbs, chi) are scaled so that they don't scale at strange angles when they're off-center. (ticket #130)
- Added a "When targeting" mode to custom cooldown bars that will always display the bar when a target is selected and never when no target is selected. (ticket #128 - Thanks lisimba!)
- Fixed CustomCDBar not displaying correctly in 6.0 when in "When ready" mode.
- Added option to not show GCD when casting a spell longer than the GCD. Defaults to the previous behavior of always showing GCD. (ticket #120)
- Added the ability to track custom units on buff/debuff watchers. (ticket #115)
- Fixed bug with the player's mana bar not updating its alpha properly when entering the world (i.e. teleporting/hearthing/etc.).
- Added support for the "custom lag tolerance" setting to the castbar's lag display. (ticket #178 - Thanks slippycheeze!)

v1.8.18.1:

- Fixed a bug causing combo points to always display in Numeric mode for any class instead of hiding when the player has 0 combo points and 0 anticipation stacks.

v1.8.18:

- Integrated a feature by slippycheeze that enables the current threat target's name to be displayed in the "lower text" portion of the Threat bar. <http://www.wowace.com/addons/ice-hud/tickets/176-show-name-of-threat-holder-and-color-based-on-their/>
- Possibly fixed some NaN/divide-by-zero errors that have been cropping up sporadically lately.
- Merged support for displaying Anticipation on the ComboPoints module (thanks MSaint!) <http://www.wowace.com/addons/ice-hud/tickets/154-anticipation-enhancement/>
- Fixed a bug where buff/debuff watchers were not removing themselves from the central Update list when deleted.
- Fixed an issue causing cooldown bars set to "when ready" to not display if the player had no target but the spell was castable on the player and ready to be cast.
- Packaged latest version of LibDogTag for some memory and performance improvements (should reduce "script ran too long" errors).

v1.8.17:

- Added 90 degree rotation as an option for mirror bars.
- Added support for DogTag strings on buff/debuff watchers.
- The "Dismiss" option in pet right-click menus is no longer disabled for Warlocks.
- Removed extremely old pop-up messages on startup that were appearing for new users.
- Ticket #173: added a toggle to hide the entire HUD during pet battles.
- Added a toggle to only show cooldown modules when you have a target selected for abilities that don't require a target to cast, by request.

v1.8.16:

- Updated TOC to patch 5.4
- Added Absorb modules for focus, target, and player.
- Added Monks as eligible "tank" classes for the Vengeance module.
- Merged Zahariel's support for the Nine-Tailed SnD bonus duration (ticket #174)

v1.8.15.1:

- updated TOC for the options module so it loads in 5.3

v1.8.15:

- updated TOC to patch 5.3
- fixed a bug in the Warlock module when using numeric mode and switching specs

v1.8.14:

- updated TOC to patch 5.2
- <http://www.wowace.com/addons/ice-hud/tickets/145-hunter-pet-dismiss-error/> blacklisted the "dismiss pet" menu entry in pet right-click menus. Hunters should use the Dismiss Pet spell instead.
- <http://www.wowace.com/addons/ice-hud/tickets/167-shaman-totems-cant-be-clicked-off/> disabled right-click-destroy on totems
- <http://www.wowace.com/addons/ice-hud/tickets/171-cc-bar-not-showing-monk/> added Monk CC spells

v1.8.13:

- fixed an error in the options module not being updated for 5.1

v1.8.12:

- updated TOC to patch 5.1
- fixed a bug with Chi power in 5.1

v1.8.11:

- fixed PVP icon showing up as a green square for Pandaren who have not yet chosen a faction. this fix applies to TargetHealth and PlayerHealth, but not to DogTag text such as on the TargetInfo frame.
- ticket #161: integrated Zahariel's fix for gradients.
- ticket #157: fixed an error when a channeled spell ends early due to being hit. (Thanks, cg110!)

v1.8.9:

- fixed an error when entering/exiting an instance as a Monk

v1.8.8:

- fixed SnD duration prediction for 5.0 (thanks Zahariel!)
- maybe fixed reported error message when mousing over a (de)buff in an Info module

v1.8.7:

- fixed Holy Power only showing 3 max on login instead of 5

v1.8.6:

- fixed a bug where the shard module could sometimes show zero runes on the graphical display after entering or exiting a dungeon
- packaged the latest version of libdogtag-unit that fixes some errors when using talent-based tags in 5.0

v1.8.5:

- fixed an error message displaying when opening the options menu as a priest
- removed level restriction on harmony power since apparently that's not a thing any more.
- fixed the fifth chi not always drawing immediately when changing specs to one that grants an additional chi.
- updated harmony power module to refresh itself more frequently so it's more accurate

v1.8.4:

- added another FAQ to the list
- fixed the numeric display mode for class power counters sometimes showing "..."
- added support for changing the outline/shadowing of all non-DogTag strings on all modules
- added support for showing the numeric value on top of a class power's graphical display. this number can also be moved vertically.

v1.8.3:

- fixed a few more causes of taint showing up in the glyph ui
- fixed Holy Power non-'Graphical' modes having the images vertically squished
- fixed a few 5.0-related errors appearing in the Threat, CC, and invuln modules.

v1.8.2:

- fixed Warlock burning embers/soul shards not updating when applying or removing a glyph that changes the total number available

v1.8.1:

- fixed IceHUD causing taint when applying glyphs

v1.8:

- updated TOC to patch 5.0.4
- full 5.0/MoP compatibility (Monks, new class powers, API changes, etc.) while maintaining 4.x compatibility as well

v1.7.10:

- fixed an issue where buff/debuff watchers and cooldown watchers would sometimes get stuck and not update

v1.7.9:

- added some localization entries that were causing errors trying to open IceHUD's options

v1.7.8:

- fixed a few cooldown bar oddities that 4.3 brought up
- added a toggle to disable tooltips on Info modules

v1.7.7:

- updated TOC to patch 4.3
- enabled the Totems module for druids since 'wild mushroom' is considered a totem (ticket #137)
- only do spell id exact-match checking if "exact match" is set. otherwise, it will compare spell names
- updated to accept either a spell id or a spell name for custom bars. this allows tracking of different debuffs with the same name (such as Hemorrhage and its DoT). thanks to Nibelheim on WoWInterface for this one as well.
- new 'max health' formula from Nibelheim over on WoWInterface (thanks!)

v1.7.6:

- updated TOC to patch 4.2
- fixed reported error in the CustomBar module
- fixed error when selecting any of the last 4 presets in the list

v1.7.5.1:

- removed the pet happiness DogTag from the PetInfo module default setting now that pet happiness is gone in 4.1

v1.7.5:

- updated TOC to patch 4.1
- fixed patch 4.1 breakages:
-- removed all references to pet happiness
-- re-implemented pulsing animations for shards and holy power since the Blizzard built-in animation system is now broken (or at least functioning differently than it used to)

v1.7.4.4:

- fixed custom cooldown bars not working quite right with the 'When ready' display mode
- fixed PlayerInfo to only show the "buff canceling is disabled" message when a buff is right-clicked instead of any button click. also clarified the popup message to better explain why the feature is currently disabled
- hid "Low Threshold Color" toggle for the PlayerAlternatePower bar since it doesn't make sense for that module
- exposed the "Low Threshold" option to CC bars by request
- added an oft-requested option to treat friendly targets the same as not having a target at all for alpha purposes. this allows people who want the HUD to be hidden when they don't have a target to stay hidden when they target a friendly, for example
- fixed a bug where targets with rage or runic power were considered 'empty' (for alpha purposes) at 0. this was causing them to show up when they shouldn't based on alpha settings
- made custom (de)buff watcher bars respect the bForceHide option for :Show() so that they are properly hidden when a profile change occurs or they are manually disabled via the options menu
- fixed the elite (classification) icon for targets to respect the "lock all icons at 100% alpha" setting

v1.7.4.3:

- added new option (enabled by default) to have buffs and debuffs in Info modules sorted by expiration time instead of the order the game returns them in (application time?)
- ticket #116: first attempt at an honest-to-goodness alternate power bar. i don't raid, so i've only tested this against the alternate power in The Maw of Madness in Twilight Highlands...
- GCD bar now stops early if the player aborts the cast or is interrupted (thereby not actually triggering a GCD)
- ticket #119: copy alwaysFullAlpha setting to the mirror bar instance
- ticket #121: patch for new visibility mode in CustomBars
- added spellids for silence from elemental slayer enchant + unglyphed avenger's shield (thanks Mikk)
- ticket #117: respect the user's mod-wide "enabled" setting when changing profiles
- cleaned up some logic that could cause errors when enabling the mod due to a profile switch when the player initially loaded with it disabled

v1.7.4.2:

- added feature to custom cooldown bars to allow them to show/hide with the rest of the mod instead of having special rules (if desired)
- added ability to ignore a spell's range/target castability if desired on a cd bar. this allows the bars to display when a buff is ready even if it can't be cast on your current target, for example
- fixed an issue where focusing a unit in combat could cause taint in the FocusHealth module
- added new user-submitted bar textures (ticket #111)
- "fixed" (read: worked around) crash that IceHUD was triggering in the client by implementing a Lua-only version of UnitSelectionColor(). the crash was triggered by having DogTags disabled, TargetInfo enabled, and leaving an instance while in combat with one of the instance's mobs targeted (ticket #110)

v1.7.4.1:

- exposed upper text on snd bar since the string specified there is actually used by the module
- disabled the potential duration text on the SnD module when the user has duration alpha set to 0
- fixed a bug where an error message would pop up when enabling the FocusHealth module while a unit is focused that has a raid icon assigned to it
- fixed custom bars not monitoring weapon enchants/poisons correctly
- fixed custom bars and cooldown bars drawing at full alpha at all times
- fixed the threat bar flickering in configuration mode
- added spell ids for holy word: sanctuary and serenity since GetSpellCooldown() is bugged with them by name
- converted DHUD skin from blp to tga because it's acting funny as a blp (ticket #106)

v1.7.4:

- added custom upper/lower text coloring to buff/debuff bars and cooldown bars since they don't have any dogtag support
- fixed lower text to be visible on custom buff/debuff bars and custom cooldown bars
- re-arranged text settings page so that options are laid out more clearly/naturally
- split the "buffs per row" setting to exist in both buffs and debuffs sub-groups instead of being a module-wide setting (ticket #103)
- added an option to enable/disable mouse interaction on totems
- fixed debuffs on info modules not drawing the proper colored border for the type of debuff
- fixed buffs not displaying the stealable border for mages if they were stealable
- fixed an error when changing from a profile with markers on a module to one with fewer/no markers on the same module
- fixed SnD bar (and potential duration bar) to show and hide much more reliably. previously it would sometimes not display the potential duration or the entire module would be visible when it shouldn't be
- fixed SnD duration bonus from glyph (to 6 seconds from 3)

v1.7.3.11:

- picked up latest version of LibRangeCheck to fix ranges reporting incorrectly for holy paladins
- fixed some errors that could pop up with totems and custom bars
- fixed low threshold flashing on custom bars

v1.7.3.10:

- added support for custom buff/debuff trackers to be able to track totems by name
- fixed layer ordering such that icons draw in front of bars again
- minor performance optimizations in class counter modules (holy power, shards)
- changed custom cooldown bars back to never forcefully hide themselves when set to 'always' display mode. they will now respect the global transparency settings instead
- added user-submitted CleanCurvesOutline texture which allows DHUD-like casting to be placed on top of another bar and only the outline fills up instead of the whole bar

v1.7.3.9:

- minor performance optimizations
- fixed custom buff bars and cooldown bars multiplying alpha values when they shouldn't have been. at low alpha this meant that they were much more transparent than they should have been
- fixed pet health/mana modules getting stuck on the player when leaving an instance while on a vehicle
- re-fixed a bug causing the player mana module to not update color when a druid left an LFD instance while in a form and was immediately placed back on a mount and not in a form
- fixed configuration mode error in the player info module when the player had weapon buffs applied (ticket #104)

v1.7.3.8:

- hopefully fixed a few error messages that have been reported, though I haven't been able to reproduce the error messages myself

v1.7.3.7:

- added a toggle for the "override alpha" behavior that displays class counters at in-combat alpha when out of combat if the counter isn't full/empty
- fixed the "debuff size" settings getting reset after every ui reload or log out/in
- fixed an issue where the wrong texture could get applied to death runes when changing zones
- fixed markers generating errors or just misbehaving when changing profiles (ticket #102)

v1.7.3.6:

- fixed PlayerInfo module misbehaving with temporary weapon enchants

v1.7.3.5:

- minor optimization in the threat bar
- fixed secondary threat bar to display properly again
- added support for pets to the second highest threat feature

v1.7.3.4:

- fixed the GCD bar not animating

v1.7.3.3:

- maybe fixed an issue where some bars (most notably the cast bar) could get stuck
- fixed occasional flickering in the cast bar and threat bar when they are first displayed
- fixed custom module creation not displaying a default
- fixed markers not updating when a bar's inverse mode is changed
- fixed markers not rotating with a bar when the rotation option is set at runtime
- fixed the player's health, mana and cast bars monitoring the wrong unit whenever the player leaves an instance while in a vehicle

v1.7.3.2:

- fixed the eclipse bar turning gray when adjusting settings that caused a Redraw()
- added ability to set icon sizes for debuffs separately from buffs in info modules
- rearranged the config screen for Info modules
- markers are now created at the proper alpha instead of 100%
- changed the 'update period' slider to represent number of updates per second instead of seconds between updates. now higher is more frequent and lower is less frequent which makes more sense to users
- fixed text staying hidden when disabling and re-enabling a module
- ripped ~1.3mb out of IceHUD itself and moved it into an LoD IceHUD_Options addon

v1.7.3.1:

- fixed markers stuck in inverted mode.
- fixed combining expanding & reverse fill options causing bars to position incorrectly.
- enabled the "expand" bar fill for the PlayerHealth & SliceAndDice modules.
- enabled bar rotation for the CastBar and Eclipse modules.
- added support for rotated markers.

v1.7.3:

- fixed an error message some users were seeing with certain fonts
- compressed buffs/debuffs in info modules to take up less vertical space when "buff size" and "own buff size" are set to different values
- fixed default Blizzard DK runes being shown when the user had "hide blizzard frame" checked in the runes module but wasn't hiding the player from from the PlayerHealth module
- made class power counters continue to display as long as they're not full/empty (depending on the class)
- more ongoing memory/garbage optimizations
- made castbars always register themselves for updates when shown. fixes a bug where opening the map fullscreen while casting will stop the cast bars from updating (ticket #97)
- most modules now support a new bar filling mode: expanding outwards from the middle.
- shamelessly ripped off code from pitbull4 to replace "set focus" in drop-down menus with instructions on how to do so
- added a check for the player's mana type when PLAYER_ENTERING_WORLD fires so that we adjust mana type properly when entering/leaving instances

v1.7.2.2:

- fixed the target cast bar to not freeze up and reset itself whenever a UNIT_SPELLCAST_INTERRUPTIBLE / UNIT_SPELLCAST_NOT_INTERRUPTIBLE event fires
- fixed the cast bar to actually use the CastChanneling color when channeling. since this was apparently never hooked up, i also changed the default color for CastChanneling to match CastCasting so that long-time users won't notice the difference unless they've explicitly set a channeling color themselves
- fixed an error introduced in 1.7.2 where the playerinfo's dropdown menu was trying to use the target's data instead of the player's data

v1.7.2.1:

- fixed an error that could crop up when tweaking colors
- fixed bars that don't support dogtags in their text blocks to say so in the tooltip instead of telling the user that they can use dogtags when they can't
- fixed late registration of textures via LibSharedMedia so that the ToT bar texture gets updated appropriately
- made height of the ToT frame configurable by request
- extended vertical offset min/max for info modules (ticket #92)
- fixed the Eclipse bar not showing up since 1.7.2 (ticket #93)

v1.7.2:

- automatically replaced Lacerate/Sunder/MaelstromCount modules with custom counters if the user was using them. custom counters accomplish the same thing and are much more fully-featured/configurable than the old per-ability modules were. the only downside to the new system is that custom counters are loaded regardless of the player's class whereas the old ones only showed for their appropriate class
- hid the "rotate 90 degrees" option on cast bars and eclipse bars since it just doesn't work very well and looks bad. users keep reporting that these are broken when rotating and since i don't have a good fix, i'm disabling the feature for now
- unified the behavior for configuration when a module is disabled. now the sub-configs (marker/text/icon settings) remain clickable but every element inside is disabled when the module is disabled. previously some sub-configs were not clickable at all and others were
- removed most of the rest of the garbage that was being generated during combat or when changing targets
- reduced cpu usage by 33%-50% across the board (and more in some cases) by changing how updates are registered and how often they run. now the 'update period' slider actually matters. it defaults to 0.033 meaning that frames update about 30 times a second instead of every frame
- fixed the "always" display mode for cooldown bars to respect alpha settings (ooc/with target/in combat/etc.)
- added level restrictions to shard and holy power class counters since players under 9/10 (different per bar, using constants provided by Blizzard) don't have those resources available yet
- finally (for reals, hopefully) fixed the gcd for all classes. gcd is a surprisingly difficult problem as there's no straightforward api for it
- fixed the vengeance module not grabbing the player's max health until a UNIT_MAXHEALTH event fired (caused #1.INF to display sometimes and bar to not function)

v1.7.1.1:

- set AceGUI-3.0-SharedMediaWidgets to load after LibSharedMedia to fix an error some users were seeing in 1.7.1

v1.7.1:

- fixed an error some users were seeing on login that caused icehud to not load
- changed the pet health/mana bars to monitor the player whenever the player enters a vehicle since the player bars already change to display vehicle info in that situation
- added AceGUI-3.0-SharedMediaWidgets support to the font selection box and ToT bar texture selection
- fixed a bug causing bar font size adjustments to not take effect/display until a ui reload
- super temp hax to make the custom cd bar work with "Holy Word: Aspire"
- added description text to each custom module explaining what type of module it is. it was pretty difficult to figure out what kind of custom module you were looking at in the config after you created it
- various performance and memory optimizations
- eclipse bar now colors the numerical value to whatever direction the bar is heading
- added a 'vengeance' tracking module by user Rokiyo
- fixed the cast lag indicator being completely wrong when using a meeting stone to summon someone

v1.7.0.9:

- no changes in IceHUD; publishing an updated version to get a fixed LibDogTag-Unit-3.0 out there and stop the errors popping up about talents from other mods

v1.7.0.8:

- very minor performance gain by not doing the per-frame update on invisible modules
- nuked the primary offender of garbage generation. there is more to get rid of but finding it is a tedious process
- fixed error caused by disabling click targeting on the targethealth frame
- added option for non-dogtag users to hide each line of text on the TargetInfo module individually
- fixed totem module not resetting totems when going through a load screen (entering/leaving instance, etc.)
- fixed 'inverse' mode to work with potential SnD bar
- expanded range of class power counters (shards, holy power) by request
- fixed lacerate and sunder count modules to work with 3 max charges instead of 5 as per the new patch (these *really* need to go away and be auto-replaced by custom counters...)
- yet another fix for text sometimes displaying the unit name for PetHealth
- fixed how the 'second highest threat' bar is drawn so that it actually works with all textures

v1.7.0.7:

- quick update to correct any click-through problems for Clique users until the new version gets pushed

v1.7.0.6:

- made several changes to how mouse interaction works with various modules to support new Clique changes available in its latest alpha version. once a new release of Clique is made, then the Info modules not being click-through will be fixed if the user doesn't want mouse interaction to work there.
- removed HungerForBlood module as the ability has been removed from the game
- fixed "bar visible" checkbox to also hide/show the solar portion of the eclipse bar
- fixed lower text popping back up when it shouldn't

v1.7.0.5:

- fixed snd glyph detection on the SliceAndDice module due to new return value on GetGlyphSocketInfo
- fixed certain buff types not displaying a tooltip on mouseover in the info modules
- fixed ability to set 'max count' to 0 and screw up a custom counter
- fixed bar text not properly hiding on bars that use RegisterUnitWatch to control visibility
- fixed scaling to affect the text and icons again like it used to

v1.7.0.4:

- added pulsing to the shard counter and holy power modules whenever they are maxed out
- added option to use out-of-combat alpha on class power bars (holy power, shards) when targeting a friendly
- fixed icons on the target health bar not always hiding when they should
- potentially fixed reported error message though i've never seen it pop up myself
- fixed icons rotating with bars incorrectly when setting bar to be rotated 90 degrees
- fixed default rune frame showing up sometimes when the player has the "hide blizzard frame" option disabled in the runes module
- fixed default runes from being incorrect (showing 6 blood runes) after re-enabling them from the runes module while the game is running
- fixed configuration mode not working since v1.7.0.3

v1.7.0.3:

- fixed CC module spell id's by removing spells/effects that no longer exist, adding some new ones, and updating id's of ones that have changed
- attempt to fix ticket #81 <http://www.wowace.com/addons/ice-hud/tickets/81-lua-error-in-eclipse-bar/>
- fixed text getting rotated along with bars when choosing the "rotate 90 degrees" option

v1.7.0.2:

- fixed Blizzard's default runes to be properly hidden if desired when the default player health frame is left enabled
- fixed gcd module to work for all classes without relying on specific spell ids

v1.7.0.1:

- fixed a few errors causing the holy power/shard modules to not show up and the IceHUD options screen to not display for Paladins or Warlocks

v1.7:

- fixed rotation of inverted bars to draw the bar correctly
- added ability for spell ids to be specified instead of names for custom bars and cooldown bars. when an id is typed it will attempt to resolve to the buff name
- fixed FocusHealth and custom health bars not disabling properly
- fixed /icehudcl to actually work again as a command-line interface to the options table
- changed all methods of opening the icehud config page into toggles (open the options page unless it's already open; if it's open, close it). this restores old behavior that was lost in the move to ace3
- removed the "abbreviate health" option from the focus health bar if the user is using dogtags since it doesn't apply then
- fixed the SnD potential bar to rotate properly with the main bar
- hid the "Low Threshold Color" option on custom bars and cooldown bars since the option doesn't apply to them
- updated the description of a few "low threshold" settings so they make more sense to users (don't reference variable names)
- fixed the "low threshold" flash to work properly on rotated bars
- fixed incoming heal bar to display properly on 4.0 clients
- added user-requested option to specify the space between each buff/debuff on the info modules
- now that Eclipse doesn't decay, use the appropriate alpha value regardless of whether or not the user has some power left over. it used to stay at the "in combat" setting until the bar was back at 0
- fixed a bug with "hidden" mode for inactive shards/runes where the unactivated runes would show up darkened when changing targets out of combat
- added new DHUD bar texture set and alternate elite/rare icons by request (ticket 80). the earliest place we found these textures was in the original DHUD which has no license at all, so it should be okay to use them. they are called DHUD in the mod, so it's clear that i'm not trying to pretend that we made them up or they are unique to IceHUD
- added the ability to further customize the shard and holy power modules by displaying all the existing custom counter textures in place of shards/holy runes and colorizing them based on how many are available
- added highlighting around buffs on the targetinfo module (and other *info modules) that are spellstealable if the player is a mage
- allowed pvp and party role icons to be offset more
- fixed a bug where cooldown timers wouldn't always reset when an ability was brought off cooldown early
- setup almost all text in the mod to support localization. only English is currently filled out, but all common languages are supported: <http://www.wowace.com/addons/ice-hud/localization/>
- added the ability to duplicate an existing custom bar
- setup the toc to properly strip out embeds.xml whenever it's building a no-lib version
- added support for automatically changing profiles when changing specs (LibDualSpec)

v1.6.12:

- added some more protection against people tweaking settings or changing profiles while in combat and added a warning message explaining that stuff could be broked if they manage to do it anyway
- fixed cooldown bars that are set to "when ready" to be properly hidden when the module is disabled or profiles are changed
- added calls to disable updates on custom modules as they are disabled so that they don't stick around on screen when they shouldn't
- minor fixes to enabling a module and how updates are handled that should allow custom modules to react appropriately when they are enabled while a player has the buff they're monitoring
- fix for custom modules generating a ton of errors if they're disabled while active (such as when changing profiles)
- added a tooltip to the LDB launcher
- set custom counters to display out of combat if they are not 0
- nuked the HungerForBlood module if the user is on a 4.0+ client since the ability is going away
- minor cleanup of the GCD module to make it (hopefully) more reliable
- doubled the maximum width of the rangecheck frame to ideally knock out the occasional complaint that certain fonts make the text spill onto a second line (never seen that myself)
- moved all "icons" settings from being under a header to being in their own group. this should unify the "icon settings" features of all modules
- added party role icon to TargetHealth module (and CustomHealth by virtue of inheritance)
- fixed the GCD to update its bar color as the user changes it instead of requiring re-enabling the module or reloading the ui
- clarified some tooltip text on the TargetInfo module's text blocks
- added DogTag support to the ToT module by request

v1.6.11.1:

- fixed the GCD module to be available in the module settings list again
- tweaked options visibility and made 'bg visible' work on the GCD module

v1.6.11:

- fixed a bug where the combat icon would get stuck if you went into combat when resting but had the resting icon display disabled
- made the combat icon replace the resting icon if you go into combat while resting and then switch back to the resting icon (if appropriate) when dropping combat
- changed all step = 10 to step = 1 on range options by request
- widened range of possible vertical offset values for the custom counter module by request
- removed the last remnants of Ace2 (AceOO-2.0 and AceLibrary) thanks to a huge amount of help with metatbles from ckknight
- fixed up several "hide blizzard frame" options to re-display when the module is disabled and to call blizzard's OnLoad for the frame instead of manually entering every event to re-register
- fixed "show incoming heals" option to be properly toggleable on 4.0 (bad conditional on the 'disabled' option)
- hid "cooldown mode" option on the totems module since there was never more than one choice
- re-added "enabled" checkbox in the settings to allow users to completely enable/disable the mod (this seems to have been something we got for free with one of the ace2 libraries and is no longer present after the move to ace3)
- registered callback for media updates from LibSharedMedia so that the mod's fonts/ToT bar texture can be refreshed if necessary

v1.6.10:

- should resolve issues that some users were seeing with their settings not being loaded properly
- minor optimization of frame rotation by un-registering the event listening for animation completion after it has done its job
- made GCD module animation smooth by utilizing the existing animation system instead of trying to run another repeating timer over the top
- hid the marker settings on the GCD and Eclipse modules as they don't make much sense to have there
- after renaming a custom module, set the mod to automatically select it in the options menu
- added support for defining markers on any bar (ticket 75)
- added rough implementation of horizontal bars by abusing some features of Blizzard's UI animation system. we'll see if there's any actual demand for this to determine if the feature needs to be improved at all (ticket 60)
- big giant options screen usability cleanup: colorized the FAQ and Module Settings description text to be more readable, removed custom coloring from certain options that didn't match the rest, hid a few debug-only settings, consolidated all the 'create custom module' buttons into a drop-down + create button, clarified description of some options so that their intent/purpose is more clear, moved around/cleaned up headers for consistency, doubled the width of long options so that they don't get cut off and ...'d

v1.6.9:

- removed Deformat as it's no longer necessary
- made all pop-up dialogs display on top of the options screen so that they're actually visible at lower resolutions
- made custom modules get auto-selected in the options screen after they're created
- added basic implementation of Eclipse bar for balance druids
- added shard bar inheriting from ClassPowerCounter. same basic functionality as the holy power module: graphical mode that shows the default shards and numeric mode that just displays a count of active shards
- replaced AceEvent-2.0 with AceEvent-3.0/AceTimer-3.0
- fixed reported taint issue from people joining or leaving a party in combat with the "hide blizzard party frames" option set on the PlayerHealth module
- updated all UnitPower code to use the SPELL_POWER_ constants instead of hardcoding numbers...mostly just a readability change
- fixed a bug where custom counters were not getting reset on target change or player death. this could cause an issue where the counter would not update when it should
- potentially fix some text overflow issues that were reported with the range finder
- added LibDBIcon to bring back the minimap icon
- don't hide the Blizzard version of Holy Power by default since we're not hiding the Blizzard player frame by default

v1.6.8:

- removed FuBarPlugin-2.0 as it's no longer used
- added a bit more user friendliness to the new configuration page. efforts to increase awareness about how to setup the mod and get help are ongoing
- added a message to the PlayerInfo module when trying to dismiss a buff in cataclysm explaining that the API is currently protected and unable to fixed. this will be removed when Blizzard gives us a way to work around it
- added upgrade detection to alert users that their profile may need to be re-selected if the last version they ran was pre-ace3-conversion
- added an FAQ section to the /icehud configuration page so that users don't have to go to one of the addon hosting sites to get their questions answered

v1.6.7:

- added basic implementation of Holy Power for Cataclysm Paladins. has a graphical mode (basically matches Blizzard's built-in frame without the background) and numeric mode (which just displays the number of runes active as 0/1/2/3)
- updated UnitGroupRolesAssigned check for the new return value
- added proper color for player focus (cataclysm hunters) on the PlayerMana module
- minor documentation fix for the incoming heal notification on the player health bar to indicate that it requires either libhealcomm-4 or cataclysm to function
- embedded libdatabroker and removed old fubar code (use broker2fubar if you still want a fubar plugin)
- updated to use UnitGetIncomingHeals instead of LibHealComm when running cataclysm client. doesn't seem to work with HoTs at the moment, so that's something to keep an eye on as the beta progresses
- fixed DK Runes module 'alpha' mode from never coming back to the correct 'usable' alpha
- converted most of the mod to ace3. the only ace2 remaining is AceEvent-2 (probably easy to get away from) and AceOO-2 (not so easy)
- the ace3 conversion also broke the dependence on Waterfall and gave a much better configuration screen through AceConfigDialog; plus Waterfall is very broken in Cataclysm and it's unclear whether anyone will bother to fix it or not
- fixed a bug with the custom CD bar when changing profiles where it would generate endless errors until a reloadui
- removed DewDrop library as it was no longer in use
- removed an unused 'about' button on the config page and some empty headers...not sure why they were ever there
- simplified GCD module to pass the spell id when calling GetSpellCooldown; apparently this didn't work at some point in time but was fixed around 3.3.2ish and works in cata as well
- fixes for cataclysm: added UNIT_POWER/UNIT_MAXPOWER event registrations in place of all the old power types, fixed mirror bar, targetinfo, and targetoftarget SetScripts to pass 'this' and 'arg#' around where necessary
- forcibly set bar upper/lower text width to 0 after setting their contents so that they auto-resize to the proper width. some massive bar/font sizes were causing strings to get cut off

v1.6.6:

- added focustarget and pettarget as valid units to look for buffs/debuffs on with a custom bar
- made custom bars able to track auras (buffs with no end time like paladin auras, righteous fury, stealth, etc.)
- fixed a few taint issues in the ToTHealth
- fixed a few edge cases where custom cooldown bars would not display when the spell was ready and the bar was set to "when ready" mode. this could happen if the player ran out of mana then gained enough back to cast the spell or for ranged spells where the target moved in and out of range
- added generic custom health and mana bars so that users can monitor any unit they want complete with click-targeting/-casting
- added click-targeting to pet health module
- added optional scaling to spell icons on the cast bars, custom bars, and cooldown bars
- fixed bars disappearing when they were set to reverse and they filled up
- fixed an issue where deleting a custom cooldown bar while it was set to "always" display would cause it to get stuck on the screen until the next UI reload
- fixed an issue where right-clicking weapon buffs in the PlayerInfo module wasn't canceling weapon buffs
- fixed an issue where weapon buff cooldowns would flicker every second in PlayerInfo

v1.6.5:

- fixed a bug with custom cooldown bars that would cause the bar to flash during the GCD if a maximum duration was specified higher than the GCD time
- user-submitted patch for an 'invert' option in addition to the 'reverse' option for all bars. now 'reverse' controls bar movement direction while 'invert' controls bar fill behavior <http://www.wowace.com/addons/ice-hud/tickets/73-reversing-cast-bars-and-channels>
- added option to hide TargetOfTarget modules if the player is the active target
- added individual checkboxes to show buffs/debuffs in any info module that derives from (or is) TargetInfo (which should be all of them)
- added user-submitted Role icon to the PlayerHealth bar for random dungeon groups (Thanks Grim Notepad!)
- fixed an issue where a disabled custom bar was always showing its icon as the default IceHUD icon and was not being properly hidden
- added a "second highest threat" overlay to the Threat module that shows where the next-closest person is on the threat bar (in terms of their raw threat value divided by yours) if you're the current tank.
- if "always display at full alpha" is checked for slice and dice bar, then don't let it hide itself

v1.6.4:

- fixed the slice'n'dice duration bar from not showing up when one of its alpha values is set to 0
- when a custom CD bar is set to "when ready" display mode, it will only display an empty bar. therefore, empty should behave like full for the purposes of alpha ooc/target/etc. settings
- fixed "when ready" option for the custom cooldown bar not working as intended (it was showing when ready OR cooling down)
- this should also remedy any issues that users are having since 3.3.5 if they do not have Ace2 installed as a separate library and are not using any other Ace2 mods that have updated since 3.3.5. there was an issue in one of the ace libraries with the 3.3.5 chat frame updates that broke Ace2

v1.6.3:

- added an option that allows a custom bar to track a substring or full name at the user's discretion. previously it was always a substring match. this was causing a custom bar for "trauma" to also trigger for "mind trauma", for example.
- fixed maximum duration configuration not working for cooldown bars
- fixed a bug where the player's icons (specifically seen with the party leader icon) would go full alpha when they first appeared instead of the proper alpha value
- changed DK GCD spell to death coil from plague strike

v1.6.2:

- fixed pet health to be colored properly whenever the "color bar by health %" option is checked
- split the buff/debuff filter into a buff filter and a debuff filter
- possibly fix weird issue where GetClassColor could be called with a function argument from somewhere...I can't reproduce the error, but several people have reported it, so this ought to fix it.
- fixed button mashing while casting channeled spells causing the cast bar to get cut off when it wasn't supposed to
- added an optional icon to the player and target casting bars that shows which spell is being casted/channeled. default is off
- fixed the cast lag indicator, the incoming heal indicator, and aggro pull indicator to draw on the proper area of the bar when the bar is set to reverse direction
- fixed the incoming heal bar being invisible sometimes (such as the bar alpha being 0 when OOC, >0 when not full, and the player being OOC with a non-full bar)

v1.6.1:

- user-submitted change care of JX: Added "Display when ready" option to Custom Cooldown bar to replace "Display when empty" toggle.
- added an optional icon to be displayed alongside a custom bar and cooldown bar that shows what spell the bar is tracking. default is off
- integrated a user-submitted cleanup of how we were managing bar texture clipping after 3.3.3's mess. this binds the texture to the frame and calls SetHeight on the frame instead of the texture as well as unifies the "reverse direction" behavior a bit
- added protection against giving a custom bar/cooldown/counter an empty name causing it to disappear from the options list
- added a feature to display a different cast bar color (red by default) if a target's spell is non-interruptible. took implementation from blizzard frames (including mid-cast event hook). enabled by default.
- made "Reverse direction" option be grayed out if the bar is disabled
- added "maximum duration" feature to cooldown bars by request
- added module to represent combo points in bar form by popular demand
- fixed the player's clickable area when using the ArcHUD texture to be on the outside edge of the bar instead of the inside

v1.6:

- fixed an issue with HiBar and GlowArc causing random textures to appear on the screen
- added user-submitted "max duration" functionality to custom bars such that they can always be a fixed time period
- fixed a couple of issues that could cause the SnD bar to display incorrectly
- fixed an issue causing a weird shadow to appear on the player health bar without LibCommHeal-4.0 installed
- made sure to set the default height on the slice'n'dice bar to 0 to make sure it doesn't go crazy
- fixed the 'bar visible' checkbox to work again

v1.5.18:

- fixed giant green bar that would appear for players who had "show incoming heals" disabled
- fixed sunder count module generating an error and not functioning

v1.5.17:

- fully fixed for WoW 3.3.3 (as far as we've tested). please submit all bug reports in this version on the comments page

v1.5.16a:

PLEASE NOTE: this is a VERY temporary stop-gap solution to fix IceHUD for the short term. This update forces ALL users to use the RivetBar texture as it's the only one that's currently functioning (since it's a vertical bar it's easy to fake). There WILL be another update once the mod is back in full working order, but everyone has been so generous and supportive so I wanted to get something out. Other changes included in this update are:

- hopefully fix a bug where the cast bar could sometimes try to access nil
- added user-submitted modifications to the threat bar so that mirror image and fade will display the threat the player will have when they wear off. this is largely untested by me
- added user-submitted "reverse direction" option that lets bars fill top to bottom instead of bottom to top
- added user-submitted horizontal position slider to lacerate count module
- added vertical offset option to the mirror bar handler
- close the config window if the user tries to open it when it's already open (<http://www.wowace.com/addons/ice-hud/tickets/33-toggle-ice-hud-on-and-off/>)
- added user-submitted PlayerCC and Target/PlayerInvuln classes
- added user-submitted root and silence groups to the CC modules
- filled out CC list a bit more with user-submitted spell id's
- (by: Phanx) Added support for CUSTOM_CLASS_COLORS (ticket #26)

v1.5.16:

- updated interface version to 3.3
- added Entangling Roots and Intimidating Shout to the CC list
- replaced libhealcomm-3 support with libhealcomm-4 support

v1.5.15:

- updated the incoming heal bar to use the correct color
- fix for user-reported runes error
- the player's cast bar can now optionally change color whenever the target goes out of range. this is currently enabled by default
- added support for custom bars to track by substring instead of an exact match

v1.5.14:

- fixed user-submitted totem bug: <http://www.wowace.com/addons/ice-hud/tickets/29-error-when-dismissing-totems/>
- changed the vertical position extents for TargetOfTarget to 600 instead of 300 by request
bug <http://www.wowace.com/addons/ice-hud/tickets/28-add-hex-to-target-cc-module/> - added Hex to the CC list as an incapacitate effect
- fixed a custom bar bug for users with rock + fubar that tried to use the right-click cascading menu to configure things

v1.5.13:

- added PetInfo module
- fixed some vehicle issues in ulduar

v1.5.12:

- bumped TOC to 3.2

v1.5.11:

- fixed custom textures not applying to low threshold, cast lag indicator, aggro indicator, slice'n'dice duration preview, and incoming heal amounts
- Hopefully fixed issues with Party Frames being shown when Pitbull and other Unit Frame addons are present

v1.5.10:

- fixed custom bars throwing all sorts of errors when creating/changing profiles with them active
- fixed the pet/vehicle cast bar not being hidden when hiding the "blizzard cast bar" via the player cast module
- changed GetDifficultyColor to GetQuestDifficultyColor. looks like this function was deprecated a while ago, but was removed in 3.2
- fixed the "hide blizzard buff frame" checkbox not hiding temporary enchants (weapon buffs)
- Added an option to PlayerHealth, to disable party frame even when not in raid.
- added user-submitted totems module based on the runes module
- added a focus threat module by request
- increased maximum horizontal text offsets for all bars
- added 'force justify text' options to the player cast bar like most other bars already had
bug <http://www.wowace.com/projects/ice-hud/tickets/18-use-new-vehicle-api-to-switch-player-bar-to-vehicle/> - added support to player health, mana, and cast bars to change which unit they are monitoring to be the vehicle when the player enters one
- made custom bars and counters not be case-sensitive in their spells-to-be-tracked
- Added option to activate both Alpha and Cooldown to DK runes

v1.5.9:

- includes newest version of LibDogTag to fix "double-free syndrome" error

v1.5.8:

- fixed alpha on the target cast bar when "ooc and not full" transparency is set to 0 and "ooc and target" is non-zero
- made tooltips on the custom bar/counter/cooldown bar more helpful
bug <http://www.wowace.com/projects/ice-hud/tickets/20-alt-tabbing-to-windows-mode-breaks-bars-in-osx/> - re-converted ArcHUD textures to blp using a tool that produces more reliable results
bug <http://www.wowace.com/projects/ice-hud/tickets/19-entry-on-blizzard-addon-options/> - added an entry to the default interface/addon options panel which opens IceHUD's configuration
- added user-submitted custom cooldown tracker module. thanks regmellon!
- re-added missing FangRune bar texture from the selection list

v1.5.7:

- added buff timer configuration modes to the custom bar
- added a rough version of tracking weapon buffs to the player info module
- added a 'display when empty' option to the custom bar that will make it still draw even if the specified buff/debuff is not present
- removed some very old settings migration code that was causing problems for new users. this was added a very long time ago to facilitate the move from account-based settings to profile-based settings which should be completely unnecessary now
- added an option to allow modules to hide the animation options in the configuration panel
- made SnD hide the animation options so that people can't break the bar by enabling animation

v1.5.6:

- added ability to specify a different texture on individual bars than the global one chosen on the main bar configuration panel
- added more reminders that you have to press Enter after typing strings into various configuration panels before they will save
- added support for the PlayerInfo module to hide the default buff frame
- added support for mh/oh weapon enchants to the custom counter module
- added the ability to track mh/oh weapon buff durations with the custom bar
- if a module is set to always be at 100% alpha, make sure the internal 'alpha' variable is set to 1 or else any custom color's alpha will override it

v1.5.5:

- added a ToT cast bar (disabled by default)
- added a couple of reminders to press [enter] after typing into text boxes in the custom bar/counter configuration screens
- fixed a bug causing rune cooldowns to not reset when the player died/res'd if the module was in alpha mode
- fixed display of buffs on the player not cast by the player for custom bars

v1.5.4:

- NaN-safe'd IceHUD's Clamp function to finally put the kibosh on any SetTexCoord errors
- fix for a bug causing the runic power (and theoretically any other mana type) bar to sometimes not update if the player spent all of his remaining runic power/rage (or gained full mana/energy) at once
- added support for binding a custom bar/counter to a larger variety of units (pets, focus targets, etc.)

v1.5.3:

- fixed an issue with buff filtering not working properly for looking at buffs only cast by the player.
- added some nil checks to avoid a few rare "accessed nil" errors

v1.5.2:

- bumped TOC to mark compatibility with wow 3.1

v1.5.1:

- added a PlayerInfo module (off by default, user requested) that inherits from TargetInfo and adds right-click dismissing buffs functionality
- made custom bars/counters work with alpha settings properly
- made multiple custom bars work together nicely...bad programmer for making local properties instead of class properties

v1.5:

- created a custom bar that the user can create while running IceHUD that will track a given buff or debuff on the player or his target
- added CustomCount module that behaves like the custom bar, but lets the user create a custom counter (the same as the sunder/lacerate/maelstrom counters)
- fixed up the buff/debuff retrieval convenience functions to work off either texture name or buff name. also changed up how it picks whether or not to get only buffs from the player
- increased the min/max vertical offset for bars by request
- fixed a minor typo in the maelstrom counter options

v1.4.4:

- fixed a bug with text alpha being unchangeable with LibDogTag usage disabled
- added toggle to enable/disable showing incoming heals on the player's health bar. also cleaned up the implementation a bit to display more consistently and hide when appropriate
- added toggles to show/hide spell cast time and spell rank on player/target cast bars
bug <http://www.wowace.com/projects/ice-hud/tickets/16-visual-heal-support/> - added support for LibHealComm by request. not included with the mod, but listed as an opt dep
- added LDB support by request/from user-submitted code. this basically will only work if a mod that loads before icehud has LDB included
- fixed HfB buff % (from 3 to 5) and added a version check so that it's correct whenever 3.1 comes out as well (goes to 1 charge of 15% instead of 3 charges of 5% each)
- updated AceAddon-2.0 so that the donation frame is gone

v1.4.3:

- fixed divide-by-zero causing a crash on the PTR (this *really* shouldn't cause a crash since it's UI script, but it would appear that the engine is not check for div-by-0 on the PTR. this could potentially happen in a lot of other places...)
- fixed bug <http://www.wowace.com/projects/ice-hud/tickets/13-low-health-colour/> - added user-submitted ability to color a bar based on the low threshold. if it's above the threshold, the bar is max health/mana color, below the threshold is min health/mana color
- added a toggle to allow specifying whether or not to flash a bar when it falls below the low threshold
- fixed bug <http://www.wowace.com/projects/ice-hud/tickets/14-taint-issue-with-focus-module/> - changed to using RegisterUnitWatch on the focus module
- added a configurable RunicPower color to the player, target, and tot mana bars
- made runic power behave like energy and rage for the "low threshold" flashing behavior
- properly set flash frame bar width
- fixed a castbar bug with channeled spells

v1.4.2:

- made the cast bar lag use the bar texture instead of the background texture. works much better to color on top of
- fix for a bug involving an error message when targeting certain players
- added user-requested toggle to color the TargetHealth bar by hostility if the target is an NPC and the bar is set to use class coloring (instead of health % coloring)
- cleaned up the options and options dependencies a bit in the target health module

v1.4.1:

- fixed a bug introduced in 1.4 that was causing taint in the target health module
- added a fourth line of text (empty by default) by request to the TargetInfo module
- fix for HfB text staying on the screen after the buff has timed out (Thanks Tunde!)

v1.4:

- set HfB bar to be always visible (even with 0 duration) because secure/clickable frames cannot be dynamically shown or hidden during combat unless they're directly tied to a unit's targeted status
- cleaned up "allow click casting" option to properly disable itself without having to reload the ui
- re-added click-targeting on the target health bar (optionally). this time using RegisterUnitWatch so that it shows and hides properly even in combat
- made the threat module use raw threat percentages by default so that its display matches Omen's.
- added an option to the threat module to display the scaled percent (the old method) instead of raw. this will cause it to disagree with Omen, but it's displaying the same information, only in a different way
- fixed range check module to work with dogtags disabled
- separated alpha settings for "OOC and target" and "OOC and not full"; existing user settings are preserved (target gets copied to the new Not Full setting) the first time this version (or later) of the addon is loaded by a user with existing settings
- added settings to allow greater customization of buff/debuff frames in the TargetInfo module (grow direction, anchor points, offsets)
- unified icon configurations for the target health bar (pvp, raid, classification) and prettied up the options a bit
- added graphical gap settings to combo points, lacerate/sunder/malestrom count, and runes modules
- "Reset" configuration now works properly (<http://www.wowace.com/projects/ice-hud/tickets/10-unable-to-reset-with-a-error/>)
- changed default GCD spell for rogues to be sin strike instead of cheap shot
- fixed a potential nil access if some other mod has redefined RAID_CLASS_COLORS like a naughty little addon
- clarified some settings text a smidge
- added Shockwave to the CC list
- added mage Deep Freeze to the CC modules
- vehicle fixes! vehicles now regenerate mana/energy properly instead of relying on events to fire (which seem to be too slow)
- pet bar is now properly colored for all types of vehicles (was sometimes failing previously for vehicles with energy)

v1.3.19:

- added separate configuration for the "resting" and "combat" portions of the player status icon
- prettified/organized some configuration screens
- made sure that "lower text" and "upper text" configuration options are not present if a given module cannot use dogtags
- fixed a bug that caused the /icehud slash command to not work when the addon was disabled (and therefore be unable to re-enable it). ouch!
- fixed an error when adjusting the status icon's position while it's not visible on the screen

v1.3.18:

- fixed TargetTargetMana bar to be able to use its own colors instead of inheriting what TargetMana was set to
- fixed buff/debuff filter in the TargetInfo module to properly filter on hostile units as well as friendlies. not sure why this was setup to ignore the filter for hostiles in the first place, but it was just creating confusion
- fixed a bug in the HfB module causing all sorts of havoc to be wreaked when trying to activate animation on the bar
- added black background to TargetOfTarget bar for readability
- made ToT text vertical align to CENTER instead of TOP so that it scales appropriately
- made ToT bar color always green so that names aren't covered up when they match the reaction color
- made ToT name/health percentage color always white instead of the reaction color for visibility reasons
- added pvp indicator to TargetHealth/TargetTargetHealth bars
- moved some icons into their own Icon Settings group for the TargetHealth/TargetTargetHealth bars configuration
- fixed localization problem with clicking HfB bar to cast HfB (untested, submitted by module author)

v1.3.17:

- removed the rogue-/druid-only restriction on the ComboPoints module since the Malygos fight needs combo points on the drakes
- fixed <http://www.wowace.com/projects/ice-hud/tickets/8-module-target-info-long-targetnames-overwrites-the/> : target name in the TargetInfo module no longer spills to the next line or gets cut off if it's too long
- made the threat module only display while the player is in combat or the player has some threat on his target
- added an option to only display the threat module while in a group. set by default
- adding HungerForBlood user-submitted module. I don't have an assassination rogue and don't plan on having one, so this is _untested_ by me. the author is responsible for fixing bugs in it
- also updated a few settings in SliceAndDice to conform with the rest of the mod
- fix for malygos fight where the player uses combo points while in a vehicle
- made runes flash when they become active whether the cooldown or alpha setting is being used
- added proper support for profiles instead of storing everything in account-wide un-customizable settings
- added FuBar support

v1.3.16:

- by popular demand, added an option to allow Rune cooldowns to be displayed in either the new cooldown wipe or the old simple alpha fade

v1.3.15:

- added the ability for runes to draw vertically stacked. new configuration option to choose horizontal/vertical alignment
- added a cooldown wipe to Runes with a "shine" when the cooldown is over (cooldown currently displays in a square instead of adhering to the circular icon...working on that)
- added the ability for elements to boost the alpha value a bit. runes were way too dark previously
- changed default for rune module to not be locked at 100% alpha
- fixed a potential nil access problem in the CastBar
- fixed a bug causing TargetInfo lines to be forced to contain data. now any of the lines can be empty if the user chooses

v1.3.14:

- fixed a bug with PlayerMana disabling OnUpdate code for warriors and DK's when their bar was full instead of when it is empty
- fixed a bug with DK runes appearing to be available as soon as a fight was done instead of when they actually became available again
- various other DK rune fixes to prepare for wotlk's release

v1.3.13:

- fixes a bug causing the player's mana bar to sometimes not display full when it should. this typically only happened when a potion, mana gem, spell, etc. took the player to his max mana as opposed to gaining it through normal regen

v1.3.12:

- added a global toggle for DogTags so they can be enabled or disabled for the mod
- added an optional rare/elite/rare-elite indicator to the target health bar (off by default)
- made configuration mode show target raid icons (and the new elite indicator as well)
- fixed a bug in the TargetInfo module that cropped up in 3.0 when LibDogTag is not present causing the module to not display
- fixed a bug with showing the "spellcast failed" flash on the player's castbar if the player tried to activate a trinket/cast another spell while casting a different one
- performance optimization: only run the OnUpdate code for the player mana bar when the player's power is not full
- performance optimization: never run the every-frame OnUpdate for TargetMana or DruidMana bars since we don't need quite that level of granularity

v1.3.11:

- added an option to force text justification on all bars
- set focus cast default scale to match focus health/mana
- set default sides and offsets on all bars to avoid them overlapping each other (fixes mirror/threat overlap and a few others)
- made "configuration mode" display the name of the bar underneath it. causes things to get a bit crowded-looking, but helps distinguish bars a little better
- fixed a bug that happened in the PlayerMana bar after disabling the predictedPower cvar without reloading the UI

v1.3.9:

- fixed debuffs appearing as "own buff size" when they shouldn't have
- made alpha settings properly affect non-bar elements (range finder, targetinfo, combo points, etc.)
- made "config mode" only show bars that are currently enabled
- made combo points module show 5 combo points while in config mode (and 5 applications of sunder/lacerate/maelstrom for those modules)
- added horizontal offset to combo points module
- added ability make combo points add vertically instead of horizontally (if in graphical mode)
- gave the player castbar a name in IceHUD's class instance. thanks greywithana
- fixed a problem with the target/focus CC bars not updating properly since the 3.0 patch
- changed the default for catching mouse clicks on the player health frame to false. it was causing too much confusion
- added an option to hide the new blizzard focus frame in the focus health module
- added an option to make the focus health module clickable to target your focus
- fixed a bug in player health's targeting where the clickable area was in the wrong spot when the bar was flipped to the right side
- added an option to only show the CC bars if the current CC was cast by the player
- fixed a small 3.0 bug in sunder & lacerate modules for determining if the buff/debuff belonged to the player or not
- added a MaelstromCount module that tracks the number of Maelstrom Weapon buffs for Shaman
- set lacerate default vertical position such that it is out of the way of the combo points module instead of on top of it
- fixed a bug where "graphical glow" and "graphical clean" presets did not work on lacerate and sunder count modules

v1.3.8:

- changed the defaults for hiding the blizzard frame on the player and target health frames (now leaves the blizzard frames on by default)
- fixed a potential nil access in the cast bar
- fixed "own buff size" to work properly for buffs you cast on targets instead of buffs they cast on themselves
- fixed an error when selecting the ArcHUD preset
- set the config to refresh itself when a new preset is selected so that the config screen is updated
- added an option to only show the target mana/power bar if the target uses mana (by request)
- increased vertical offset range by request
- fixed Slice And Dice module for new Imp SnD talent values as well as the new SnD glyph

v1.3.6:

- fixed a bug causing the mod to not load at all...(LibSharedMedia got borked in the last packaged release)

v1.3.5:

- added user-submitted ArcHUD-like textures and preset
- modified cast lag and threat pull indicators to use a custom color instead of being an alpha'd version of the background
- fixed a bug where runic power would use the "not full" aggro setting when it was empty (it should behave like rage and treat "not full" as empty)

v1.3.4:

- interface version up to 3.0! hooray new stuff.
- made the threat module wow 3.0-compatible (these changes do not branch based on interface version due to the removal of lots of libs...there's no goin' back now!)
- fixed text display on threat module to actually show threat % as intended
- added a few more user-submitted bar textures (no presets with these since they're just textures and not entire layout changes)
- removed LibDruidMana and fixed up DruidMana module to work with the new UnitPower API
- fixed a bug causing the mirror bar to not obey "offset" setting
- made the mirror bar's text stop bouncing up and down based on its offset setting. now will always remain in the same place (since there are vertical/horizontal adjustment sliders for this text already)

v1.3.2:

- added bar/background graphical blend mode options so we can have us some snazzier artses
- added 3 new user-submitted bar textures (GlowArc, CleanCurves, and BloodGlaives) and 2 new user-submitted combo/sunder/lacerate count textures (Glow and CleanCurves)
- fixed a bug that caused mana frames to stop updating properly in wotlk under certain conditions
- widened the maximum gap once again to 700 by request (from 500)
- made aggro alpha setting on the threat bar actually work

v1.3.1: (minor fixes)

- made lag indicator on the player's cast bar respect the bar width setting
- made castbar text respect alpha settings

v1.3:

- officially tagged v1.3 version, considered a "release" version as opposed to the recent wotlk betas (this version does work with both wotlk and live realms)

- added a new Threat module that works off the Threat-2.0 library (does not currently function in wotlk due to threat-2.0 not being updated for wotlk) (implementation and fixes taken from another user's now-defunct threat addon and acapela's threat-2.0 fixes from that mod's comments page)
- added Target of Target health and mana bars (off by default) (idea "stolen" with permission from Dark Imakuni)
- added a range finder (off by default)
- made the Runes module able to be moved horizontally and set the default to be properly centered
- increased the maximum "gap" setting by request
- general cleanup, removing unused libs, etc.
- added a few new user-submitted textures for the bars and combo/sunder/lacerate count modules
- added an option to disable click-targeting on the player health bar when in combat (set by default)

Wrath beta v9:

- added horizontal positioning option to the ToT module by request
- added an option to disable click-targeting while in combat by request
- added 3 new user-submitted bar presets/skins (thanks KcuhC!)
- fixed TargetOfTarget module's error message as of wotlk beta 8962
- added support for new combo point, sunder/lacerate count textures
- added a new round combo point texture (user-submitted)
- fixed a bug in the slice and dice module that caused it to stay visible for much longer than it should have under certain circumstances
- added user-requested per-bar vertical offsets and setup pet and focus bars to fit within the vertical center of the hud
- added user-requested feature to resize TargetOfTarget module so it doesn't have to fit to the hud's gap setting
- fixed own buffs/debuffs in the TargetInfo module overlapping the icons next to them

Wrath beta v8:

- (wotlk) fixed cooldown display on buffs/debuffs in the TargetInfo module

Wrath beta v7:
Wrath-related fixes:

- updated for beta build 8820. IceHUD will start up correctly once again
- updated SunderCount/LacerateCount modules to use the new UnitDebuff return values in wotlk properly/register the changed wotlk events
- updated SliceAndDice module to use the new UnitBuff return values in wotlk properly/register the changed wotlk events/new combo point parameters
- updated DruidMana module to update every frame in wotlk since the other mana frames need to...this still needs dogtag to be updated to work fully in wotlk
- updated ComboPoints module to use the new combo point functionality and events in wotlk

Non-wrath-related fixes:

- updated SliceAndDice module to be more efficient outside of combat (avoids unnecessary OnUpdate stuff)

Wrath beta v6:
Wrath-related fixes:

- removed UNIT_RUNIC_POWER hack in player & target mana modules since blizzard seems to have fixed the bug in the latest beta build
- fixed bug with runes module where the last rune would never show as being used
- added hax to the runes module to swap placement of frost and unholy runes since blizzard has had their hack in for 2 builds now
- now fully compatible with blizzard's "predicted power" system to constantly show energy/mana gains instead of ticking them

Non-wrath-related fixes:

- only show Lacerates if they were applied to the target by the player (not by other players); had problems with bear tank + feral dps in the same group
- increasing higher vertical positioning from 200 to 300 for the runes module by request
- added user-submitted FocusCast module

Wrath beta v5:

- updated to use the new rune graphics
- frost and unholy are in their old locations still in this module...we'll see if Blizzard leaves their rune swap hack in before changing it

Wrath beta v4:

- Fixed a bug that caused a lua error every time the player mounted as a DK (why the crap does the non-existent rune 7 and 8 get updated whenever the player mounts??)
- Worked around a Blizzard bug introduced by the new system that allows the player to see his power (mana/energy/runic power) updating in "real-time" (they call it predicted power). The events for mana/runic power/energy/etc. regen are no longer being fired and the client uses a more cpu-expensive method of updating the available amount of power. Mimicked this new method (which the default UI uses) in IceHUD.

Wrath beta v3:

- Updated Ace2 libraries to work with the latest beta build. No other changes in IceHUD functionality.

Wrath beta v2:
-Added a Runes module (similar to combo points/sunder count) for DK's. This is a first rev and will probably go through some fine-tuning to make it prettier...though I kinda like it as is
-Added a few DK CC frost spells to the CC modules

Wrath beta (fixed):
-Fixed an error in the GCD module in the wow version check

Wrath beta:
-Added DK-specific runic power updates to the player and target mana bars
-Fixed the return values of UnitBuff to work with 3.0
-Added DK starter spell to the GCD module
-No rune module available yet, but coming soon
-This version is backward compatible with older wow clients (such as the current live version) and will require "load out of date addons" to be checked if used in Wrath

r77363:

- removed LibGratuity-2.0 (or GratuityLib, whichever you wanna call it) since only the DruidMana module used it and even then only if the user didn't have LibDruidMana installed. now LibDruidMana is required instead of falling back to Gratuity...the Gratuity method was broken for powershifting anyway
- fixed GCD module to work in all localizations
- fixed CC bars to work for any loc by using GetSpellInfo along with a list of spell ID's for each CC spell it supports (thanks to Arrowmaster/#wowace for the help!)
- moved CallbackHandler into the externals instead of embedding it directly into the mod. LSM-3.0 won't load cleanly without it
- removed LibMobHealth from the externals list and the embeds xml
- added LibDogTag-Unit to the optional deps list
- fixed text display for non-dogtag strings
- switched from LibSharedMedia-2 to LibSharedMedia-3
- fixed GCD for non-rogues/cat form druids (user-submitted)
- added user-submitted LacerateCount module; works like SunderCount for warriors or ComboPoints for rogues
- added focus health and mana bars. disabled by default
- TargetInfo: added optional sizing for (de)buffs i cast versus other players
- added Shackle Undead to the CC bar's list of CC's
- SnD: added text readout of potential snd time next to current snd buff time
- SnD: added configurable color for snd potential bar
- SnD: fix equip locs for non-english clients
- SnD: optionally show a shadow of the duration bar as you build combo points. this shadow will show how long your snd will last if you hit it right then
- SnD: now works for non-english clients
- SnD: added a toggleable option to make the bar show as a percentage of the maximum attainable slice and dice time (with set bonuses and talents accounted for) instead of going from full to empty no matter the duration
- fixed a rare error that could occur when bars appeared or disappeared
- widen the minimum width for the TargetInfo module to account for long NPC names
- added width scaling to individual bars
- allow horizontal positioning of the TargetInfo module
- fixing a bug where Banish wasn't triggering the CC bar
- changed DruidMana module to use LibDruidMana/DogTag for simplicity/compatibility purposes (fixed a bug with powershifting not updating the mana amount)
- fixed a bug with the low health flashing frame if alphas are set to 0
- updated the TargetInfo default dogtag by request
- adding 4 new modules care of Antumbra of Lothar server. Huge thanks to him for writing these! They are:
- FocusCC - tracks a list of CC spells on the focus target
- GlobalCoolDown - shows when the global cooldown is active
- SliceAndDice - a counter/tracker for rogue slice'n'dice buff
- TargetCC - tracks a list of CC spells on the current target
- added a configuration mode to show all bars temporarily so they can be placed
- changed how frames are shown and hidden so we don't call show/hide unnecessarily
- widened the min/max offset numbers to allow greater placement flexibility
- performance improvement: only call SetTexCoord if the coords need to actually change this frame. brings cpu cost from 1% per bar to 0.5% per bar. WIP
- fixed error message displayed when enabling the mirror bar
- updated targetinfo dogtag to display the word "Combat" when in combat instead of "True"
- updated to support LibDogTag-3.0
- on first run, forced reset all custom DogTags to the module default since some of the old default tags no longer work

v1.2-2.4:

- updated TOC for WoW 2.4

v1.2-r62057:

- fixed castbar "lock text alpha" setting
- added LibMobHealth-4.0 to externals/embeds so people without other ace mods get estimated health values properly
- added an option to allow shortening health values or not (1100 => 1.1k) for non-dogtag people
- made default dogtag for fractional health into CurHP:Round/MaxHP:Round since FractionalHP liked to show decimals and wouldn't :Round
- expanded raid icon placement ranges to allow more flexibility
- fixed bar transparency when going in and out of combat
- fixed a bug where the resting icon would stay on way too long (nasty typo bug...)
- added icon to config for purtiness
- made player icons and raid icons fade according to bar visibility and added a config option to make them always locked to 100%
- added party leader, status, master looter, and pvp icons to the player health bar

v1.2:

- made the player health bar (configurably) clickable for targeting/click-casting/menus
- added DogTag fields to the TargetInfo module
- added a configurable raid icon on the target health bar
- added a SunderCount module to count sunder applications on a target for warriors
- added a requested option to hide bars or their backgrounds
- made bars animate their gained/lost amounts
- fixed alpha fading of dogtag texts under the health and power bars
- optimized dogtag usage on all bars
- made icehud configuration show up in RockConfig
- added an intermediate color for health and mana fading so it turns yellow in the middle instead of a gross brown
- various other tweaks and fixes

r60273:

- added vertical/horizontal text offset options to the castbar
- add an option to the player cast bar to show the default cast bar or not
