// =====================================================================================================================
// Unbind Vanilla Controls - ONE WEAPON BUTTON: TAP FOR STEEL, HOLD FOR SILVER (the owner, 2026-10-14: "there's just one
// row for weapon in any context ... it follows the same logic that modern control map follows of pressing for steel,
// holding for silver"). Taken over from Modern Control Map (ModernControlMap.ws, part 2), which first had it.
//
// When the steel and the silver sword's draw are on the same button - the Key Bindings page's one weapon row puts both on
// one key, and the controller map puts both on X - a TAP does the steel sword and a HOLD (0.3 s, acting when the button
// is let go) the silver one. Each is the game's own draw (EBAT_Draw_Steel / EBAT_Draw_Silver -> OnEquipMeleeWeapon with
// "sheathe if already equipped"): nothing drawn -> draw; that sword drawn -> sheathe; the other sword drawn -> switch.
// On a controller the pad buttons are compared, on the keyboard the keys. With the swords on different buttons the
// game's own handlers run unchanged.
//
// While Cast Sign is held on a controller the button is a sign's own (Yrden on X - UnbindVanillaControlsSigns.ws): no
// sword. These wrappers also carry the per-tab off switch (UnbindVanillaControlsGate.ws). Wrappers over events: no early
// return (logic library, AMF Witcher 3).
// =====================================================================================================================

@addField(CPlayerInput)
var uvcSwordPressedAt : float;

// the first pad button the game has for an action, or IK_None
function UVC_FirstPadKey(action : name) : EInputKey
{
	var keys : array<EInputKey>;
	var i : int;

	theInput.GetPadKeysForAction(action, keys);
	for (i = 0; i < keys.Size(); i += 1)
	{
		if (keys[i] != IK_None)
		{
			return keys[i];
		}
	}
	return IK_None;
}

// the first keyboard or mouse key the game has for an action, or IK_None
function UVC_FirstPcKey(action : name) : EInputKey
{
	var keys : array<EInputKey>;
	var i : int;

	theInput.GetPCKeysForAction(action, keys);
	for (i = 0; i < keys.Size(); i += 1)
	{
		if (keys[i] != IK_None)
		{
			return keys[i];
		}
	}
	return IK_None;
}

// both draws on one button of the device in use
function UVC_SwordsOnOneButton() : bool
{
	var steel : EInputKey;

	if (theInput.LastUsedGamepad())
	{
		steel = UVC_FirstPadKey('SteelSword');
		return steel != IK_None && steel == UVC_FirstPadKey('SilverSword');
	}
	steel = UVC_FirstPcKey('SteelSword');
	return steel != IK_None && steel == UVC_FirstPcKey('SilverSword');
}

// the game's own draw: the same checks and the same action its own handlers use
function UVC_DrawOrSheathe(silver : bool)
{
	if (!thePlayer)
	{
		return;
	}
	if (silver)
	{
		LogChannel('UnbindVanillaControls', "Weapon button: hold - silver sword");
	}
	else
	{
		LogChannel('UnbindVanillaControls', "Weapon button: tap - steel sword");
	}
	if (thePlayer.IsActionAllowed(EIAB_DrawWeapon) && thePlayer.GetBIsInputAllowed() && thePlayer.GetWeaponHolster().IsMeleeWeaponReady())
	{
		if (silver)
		{
			thePlayer.PushCombatActionOnBuffer(EBAT_Draw_Silver, BS_Pressed);
		}
		else
		{
			thePlayer.PushCombatActionOnBuffer(EBAT_Draw_Steel, BS_Pressed);
		}
		if (thePlayer.GetBIsCombatActionAllowed())
		{
			thePlayer.ProcessCombatActionBuffer();
		}
	}
	else if (!thePlayer.IsActionAllowed(EIAB_DrawWeapon))
	{
		thePlayer.DisplayActionDisallowedHudMessage(EIAB_DrawWeapon);
	}
}

@wrapMethod(CPlayerInput)
function OnCommSteelSword(action : SInputAction)
{
	var now : float;

	if (!UVC_ActionOffHere('SteelSword') && !(theInput.LastUsedGamepad() && GetIsAltSignCastingPressed()))
	{
		if (UVC_SwordsOnOneButton())
		{
			now = theGame.GetEngineTimeAsSeconds();
			if (IsPressed(action))
			{
				uvcSwordPressedAt = now;
			}
			else if (IsReleased(action) && uvcSwordPressedAt > 0)
			{
				UVC_DrawOrSheathe(now - uvcSwordPressedAt >= 0.3f);
				uvcSwordPressedAt = 0;
			}
		}
		else
		{
			wrappedMethod(action);
		}
	}
}

@wrapMethod(CPlayerInput)
function OnCommSilverSword(action : SInputAction)
{
	// with both swords on one button, the silver sword is the steel handler's hold - this press is that same press
	if (!UVC_ActionOffHere('SilverSword') && !UVC_SwordsOnOneButton() && !(theInput.LastUsedGamepad() && GetIsAltSignCastingPressed()))
	{
		wrappedMethod(action);
	}
}

// Draw/Sheathe is one row (the owner, 2026-10-14: "it should be one row that says draw/sheathe"): on the keyboard the
// game's sheathe holds (Sword Sheathe Steel / Silver, a hold of the draw key) sit on that row too. With both swords on
// one key the hold is the silver sword, and a tap sheathes whatever is out, so the game's sheathe holds stay quiet then.
// They still run for the alternate sign cast, which the game hangs on them (Yrden / Aard with Cast Sign held).
@wrapMethod(CPlayerInput)
function OnCommSheatheSteel(action : SInputAction)
{
	if (!UVC_SwordsOnOneButton() || GetIsAltSignCastingPressed())
	{
		wrappedMethod(action);
	}
}

@wrapMethod(CPlayerInput)
function OnCommSheatheSilver(action : SInputAction)
{
	if (!UVC_SwordsOnOneButton() || GetIsAltSignCastingPressed())
	{
		wrappedMethod(action);
	}
}
