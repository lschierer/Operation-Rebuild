# Adapting the SRD to Operation Rebuild

The rules baseline is the D&D System Reference Document 5.2.1 (CC-BY-4.0,
Wizards of the Coast LLC; a copy is in `share/`). We keep its structure and
probability mechanics, and change how abilities are *explained*. Because the
material is adapted, every adapted trait records its SRD source so that the
attribution and the "changes were made" notice stay accurate.

## Principles

1. **No spellcasting.** There are no spell lists, spell slots or on-demand
   magic. Supernatural capability is allowed, but it has a mechanism.
2. **Every trait has three parts.**
   - *mechanics*: what it does in the rules (mostly as in the SRD, so the
     SRD's balance work still applies);
   - *explanation*: how it works in this world (ours to rewrite freely);
   - *srd_source*: the original SRD name.
3. **Every class feature has a channel** describing where it comes from:
   - `training`: learned skill. Healing is training (field medicine).
   - `technique`: learned method. Inspiration is technique (leadership,
     performance, tactics).
   - `mutation`: engineered biology. Species traits are mutations: lines
     bred for sport, labour or war from a common stock.
   - `faith`: religion (see below).
4. **Species are engineered or diverged lines** of one ancestral stock. This
   leaves room for hybrids later.

## Religion is not a spell list

Religion is central to the setting. Miracles are real but are not available
on demand. Therefore:

- Faith-channel features (for example Divine Smite, Divine Intervention,
  Channel Divinity) do not become player-activated abilities.
- Faith is modelled as world state: observance, oaths kept or broken,
  shrines, community. It produces steady effects such as morale, resistance
  to fear, and conviction, and it may raise the chance of rare miracle
  *events* that the world generates, not the player.
- Until that system exists, faith-channel features are kept in the data with
  `deferred: true` so nothing from the SRD is lost.

## Open questions

- Time scale of a turn (affects how lifespan matters).
- Lifespans per species. Starting figures to review: human ~80, halfling
  ~150, dwarf 500, elf 3000 (Riyria-style: slow ageing, mythologised as
  immortal), gnome 350 to 500, goliath and orc 50 to 80.
- Whether the player can influence miracle odds (for example by observance)
  without controlling the outcome.
- How strictly to model fuel for fire-based mutations.

## The fighting classes: three answers to cooperation

Fighter, Paladin and Barbarian are one family that differs on how it fights
alongside others and how it survives.

| | Role | Offence | Survivability | Cooperation |
|---|---|---|---|---|
| Barbarian | Solo fighter, even in a mob | Highest. Fury and adrenaline amplify attacks | Poor over time. Strong while raging, then crashes, and has no team support, so it must win fast | None. Neither gives nor receives team bonuses |
| Fighter | Soldier trained in group tactics | Moderate | Grows steadily along its skill tree through formation and teamwork | Core strength |
| Paladin | Defender and medic, the medieval field hospital | Lower | High. Guards others and treats the wounded | Core strength |

Consequences for the rules (proposals, to be confirmed):

- **Rage** works as in the SRD while it lasts (damage bonus, advantage on
  Strength, resistance to physical damage). The adaptation is a crash when
  the rage ends: the barbarian takes a level of Exhaustion. The crash always
  happens eventually, but *when* depends on level:
  - Rage has an endurance limit in rounds that grows with level (placeholder:
    3 rounds at level 1, plus 1 per level, so 16 rounds at level 14). The SRD
    rule that attacking, forcing a save or spending a Bonus Action extends
    the rage by a round stays, but the endurance limit caps it. A low-level
    barbarian can therefore crash in the middle of a fight.
  - At level 15 (Persistent Rage) the limit goes away: the rage lasts as long
    as there is a fight, and the crash comes at a break or rest point, when
    nobody is left to fight. This replaces the SRD's flat 10 minutes.
  A "break or rest point" means no enemy is within the barbarian's attack
  range or awareness, whichever is greater. Awareness is the distance at
  which the barbarian can perceive an enemy (senses and passive Perception
  against the enemy's stealth). So sharper senses keep a rage going longer.
  Poor survivability comes from the crash, the limited duration, lack of team
  support, and Reckless Attack (attacks against you have advantage). The
  Exhaustion level and the endurance numbers are proposals to tune in play.
- **Cohesion** is a new rule: allies who are trained in group tactics and are
  nearby give each other defensive and offensive bonuses. A raging Barbarian
  neither gives nor receives them. This needs a position model for combat.
- **Fighter** survivability comes from a formation skill tree (shared cover,
  covering fire, holding a line), not from personal toughness.
- **Paladin** uses the SRD's Protection and Defense fighting styles plus
  field medicine. Healing draws on a pool of medical supplies, so medical
  technology in the tech tree raises it. Faith features stay deferred.
- The SRD provides one subclass per class (Berserker, Champion, Oath of
  Devotion). Specialisations beyond those are our own design.
