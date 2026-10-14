"""Build the Key Bindings menu files of Modern Control Remapping (formerly Unbind Vanilla Controls) from the game's own data.

    python tools/gen_menu.py [--game "<The Witcher 3 folder>"] [--check]

Reads the game's bin\\config\\r4game\\user_config_matrix\\pc\\input.xml and content\\content0\\<lang>.w3strings and writes:

  dist\\bin\\config\\r4game\\user_config_matrix\\pc\\input.xml
      the game's file with the linked rows split (SPLITS below), the panel shortcuts unlocked, and the vanilla
      "PlaceTrophy,BuryBody" typo corrected to a semicolon so BuryBody is rebound with the row;
  dist\\Mods\\modUnbindVanillaControls\\content\\<lang>.w3strings
      the labels of the new rows that join two of the game's own strings ("Horse Riding - Jump"), for every language
      the game ships, built from that language's own strings - so every word a player reads is the game's.

Then it checks (and with --check only checks, exit 1 on a problem):
  * every action of the game's file is on a row of ours exactly as many times as it was on the game's rows;
  * every vanilla row id still exists (the player's saved binding for it is kept);
  * every row's label resolves: a game string key, or one of ours present in every language file.

The game folder comes from --game, else the W3_GAME environment variable, else Steam's library folders.
"""
import argparse
import os
import re
import sys
import winreg

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import w3strings  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIST = os.path.join(REPO, "dist")
XML_REL = os.path.join("bin", "config", "r4game", "user_config_matrix", "pc", "input.xml")
STRINGS_DIR = os.path.join(DIST, "Mods", "modUnbindVanillaControls", "content")

# Our string ids: idspace 7712 (2110000000 + 7712 * 1000 + n), clear of the game's own ids and the usual mod ranges.
ID_BASE = 2117712000

# Labels that join game strings: our key -> (game keys...). Shown as "first - second - ...".
COMPOSED = {
    "uvc_choice_up": ("panel_button_common_Talk", "input_device_key_name_IK_Up"),
    "uvc_choice_down": ("panel_button_common_Talk", "input_device_key_name_IK_Down"),
    "uvc_boat_reverse": ("ControlLayout_BoatLayoutTitle", "panel_input_action_GI_Decelerate"),
    "uvc_exploration_roll": ("ControlLayout_ExplorationLayoutTitle", "ControlLayout_Roll"),
    "uvc_horse_jump": ("ControlLayout_HorseLayoutTitle", "panel_button_common_Jump"),
    # Settings > Mods > Modern Control Remapping: the switch for tap-Sprint-to-dodge (option_<Var displayName>)
    "option_UvcTapSprintDodge": ("ControlLayout_RunSprint", "ControlLayout_press", "panel_input_action_Dodge"),
    "uvc_horse_jump_dismount": ("ControlLayout_HorseLayoutTitle", "panel_button_common_Jump", "ControlLayout_hold", "dismount_horse"),
    "uvc_horse_attack": ("ControlLayout_HorseLayoutTitle", "panel_groupname_fast_attack"),
    "uvc_horse_cast_sign": ("ControlLayout_HorseLayoutTitle", "ControlLayout_CastSign"),
    "uvc_horse_quick_slot": ("ControlLayout_HorseLayoutTitle", "ControlLayout_UseQuickSlot"),
    "uvc_meditation": ("ControlLayout_RadialMenu", "panel_title_meditation"),
    "uvc_boat_accelerate": ("ControlLayout_BoatLayoutTitle", "ControlLayout_Accelerate"),
    "uvc_cancel_aim": ("ControlLayout_UseQuickSlot", "panel_common_cancel"),
    "uvc_photo_forward": ("ControlLayout_PhotoMode", "ControlLayout_Movement", "input_device_key_name_IK_Up"),
    "uvc_photo_back": ("ControlLayout_PhotoMode", "ControlLayout_Movement", "input_device_key_name_IK_Down"),
    "uvc_photo_left": ("ControlLayout_PhotoMode", "ControlLayout_Movement", "input_device_key_name_IK_Left"),
    "uvc_photo_right": ("ControlLayout_PhotoMode", "ControlLayout_Movement", "input_device_key_name_IK_Right"),
    "uvc_photo_up": ("ControlLayout_PhotoMode", "photomode_params_char_updown", "input_device_key_name_IK_Up"),
    "uvc_photo_down": ("ControlLayout_PhotoMode", "photomode_params_char_updown", "input_device_key_name_IK_Down"),
    "uvc_photo_fast": ("ControlLayout_PhotoMode", "ControlLayout_RunSprint"),
}

# Fixed texts, the same in every language: the mod's name (a proper name) for its Settings > Mods page.
LITERALS = {"panel_UnbindVanillaControls": "Modern Control Remapping"}   # the mod's name since 2026-10-14 (the owner: "rename unbind vanilla controls to modern control remapping"); the key keeps the settings group id

