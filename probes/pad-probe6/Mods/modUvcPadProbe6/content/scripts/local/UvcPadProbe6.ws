// Unbind Vanilla Controls (Witcher 3) - SCRATCH PROBE 6, not a release. Once, at the main menu. Touches ONLY CameraLock,
// TrackQuest, Jump and OpenMeditation (never a group reset). The answer is in input.settings.
@wrapMethod(CR4CommonMainMenuBase)
function OnConfigUI()
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	if (cfg.GetVarValue('UvcPadProbe6State', 'ProbeRan') != "true")
	{
		cfg.SetVarValue('UvcPadProbe6', 'ProbeCameraLock', "IK_Pad_Last");
		cfg.SetVarValue('UvcPadProbe6', 'ProbeTrackQuest', "IK_Pad_Last");
		cfg.SetVarValue('UvcPadProbe6', 'ProbeTrackQuest', "IK_Pad_RightThumb");
		cfg.SetVarValue('UvcPadProbe6', 'ProbeJump', "IK_Pad_First");
		cfg.SetVarValue('UvcPadProbe6', 'ProbeOpenMeditation', "IK_Pad_First");
		cfg.SetVarValue('UvcPadProbe6', 'ProbeOpenMeditation', "IK_Pad_X_SQUARE");
		cfg.SetRawConfigValueByStr("UvcPadProbe6Log", "ran", "[F G H I]");
		cfg.SetVarValue('UvcPadProbe6State', 'ProbeRan', "true");
		theGame.SaveUserSettings();
	}
	wrappedMethod();
}
