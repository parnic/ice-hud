# IceHUD

## If you are getting a `PLAYER_TALENT_UPDATE` error in LibRangeCheck-2.0 on BC-Classic, please see https://www.wowace.com/projects/ice-hud/issues/303 - this is not IceHUD's fault.

IceHUD is a highly configurable and customizable HUD addon in the spirit of DHUD, MetaHUD, and others designed to keep your focus in the center of the screen where your character is.

## **What it is**

* Player and target health and mana bars, casting and mirror bars, pet health and mana bars, druid mana bar in forms, extensive target info, ToT display, and much more, in a vertically-oriented heads-up display.

## **Short feature list**

* Lots of different bar shapes and patterns to make the HUD look like you want
* Class-specific modules such as combo point counters, Slice'n'dice timers, druid mana trackers, Eclipse bar, Holy Power monitoring, Warlock shard tracking, and more
* Target-of-target bars, Crowd Control timers, Range Finders, Threat meters, and plenty of other helpful modules
* Lots of DogTag-supported strings for extreme customizability (with the option to completely disable DogTag support for those that dislike the CPU toll that it takes)
* Cast lag indicator (optional)
* Alpha settings for in combat, target selected, etc.
* Fully customizable bars and counters capable of tracking buff/debuff applications on any unit, spell/ability cooldowns, and the health/mana of any unit you specify. The custom health/mana bars will even work with crazy unit specifications like "focustargettargetfocustarget" if you want!
* Highly configurable (can totally re-arrange all bars, change text display, etc.)

## **Slash commands**

* /icehud - opens the configuration UI to tweak any setting
* /icehudCL - command-line access to tweak IceHUD settings (for use with macros, etc.)

## **Frequently Asked Questions**

1. **How do I hide the default Blizzard player, target unit frames and party unit frames?**
   Type /icehud, expand the "Module Settings" section, click "Player Health" or "Target Health," and check "Hide Blizzard Frame" and/or "Hide Blizzard Party Frame". (NOTE: before version 1.3.7, the player/target unitframes were hidden by default. Follow the same steps to enable them if desired)

1. **How do I turn off click-targeting and menus on the player bar?**
   Type /icehud, expand the "Module Settings" section, click "Player Health," un-check "Allow click-targeting." Note that as of v1.3, there is now an option to allow click-targeting out of combat, but turn it off while in combat.

1. **How do I hide the HUD or change its transparency based on combat, targeting, etc.?**
   Type /icehud, check the "Transparency Settings" section. Nearly any combination of states should be available for tweaking.

1. **Even if the rest of the HUD is transparent, the health percentages seem to show up. Why?**
   Type /icehud, expand the "Module Settings" section, expand "Player Health," click "Text Settings," look for options about keeping the lower/upper text blocks alpha locked. If the text is alpha locked, it will not drop below 100%, otherwise it respects its bar's transparency setting. Player Health/Mana, Target Health/Mana, and pet bars should all have these options.

