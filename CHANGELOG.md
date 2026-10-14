# ModernControlRemappingW3 - changelog (formerly UnbindVanillaControlsW3)

Rule 61: this mod's own history, kept beside the code it describes.

<!-- VERSIONING-RULES -->
> **Versioning rules (CLAUDE.md rules 6 and 48):** `X.Y.Z`; a change increments the THIRD
> number; at `.9` the MINOR rolls. The next number is LAST WORKING + 1; failed/scratch/
> untested numbers are reused. Numbers come from version-gate.ps1.

## 1.0.1 - 2026-10-14 - untested

### Changed
- Modern Control Map is now Modern Control Remapping (the owner, 2026-10-14: 'Modern control remapping should be an update to modern control map mod that we already posted. So just rename it and update the mod page to match the new file.'). This version is the Unbind Vanilla Controls (Witcher 3) 1.0.0 build tested by the owner, renamed: it carries Modern Control Map's map and controls itself (no separate script) and adds Key Bindings (clear any key, split linked rows, menu keys apart, panel shortcuts unlocked, one Draw/Sheathe row) and the Controller Scheme list (view per context, rebind, unbind by pressing the bound button). Users of Modern Control Map replace it with this file - never both. Version gate: key ModernControlMapW3 (Nexus 13679), last posted 1.0.0, so 1.0.1; the development record stays under UnbindVanillaControlsW3 1.0.0.

## 1.0.0 - 2026-10-06 - working

**Recorded working 2026-10-14** (version gate, against the installed "unbind fix" build, 34 artefacts byte-identical to the
package): the owner, ~06:15, *"I'm confirming that it's functional"*; the scriptslog shows the same-button unbind
(`PadSprint off-switch code received 9000 -> tab 0`, `off switch for PadSprint in tab 0 -> 'PadSprint_off0'`) and
re-binds (`PadQuickItem = IK_Pad_LeftTrigger / IK_Pad_LeftShoulder / IK_Pad_DigitUp`).

