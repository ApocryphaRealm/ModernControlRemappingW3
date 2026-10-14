// =====================================================================================================================
// Unbind Vanilla Controls - a control OFF in a Controller Scheme tab (the owner, 2026-10-06: "set the sign casting to left
// trigger in combat and the Witcher senses to left trigger in exploration only").
//
// The game's binding rows give an action its button in every context. To let one button do one job in combat and another
// in exploration, a control is switched off in a tab (Y on its row, UvcPadTabsOff.<row>_off<tab>) and its handler here
// does nothing while the player is in that tab's contexts and the pad is in use - so the other control on that button is
// the only one that answers. The keyboard is not affected. Which action belongs to which switch:
// UnbindVanillaControlsGateMap.ws (generated). Sprint, Dodge and Roll are gated in UnbindVanillaControlsDodge.ws and the
// swords in UnbindVanillaControlsSwords.ws, which
// already wrap them.
//
// Wrappers over events: no early return (logic library, AMF Witcher 3).
// =====================================================================================================================

// the Controller Scheme tab of the context the player is in: 0 Exploration, 1 Swimming and Diving, 2 Combat,
// 3 Horse Riding, 4 Sailing; -1 for any other context (menus, scenes)
function UVC_CurrentTab() : int
{
	switch (theInput.GetContext())
	{
		case 'Exploration':
		case 'Exploration_Replacer_Ciri':
		case 'JumpClimb':
			return 0;
		case 'Swimming':
		case 'Diving':
			return 1;
		case 'Combat':
		case 'Combat_Replacer_Ciri':
			return 2;
		case 'Horse':
		case 'Horse_Replacer_Ciri':
			return 3;
		case 'Boat':
		case 'BoatPassenger':
			return 4;
	}
	return -1;
}

function UVC_ActionOffHere(action : name) : bool
{
	var tab : int;
	var offVar : name;

	if (!theInput.LastUsedGamepad())
	{
		return false;
	}
	tab = UVC_CurrentTab();
	if (tab < 0)
	{
		return false;
	}
	offVar = UVC_ActionOffVar(action, tab);
	if (offVar == '')
	{
		return false;
	}
	return theGame.GetInGameConfigWrapper().GetVarValue('UvcPadTabsOff', offVar) == "true";
}

@wrapMethod(CPlayerInput)
function OnCastSign(action : SInputAction)
{
	if (!UVC_ActionOffHere('CastSign')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnExpFocus(action : SInputAction)
{
	if (!UVC_ActionOffHere('Focus')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCbtLockAndGuard(action : SInputAction)
{
	if (!UVC_ActionOffHere('LockAndGuard')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCbtAttackLight(action : SInputAction)
{
	if (!UVC_ActionOffHere('AttackLight')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCbtAttackHeavy(action : SInputAction)
{
	if (!UVC_ActionOffHere('AttackHeavy')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCbtSpecialAttackLight(action : SInputAction)
{
	if (!UVC_ActionOffHere('SpecialAttackLight')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCbtSpecialAttackHeavy(action : SInputAction)
{
	if (!UVC_ActionOffHere('SpecialAttackHeavy')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCbtCameraLock(action : SInputAction)
{
	if (!UVC_ActionOffHere('CameraLock')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCbtThrowItem(action : SInputAction)
{
	if (!UVC_ActionOffHere('ThrowItem')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCbtThrowItemHold(action : SInputAction)
{
	if (!UVC_ActionOffHere('ThrowItemHold')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCommSpawnHorse(action : SInputAction)
{
	// On a controller the game calls Roach on a SECOND tap within its double-tap window (isSpawnHorseSecondTap). The owner
	// first asked for one press; with Witcher Senses on the same left stick he chose the double press (2026-10-06: "Make
	// calling the horse to stick presses"), which is the game's own handler - so only the per-tab off switch is added here.
	// (The earlier "nothing happens even if I ... double tap it" was the binding never reaching the file - IK_None.)
	if (!UVC_ActionOffHere('SpawnHorse'))
	{
		wrappedMethod(action);
	}
}

@wrapMethod(CPlayerInput)
function OnCommDrinkPotion1(action : SInputAction)
{
	if (!UVC_ActionOffHere('DrinkPotion1')) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnCommDrinkPotion2(action : SInputAction)
{
	if (!UVC_ActionOffHere('DrinkPotion2')) { wrappedMethod(action); }
}

// Off switches added 2026-10-14 with "unbind = the same button again" (UnbindVanillaControlsPad.ws): aiming's cancel and
// dive / surface. OnDiving answers both DiveDown and DiveUp, so the action's own name picks the switch.
@wrapMethod(CPlayerInput)
function OnCbtThrowCastAbort(action : SInputAction)
{
	if (!UVC_ActionOffHere(action.aName)) { wrappedMethod(action); }
}

@wrapMethod(CPlayerInput)
function OnDiving(action : SInputAction)
{
	if (!UVC_ActionOffHere(action.aName)) { wrappedMethod(action); }
}

// Dismount follows its own binding on a controller (taken back from Modern Control Map, part 3, on 2026-10-14 - the owner:
// "holding A and holding B both dismount when it should be sprinting with B and dismounting with A"). The game's horse
// script and HUD hand the hold-to-dismount indicator a fixed B (EnableHudHoldIndicator_Impl(IK_Pad_B_CIRCLE, ...,
// 'HorseDismount')), and the indicator's completed hold dismounts - so with Gallop on B and Horse Dismount on A's hold,
// holding B still threw the rider off. The indicator is given Horse Dismount's own pad button instead; with none, the
// game's B is kept.
@wrapMethod(CR4GuiManager)
function EnableHudHoldIndicator_Impl(gpadKeyCode : int, kbKeyCode : int, label : string, holdDuration : float, optional intName : name)
{
	var dismountKey : EInputKey;

	if (intName == 'HorseDismount' && gpadKeyCode == (int)IK_Pad_B_CIRCLE)
	{
		dismountKey = UVC_FirstPadKey('HorseDismount');
		if (dismountKey != IK_None)
		{
			gpadKeyCode = (int)dismountKey;
		}
	}
	wrappedMethod(gpadKeyCode, kbKeyCode, label, holdDuration, intName);
}
