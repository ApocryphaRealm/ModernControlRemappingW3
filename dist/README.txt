Witcher III Modding Tool, developed and released by CD PROJEKT RED

Modern Control Remapping (The Witcher 3: Wild Hunt)
Version 0.0.0

MODERN CONTROL MAP IS NOW MODERN CONTROL REMAPPING
This is the new version of Modern Control Map. It carries that mod's controller layout and its controls (tap or hold
Sprint, one button for both swords, gallop on B and dismount on A, the sign buttons) by itself, and adds the Key
Bindings and Controller Scheme features below. If Modern Control Map is installed, remove it and install this file in
its place - do not run both: both scripts would act on one press. A controller map you installed with Modern Control
Map stays in your settings; you do not need to install it again.

The Witcher 3's Key Bindings page gives one key to several actions at once, cannot leave a control with no key from
the keyboard, and does not let menu keys and gameplay keys differ. This mod changes that page. There is no other menu
and no settings file: everything is on Options > Key Bindings.

CLEAR A ROW
Select a row, press Enter (or click it), then press Delete - or the key the row already has. The row has no key, and stays that way: the game saves it
like any other binding. A middle click on a row does the same, as it always has in the game.

LINKED ROWS ARE SPLIT
Where the game's page had one row for several actions, each has its own row now, starting on the same key:
  Jump / Climb / Exploration - Roll / Horse Riding - Jump
  Talk / Loot / Pick Up / Mount / Open / Fast travel / Examine / Interact (everything else)
  Fast Attack / Fast Attack - Hold / Horse Riding - Fast Attack
  Strong Attack / Strong Attack - Hold
  Cast Sign / Horse Riding - Cast Sign
  Use Quick Access Item / Horse Riding - Use Quick Access Item
  Gallop / Canter      Dismount / Disembark      Change Objective / Track Quest
  Draw/Sheathe / Steel sword oils / Silver sword oils (the oil holds the game kept on the sword keys)
  walking forward and back / Talk - Up / Talk - Down / Sailing - Stop / Reverse
Rows that came from one row may share a key again, as they did.

MENU KEYS AND GAMEPLAY KEYS
New rows for keys the game used but never showed: Quick Access Menu - Meditation, Use Quick Access Item - Cancel,
Sailing - Accelerate, and Photo Mode's movement keys. A row used in a menu-like screen (dialogue choices, the quick
access menu, photo mode, aiming a throw) can hold the same key as a gameplay row: giving it a key never takes that key
off a gameplay row, and the other way round.

ONE ROW: DRAW/SHEATHE - TAP FOR STEEL, HOLD FOR SILVER
Draw Steel Sword, Draw Silver Sword and their sheathe holds are one row, "Draw/Sheathe", on Key Bindings and on the
controller list. Tap its button: the steel sword is drawn, or sheathed if it is out. Hold it (about a third of a
second) and let go: the silver sword, the same way. With the other sword out, the press switches swords. On a
controller this works when both swords are on one button (the controller map puts them on X). Until you give the row
a key, the keys you had stay as they were. If an oil row is on the same key, holding the key applies oil too - clear
that row (Delete) to keep the hold for the silver sword alone.

TAP SPRINT TO DODGE OR TO RUN
In combat, tap Sprint and Geralt (or Ciri) dodges; hold it and he runs - keyboard or controller. Out of combat on a
controller, a tap of Sprint starts running and keeps running until you tap it again; a hold runs while held. Near
something you can talk to or loot, a tap still does that. On a controller in combat, where Sprint and Combat Roll
share a button, a tap dodges instead of rolling. Switch it off in Settings > Mods > Modern
Control Remapping. Nothing dodges or rolls out of combat.

HORSE: GALLOP ON B, DISMOUNT ON A
The game draws its hold-to-dismount circle on B whatever Horse Dismount is bound to, and a full hold of B threw the
rider off. The circle now follows Horse Dismount's own button: with the controller map, hold B to gallop and hold A to
dismount.

SIGN BUTTONS
With Options > Gameplay > alternative sign casting on and the five Select Sign actions on pad buttons (the controller
map: Igni RT, Quen B, Axii Y, Yrden X, Aard RB), hold Cast Sign and press a sign's button to cast it. On their own those
buttons keep their own jobs (B runs, X is the weapon button). Jump waits while Cast Sign is held and half a second
after a cast.

CONTROLLER ROWS (Options > Controller Scheme)
Under the controller diagram, a list of the controls of the tab on show (Exploration, Swimming and Diving, Combat, Horse
Riding, Sailing), each with the button it has now. D-pad or sticks choose a row; A, then any pad button, gives the
control that button (in every tab it is used in - the row says which); Start cancels.
To unbind a control in a tab: A, then the button it already has. It shows "-" there and does nothing in that tab, so
another control can have the button there; A and any button binds it again. Its button is kept underneath, because the
game cannot give a control a button again once its button is taken away - so an unbound row can always be bound again.
The controls the game handles one by one can be unbound this way: Sprint, the attacks, Cast Sign, Parry, Witcher
Senses, Dodge, Roll, Quick Access Item, Camera Lock, Summon Horse, the potions, Draw/Sheathe, Dive and Surface. A
control that already has no button (or a PlayStation one) is shown dim and cannot be changed from the list.

CONTROLLER MAP
The controller layout comes with the mod as an installer: close the game
and run "Controller Map Installer\Install Controller Map.bat" (drag a settings folder onto it to install there instead
of Documents\The Witcher 3 - for Mod Organizer 2 with profile-specific settings, the profile folder). It sets 250
controller bindings in every context (exploration, combat, horse, swimming, diving, sailing, aiming, the quick access
menu) and leaves every keyboard key alone; it also turns Left Stick Sprint off and alternative sign casting on. Each
file it changes is backed up first, and "Uninstall Controller Map.bat" puts back the first backup. Also set in the game:
Options > Accessibility > Automatically Apply Blade Oils on, and Manual Sword Drawing/Sheathing off.

LOCKED ROWS
Inventory, Map, Journal, Character, Alchemy, Crafting, Bestiary, Glossary, Gwent deck, Meditation, Hub and Toggle HUD
can be moved or cleared without turning Safeties off.

INSTALL
With a mod manager (Mod Organizer 2, Vortex): install the archive as a mod. By hand: copy the Mods and bin folders into
the game folder (The Witcher 3), allowing bin\config\r4game\user_config_matrix\pc\input.xml to be replaced.
Patch 5.0 (Remastered) only. No other mod required.

COMPATIBILITY
Replaces the game's input.xml (the list of rows on the Key Bindings page): another mod that replaces it too wins or
loses by install order. The scripts wrap functions of the game's in-game menu, player input and HUD with annotations,
so they merge with other script mods without Script Merger. Do not keep Modern Control Map installed beside it:
this mod is its new version and carries its behaviour, and both would act on one press.

UNINSTALL
Remove the mod. Rows that do not exist in the game's own list go back to the game's linked rows the next time the game
starts; Options > Key Bindings > Reset to defaults puts every key back.