First build. Everything lives in the game's own Settings pages (Key Bindings, Controller Scheme) - no other menu, no INI
(the owner, 2026-10-06: *"i want all these settings in the game ui not amf and i want to be able to unbind keys and
leave them unbound"*).

### Fixed (before release) - 2026-10-14: unbind did nothing
The owner's run of the unbind build: *"I'm trying to unbind different buttons by selecting the button that is already
bound to, and it's not working."* His log: `PadStrongAttack has no off switch in tab 1175223512`, `PadSprint ... tab
1175224536`. The page put `9000 + this.selectedIndex` straight into the call, and the engine handed the script that
Number's FLOAT bit pattern (1175232512 = 9000.0f; 9001.0f is 1024 more) - so every off-switch lookup missed (Y - Off in
the earlier builds went the same way). The page now sends an int local; the script also reads the float form
(UVC_PadTabFromCode) and logs the received tab with the row's whole switch table. Every unbindable row has its switch
in every tab it shows in (checked against the generated tables).

### Changed (before release) - 2026-10-14: unbind by the same button; one Draw/Sheathe row
The owner, on the controller list build: *"if you select the same button that's already bound to it, it should unbind
it"* (instead of Y - Off), and *"there are still 2 rows for weapon drawing, it should be one row that says
draw/sheathe"*.
- **Unbind = A, then the row's own button.** It is the off switch of that tab (the binding stays in input.settings, so
  the game never sees IK_None); the row shows "-"; A and any button binds it again (switch back on, then the new button
  over the kept Xbox binding). Y does nothing now and is gone from the hint ("A - Select  Start - Cancel"). Rows without
  an off switch cannot be unbound. Off switches added for Draw/Sheathe (OnCommSteelSword / OnCommSilverSword) and Dive /
  Surface (OnDiving); not for aiming's cancel, whose contexts belong to no tab.
- **One Draw/Sheathe row** on both pages ("Draw/Sheathe", each language's own verb pair from the game's "Draw/Sheathe
  Steel Sword"). Key Bindings: the sheathe holds join the row, and with both swords on its key the game's sheathe holds
  stay quiet (a tap sheathes the sword that is out), except for the alternate sign cast the game hangs on them. The
  controller list's separate Sheathe Sword row is gone. The oil rows stay (a different job; the controller map leaves
  them unbound and the game's automatic oils cover them).
- The diagram's "LEFT BUTTON - Draw/Sheathe Steel Sword ..." text is the game's fixed per-platform text
  (InGameMenu_CreateControllerData), not read from the bindings; it is left as it is.
- Locked rows stay locked: the off switch keeps a binding, it cannot give a control that already has no button one -
  the game still refuses a pad write over IK_None.

### Changed (before release) - 2026-10-14: the controller list is back, and can no longer strand a control
The owner, after testing the MCM carry-over: *"the control scheme menu doesn't have the interaction point for you to
select to and view what buttons do what in which context and change them."* The list under Settings > Controller Scheme
ships again (blob0.bundle built by `tools/build_flash.py`; UVC_PadListShipped is gone). Why it was parked on 2026-10-06:
X, Delete and "the row's own button again" CLEARED a row to IK_None, and the game never writes a pad button over IK_None
(or another pad layout's key) - the control could not be bound again and the read-back claimed it had been (probes 4-6).
Fixed at that cause:
- **A controller row is never cleared.** X, Delete and the row's own button again do nothing; the script's
  OnClearKeybind refuses a controller row. Y (off in this tab) still takes a control off a button in one tab without
  touching its binding. The hint reads "A - Select  Y - Off  Start - Cancel".
- **A row that cannot take a button is shown locked.** When the row's control has no Xbox pad button in the game's live
  mapping (theInput.GetPadKeysForAction - not the settings read-back), it is drawn dim, A does not open it, and the
  script writes nothing to it. On the owner's current map: Sprint Toggle, Exploration - Roll, Sheathe Sword and both oils
  (the map leaves them unbound). `gen_menu.py` writes UVC_PadRowFirstAction into the generated gate map for this.
- **Horse Riding - Jump and Dismount are two rows** (PadHorseJump, PadHorseDismount): the controller map has Jump on Y
  and Dismount on A's hold, so one row showed only Y and a change would have moved Dismount onto the jump button.
- The values shown are the game's own mapping - his input.settings, i.e. Modern Control Map's layout - and the weapon row
  is the one PadWeapon row.

### Changed (before release) - 2026-10-14: Modern Control Map carried over into UVC
The owner, resuming UVC with Modern Control Map unticked: *"look back at MCM and try and transfer over any of the current
keybinds that it has to the current UVC, because the horse controls don't match what I expect."* UVC now plays like
Modern Control Map without it (do not run both - their scripts would act twice on one press).
- **One weapon row** (the owner: *"just one row for weapon in any context ... the same logic that modern control map
  follows of pressing for steel, holding for silver"*). Key Bindings: the game's Draw Steel Sword and Draw Silver Sword
  rows are one row, "Draw Steel Sword - Hold - Draw Silver Sword" (the game's own words, every language); its key draws
  or sheathes the steel sword on a tap and the silver sword on a hold (0.3 s, on release), switching when the other is
  out - the game's own draw. The holds the game kept on those keys have rows of their own: Sheathe Sword, Steel sword
  oils, Silver sword oils. The controller list's two draw rows are one row too (PadWeapon). On a controller the same
  tap/hold works when both draws share a pad button (the controller map puts them on X). `gen_menu.py` gained `MERGED`
  for the game row folded in.
- **Tap B to sprint out of combat** (the owner: *"holding B does sprint, but tapping it doesn't"* - *"Modern Control Map
  already has the mechanic I'm looking for, which is you tap to sprint or hold the sprint"*): on a controller out of
  combat a tap of Sprint toggles running (the game's own SetSprintToggle) and a hold runs. In combat a tap still dodges.
- **Horse: B gallops, only A dismounts** (the owner: *"holding A and holding B both dismount when it should be sprinting
  with B and dismounting with A"*): the hold-to-dismount circle follows Horse Dismount's own pad button; the game hands
  it a fixed B.
- **Sign buttons** for alternative sign casting (Igni RT, Quen B, Axii Y, Yrden X, Aard RB): cast only while Cast Sign is
  held; Jump waits while it is held and 0.5 s after. Active once Select Igni has a pad button.
- **Controller Map Installer** in the package: Modern Control Map's installer and its map.json unchanged (250 controller
  bindings in every context; keyboard untouched; Left Stick Sprint off, alternative sign casting on; backups
  `*.before-uvc-controller-map-*`, Uninstall restores the first). Tested on copies: the game's default file comes out as
  the map line for line; the owner's current file (already on the map) comes out with the same lines.

### Changed (before release)
- **The controller map's behaviour moved to its own mod, Modern Control Map** (reversed 2026-10-14, above) (the owner, 2026-10-06: *"the current
  control map shouldn't require UVC it should just come as a control map"*): the out-of-combat sprint toggle, both
  swords on one button, the dismount hold that follows its binding and the sign buttons are no longer in UVC.

- **The controller list is parked; the controller map is set for the owner outside the game** (the owner, 2026-10-06:
  *"For now let's just make this a straight control map that doesn't need to be unbindable or rebindable and you can
  just configure it the way I tell you to and lock those in and if I want to change you can change it"*). The game does
  not write a controller button over a cleared one (IK_None) or another layout's key, so a cleared row could never be
  bound again; and no unpressable pad key exists to clear onto (IK_Pad_First/Last resolve to A and the right stick's Y
  axis; a stick axis would fire on the stick) - probes 4-6. The package ships no blob0.bundle: Controller Scheme is the
  game's own page. The list's code stays (UVC_PadListShipped).

### Added
- **Alternative sign casting on the signs' own buttons** (the owner, 2026-10-06: *"Let's unbind the signs from the
  functions and bind them to the face buttons themselves, which are rebindable"*; his layout Igni RT, Quen B, Axii Y,
  Yrden X, Aard RB). On a controller the game's SelectAard...SelectAxii cast through its OnSelectSign only while Cast
  Sign is held; AltCastSign from any other control is skipped; Jump waits while Cast Sign is held and 0.5 s after.
- **The row's own button pressed again unbinds it** (the owner, 2026-10-06: *"selecting the same button a second time
  while unbinding will unselect it so it's unbound"*), on both pages: Controller Scheme (A, then the row's own pad
  button) and Key Bindings (Enter, then the row's own key). The row is left with no button and stays that way.
- **Both swords on one button** (the owner, 2026-10-06: *"tap to draw steel and tap to sheath steel. And then hold to draw
  silver and hold again to sheath silver"*). Set Draw Steel Sword and Draw Silver Sword to the same button (his: X): a
  tap draws or sheathes the steel sword, a hold (0.3 s) the silver one - the game's own draw (with the other sword out it
  switches). Oils have rows of their own now (the D-pad's hold), so they can be left with no button: the game's automatic
  oil and sword options cover them (the owner). An earlier "Swords" row that named both draws is gone - two rows naming
  one action left the second row's writes with no effect.
- **A control can be off in one Controller Scheme tab** (the owner, 2026-10-06: *"set the sign casting to left trigger in
  combat and the Witcher senses to left trigger in exploration only"*). Y on a row switches its control off in the tab
  on show (the row shows the game's "Off" there); in that tab's contexts the control does nothing while the pad is in use,
  so another control on the same button has it alone. Cast Sign on LT and off in Exploration, Witcher Senses on LT: LT
  senses when exploring and casts in combat. Available for the controls the game handles one by one: attacks, Cast Sign,
  Parry, Witcher Senses, Dodge, Roll, Sprint, Quick Access Item, Camera Lock, Summon Horse, potions, swords.
- **Tap Sprint to dodge, hold it to run, in combat** (the owner, 2026-10-06, after two runs of an out-of-combat dodge through the game's unarmed combat state - it dodged once and then left B neither dodging nor running: *"we're going to have to get rid of the dodging out of combat and rolling out of combat because the game just doesn't allow it and it keeps messing up"*). Out of combat nothing dodges or rolls; on a controller a tap of Sprint toggles running and a hold runs (the owner: *"B should both hold or tap to toggle in exploration"*), through the game's own SetSprintToggle - its pad Sprint Toggle only answers with Left Stick Sprint on, which makes the Sprint button do nothing (the game's default is on). The game's own 0.2 s tap rule
  (its controller Dodge in combat) on Sprint, everywhere; the game's own dodge (EvadePressed) does the dodging. A tap
  near something to talk to or loot still talks or loots (on a controller A is Interact and Sprint); in combat a tap of A
  dodges instead of also rolling (Combat Roll shares A; move Roll on the Controller Scheme page to keep both). On/off in
  Settings > Mods > Unbind Vanilla Controls, on by default.
- **Controller rows under the Controller Scheme diagram** (the owner, 2026-10-06: *"I want the controller specific stuff
  to be in a scrollable window below the controller scheme ... you can just have the rows for each control beneath it"*,
  and the priority: *"I'm not super concerned with the keyboard and mouse side of this, just the controller"*). Settings >
  Controller Scheme keeps its diagram and tabs (Exploration, Swimming and Diving, Combat, Horse Riding, Sailing); under
  it, a scrollable list of the tab's controls (41 in all): D-pad, left stick or right stick to choose (the row is
  highlighted and the list scrolls with it), A then any pad button to change it (the row turns gold with its new
  button), X to leave it with no button, Start to cancel. The page shrinks so the diagram ends at 60% of the screen and
  the list sits at 63-90%, clear of the Navigation/Back bar. The row shows the button's own icon for the pad in use. A control used in
  several tabs names them, and its button moves in all of them (the owner chose this: live, shared actions move
  together). Start and Back (the menus), Sheathe (two D-pad buttons at once), debug actions and the sticks are left out.
  Built on the game's own INPUTPAD binding rows (probe 1: they write the pad side and leave the keyboard alone); the
  page is the game's Controller Scheme movie with the list added at build time from REDkit's source
  (`tools/build_flash.py`).
- **A button's press and hold stay on one row** (the owner, 2026-10-06: *"the hold variant of the strong and fast
  attacks should not be unlinked because they're still part of the attack"*): Fast and Strong Attack with their held
  forms, Draw Sword with its held Oil, Gallop/Canter, Horse Jump with its held Dismount - on both pages.
- **Delete clears a row, and it stays cleared.** Pressing Delete when the page asks for a key leaves the row with no
  key - through the game's own OnClearKeybind, so the game saves it like any binding. Works with Safeties on or off.
  (A middle click on a row already did this in the game; nothing on the keyboard did.)
- **Linked rows are split** (the owner, 2026-10-05: *"remap their linked mappings so that they're separate"*). The
  game's page gave one key to several actions at once; each now has its own row: Jump / Climb / Exploration - Roll /
  Horse Riding - Jump; Talk / Loot / Pick Up / Mount / Open / Fast travel / Examine / Interact (everything else);
  Fast Attack / Fast Attack - Hold / Horse Riding - Fast Attack; Strong Attack / Strong Attack - Hold; Cast Sign /
  Horse Riding - Cast Sign; Use Quick Access Item / Horse Riding - Use Quick Access Item; Gallop / Canter; Dismount /
  Disembark; Draw Steel Sword / Steel sword oils (and silver); Change Objective / Track Quest; walking forward and back
  apart from Talk - Up / Talk - Down and Sailing - Stop / Reverse. Each split row starts on the key its game row has.
- **Menu keys apart from gameplay keys** (the owner, 2026-10-06: *"make it context aware so that you can have
  different keybinds for whether you're in a menu or in gameplay"*). Rows for actions the game binds but never put on
  the page: Quick Access Menu - Meditation (Space), Use Quick Access Item - Cancel (Space while aiming), Sailing -
  Accelerate (Shift) and Photo Mode's seven movement keys. Rows for a context of their own (dialogue choices, the
  quick access menu, photo mode, aiming) never take a key off a gameplay row, or the other way round.
- **The panel shortcuts are unlocked** (Inventory, Map, Journal, Character, Alchemy, Crafting, Bestiary, Glossary,
  Gwent deck, Meditation, Hub, Toggle HUD): rebindable and clearable with Safeties on.
- Every row's text is the game's own words in every language the game ships (18): single rows use the game's string,
  joined rows ("Horse Riding - Jump") are built from that language's own strings by `tools/gen_menu.py`.

### Fixed
- Summon Horse on a controller stays the game's double press (the owner, 2026-10-06, with Witcher Senses on the same
  stick: *"Make calling the horse to stick presses"*). A one-press call was tried first; it was not the cause of "nothing
  happens" - the binding had never reached the file (IK_None).
- Holding D-pad Left or Right still sheathed the sword after the draws were moved off the D-pad (the owner): that is the
  game's separate "sheathe" action. It has a Controller Scheme row of its own now (Sheathe Sword), to move or clear.
- Binding or unbinding a controller row with the D-pad also changed the Controller Scheme tab (the owner's run): one press
  arrives as more than one input event and the second went to the tabs. The list now swallows input for 250 ms after a
  change, a clear or an off switch.
- A controller change could empty the row and write nothing (the owner's run: Strong Attack to RT and Fast Attack to RB
  left both attacks on IK_None). The button's name came from the event's EInputKey and a name outside the table read as
  "none"; it now comes from the number the page sends, through the mod's own table, written as one key alone (probe 2),
  and an unknown number writes nothing.
- The controller list sat at the bottom edge of the screen: it was placed under the page's full bounds, which reach
  down through elements the diagram does not show. It is now placed at fixed parts of the screen.
- Labels from our .w3strings showed as `##uvc_choice_up` / `##uvc_choice_down` on the first run: the game binary-searches
  a string table's keys, which must be sorted by hash; ours were in id order (Main Agent's run, check C).
- The game's Interact row listed `PlaceTrophy,BuryBody` with a comma, so Bury Body kept E when Interact was moved. It
  is a semicolon here. Pet the dog (PetDog) is on the Interact row too; the game's page left it on E.

### Changed
- Renamed to Modern Control Remapping before its first release (the owner, 2026-10-14: 'Let's rename unbind vanilla controls to modern control remapping'). Changed: the Settings > Mods page title in all 18 language files, the README, NOTICE, the controller map installer's messages and two XML comments. Kept: the modUnbindVanillaControls folder, every script file (byte-identical), the UnbindVanillaControls settings group id and log channel, and the menu movie - so saved settings and installs carry over. The generated CD PROJEKT RED-derived files (the split input.xml and the .w3strings) are no longer tracked in git; tools/gen_menu.py rebuilds them.