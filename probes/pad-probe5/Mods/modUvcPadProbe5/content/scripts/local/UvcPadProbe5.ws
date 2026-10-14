// Unbind Vanilla Controls (Witcher 3) - SCRATCH PROBE 5, not a release. Once, at the main menu. Touches ONLY CameraLock,
// TrackQuest and SprintToggle (never a group reset). The answer is in input.settings; [UvcPadProbe5Log] only marks that it ran.
@wrapMethod(CR4CommonMainMenuBase)
function OnConfigUI()
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	if (cfg.GetVarValue('UvcPadProbe5State', 'ProbeRan') != "true")
	{
		cfg.SetVarValue('UvcPadProbe5', 'ProbeCameraLock', "IK_Pad_LeftAxisX");
		cfg.SetVarValue('UvcPadProbe5', 'ProbeTrackQuest', "IK_Pad_LeftAxisX");
		cfg.SetVarValue('UvcPadProbe5', 'ProbeTrackQuest', "IK_Pad_RightThumb");
		cfg.SetVarValue('UvcPadProbe5', 'ProbePcSprintToggle', "IK_Pad_LeftThumb");
		cfg.SetRawConfigValueByStr("UvcPadProbe5Log", "ran", "[C D E]");
		cfg.SetVarValue('UvcPadProbe5State', 'ProbeRan', "true");
		theGame.SaveUserSettings();
	}
	wrappedMethod();
}
