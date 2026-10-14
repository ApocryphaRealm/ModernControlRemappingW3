// =====================================================================================================================
// Unbind Vanilla Controls - the game's Key Bindings page (Options > Key Bindings).
//
// Annotations only: no game script is replaced, so nothing needs merging in Script Merger and other mods that wrap the
// same functions keep working.
//
// 1. DELETE - OR THE ROW'S OWN KEY PRESSED AGAIN - CLEARS A ROW, AND IT STAYS CLEARED. The game can already leave a row with no key - its page calls
//    OnClearKeybind when a middle click lands on a row - but nothing on the keyboard reaches it. With this mod, pressing
//    Delete when the page asks for a key clears that row instead of binding Delete. The page passes Delete through
//    whether Safeties is on or off (its own list of refused keys does not name it). The game saves the cleared row like
//    any other binding.
//
// 2. ROWS SPLIT FROM ONE GAME ROW MAY STILL SHARE A KEY. This mod's input.xml splits rows the game linked together (Jump,
//    Climb, Roll and Horse Jump were one row; Interact held Talk, Loot, Mount and seventy more). When a key is given to a
//    row, the page takes it off every other row on that key unless both carry the same input_overlap tag. Parts of a
//    tagged row keep the game's tag; parts of an untagged row carry a tag of ours, uvc_overlap_<row>, which the game's
//    check does not know - GetKeybindGroupTag below hands it over.
//
// 3. A MENU KEY AND A GAMEPLAY KEY NEVER KNOCK EACH OTHER OFF. Rows tagged uvc_menu are for screens that read their keys
//    in a context of their own (dialogue choices, the quick access menu, photo mode): W choosing a dialogue line and W
//    walking forward never answer at the same time. The page's check knows nothing of contexts, so while a key is being
//    given, a row on the other side of that line reports the same group as the row being bound, and the check leaves it.
// =====================================================================================================================

// Our overlap tags, one per game row that had none (tools/gen_menu.py checks that every tag it writes is listed here).
function UVC_OverlapTag(config : CInGameConfigWrapper, keybindName : name) : name
{
	var tags : array<name>;
	var i : int;

	tags.PushBack('uvc_overlap_movefwd');
	tags.PushBack('uvc_overlap_movebck');
	tags.PushBack('uvc_overlap_attacklight');
	tags.PushBack('uvc_overlap_attackheavy');
	tags.PushBack('uvc_overlap_castsign');
	tags.PushBack('uvc_overlap_throwitem');
	tags.PushBack('uvc_overlap_steelsword');
	tags.PushBack('uvc_overlap_silversword');
	tags.PushBack('uvc_overlap_changequest');

	for (i = 0; i < tags.Size(); i += 1)
	{
		if (config.DoVarHasTag('PCInput', keybindName, tags[i]))
		{
			return tags[i];
		}
	}
	return '';
}

function UVC_IsMenuRow(config : CInGameConfigWrapper, keybindName : name) : bool
{
	return config.DoVarHasTag('PCInput', keybindName, 'uvc_menu');
}

// The row a key is being given to right now, while the game's OnChangeKeybind runs; '' otherwise.
@addField(CR4IngameMenu)
var uvcBindingRow : name;

@wrapMethod(CR4IngameMenu)
function GetKeybindGroupTag(keybindName : name) : name
{
	var tag : name;

	tag = wrappedMethod(keybindName);
	if (tag == '')
	{
		tag = UVC_OverlapTag(mInGameConfigWrapper, keybindName);
	}
	if (uvcBindingRow != '')
	{
		if (keybindName == uvcBindingRow)
		{
			// The game clears every other row on the key when the row being bound has no group at all; a group name of
			// its own keeps that (no other row shares it) and lets the case below say "same group" to it.
			if (tag == '')
			{
				tag = 'uvc_lone_row';
			}
		}
		else if (UVC_IsMenuRow(mInGameConfigWrapper, keybindName) != UVC_IsMenuRow(mInGameConfigWrapper, uvcBindingRow))
		{
			tag = GetKeybindGroupTag(uvcBindingRow);
		}
	}
	return tag;
}

// The key a Key Bindings row has now is the key pressed for it: pressing a row's own key again leaves it with no key (the
// owner, 2026-10-06: "selecting the same button a second time while unbinding will unselect it so it's unbound"). The
// row's value reads "IK_E;IK_None"; the empty slot is dropped the way the game's own OnChangeKeybind drops it.
function UVC_PcRowHasKey(config : CInGameConfigWrapper, keybindTag : name, key : EInputKey) : bool
{
	var current : string;
	var pressed : string;

	current = config.GetVarValue('PCInput', keybindTag);
	current = StrReplace(current, ";IK_None", "");
	current = StrReplace(current, "IK_None;", "");
	pressed = key;
	return current != "" && current != "IK_None" && current == pressed;
}

// OnChangeKeybind is an event: no early return in this wrapper (a bare "return;" in a wrapper over an event stops the
// script compile - logic library, AMF Witcher 3). The game's own handler moves a potion's hidden Hold row with it;
// clearing does the same.
@wrapMethod(CR4IngameMenu)
function OnChangeKeybind(keybindTag : name, newKeybindValue : EInputKey)
{
	var outer : name;

	if (UVC_IsPadRow(mInGameConfigWrapper, keybindTag))
	{
		// a controller row of the Controller Scheme page (UnbindVanillaControlsPad.ws); 9000 + tab is the tab's off switch
		// (unbind = the row's own button again)
		if ((int)newKeybindValue >= 9000)
		{
			LogChannel('UnbindVanillaControls', "Controller Scheme: " + keybindTag + " off-switch code received " + (int)newKeybindValue + " -> tab " + UVC_PadTabFromCode((int)newKeybindValue));
			UVC_TogglePadRowOff(keybindTag, UVC_PadTabFromCode((int)newKeybindValue));
		}
		else
		{
			UVC_BindPadRow(this, keybindTag, newKeybindValue);
		}
		UVC_SendPadRows(m_flashValueStorage);
	}
	else if (newKeybindValue == IK_Delete || UVC_PcRowHasKey(mInGameConfigWrapper, keybindTag, newKeybindValue))
	{
		LogChannel('UnbindVanillaControls', "Key Bindings: Delete or the row's own key on " + keybindTag + " - the row is cleared");
		OnClearKeybind(keybindTag);
		if (keybindTag == 'DrinkPotion1')
		{
			OnClearKeybind('DrinkPotion1Hold');
		}
		else if (keybindTag == 'DrinkPotion2')
		{
			OnClearKeybind('DrinkPotion2Hold');
		}
		else if (keybindTag == 'DrinkPotion3')
		{
			OnClearKeybind('DrinkPotion3Hold');
		}
		else if (keybindTag == 'DrinkPotion4')
		{
			OnClearKeybind('DrinkPotion4Hold');
		}
	}
	else
	{
		// the game's handler calls itself again for a potion's Hold row; keep the outer row for when it returns
		outer = uvcBindingRow;
		uvcBindingRow = keybindTag;
		wrappedMethod(keybindTag, newKeybindValue);
		uvcBindingRow = outer;
	}
}
