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

## Time

Durations, rests and recharge periods use the SRD's game-time units (rounds,
minutes, hours), never real-world time. As in Civilization or Castle of the
Winds, game time is tied to turns by a mapping still to be defined together
with combat and the strategic layer. Data files therefore say
`duration_minutes: 10` and never refer to the clock.

## Heritable nanites

Some species carry nanites passed from mother to child during gestation. The
goliath is the first case: the nanites sustain a body that would otherwise
fail (blood pressure), and can be driven to grant Large Form. Since the
setting is about rediscovering lost technology, nanites may deserve their own
treatment in the tech tree later.

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

## Alchemy replaces spells

"Magic Initiate (X)" in the SRD means: choose two cantrips and one level 1
spell from a spell list. The real design question is what replaces the lists.
In this setting chemistry is lost as a science but survives as folklore, so a
spell becomes a **formula**: a remembered recipe that always needs materials.
Nobody casts; they prepare and use something.

Categories of formula (what the SRD spell becomes):

- **Reaction**: a chemical reaction used as a weapon or tool. Acid, strong
  endothermic reactions (cold), exothermic reactions (fire, heat, blast),
  phosphorus (light).
- **Compound**: a drug or chemical that affects the user (stimulants,
  steroid-like strengthening, possibly harmful) or its target (poison,
  sedative).
- **Trap or ritual**: a prepared setup that triggers a reaction later (the
  SRD's ritual spells such as Alarm).
- **Trick**: small effects, such as invisible ink or a signal (Message,
  Illusory Script, Prestidigitation).
- **Nanite**: learning to draw on the nanites most people carry, without
  knowing that is what is happening (Detect Magic, Sleep, Charm Person).
  Who can learn these depends on how the nanites are spread (open question:
  all infected humans, only some species, or being able to do this is what
  makes someone a sage).

Rules for formulas:

- All formulas need materials. Cheap ones are used at will in the SRD sense
  and still need a supply; materials need an item and supply model.
- A formula records the SRD spell it replaces (`srd_replaces`), as the species
  abilities do.
- Magic Initiate becomes three formula slots: two minor formulas and one
  stronger formula, chosen from a formulary instead of a spell list.

Dropped, with no formula equivalent: False Life, Find Familiar, Identify, Mage
Armor, Protection from Evil and Good, Unseen Servant.

Backgrounds: Acolyte is left out until religion has a design (its feat is
Magic Initiate (Cleric)). Sage uses the Wizard formulary.

## Two levels: what it is, and what people believe

The setting is told at two levels at once.

- **Engineering level** (the designers and the data): bioengineering,
  nanites, chemistry. This is what the rules and the `explanation` fields
  describe.
- **In-world level** (the characters and the player's first impression): after
  two generations without schools, nobody knows how any of it works, so those
  who keep fragments of the old knowledge are thought to do magic. This is how
  things feel and are named in the game.

Every ability should be explainable at the first level and still feel
fantastic at the second. The opening narrative sets this up (see
`backstory.md`), with Clarke's third law as its hook.

## Further formula decisions

- **Comprehend Languages** is a nanite formula: a neural interface that
  translates, more general than the gnomes' animal communication and covering
  human languages. Those who use it believe it is magic.
- **Feather Fall** is explained by body, not magic: mostly the dwarf's
  resistance to injury (you feel the fall less, and get up unbruised, as if you
  had floated), partly the elf's acrobatic control. For a human sage it is a
  compound that numbs and relaxes. It is weighted toward the dwarf version.

## Where the two levels live in the data

- `explanation` is the engineering truth and is what the help files show.
- `name` is what the in-world character calls it, so it should sound
  fantastic. The SRD names already do (Fey Ancestry, Stonecunning, Detect
  Magic, Dancing Lights), so keep them where they exist. Names that describe
  the mechanism (for example "Nanite Camouflage") belong in the
  `explanation`, not the name.
- No separate in-world text field exists yet. Add an optional `lore` field
  only when the game needs flavour text beyond the name.

## Organs and supplies

Species abilities that are chemical reactions work from organs the line was
engineered with: glands, like a snake's venom sac but placed where it is
useful (a wrist, as with a comic-book web shooter). The organ makes the
compound, so these abilities need no materials, and it refills with rest. That
is why they use the `uses` and `recharge` fields. Only the one or two
reactions listed in a species file work this way. The organs are small and
release the compound as a fine aerosol, so a minor effect (a cantrip) is
effectively at will, and only the stronger uses are limited by rest.

Formulas learned by sages (see "Alchemy replaces spells") are different: they
have no organ, so they always need materials from outside. Rule of thumb:
innate ability means internal supply and rest; learned formula means external
materials.

## Formula decisions (answers)

- **Mage Hand**: dropped.
- **Floating Disk**: kept, as a trivial materials formula based on magnetism.
- **Message**: a trick, similar to ventriloquism.
- **Shield**: kept as a magnetic field. It only affects metal and
  electromagnetic (nanite-based or lightning) attacks. It does not stop
  chemical attacks (acid, fire, poison, gas), which look equally magical;
  some magic is harder to block than others.
- **Chill Touch** is cold damage (the injury from touching very cold metal
  with bare skin). **Shocking Grasp** is lightning damage (an electrical
  burn). They are separate SRD damage types (cold, lightning) and stay so.
- **Materials**: every formula needs materials; cheap ones cost a trivial
  supply. A small item and material model comes with equipment.
- **Nanite formulas**: no prerequisite is modelled. A player who chooses one
  is assumed to have the nanites for it. The game does not simulate a
  character who wants to do something their body cannot.
- **Name**: the feat that replaces Magic Initiate is **Alchemist**. In the
  world the word carries a connotation of the unscientific and superstitious,
  which is how survivors would see it; the same practice is chemistry at the
  engineering level (the word changed to "chemist" in time).
- **Skills** keep their SRD names (Arcana, Religion) as the in-world names,
  following the two-level convention.
- **Backgrounds** to start with: Criminal, Sage, Soldier. Acolyte is out for
  now.
