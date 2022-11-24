# Changelog

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