# Texts the game has no string for, in every language it ships. The one weapon row is "Draw/Sheathe" (the owner,
# 2026-10-14: "it should be one row that says draw/sheathe"): the game says it only inside "Left Button - Draw/Sheathe
# Steel Sword" (ControlLayout_LeftSteelSword), so each language's text here is that string's own verb pair.
TRANSLATED = {
    "uvc_draw_sheathe": {
        "en": "Draw/Sheathe", "de": "Ziehen/Wegstecken", "fr": "Dégainer / rengainer", "es": "Desenvainar/Envainar",
        "esmx": "Desenvainar/Envainar", "it": "Sfodera/Rinfodera", "pl": "Wyciągnij/schowaj", "ru": "Обнажить/убрать",
        "ua": "Витягнути / сховати", "cz": "Tasit/zasunout", "hu": "Előhúzás/eltétel", "tr": "Çek/Kınına Koy",
        "br": "Sacar/embainhar", "jp": "抜刀/納刀", "kr": "뽑기 / 집어넣기", "cn": "拔剑/收剑", "zh": "拔劍／收劍",
        "ar": "سحب/إغماد",
    },
}

# Rows the game's file does not have, for actions it binds but never put on the page: after which game row they go,
# (row id, label key, actions[, tags]). Sailing - Accelerate joins Sprint's group (both on Shift by default). Most are what a menu-like screen does with a key that gameplay also uses - Space in the
# quick access menu is Meditation, not Jump - so with their own row the menu key and the gameplay key are set apart.
ADDED = {
    "RadialMenu": [("UvcMeditation", "uvc_meditation", ["OpenMeditation"])],
    "ThrowItem": [("UvcCancelAim", "uvc_cancel_aim", ["ThrowCastAbort", "VehicleItemActionAbort"])],
    "UvcBoatDismount": [("UvcBoatAccelerate", "uvc_boat_accelerate", ["GI_Accelerate"], ["input_overlap1"])],
    "PhotoMode": [
        ("UvcPhotoForward", "uvc_photo_forward", ["PMC_MoveForward"]),
        ("UvcPhotoBack", "uvc_photo_back", ["PMC_MoveBackward"]),
        ("UvcPhotoLeft", "uvc_photo_left", ["PMC_MoveLeft"]),
        ("UvcPhotoRight", "uvc_photo_right", ["PMC_MoveRight"]),
        ("UvcPhotoUp", "uvc_photo_up", ["PMC_MoveUp"]),
        ("UvcPhotoDown", "uvc_photo_down", ["PMC_MoveDown"]),
        ("UvcPhotoFast", "uvc_photo_fast", ["PMC_MoveFast"]),
    ],
}

# Actions the game binds with a row's key but left off the row, so rebinding the row left them behind: added to it.
EXTRA = {"Interaction": ["PetDog"]}

# Rows for a context of their own (dialogue choices, the quick access menu, photo mode, aiming a throw). They carry the tag
# uvc_menu, and the script keeps the page from taking a key off a gameplay row when a menu row gets it, and the other way
# round: those keys answer in different contexts, so both can hold one.
MENU_ROWS = {"UvcCancelAim", "UvcChoiceUp", "UvcChoiceDown", "UvcMeditation", "UvcPhotoForward", "UvcPhotoBack", "UvcPhotoLeft",
             "UvcPhotoRight", "UvcPhotoUp", "UvcPhotoDown", "UvcPhotoFast"}

