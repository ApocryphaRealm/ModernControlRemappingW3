// =====================================================================================================================
// Unbind Vanilla Controls - TAP SPRINT TO DODGE, HOLD IT TO RUN, in combat (the owner, 2026-10-06: "I want to
// make the dodge button active even outside of combat and ... dodge with a tap of sprint and run by holding sprint";
// then "Let's just leave dodging and rolling out of combat alone"; then "I do want the sprint while holding B and tapping B
// to dodge, regardless of context. And pressing A is only a roll in combat so that it doesn't affect selecting"; then,
// after two runs where it went wrong, "we're going to have to get rid of the dodging out of combat and rolling out of
// combat because the game just doesn't allow it and it keeps messing up").
//
// OUT OF COMBAT ON A CONTROLLER, A TAP OF SPRINT TOGGLES RUNNING AND A HOLD RUNS (the owner, 2026-10-14: "holding B does
// sprint, but tapping it doesn't" - "Modern Control Map already has the mechanic I'm looking for, which is you tap to
// sprint or hold the sprint"). Taken back from Modern Control Map (ModernControlMap.ws, part 1), as UVC first had it on
// 2026-10-06: the game's own Sprint Toggle answers a pad only with its Left Stick Sprint option on, and that option makes
// the Sprint button itself do nothing - so a release of Sprint within 0.2 s calls the game's own SetSprintToggle. Not while
// the alternate sign cast is held (Cast Sign + B casts Quen on the controller map). Independent of the switch below.
//
// The game already has this shape on a controller in combat - its OnCbtDodge dodges on a release within 0.2 s and
// sprints when the button is held (HoldDodgeToSprintTimer) - but only on the Dodge button, only in combat. Here the same
// 0.2 s rule is put on Sprint in combat: the press still starts running as the game does; a release within 0.2 s
// dodges (thePlayer.EvadePressed, the game's own dodge, which keeps its own checks - EIAB_Dodge, input allowed).
//
// Not a dodge when the tap has another job: an interaction in range (on a controller A is Interact on a tap and Sprint
// on a hold - talking or looting must not dodge too), the alternate sign cast (Sprint + the sign button casts Aard), and
// dead. On a controller in combat A is also Combat Roll: while Sprint's button is down, a Roll press of that same button
// is skipped, so the tap dodges and does not also roll. Roll on another button (Settings > Controller Scheme) is untouched.
//
// Switch: Settings > Mods > Unbind Vanilla Controls (bin\config\r4game\user_config_matrix\pc\UnbindVanillaControls.xml);
// an unset value is on.
// =====================================================================================================================

function UVC_TapSprintDodgeOn() : bool
{
	return theGame.GetInGameConfigWrapper().GetVarValue('UnbindVanillaControls', 'TapSprintDodge') != "false";
}

// when Sprint was pressed (engine seconds), 0 when it is not down
@addField(CPlayerInput)
var uvcSprintPressedAt : float;

// when the game's own Dodge was last pressed: the owner puts Sprint on B (2026-10-06: "the dodge/sprint to B"), where
// combat's Dodge already is - a tap of B there is the game's own dodge, and a second one from here would double it
@addField(CPlayerInput)
var uvcDodgePressedAt : float;

@wrapMethod(CPlayerInput)
function OnCbtDodge(action : SInputAction)
{
	if (!UVC_ActionOffHere('Dodge'))
	{
		if (IsPressed(action))
		{
			uvcDodgePressedAt = theGame.GetEngineTimeAsSeconds();
		}
		wrappedMethod(action);
	}
}

@wrapMethod(CPlayerInput)
function OnCommSprint(action : SInputAction)
{
	var now : float;

	// off in this Controller Scheme tab (UnbindVanillaControlsGate.ws): neither run, tap-dodge nor tap-toggle here
	if (!UVC_ActionOffHere('Sprint'))
	{
		now = theGame.GetEngineTimeAsSeconds();
		if (IsPressed(action))
		{
			uvcSprintPressedAt = now;
		}
		else if (IsReleased(action) && uvcSprintPressedAt > 0)
		{
			if (now - uvcSprintPressedAt <= 0.2f && thePlayer)
			{
				if (thePlayer.IsInCombat())
				{
					// the same press also pressed the game's Dodge (both on one button): the game dodges, not this
					if (UVC_TapSprintDodgeOn() && AbsF(uvcDodgePressedAt - uvcSprintPressedAt) > 0.05f)
					{
						UVC_TapDodge();
					}
				}
				else if (theInput.LastUsedGamepad())
				{
					UVC_TapSprintToggle();
				}
			}
			uvcSprintPressedAt = 0;
		}
		wrappedMethod(action);
	}
}

// Out of combat on a controller: a tap of Sprint turns running on or off (the game's own SetSprintToggle); a hold runs
// while held, as the game does. The same conditions as Modern Control Map's: alive, out of combat, alternate sign cast
// not held.
function UVC_TapSprintToggle()
{
	if (!thePlayer || !thePlayer.IsAlive() || thePlayer.IsInCombat())
	{
		return;
	}
	if (thePlayer.GetInputHandler() && thePlayer.GetInputHandler().GetIsAltSignCastingPressed())
	{
		return;
	}
	thePlayer.SetSprintToggle(!thePlayer.GetIsSprintToggled());
	LogChannel('UnbindVanillaControls', "Sprint tap: running toggled");
}

// No roll out of combat: A out of combat stays the game's own (interact, select) - the owner, 2026-10-06: "pressing A is
// only a roll in combat so that it doesn't affect selecting". Combat Roll is the game's, gated below.

@wrapMethod(CPlayerInput)
function OnCbtRoll(action : SInputAction)
{
	if (!UVC_ActionOffHere('CbtRoll') && !(UVC_TapSprintDodgeOn() && IsPressed(action) && theInput.GetActionValue('Sprint') > 0.5f))
	{
		wrappedMethod(action);
	}
}

function UVC_TapDodge()
{
	if (!thePlayer || !thePlayer.IsAlive())
	{
		return;
	}
	// in combat only: the game has no dodge outside its combat states, and taking the player into one for a dodge left
	// him there (the owner's runs, 2026-10-06)
	if (!thePlayer.IsInCombat())
	{
		return;
	}
	if (thePlayer.IsInsideInteraction())
	{
		return;
	}
	if (thePlayer.GetInputHandler() && thePlayer.GetInputHandler().GetIsAltSignCastingPressed())
	{
		return;
	}
	if ((W3ReplacerCiri)thePlayer)
	{
		if (thePlayer.IsActionAllowed(EIAB_Dodge))
		{
			thePlayer.PushCombatActionOnBuffer(EBAT_Ciri_Dodge, BS_Pressed);
			if (thePlayer.GetBIsCombatActionAllowed())
			{
				thePlayer.ProcessCombatActionBuffer();
			}
		}
		return;
	}
	if (thePlayer.GetIsSprintToggled())
	{
		thePlayer.SetSprintToggle(false);
	}
	thePlayer.EvadePressed(EBAT_Dodge);
}
