// Unbind Vanilla Controls (Witcher 3) - SCRATCH PROBE 4, not a release. Once, at the main menu. Touches ONLY CameraLock (never a group reset). Read-backs go to [UvcPadProbe4Log] (dx12user.settings); the answer is in input.settings.
function UvcProbe4Step(cfg : CInGameConfigWrapper, row : name, value : string, tag : string)
{
	cfg.SetVarValue('UvcPadProbe4', row, value);
	cfg.SetRawConfigValueByStr("UvcPadProbe4Log", tag, "[set " + value + " -> read " + cfg.GetVarValue('UvcPadProbe4', row) + "]");
}

@wrapMethod(CR4CommonMainMenuBase)
function OnConfigUI()
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	if (cfg.GetVarValue('UvcPadProbe4State', 'ProbeRan') != "true")
	{
		// step A dropped: the owner's own menu binds already answered it (Sprint and SpawnHorse from IK_None never reached the
		// file, 2026-10-06 03:37), and an all-context SpawnHorse write would put LS on Combat too, where he wants the quick item
		cfg.SetRawConfigValueByStr("UvcPadProbe4Log", "B0", "[" + cfg.GetVarValue('UvcPadProbe4', 'ProbeCameraLock') + "]");
		UvcProbe4Step(cfg, 'ProbeCameraLock', "IK_PS4_OPTIONS", "B1_parked");
		UvcProbe4Step(cfg, 'ProbeCameraLock', "IK_Pad_RightThumb", "B2_back");
		cfg.SetVarValue('UvcPadProbe4State', 'ProbeRan', "true");
		theGame.SaveUserSettings();
	}
	wrappedMethod();
}