# A linked row of the game's file -> the rows it becomes: (row id, label key, actions). The first row keeps the game's
# id, so the binding a player already has stays on it. "*" as the actions of the last row means "everything the game's
# row had that no row above took". Rows the game marks with an input_overlap tag keep it on every part, so the parts may
# still share one key; parts of an untagged row get a tag of ours (uvc_overlap_<row>), which the script adds to the
# menu's overlap check.
SPLITS = {
    "MoveFwd": [
        ("MoveFwd", "move_forward", ["MoveForward", "MovementDoubleTapW"]),
        ("UvcChoiceUp", "uvc_choice_up", ["ChangeChoiceUp"]),
    ],
    "MoveBck": [
        ("MoveBck", "move_back", ["MoveBackward", "MovementDoubleTapS"]),
        ("UvcChoiceDown", "uvc_choice_down", ["ChangeChoiceDown"]),
        ("UvcBoatReverse", "uvc_boat_reverse", ["GI_Decelerate"]),
    ],
    "JumpRoll": [
        ("JumpRoll", "panel_button_common_jump", ["Jump"]),
        ("UvcClimb", "panel_button_common_Climb", ["ExplorationInteraction"]),
        ("UvcExplorationRoll", "uvc_exploration_roll", ["Roll"]),
        ("UvcHorseJump", "uvc_horse_jump", ["HorseJump"]),
    ],
    "Interaction": [
        ("UvcTalk", "panel_button_common_Talk", ["Talk"]),
        ("UvcLoot", "panel_button_common_Pick", ["Container"]),
        ("UvcGatherHerbs", "panel_button_hud_interaction_Pick_up", ["GatherHerbs"]),
        ("UvcMountHorse", "panel_button_common_Mount", ["MountHorse"]),
        ("UvcOpen", "panel_button_common_Open", ["Open", "Close", "Lock", "Unlock", "Locked"]),
        ("UvcFastTravel", "panel_button_hud_interaction_Fast_travel", ["FastTravel"]),
        ("UvcExamine", "panel_button_common_Examine", ["Examine", "Look"]),
        ("Interaction", "ControlLayout_Interact", "*"),
    ],
    # press and hold of one control stay on one row (the owner, 2026-10-06: "the hold variant of the strong and fast
    # attacks should not be unlinked because they're still part of the attack")
    "AttackLight": [
        ("AttackLight", "panel_groupname_fast_attack", ["AttackWithAlternateLight", "SpecialAttackWithAlternateLight", "Finish", "Finisher"]),
        ("UvcHorseAttack", "uvc_horse_attack", ["VehicleAttack"]),
    ],
    "CastSign": [
        ("CastSign", "ControlLayout_CastSign", ["CastSign", "CastSignHold", "CiriSpecialAttack"]),
        ("UvcHorseCastSign", "uvc_horse_cast_sign", ["VehicleCastSign"]),
    ],
    "ThrowItem": [
        ("ThrowItem", "ControlLayout_UseQuickSlot", ["ThrowItem", "ThrowItemHold"]),
        ("UvcHorseQuickSlot", "uvc_horse_quick_slot", ["VehicleItemAction", "VehicleItemActionHold"]),
    ],
    "HorseDismount": [
        ("HorseDismount", "dismount_horse", ["HorseDismount"]),
        ("UvcBoatDismount", "panel_input_action_BoatDismount", ["BoatDismount"]),
    ],
    "ChangeQuest": [
        ("ChangeQuest", "ControlLayout_ChangeQuest", ["HighlightObjective"]),
        ("UvcTrackQuest", "panel_button_journal_track", ["TrackQuest"]),
    ],
    # ONE row for the swords (the owner, 2026-10-14: "just one row for weapon in any context ... pressing for steel,
    # holding for silver"): the game's Draw Steel Sword and Draw Silver Sword rows become one row whose key draws the
    # steel sword on a tap and the silver one on a hold (UnbindVanillaControlsSwords.ws). The game's silver row is merged
    # in (MERGED below). The holds the game had on those keys - sheathe and oil - get rows of their own, so a hold of the
    # weapon key is the silver sword and nothing else unless the player puts them back on it.
    "SteelSword": [
        # Draw/Sheathe, one row (the owner, 2026-10-14): the sheathe holds ride on it, and with both swords on its key the
        # script leaves them out - a tap sheathes the sword that is out (UnbindVanillaControlsSwords.ws)
        ("SteelSword", "uvc_draw_sheathe", ["SteelSword", "SilverSword", "CiriDrawWeapon", "CiriDrawWeaponAlternative",
                                            "SwordSheatheSteel", "SwordSheatheSilver"]),
        ("UvcOilSteel", "panel_inventory_paperdoll_slotname_steel_oil", ["OilSteelKB"]),
        ("UvcOilSilver", "panel_inventory_paperdoll_slotname_silver_oil", "*"),
    ],
}

# Game rows folded into another game row (their actions go to that row's SPLITS parts): row id -> the row it joins.
# The binding itself lives in input.settings by action, so nothing a player set is lost; the row id simply stops being shown.
MERGED = {"SilverSword": "SteelSword"}

# Rows the game locks (only rebindable with Safeties off); ours leaves them unlocked. The potion Hold rows stay locked:
# the menu hides them and the script moves them with their potion row.
KEEP_LOCKED = {"DrinkPotion1Hold", "DrinkPotion2Hold", "DrinkPotion3Hold", "DrinkPotion4Hold"}

VAR_RE = re.compile(r'^(?P<indent>\s*)<Var builder="Input"\s+id="(?P<id>\w+)"(?P<rest>.*?)/>(?P<tail>.*)$')
ATTR_RE = r'{}="([^"]*)"'


def find_game(arg):
    for cand in (arg, os.environ.get("W3_GAME")):
        if cand and os.path.isfile(os.path.join(cand, XML_REL)):
            return cand
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Valve\Steam") as k:
            steam = winreg.QueryValueEx(k, "SteamPath")[0]
        vdf = open(os.path.join(steam, "steamapps", "libraryfolders.vdf"), encoding="utf-8").read()
        for lib in re.findall(r'"path"\s+"([^"]+)"', vdf):
            cand = os.path.join(lib.replace("\\\\", "\\"), "steamapps", "common", "The Witcher 3")
            if os.path.isfile(os.path.join(cand, XML_REL)):
                return cand
    except OSError:
        pass
    sys.exit("The Witcher 3 was not found: pass --game or set W3_GAME.")


def split_actions(s):
    return [a for a in re.split(r"[;,]", s) if a]


def attr(rest, name):
    m = re.search(ATTR_RE.format(name), rest)
    return m.group(1) if m else None


def set_attr(rest, name, value):
    if re.search(ATTR_RE.format(name), rest):
        return re.sub(ATTR_RE.format(name), f'{name}="{value}"', rest, count=1)
    return rest + f' {name}="{value}"'


def drop_attr(rest, name):
    return re.sub(r'\s+' + ATTR_RE.format(name), "", rest, count=1)


