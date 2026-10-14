// =====================================================================================================================
// Unbind Vanilla Controls - SIGN BUTTONS FOR ALTERNATIVE SIGN CASTING (the owner, 2026-10-06: "Let's unbind the signs
// from the functions and bind them to the face buttons themselves"; his layout Igni RT, Quen B, Axii Y, Yrden X, Aard RB).
// Taken back from Modern Control Map (ModernControlMap.ws, part 4) on 2026-10-14 (the owner: "transfer over any of the
// current keybinds that it has to the current UVC").
//
// With the game's alternative sign casting on (Options > Gameplay), holding Cast Sign and pressing a second button casts
// a sign - but the game picks the sign by the second button's CONTROL (Sprint casts Aard, Heavy Attack Yrden, Light
// Attack Axii, Witcher Senses Igni, its Alt Quen action Quen), so moving a control moved a sign. Here, on a controller,
// once Select Igni has a pad button (the controller map gives the five Select Sign actions their buttons):
//   - the game's own sign actions (Select Aard ... Select Axii) carry the signs: they cast through the game's own
//     OnSelectSign -> AltCastSign while Cast Sign is held, and do nothing on their own (no sign is selected or cast by a
//     plain press - B stays Sprint, X the weapon button);
//   - the casts the game hangs on other controls are not made (AltCastSign from anywhere else is skipped);
//   - Jump does not fire while Cast Sign is held, or for half a second after a sign cast that way (a sign on Y); the
//     weapon button draws nothing while it is held (UnbindVanillaControlsSwords.ws).
// The keyboard, the alternative casting off, and a pad with no Select Igni button are untouched.
// =====================================================================================================================

// set while OnSelectSign is running, so AltCastSign knows the cast came from a sign's own button
@addField(CPlayerInput)
var uvcCastFromSignButton : bool;

// when a sign was last cast from its own button on a pad (engine seconds)
@addField(CPlayerInput)
var uvcSignButtonCastAt : float;

function UVC_AltSignHeld() : bool
{
	if (!thePlayer || !thePlayer.GetInputHandler())
	{
		return false;
	}
	return thePlayer.GetInputHandler().GetIsAltSignCastingPressed();
}

// the sign buttons are in use when Select Igni has a pad button (the controller map gives it RT)
function UVC_SignButtonsBound() : bool
{
	return UVC_FirstPadKey('SelectIgni') != IK_None;
}

function UVC_JumpHeldBack() : bool
{
	if (!thePlayer || !thePlayer.GetInputHandler() || !theInput.LastUsedGamepad())
	{
		return false;
	}
	return UVC_AltSignHeld() || theGame.GetEngineTimeAsSeconds() - thePlayer.GetInputHandler().uvcSignButtonCastAt < 0.5f;
}

@wrapMethod(CPlayerInput)
function OnSelectSign(action : SInputAction)
{
	// on a controller a sign's own button only casts while Cast Sign is held; on its own it does nothing
	if (!(theInput.LastUsedGamepad() && IsPressed(action) && !GetIsAltSignCastingPressed()))
	{
		if (IsPressed(action) && theInput.LastUsedGamepad())
		{
			uvcSignButtonCastAt = theGame.GetEngineTimeAsSeconds();
		}
		uvcCastFromSignButton = true;
		wrappedMethod(action);
		uvcCastFromSignButton = false;
	}
}

@wrapMethod(CPlayerInput)
function AltCastSign(signType : ESignType)
{
	if (uvcCastFromSignButton || !theInput.LastUsedGamepad() || !UVC_SignButtonsBound())
	{
		wrappedMethod(signType);
	}
}

@wrapMethod(CExplorationInput)
function IsJumpPressedInTime() : bool
{
	if (UVC_JumpHeldBack())
	{
		return false;
	}
	return wrappedMethod();
}

@wrapMethod(CExplorationInput)
function IsJumpJustPressed() : bool
{
	if (UVC_JumpHeldBack())
	{
		return false;
	}
	return wrappedMethod();
}

@wrapMethod(CExplorationInput)
function IsJumpPressed() : bool
{
	if (UVC_JumpHeldBack())
	{
		return false;
	}
	return wrappedMethod();
}