1. **Is there any way to see combo points for Rogues and Druids or sunder applications for Warriors?**
   Yes, check the "Combo Points" and "Sunders" modules in the /icehud configuration panel. (Note that these modules may not show up if you're not of the appropriate class to see them. They should be present for their respective classes, however.)

1. **What's this thing at the top of the player's cast bar and threat bar? It's darker than the rest of the bar.** (and may be colored red)
   That's the Cast Lag Indicator (or the aggro-pull warning for the Threat bar) that shows you when you can start casting a new spell and still be able to finish the current one (based on your lag to the server). You can disable this in the Player Cast Bar settings under the /icehud configuration screen.

1. **Is there a bar that shows breath underwater and if so, how can I adjust it?**
   Yes, this is called the MirrorBarHandler in the module settings portion of the /icehud configuration. It's called that because it mirrors casting bar behavior, displays more than just breathing (fatigue is one example), and that's what Blizzard calls it. It can be moved/adjusted/resized/etc. as with any other module.

1. **There's a long green bar that sometimes shows up below everything else. What is it?**
   That would be the TargetOfTarget module. That module is available for people who don't want the full ToT health/mana bars, but do want some sort of ToT representation on the screen. It's configurable through the /icehud module settings.

1. **IceHUD needs a bar or counter for buff/debuff X!**
   Good news: as of v1.5, you can create as many bars and counters for any buffs or debuffs you want! Type /icehud, select one of the custom module types in the drop-down at the top of the settings page, and press the Create button. This will create a custom module and automatically select it in the list. It is highly recommend that you rename the bar as soon as possible to avoid any confusion later.

1. **How do I turn off the resting/combat/PvP/etc. icons on the player or target?**
   Type /icehud, expand Module Settings, expand PlayerHealth (or TargetHealth for targets), click Icon Settings. You can control every aspect of the icons there including location, visibility, draw order, etc.

1. **How do I turn off buffs/debuffs on the player's or target's bar?**
   Type /icehud, expand Module Settings, expand PlayerInfo (or TargetInfo for targets), select Buff Settings or Debuff Settings, and un-check "show buffs" (or "show debuffs").

1. **How do I turn off these big huge bars that pulse whenever one of my abilities procs?**
   This isn't IceHUD - it's Blizzard's Spell Alerts they added in 4.0.1. Interface options => Combat => "Spell Alert Opacity" to turn them off or search for a mod to tweak their positioning/size/etc.

1. **I don't like where some of the bars are placed. How do I put the health/mana on the left/right?**
   Type /icehud, expand Module Settings, expand whatever module you want to move (e.g. PlayerHealth, PlayerMana), and adjust the "Side" and "Offset" settings. "Side" controls whether it's on the left or the right and "Offset" controls how far from center it is.

1. **Which module displays Monk Chi power?**
   Prior to v1.11.2, this module was called HarmonyPower. Harmony was the original name for Chi back when 5.0 was in beta, so I used Blizzard's name for it while I was developing for Cataclysm. IceHUD v1.11.2 changed this module to be called Chi.

1. **How do I add commas/periods into big numbers like health?**
   If you have DogTags enabled, you can open the Text Settings for the module in question and add SeparateDigits() around the tag you're trying to split up. To display Health/MaxHealth with commas, use: [(SeparateDigits(HP):HPColor "/" SeparateDigits(MaxHP):HPColor):Bracket]. To use periods instead of commas, use: [(SeparateDigits(HP, "."):HPColor "/" SeparateDigits(MaxHP, "."):HPColor):Bracket]. Use the /dog help menu to build your own similar tags for Mana, etc.

1. **The countdown timers on buffs and debuffs completely obscure the icon. How do I disable or adjust the text?**
   IceHUD is not responsible for this countdown text and cannot control it. The 6.0 patch added an option in the game client to display counts on top of cooldowns. Look at the Action Bars menu under the game's Interface options. You can turn the text on or off there. Mods like OmniCC or CooldownCount will generally give you the same feature but allow you to control when, where, and how the text shows up.

1. **When I rotate some modules 90 degrees, such as the castbar, the bar appears to wiggle up and down as it fills or empties. How do I fix this?**
   This is a side effect of the animation API that I'm co-opting to force a rotation without having to provide duplicates of every bar texture in the mod. Any bar moving sufficiently quickly and updating rapidly will cause this. IceHUD is intended to be a vertically-oriented mod, so the rotation feature is there for people who are willing to accept the side effects that come with it. My suggestion is to use one of the many horizontally-oriented bar mods out there if you're wanting horizontal bars. Quartz is a good castbar replacement that you can use and disable IceHUD's built-in castbar, for example.

1. **How do I get rid of the bars that showed up beneath the player in the 7.0 patch?**
   Blizzard added a "Personal Resource Display" feature in the 7.0 game client. You can disable it in the Game options -> Interface -> Names -> Personal Resource Display.

1. **Why is there no target castbar for Classic?**
   The Classic game client doesn't offer a reliable way to show castbars for anyone except the player. IceHUD doesn't support the type of inaccurate guessing at combat log details that would be required to get a semi-useful target castbar.

1. **Why do buff/debuff timers not work in Classic?**
   The Classic game client doesn't provide this information to addons because it wasn't a feature when the game first released. You can install the LibClassicDurations addon to enable support, but it's a best guess and not completely accurate.

See [here](https://www.wowace.com/projects/ice-hud/issues/113) for a user-created guide to creating new IceHUD textures.