def build_xml(vanilla):
    """-> (our xml text, rows {id: (label key, [actions], tags)}, vanilla rows {id: [actions]})."""
    out_lines = []
    ours = {}
    theirs = {}
    # the actions of the rows MERGED into another, added to that row before it is split
    merged_in = {}
    for line in vanilla.splitlines():
        m = VAR_RE.match(line.strip("\r\n"))
        if m and m.group("id") in MERGED:
            merged_in.setdefault(MERGED[m.group("id")], []).extend(split_actions(attr(m.group("rest"), "actions") or ""))
    for vid, into in MERGED.items():
        if into not in merged_in:
            sys.exit(f"MERGED: the game's file has no row {vid}")
    in_comment = False
    for line in vanilla.splitlines(keepends=True):
        # rows inside a <!-- --> block are the file's examples, not rows
        opens, closes = line.rfind("<!--"), line.rfind("-->")
        if in_comment or opens >= 0:
            in_comment = (in_comment and closes < 0) or (opens >= 0 and closes < opens)
            out_lines.append(line)
            continue
        m = VAR_RE.match(line.rstrip("\r\n"))
        if not m:
            out_lines.append(line)
            continue
        eol = line[len(line.rstrip("\r\n")):]
        vid, rest, indent, tail = m.group("id"), m.group("rest"), m.group("indent"), m.group("tail")
        actions = split_actions(attr(rest, "actions") or "")
        theirs[vid] = actions
        if vid in MERGED:
            continue   # its actions are on the row it joins
        actions = actions + [a for a in merged_in.get(vid, []) if a not in actions]
        actions = actions + [a for a in EXTRA.get(vid, []) if a not in actions]
        tags = [t for t in (attr(rest, "tags") or "").split(";") if t]
        if "locked" in tags and vid not in KEEP_LOCKED:
            tags.remove("locked")
        parts = SPLITS.get(vid)
        if not parts:
            parts = [(vid, attr(rest, "displayName"), actions)]
        else:
            if not any(t.startswith("input_overlap") for t in tags):
                tags = tags + [f"uvc_overlap_{vid.lower()}"]
        taken = [a for _, _, acts in parts if acts != "*" for a in acts]
        for a in taken:
            if a not in actions:
                sys.exit(f"SPLITS[{vid}] names {a}, which the game's row does not carry ({actions})")
        rows = [(pid, label, acts, tags) for pid, label, acts in parts]
        for pid, _, _ in parts:
            rows += [(a[0], a[1], a[2], list(a[3]) if len(a) > 3 else []) for a in ADDED.get(pid, [])]
        for pid, label, acts, rtags in rows:
            if acts == "*":
                acts = [a for a in actions if a not in taken]
            if pid in MENU_ROWS:
                rtags = rtags + ["uvc_menu"]
            r = rest
            r = set_attr(r, "displayName", label)
            r = set_attr(r, "actions", ";".join(acts))
            r = set_attr(r, "tags", ";".join(rtags)) if rtags else drop_attr(r, "tags")
            out_lines.append(f'{indent}<Var builder="Input" id="{pid}"{r}/>{tail}{eol}')
            ours[pid] = (label, acts, rtags)
    return "".join(out_lines), ours, theirs


def build_strings(content0):
    """{lang: [(id, key, text)]} for every language file the game ships."""
    langs = sorted(f[:-10] for f in os.listdir(content0) if f.endswith(".w3strings"))
    out = {}
    en = w3strings.read(os.path.join(content0, "en.w3strings"))
    for lang in langs:
        table = w3strings.read(os.path.join(content0, f"{lang}.w3strings"))
        rows = []
        for n, (key, gkeys) in enumerate(sorted(COMPOSED.items())):
            parts = []
            for gk in gkeys:
                t = table.get(w3strings.key_hash(gk)) or en.get(w3strings.key_hash(gk))
                if not t:
                    sys.exit(f"game string {gk} missing in {lang} and en")
                parts.append(t.strip().rstrip("-–—").rstrip())   # some languages end a word with a dash (de "Drücken -", ru "Нажать —")
            rows.append((ID_BASE + n + 1, key, " - ".join(parts)))
        for m, (key, text) in enumerate(sorted(LITERALS.items())):
            rows.append((ID_BASE + 900 + m, key, text))
        for m, (key, texts) in enumerate(sorted(TRANSLATED.items())):
            if lang not in texts:
                sys.exit(f"TRANSLATED[{key}] has no {lang} text")
            rows.append((ID_BASE + 950 + m, key, texts[lang]))
        out[lang] = rows
    return out


