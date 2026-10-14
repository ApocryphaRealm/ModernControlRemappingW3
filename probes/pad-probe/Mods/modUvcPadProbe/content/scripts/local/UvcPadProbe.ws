// Unbind Vanilla Controls (Witcher 3) - SCRATCH PROBE, not a release.
// Once, when the main menu opens: give the hidden INPUTPAD row for SpawnHorse the D-pad Left and save the settings.
// Then input.settings shows whether the engine rebinds pad keys through an INPUTPAD row.
@wrapMethod(CR4CommonMainMenuBase)
function OnConfigUI()
{
	var cfg : CInGameConfigWrapper;

	cfg = theGame.GetInGameConfigWrapper();
	if (cfg.GetVarValue('UvcPadProbeState', 'ProbeRan') != "true")
	{
		cfg.SetVarValue('UvcPadProbe', 'ProbeSpawnHorse', "IK_Pad_DigitLeft;IK_None");
		cfg.SetVarValue('UvcPadProbeState', 'ProbeRan', "true");
		theGame.SaveUserSettings();
	}
	wrappedMethod();
}
