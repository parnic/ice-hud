# Changelog

v1.16.1:

- Add option for combo points to grow in reverse (right->left or bottom->top) by request.

v1.16.0:

- Add initial compatibility with WoW 12.x / Midnight. Please see readme/in-game FAQ page for details about this significant change.
- Add option to forcibly disable cooldown numbers on TargetInfo buff and debuff as well as class power frames (DK runes, Paladin holy power, etc.) when set to "Cooldown" or "Both" mode.
- Add option to hide the default breath ("mirror") bar when the IceHUD MirrorBar is enabled (the built-in bar is now hidden by default).
- Fix Vigor display for Druid flight form in 11.2.7+
- Fix 90-degree rotated bar wiggling in 12.0+. Note that this is still a largely unsupported feature and requires a lot of manual manipulation of ancillary module items (icons, text labels, etc.), but the core "the bar wiggles like crazy" problem is now gone.
- Fix bar texture overrides not always applying immediately after enabling the option (previously you sometimes had to change the texture before the override would take effect).
- Update TBC Anniversary TOC.
- Fix "locked" alpha text showing even when the bar was at 0% alpha (via the Transparency Settings cases in the module's options).