def check(ours, theirs, en_hashes, our_keys):
    problems = []
    script = open(os.path.join(DIST, "Mods", "modUnbindVanillaControls", "content", "scripts", "local", "UnbindVanillaControls.ws"), encoding="utf-8").read()
    for pid, (_, _, tags) in ours.items():
        for t in tags:
            if t.startswith("uvc_") and f"'{t}'" not in script:
                problems.append(f"row {pid}: tag {t} is not known to UnbindVanillaControls.ws")
    for after in ADDED:
        if after not in ours and after not in theirs:
            problems.append(f"ADDED rows follow {after}, which is not a row")
    count_ours, count_theirs = {}, {}
    for _, acts, _ in ours.values():
        for a in acts:
            count_ours[a] = count_ours.get(a, 0) + 1
    for acts in theirs.values():
        for a in acts:
            count_theirs[a] = count_theirs.get(a, 0) + 1
    for added in [a for rows in ADDED.values() for row in rows for a in row[2]] + [a for v in EXTRA.values() for a in v]:
        count_theirs[added] = count_theirs.get(added, 0) + 1   # documented additions
    for a in sorted(set(count_ours) | set(count_theirs)):
        if count_ours.get(a, 0) != count_theirs.get(a, 0):
            problems.append(f"action {a}: on {count_theirs.get(a, 0)} game row(s), {count_ours.get(a, 0)} of ours")
    for vid in theirs:
        if vid in MERGED:
            if MERGED[vid] not in ours or not all(a in [x for _, acts, _ in ours.values() for x in acts] for a in theirs[vid]):
                problems.append(f"the game's row {vid} is merged into {MERGED[vid]}, but its actions are not all on our rows")
            continue
        if vid not in ours:
            problems.append(f"the game's row {vid} is gone - a player's saved binding for it would be lost")
    for pid, (label, _, _) in ours.items():
        if label in our_keys:
            continue
        if w3strings.key_hash(label) not in en_hashes and label not in ("move_forward", "move_back", "move_left", "move_right"):
            problems.append(f"row {pid}: label key {label} is in neither the game's strings nor ours")
    return problems


# ---- controller rows (Settings > Controller Scheme) -------------------------------------------------------------
# The owner, 2026-10-06: the controller rows go under the controller diagram, per context tab. They are INPUTPAD rows
# of a hidden group; the game writes a row's pad key to every action on it, in every context (probe 1, Main Agent's run:
# an INPUTPAD row changed SpawnHorse's pad lines in both contexts and left its keyboard line alone). A row shows under
# every tab whose contexts bind one of its actions to a pad button in the game's defaults; an action used in several tabs
# moves in all of them (the owner chose that: "Live, shared actions move together").
PAD_XML_REL = os.path.join("bin", "config", "r4game", "user_config_matrix", "pc", "uvc_pad.xml")
DEFAULTS_REL = os.path.join("bin", "config", "r4game", "legacy", "base", "input_qwerty.ini")
PAD_GROUP = "UvcPadInput"
# Controller Scheme tab -> the contexts it shows (the order the game's InGameMenu_CreateControllerData lists the tabs;
# the Ciri tabs follow the same order)
PAD_TABS = [["Exploration", "Exploration_Replacer_Ciri", "JumpClimb"], ["Swimming", "Diving"],
            ["Combat", "Combat_Replacer_Ciri"], ["Horse", "Horse_Replacer_Ciri"], ["Boat", "BoatPassenger"]]
