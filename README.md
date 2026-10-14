# Modern Control Remapping (The Witcher 3: Wild Hunt)

The new version of [Modern Control Map](https://github.com/ApocryphaRealm/ModernControlMapW3) (Nexus: The Witcher 3
mod 13679), which it replaces: it carries that mod's controller map and controls and adds the Key Bindings and
Controller Scheme work, developed as "Unbind Vanilla Controls". Internal names - the `modUnbindVanillaControls` folder,
the script files, the `UnbindVanillaControls` settings group and log channel - are kept, so saved settings carry over.

The Witcher 3's Key Bindings page, made to unbind, unlink and separate controls - in the game's own page, nothing else.

* **Delete clears a row**, and the game keeps it cleared.
* **Linked rows are split**: Jump / Climb / Roll / Horse Jump, Talk / Loot / Mount / Open / ..., attacks and their held
  and mounted forms, Gallop / Canter, Dismount / Disembark, Draw / Oil, dialogue choices apart from walking.
* **Menu keys apart from gameplay keys**: rows for the quick access menu, photo mode, dialogue and aiming never take a
  key off a gameplay row, and the other way round.
* **Panel shortcuts unlocked** without turning Safeties off.
* **Controller rows under the Controller Scheme diagram**: each tab's controls with their buttons, A to change one, Y to
  switch it off in that tab; never cleared to IK_None (the one value the game cannot bind over again).
* **One weapon row**: a tap draws the steel sword, a hold the silver one.
* **Modern Control Map's controller behaviour and map, carried over**: tap Sprint to run out of combat, gallop on B with
  dismount on A only, the sign buttons, and the map's installer (`dist/Controller Map Installer/`).

Patch 5.0 (Remastered). Player documentation: [dist/README.txt](dist/README.txt). History: [CHANGELOG.md](CHANGELOG.md).

## How it is built

There is nothing to compile. `tools/gen_menu.py` reads the game's own
`bin\config\r4game\user_config_matrix\pc\input.xml` and `content\content0\<lang>.w3strings` and writes `dist\`: the
split `input.xml` and, for every language the game ships, the labels that join two of the game's strings. It also
checks that every action of the game's rows is still on a row, every game row id is kept, every label resolves and
every tag of ours is known to the script (`--check` runs only the checks). The game folder comes from `--game`, the
`W3_GAME` environment variable, or Steam's library folders. Python 3.10+, standard library only.

`dist\Mods\modUnbindVanillaControls\content\scripts\local\UnbindVanillaControls.ws` is the WitcherScript side
(REDkit 5.0 annotations: `@wrapMethod`, `@addField`). `tools/package.ps1` packages a version issued by the project's
version gate.

## Licence

GPL-3.0-or-later - see [LICENSE](LICENSE). Row labels are the game's own strings; the game's data stays CD PROJEKT
RED's.
