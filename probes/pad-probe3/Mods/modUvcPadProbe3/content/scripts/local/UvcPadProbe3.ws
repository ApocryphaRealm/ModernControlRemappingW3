// Unbind Vanilla Controls (Witcher 3) - SCRATCH PROBE 3, not a release. Once, at the main menu:
//   A  SpawnHorse: IK_None, then IK_Pad_DigitLeft    - does a cleared row take a button again?
//   B  CameraLock: IK_JcmsRightStickScroll, then IK_Pad_DigitRight - park on a Switch-only key, then back?
//   C  HorseJump:  IK_Gesture_DoubleTap, then IK_Pad_B_CIRCLE      - park on a touch gesture, then back?
//   D  SpawnHorse cleared again, then ResetGroupToDefaults - does a reset bring a cleared row back?
// Each value read back is recorded with SetRawConfigValueByStr into [UvcPadProbe3Log] (dx12user.settings).
function UvcProbe3Step(cfg : CInGameConfigWrapper, row : name, value : string, tag : string)
{
	cfg.SetVarValue('UvcPadProbe3', row, value);
	cfg.SetRawConfigValueByStr("UvcPadProbe3Log", tag, "[set " + value + " -> read " + cfg.GetVarValue('UvcPadProbe3', row) + "]");
}

@wrapMethod(CR4CommonMainMenuBase)
function OnConfigUI()
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	if (cfg.GetVarValue('UvcPadProbe3State', 'ProbeRan') != "true")
	{
		cfg.SetRawConfigValueByStr("UvcPadProbe3Log", "A0_SpawnHorse", "[" + cfg.GetVarValue('UvcPadProbe3', 'ProbeSpawnHorse') + "]");
		UvcProbe3Step(cfg, 'ProbeSpawnHorse', "IK_None", "A1_cleared");
		UvcProbe3Step(cfg, 'ProbeSpawnHorse', "IK_Pad_DigitLeft", "A2_rebound");
		cfg.SetRawConfigValueByStr("UvcPadProbe3Log", "B0_CameraLock", "[" + cfg.GetVarValue('UvcPadProbe3', 'ProbeCameraLock') + "]");
		UvcProbe3Step(cfg, 'ProbeCameraLock', "IK_JcmsRightStickScroll", "B1_parked");
		UvcProbe3Step(cfg, 'ProbeCameraLock', "IK_Pad_DigitRight", "B2_rebound");
		cfg.SetRawConfigValueByStr("UvcPadProbe3Log", "C0_HorseJump", "[" + cfg.GetVarValue('UvcPadProbe3', 'ProbeHorseJump') + "]");
		UvcProbe3Step(cfg, 'ProbeHorseJump', "IK_Gesture_DoubleTap", "C1_parked");
		UvcProbe3Step(cfg, 'ProbeHorseJump', "IK_Pad_B_CIRCLE", "C2_rebound");
		// D: SpawnHorse cleared again, then the group reset to the game's defaults - does a reset bring a cleared row back?
		UvcProbe3Step(cfg, 'ProbeSpawnHorse', "IK_None", "D1_cleared_again");
		cfg.ResetGroupToDefaults('UvcPadProbe3');
		cfg.SetRawConfigValueByStr("UvcPadProbe3Log", "D2_after_reset_SpawnHorse", "[" + cfg.GetVarValue('UvcPadProbe3', 'ProbeSpawnHorse') + "]");
		cfg.SetRawConfigValueByStr("UvcPadProbe3Log", "D2_after_reset_CameraLock", "[" + cfg.GetVarValue('UvcPadProbe3', 'ProbeCameraLock') + "]");
		cfg.SetRawConfigValueByStr("UvcPadProbe3Log", "D2_after_reset_HorseJump", "[" + cfg.GetVarValue('UvcPadProbe3', 'ProbeHorseJump') + "]");
		cfg.SetVarValue('UvcPadProbe3State', 'ProbeRan', "true");
		theGame.SaveUserSettings();
	}
	wrappedMethod();
}