# (row id, label key, actions). Left out on purpose: Start and Back (the menus - a player must not lose the way in),
# SwordSheathe (on two D-pad buttons at once), the debug actions, and the stick axes.
PAD_ROWS = [
    ("PadSprint", "ControlLayout_RunSprint", ["Sprint"]),
    ("PadSprintToggle", "toggle_sprint", ["SprintToggle"]),
    ("PadJump", "panel_button_common_jump", ["Jump"]),
    ("PadClimb", "panel_button_common_Climb", ["ExplorationInteraction"]),
    ("PadExplorationRoll", "uvc_exploration_roll", ["Roll"]),
    ("PadTalk", "panel_button_common_Talk", ["Talk"]),
    ("PadLoot", "panel_button_common_Pick", ["Container"]),
    ("PadGatherHerbs", "panel_button_hud_interaction_Pick_up", ["GatherHerbs"]),
    ("PadMountHorse", "panel_button_common_Mount", ["MountHorse"]),
    ("PadOpen", "panel_button_common_Open", ["Open", "Close", "Lock", "Unlock", "Locked"]),
    ("PadFastTravel", "panel_button_hud_interaction_Fast_travel", ["FastTravel"]),
    ("PadExamine", "panel_button_common_Examine", ["Examine", "Look"]),
    ("PadInteract", "ControlLayout_Interact", "INTERACT_REST"),
    # a button's press and hold stay on one row (the owner, 2026-10-06 - attacks; the same for draw/oil, canter/gallop
    # and horse jump/dismount, each one button pressed or held)
    ("PadFastAttack", "panel_groupname_fast_attack", ["AttackLight", "SpecialAttackLight"]),
    ("PadStrongAttack", "panel_groupname_strong_attack", ["AttackHeavy", "SpecialAttackHeavy", "CiriAttackHeavy", "CiriSpecialAttackHeavy"]),
    ("PadCastSign", "ControlLayout_CastSign", ["CastSign", "CastSignHold", "CiriSpecialAttack"]),
    ("PadParry", "panel_input_action_lockandguard", ["LockAndGuard"]),
    ("PadFocus", "ControlLayout_Focus", ["Focus"]),
    ("PadDodge", "ControlLayout_Dodge", ["Dodge", "CiriDodge"]),
    ("PadCombatRoll", "ControlLayout_Roll", ["CbtRoll", "CiriDash"]),
    ("PadQuickItem", "ControlLayout_UseQuickSlot", ["ThrowItem", "ThrowItemHold"]),
    ("PadCancelAim", "uvc_cancel_aim", ["ThrowCastAbort", "VehicleItemActionAbort"]),
    ("PadRadialMenu", "ControlLayout_RadialMenu", ["RadialMenu"]),
    ("PadCameraLock", "camera_lock", ["CameraLock"]),
    ("PadChangeObjective", "ControlLayout_ChangeQuest", ["HighlightObjective"]),
    ("PadTrackQuest", "panel_button_journal_track", ["TrackQuest"]),
    ("PadSummonHorse", "ControlLayout_SummonHorse", ["SpawnHorse"]),
    ("PadPotion1", "potion_1", ["DrinkPotion1", "DrinkPotionUpperHold"]),
    ("PadPotion2", "potion_2", ["DrinkPotion2", "DrinkPotionLowerHold"]),
    # The draws are press-only and the oils (the D-pad's hold) rows of their own (the owner, 2026-10-06: "I want the
    # apply oils control button rows unbound since they're not necessary" - the game's automatic oil and sword options
    # cover them). ONE weapon row for both draws (the owner, 2026-10-14): its one button draws the steel sword on a tap
    # and the silver one on a hold (UnbindVanillaControlsSwords.ws).
    ("PadWeapon", "uvc_draw_sheathe", ["SteelSword", "SilverSword"]),
    ("PadOilSteel", "panel_inventory_paperdoll_slotname_steel_oil", ["OilSteel"]),
    ("PadOilSilver", "panel_inventory_paperdoll_slotname_silver_oil", ["OilSilver"]),
    ("PadGallop", "gallop_and_canter", ["Gallop", "Canter"]),
    # Horse Jump and Dismount apart (2026-10-14): the controller map has Jump on Y and Dismount on A's hold - one row would
    # show only Y and a change would put Dismount on the jump button
    ("PadHorseJump", "uvc_horse_jump", ["HorseJump"]),
    ("PadHorseDismount", "dismount_horse", ["HorseDismount"]),
    ("PadHorseAttack", "uvc_horse_attack", ["VehicleAttack"]),
    ("PadHorseCastSign", "uvc_horse_cast_sign", ["VehicleCastSign"]),
    ("PadHorseQuickItem", "uvc_horse_quick_slot", ["VehicleItemAction", "VehicleItemActionHold"]),
    ("PadDive", "ControlLayout_Dive", ["DiveDown"]),
    ("PadSurface", "ControlLayout_Emerge", ["DiveUp"]),
    ("PadBoatAccelerate", "uvc_boat_accelerate", ["GI_Accelerate"]),
    ("PadBoatReverse", "uvc_boat_reverse", ["GI_Decelerate"]),
    ("PadDisembark", "panel_input_action_BoatDismount", ["BoatDismount"]),
]


# Per-tab OFF (the owner, 2026-10-06: "set the sign casting to left trigger in combat and the Witcher senses to left
# trigger in exploration only"). The game's binding rows move an action in every context, so a control is given its
# button everywhere and switched OFF in the tabs where it must not answer: Y on its row. The script then skips the
# control's handler in that tab's contexts while the pad is in use. Only actions the game handles in CPlayerInput can
# be skipped (the handler -> UnbindVanillaControlsGate.ws); a row is switchable when its first action is one of them.
GATE = {
    "Sprint": "OnCommSprint", "SpawnHorse": "OnCommSpawnHorse", "DrinkPotion1": "OnCommDrinkPotion1",
    "DrinkPotion2": "OnCommDrinkPotion2",
    "CastSign": "OnCastSign", "Focus": "OnExpFocus", "AttackLight": "OnCbtAttackLight", "AttackHeavy": "OnCbtAttackHeavy",
    "SpecialAttackLight": "OnCbtSpecialAttackLight", "SpecialAttackHeavy": "OnCbtSpecialAttackHeavy",
    "Dodge": "OnCbtDodge", "CbtRoll": "OnCbtRoll", "LockAndGuard": "OnCbtLockAndGuard", "CameraLock": "OnCbtCameraLock",
    "ThrowItem": "OnCbtThrowItem", "ThrowItemHold": "OnCbtThrowItemHold",
    # 2026-10-14 (unbind = the same button again, which is this off switch): the weapon row and dive / surface. Not
    # aiming's cancel: it answers in the aiming contexts (ThrowHold...), which belong to no tab, so its switch would never act
    "SteelSword": "OnCommSteelSword", "SilverSword": "OnCommSilverSword",
    "DiveDown": "OnDiving", "DiveUp": "OnDiving",
}
OFF_GROUP = "UvcPadTabsOff"
# rows that share their first action with another row: the off switch belongs to that other row
GATE_EXCLUDE = set()
GATE_MAP_REL = os.path.join("Mods", "modUnbindVanillaControls", "content", "scripts", "local", "UnbindVanillaControlsGateMap.ws")


