// Unbind Vanilla Controls (Witcher 3) - SCRATCH PROBE 2, not a release.
// Once, when the main menu opens: record what INPUTPAD rows read, set three formats on three actions, record again.
// Records go two ways: SetRawConfigValueByStr into the settings group UvcPadProbe2Log (dx12user.settings), and
// WriteIniFile("uvc_pad_probe2.ini", ...), wherever the game puts that file.
function UvcProbe2Note(cfg : CInGameConfigWrapper, key : string, value : string)
{
	cfg.SetRawConfigValueByStr("UvcPadProbe2Log", key, "[" + value + "]");
	cfg.WriteIniFile("uvc_pad_probe2.ini", key, "[" + value + "]");
}

function UvcProbe2ReadAll(cfg : CInGameConfigWrapper, when : string)
{
	UvcProbe2Note(cfg, when + "_ReadJump", cfg.GetVarValue('UvcPadProbe2', 'ReadJump'));
	UvcProbe2Note(cfg, when + "_ReadHorseDismount", cfg.GetVarValue('UvcPadProbe2', 'ReadHorseDismount'));
	UvcProbe2Note(cfg, when + "_ReadJumpPC", cfg.GetVarValue('UvcPadProbe2', 'ReadJumpPC'));
	UvcProbe2Note(cfg, when + "_SetSpawnHorse", cfg.GetVarValue('UvcPadProbe2', 'SetSpawnHorse'));
	UvcProbe2Note(cfg, when + "_SetCameraLock", cfg.GetVarValue('UvcPadProbe2', 'SetCameraLock'));
	UvcProbe2Note(cfg, when + "_SetHorseJump", cfg.GetVarValue('UvcPadProbe2', 'SetHorseJump'));
}

@wrapMethod(CR4CommonMainMenuBase)
function OnConfigUI()
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	if (cfg.GetVarValue('UvcPadProbe2State', 'ProbeRan') != "true")
	{
		UvcProbe2ReadAll(cfg, "before");
		cfg.SetVarValue('UvcPadProbe2', 'SetSpawnHorse', "IK_Pad_DigitLeft");
		cfg.SetVarValue('UvcPadProbe2', 'SetCameraLock', "IK_None;IK_Pad_DigitRight");
		cfg.SetVarValue('UvcPadProbe2', 'SetHorseJump', "IK_Pad_X_SQUARE;IK_None");
		UvcProbe2ReadAll(cfg, "after");
		cfg.SetVarValue('UvcPadProbe2State', 'ProbeRan', "true");
		theGame.SaveUserSettings();
	}
	wrappedMethod();
}