def build_gate_map(pad_rows):
    """-> (WitcherScript text mapping (action, tab) to the row's off switch, {row: [tabs]} of switchable rows)."""
    switchable = {}
    cases = {}
    for rid, (label, acts, tabs) in pad_rows.items():
        if not acts or acts[0] not in GATE or rid in GATE_EXCLUDE:
            continue
        ts = [t for t in range(len(PAD_TABS)) if tabs & (1 << t)]
        switchable[rid] = ts
        for a in acts:
            if a in GATE:
                cases.setdefault(a, {}).update({t: f"{rid}_off{t}" for t in ts})
    out = ["// GENERATED by tools/gen_menu.py - do not edit. The off switch of a control in a Controller Scheme tab:",
           "// UvcPadTabsOff.<row>_off<tab> (hidden TOGGLE vars in uvc_pad.xml), by action and tab; '' = no switch.",
           "function UVC_ActionOffVar(action : name, tab : int) : name", "{", "\tswitch (action)", "\t{"]
    for a in sorted(cases):
        out.append(f"\t\tcase '{a}':")
        out.append("\t\t\tswitch (tab)")
        out.append("\t\t\t{")
        for t, var in sorted(cases[a].items()):
            out.append(f"\t\t\t\tcase {t}: return '{var}';")
        out.append("\t\t\t}")
        out.append("\t\t\tbreak;")
    out += ["\t}", "\treturn '';", "}", "",
            "// The same switch by row and tab, for the page (Y on a row).",
            "function UVC_RowOffVar(row : name, tab : int) : name", "{", "\tswitch (row)", "\t{"]
    for rid, ts in switchable.items():
        out.append(f"\t\tcase '{rid}':")
        out.append("\t\t\tswitch (tab)")
        out.append("\t\t\t{")
        for t in ts:
            out.append(f"\t\t\t\tcase {t}: return '{rid}_off{t}';")
        out.append("\t\t\t}")
        out.append("\t\t\tbreak;")
    out += ["\t}", "\treturn '';", "}", ""]
    # the page asks the GAME's live mapping whether a row's button can still be changed (UVC_PadRowLocked): a pad write
    # lands only when the action's current pad key is an Xbox button (logic library, UVC probe 4)
    out += ["// The first action of each controller row: the action whose live pad key decides whether the row can change.",
            "function UVC_PadRowFirstAction(row : name) : name", "{", "\tswitch (row)", "\t{"]
    for rid, (label, acts, tabs) in pad_rows.items():
        out.append(f"\t\tcase '{rid}': return '{acts[0]}';")
    out += ["\t}", "\treturn '';", "}", ""]
    return "\r\n".join(out), switchable


def read_defaults(path):
    """{context: [(key, action)]} with DERIVED_FROM resolved."""
    sections, cur = {}, None
    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.strip()
        m = re.match(r"\[(.+)\]$", line)
        if m:
            cur = m.group(1)
            sections[cur] = ([], [])
            continue
        if cur is None:
            continue
        m = re.match(r"DERIVED_FROM=(\w+)", line)
        if m:
            sections[cur][0].append(m.group(1))
            continue
        m = re.match(r"(IK_\w+)=\([Aa]ction=(\w+)", line)
        if m:
            sections[cur][1].append((m.group(1), m.group(2)))

    def resolve(name, seen):
        if name in seen or name not in sections:
            return []
        seen.add(name)
        out = list(sections[name][1])
        for d in sections[name][0]:
            out += resolve(d, seen)
        return out
    return {name: resolve(name, set()) for name in sections}


def pad_button(key):
    return key.startswith("IK_Pattern_") or (key.startswith("IK_Pad_") and "Axis" not in key)


def build_pad(game, ours):
    """-> (xml text, rows {id: (label, actions, tabs)}, problems)."""
    defaults = read_defaults(os.path.join(game, DEFAULTS_REL))
    problems = []
    interact_rest = ours["Interaction"][1]
    rows = {}
    for rid, label, acts in PAD_ROWS:
        if acts == "INTERACT_REST":
            acts = interact_rest
        tabs = 0
        for t, ctxs in enumerate(PAD_TABS):
            for c in ctxs:
                if any(pad_button(k) and a in acts for k, a in defaults.get(c, [])):
                    tabs |= 1 << t
        if not tabs:
            problems.append(f"controller row {rid}: none of {acts[:4]} has a pad button in any Controller Scheme tab")
        rows[rid] = (label, acts, tabs)
    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             "<!-- Modern Control Remapping - the controller rows shown under the diagram of Settings > Controller Scheme",
             "     (generated by tools/gen_menu.py). Hidden from Settings: the rows are drawn by the mod's Controller Scheme page.",
             "     uvc_tab<n>: the tab (0 Exploration, 1 Swimming and Diving, 2 Combat, 3 Horse Riding, 4 Sailing) whose",
             "     contexts bind one of the row's actions to a pad button in the game's defaults. -->",
             "<UserConfig>",
             f'\t<Group builder="Input" id="{PAD_GROUP}" displayName="hidden" tags="keybinds" visibilityCondition="hideAlways">',
             "\t\t<VisibleVars>"]
    # one action, one row: the engine gives an action to one binding row, and a second row naming it wrote nothing (the
    # "Swords" row, 2026-10-06 - logic library)
    seen = {}
    for rid, (_, acts, _) in rows.items():
        for a in acts:
            if a in seen:
                problems.append(f"controller action {a} is on two rows ({seen[a]}, {rid}) - a write to the second would change nothing")
            seen[a] = rid
    gate_script, switchable = build_gate_map(rows)
    for rid, (label, acts, tabs) in rows.items():
        tags = ";".join(["uvc_pad"] + [f"uvc_tab{t}" for t in range(len(PAD_TABS)) if tabs & (1 << t)]
                        + (["uvc_gate"] if rid in switchable else []))
        lines.append(f'\t\t\t<Var builder="Input" id="{rid}" displayName="{label}" displayType="INPUTPAD" '
                     f'actions="{";".join(acts)}" tags="{tags}"/>')
    lines += ["\t\t</VisibleVars>", "\t</Group>",
              "\t<!-- Y on a row: the control is off in that tab (UnbindVanillaControlsGate.ws skips its handler there). -->",
              f'\t<Group id="{OFF_GROUP}" displayName="hidden" visibilityCondition="hideAlways">', "\t\t<VisibleVars>"]
    for rid, ts in switchable.items():
        for t in ts:
            lines.append(f'\t\t\t<Var id="{rid}_off{t}" displayName="hidden" displayType="TOGGLE"/>')
    lines += ["\t\t</VisibleVars>", "\t</Group>", "</UserConfig>", ""]
    return "\r\n".join(lines), rows, problems, gate_script


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--game")
    ap.add_argument("--check", action="store_true", help="only check the files already in dist")
    args = ap.parse_args()
    game = find_game(args.game)
    content0 = os.path.join(game, "content", "content0")
    vanilla = open(os.path.join(game, XML_REL), encoding="utf-8-sig").read()
    xml, ours, theirs = build_xml(vanilla)
    strings = build_strings(content0)
    en_hashes = set(w3strings.read(os.path.join(content0, "en.w3strings")))
    problems = check(ours, theirs, en_hashes, set(COMPOSED) | set(TRANSLATED))
    pad_xml, pad_rows, pad_problems, gate_script = build_pad(game, ours)
    out_gate = os.path.join(DIST, GATE_MAP_REL)
    problems += pad_problems
    for rid, (label, _, _) in pad_rows.items():
        if label not in COMPOSED and label not in TRANSLATED and w3strings.key_hash(label) not in en_hashes:
            problems.append(f"controller row {rid}: label key {label} is in neither the game's strings nor ours")
    out_xml = os.path.join(DIST, XML_REL)
    out_pad = os.path.join(DIST, PAD_XML_REL)
    if args.check:
        if open(out_xml, encoding="utf-8-sig").read() != xml:
            problems.append("dist input.xml differs from what the generator builds - run tools/gen_menu.py")
        if not os.path.isfile(out_pad) or open(out_pad, encoding="utf-8", newline="").read() != pad_xml:
            problems.append("dist uvc_pad.xml differs from what the generator builds - run tools/gen_menu.py")
        if not os.path.isfile(out_gate) or open(out_gate, encoding="utf-8", newline="").read() != gate_script:
            problems.append("dist UnbindVanillaControlsGateMap.ws differs from what the generator builds - run tools/gen_menu.py")
        for lang, rows in strings.items():
            p = os.path.join(STRINGS_DIR, f"{lang}.w3strings")
            got = w3strings.read(p) if os.path.isfile(p) else {}
            for _, key, text in rows:
                if got.get(w3strings.key_hash(key)) != text:
                    problems.append(f"{lang}.w3strings: {key} missing or stale")
    else:
        os.makedirs(os.path.dirname(out_xml), exist_ok=True)
        # the game's own file starts with a BOM; ours keeps that
        with open(out_xml, "w", encoding="utf-8-sig", newline="") as f:
            f.write(xml)
        with open(out_pad, "w", encoding="utf-8", newline="") as f:
            f.write(pad_xml)
        with open(out_gate, "w", encoding="utf-8", newline="") as f:
            f.write(gate_script)
        print(f"wrote {out_pad} ({len(pad_rows)} controller rows)")
        os.makedirs(STRINGS_DIR, exist_ok=True)
        for lang, rows in strings.items():
            p = os.path.join(STRINGS_DIR, f"{lang}.w3strings")
            w3strings.write(p, rows)
            back = w3strings.read(p)
            for _, key, text in rows:
                if back.get(w3strings.key_hash(key)) != text:
                    problems.append(f"{lang}.w3strings: {key} did not read back")
        print(f"wrote {out_xml} ({len(ours)} rows, {len(theirs)} in the game's file) and {len(strings)} language files")
    # every handler the gate names must be wrapped by a script of ours, or the off switch would do nothing
    script_dir = os.path.join(DIST, "Mods", "modUnbindVanillaControls", "content", "scripts", "local")
    wrapped = "".join(open(os.path.join(script_dir, f), encoding="utf-8").read() for f in os.listdir(script_dir) if f.endswith(".ws"))
    for action, handler in GATE.items():
        if not re.search(r"@wrapMethod\(CPlayerInput\)\s*function " + handler + r"\(", wrapped):
            problems.append(f"GATE names {action} -> {handler}, which no script of ours wraps")
    for p in problems:
        print("FAIL ", p)
    if problems:
        sys.exit(1)
    print("ok    every action is on our rows as often as on the game's (plus the documented additions), every game row id kept, every label resolves, every tag of ours is known to the script")


if __name__ == "__main__":
    main()
