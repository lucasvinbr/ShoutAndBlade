scriptname SAB_MCM extends nl_mcm_module

SAB_MainQuest Property MainQuest Auto

bool Property isLoadingData Auto

int key_openMCM = -1

event OnInit()
    RegisterModule("$sab_mcm_page_load_save", 4)
endevent

event OnPageInit()
    SetModName("Shout and Blade")
    SetLandingPage("$sab_mcm_page_edit_units")
    isLoadingData = false

    ;GoToState("MENU_CLOSED")
    QuickHotkey = key_openMCM
endevent

Event OnVersionUpdate(Int a_version)
    ; (brought from tonycubed's Sands of Time mod)
	; a_version is the new version set in GetVersion() above
	; CurrentVersion is the old version currently running - new game will be 0
	Debug.Notification("SAB MCMenu current version = : "+CurrentVersion+" New version =: "+a_version)
	
	If (CurrentVersion < a_version)
		Debug.Trace(Self + ": Updating script to version "+a_version)
		Debug.Notification("Updating SAB McMenu to version: "+a_version)
		Debug.Notification("SAB Update: Recommended to start new game")
	EndIf
	
	OnPageInit()
EndEvent

; enables or disables quickHotkey functionality by setting it to the stored value or an invalid one
Function ToggleQuickHotkey(bool enabled)
	if enabled
		QuickHotkey = key_openMCM
	else
		QuickHotkey = -1
	endif
EndFunction

event OnPageDraw()

	SetLandingPage("$sab_mcm_page_load_save")

	if isLoadingData || !MainQuest.HasInitialized
        AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
        return
    endif

    SetCursorFillMode(LEFT_TO_RIGHT)

    AddKeyMapOptionST("KEY_OPENMCM", "$sab_mcm_main_keymap_openmcm", key_openMCM)


    AddTextOptionST("MAIN_TEST_LOAD", "$sab_mcm_main_button_load", "")

    AddEmptyOption()
    AddEmptyOption()

    ; save mod options
    AddTextOptionST("OPTIONS_SAVE", "$sab_mcm_options_button_save", "")
    AddTextOptionST("OPTIONS_LOAD", "$sab_mcm_options_button_load", "")

    AddEmptyOption()
    AddEmptyOption()

    AddHeaderOption("$sab_mcm_options_header_factionoptions")
    AddEmptyOption()

    AddSliderOptionST("OPTIONS_FAC_GOLD___initialGold", "$sab_mcm_options_slider_fac_initialgold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))
    AddSliderOptionST("OPTIONS_FAC_INTERVAL___updateInterval", "$sab_mcm_options_slider_fac_updateinterval", JDB.solveFlt(".ShoutAndBlade.factionOptions.updateInterval", 0.025), "{3}")
    AddSliderOptionST("OPTIONS_FAC_INTERVAL___goldInterval", "$sab_mcm_options_slider_fac_goldinterval", JDB.solveFlt(".ShoutAndBlade.factionOptions.goldInterval", 0.12), "{3}")
    AddSliderOptionST("OPTIONS_FAC_GOLD___baseGoldAward", "$sab_mcm_options_slider_fac_goldaward", JDB.solveInt(".ShoutAndBlade.factionOptions.baseGoldAward", 500))
    AddSliderOptionST("OPTIONS_FAC_GOLD___createCmderCost", "$sab_mcm_options_slider_fac_createcmdercost", JDB.solveInt(".ShoutAndBlade.factionOptions.createCmderCost", 250))
    AddSliderOptionST("OPTIONS_FAC_INTERVAL___destCheckInterval", "$sab_mcm_options_slider_fac_destcheckinterval", JDB.solveFlt(".ShoutAndBlade.factionOptions.destCheckInterval", 0.15), "{3}")
    AddSliderOptionST("OPTIONS_FAC_INTERVAL___destChangeInterval", "$sab_mcm_options_slider_fac_destchangeinterval", JDB.solveFlt(".ShoutAndBlade.factionOptions.destChangeInterval", 1.05), "{3}")
    AddSliderOptionST("OPTIONS_FAC_GOLD___minCmderGold", "$sab_mcm_options_slider_fac_mincmdergold", JDB.solveInt(".ShoutAndBlade.factionOptions.minCmderGold", 600))
    AddSliderOptionST("OPTIONS_FAC_POWER___safeLocationPower", "$sab_mcm_options_slider_fac_safelocationpower", JDB.solveFlt(".ShoutAndBlade.factionOptions.safeLocationPower", 32.0), "{1}")

    AddEmptyOption()
    AddEmptyOption()
    AddEmptyOption()

    AddHeaderOption("$sab_mcm_options_header_cmderoptions")
    AddEmptyOption()
    AddSliderOptionST("OPTIONS_CMDER_EXP___initialExpPoints", "$sab_mcm_options_slider_cmder_initialxp", JDB.solveFlt(".ShoutAndBlade.cmderOptions.initialExpPoints", 600.0))
    AddSliderOptionST("OPTIONS_CMDER_INTERVAL___expAwardInterval", "$sab_mcm_options_slider_cmder_xpawardinterval", JDB.solveFlt(".ShoutAndBlade.cmderOptions.expAwardInterval", 0.08), "{3}")
    AddSliderOptionST("OPTIONS_CMDER_EXP___awardedXpPerInterval", "$sab_mcm_options_slider_cmder_awardedxp", JDB.solveFlt(".ShoutAndBlade.cmderOptions.awardedXpPerInterval", 500.0))
    AddSliderOptionST("OPTIONS_CMDER_INTERVAL___unitMaintenanceInterval", "$sab_mcm_options_slider_cmder_unitmaintenanceinterval", JDB.solveFlt(".ShoutAndBlade.cmderOptions.unitMaintenanceInterval", 0.06), "{3}")
    AddSliderOptionST("OPTIONS_CMDER_INTERVAL___destCheckInterval", "$sab_mcm_options_slider_cmder_destcheckinterval", JDB.solveFlt(".ShoutAndBlade.cmderOptions.destCheckInterval", 0.01), "{3}")
    AddSliderOptionST("OPTIONS_CMDER_DISTANCE___isNearbyDistance", "$sab_mcm_options_slider_cmder_isnearbydist", JDB.solveFlt(".ShoutAndBlade.cmderOptions.isNearbyDistance", 4096.0))
    AddSliderOptionST("OPTIONS_CMDER_UNITS___maxOwnedUnits", "$sab_mcm_options_slider_cmder_maxownedunits", JDB.solveInt(".ShoutAndBlade.cmderOptions.maxOwnedUnits", 30))
    AddSliderOptionST("OPTIONS_CMDER_UNITS___maxSpawnsOutsideCombat", "$sab_mcm_options_slider_cmder_spawnsoutsidecombat", JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsOutsideCombat", 2))
    AddSliderOptionST("OPTIONS_CMDER_UNITS___maxSpawnsWhenBesieging", "$sab_mcm_options_slider_cmder_spawnswhenbesieging", JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsWhenBesieging", 8))
    AddSliderOptionST("OPTIONS_CMDER_UNITS___maxSpawnsInCombat", "$sab_mcm_options_slider_cmder_spawnsincombat", JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsInCombat", 8))
    AddSliderOptionST("OPTIONS_CMDER_UNITS___nearbyCmdersLimit", "$sab_mcm_options_slider_cmder_nearbycmderslimit", JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5))
    AddSliderOptionST("OPTIONS_CMDER_DISTANCE___nearbyDistanceDividend", "$sab_mcm_options_slider_cmder_nearbydistancedividend", JDB.solveFlt(".ShoutAndBlade.cmderOptions.nearbyDistanceDividend", 16384.0))
    AddSliderOptionST("OPTIONS_CMDER_UNITS___combatSpawnsDividend", "$sab_mcm_options_slider_cmder_combatspawnsdividend", JDB.solveInt(".ShoutAndBlade.cmderOptions.combatSpawnsDividend", 20))

    AddEmptyOption()
    AddEmptyOption()
    AddEmptyOption()

    AddHeaderOption("$sab_mcm_options_header_locationoptions")
    AddEmptyOption()
    ; exp award interval
    ; exp awarded per interval
    ; base gold award
    ; unit maintenance check interval
    ; max owned units
    ; max spawned units

    AddEmptyOption()
    AddEmptyOption()

    AddHeaderOption("$sab_mcm_options_header_bodycleaneroptions")
    AddEmptyOption()

    AddSliderOptionST("OPTIONS_UNITS___maxDeadBodies", "$sab_mcm_options_slider_unit_maxdeadbodies", JDB.solveInt(".ShoutAndBlade.generalOptions.maxDeadBodies", 12))
    

    
endevent

state KEY_OPENMCM

    event OnKeyMapChangeST(string state_id, int keycode)
		key_openMCM = keycode
		SetKeyMapOptionValueST(key_openMCM)
        QuickHotkey = key_openMCM
	endevent

    event OnDefaultST(string state_id)
		key_openMCM = -1
		SetKeyMapOptionValueST(key_openMCM)
        QuickHotkey = key_openMCM
	endevent

	event OnHighlightST(string state_id)
		SetInfoText("$sab_mcm_main_keymap_openmcm_desc")
	endevent

endstate


state MAIN_TEST_LOAD
    event OnSelectST(string state_id)
        MainQuest.SpawnerScript.HideCustomizationGuy()
        isLoadingData = true
        ForcePageReset()
        int loadSuccesses = 0
        int expectedLoadSuccesses = 3

        ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)


        string optionsFilePath = JContainers.userDirectory() + "SAB/options.json"
        int jReadOptionsData = JValue.readFromFile(optionsFilePath)
        if jReadOptionsData != 0
            JDB.solveObjSetter(".ShoutAndBlade", jReadOptionsData, true)
            loadSuccesses += 1
            Debug.Notification("SAB: options data load complete! (" + loadSuccesses + " of " + expectedLoadSuccesses + ")")
        else
            Debug.Notification("SAB: options data load failed!")
        endif

        string unitFilePath = JContainers.userDirectory() + "SAB/unitData.json"
        int jReadUnitData = JValue.readFromFile(unitFilePath)
        if jReadUnitData != 0
            ;force a page reset to disable all action buttons!
            MainQuest.UnitDataHandler.jSABUnitDatasArray = JValue.releaseAndRetain(MainQuest.UnitDataHandler.jSABUnitDatasArray, jReadUnitData, "ShoutAndBlade")
            MainQuest.UnitDataHandler.EnsureUnitDataArrayCount()
            MainQuest.UnitDataHandler.UpdateAllGearAndRaceListsAccordingToJMap()
            loadSuccesses += 1
            Debug.Notification("SAB: unit data load complete! (" + loadSuccesses + " of " + expectedLoadSuccesses + ")")
        else
            Debug.Notification("SAB: unit data load failed!")
        endif

        string factionFilePath = JContainers.userDirectory() + "SAB/factionData.json"
        int jReadFactionData = JValue.readFromFile(factionFilePath)
        if jReadFactionData != 0
            ;force a page reset to disable all action buttons!
            MainQuest.FactionDataHandler.jSABFactionDatasArray = JValue.releaseAndRetain(MainQuest.FactionDataHandler.jSABFactionDatasArray, jReadFactionData, "ShoutAndBlade")
            MainQuest.FactionDataHandler.EnsureArrayCounts()
            MainQuest.FactionDataHandler.UpdateAllFactionQuestsAccordingToJMap()
            loadSuccesses += 1
            Debug.Notification("SAB: faction data load complete! (" + loadSuccesses + " of " + expectedLoadSuccesses + ")")
        else
            Debug.Notification("SAB: Faction data load failed!")
        endif

        if loadSuccesses == expectedLoadSuccesses
            Debug.TraceAndBox("Data for all SAB modules were loaded successfully! SAB menus can be opened normally now.")
        else 
            Debug.TraceAndBox("Data for one or more SAB modules weren't loaded successfully, but SAB menus can be opened normally now.")
        endif

        Debug.Notification("SAB: Load finished!")
        isLoadingData = false
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_main_button_load_desc")
	endEvent
endstate




;---------------------------------------------------------------------------------------------------------
; OPTIONS STUFF
;---------------------------------------------------------------------------------------------------------


state OPTIONS_SAVE

    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/options.json"
        JValue.writeToFile(JDB.solveObj(".ShoutAndBlade"), filePath)
        ShowMessage("Save: " + filePath, false)
	endEvent

    event OnDefaultST(string state_id)
        ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
    endevent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_options_button_save_desc")
	endEvent

endstate


state OPTIONS_LOAD

    event OnSelectST(string state_id)
        MainQuest.SpawnerScript.HideCustomizationGuy()
        string filePath = JContainers.userDirectory() + "SAB/options.json"
        isLoadingData = true
        int jReadData = JValue.readFromFile(filePath)
        if jReadData != 0
            ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()
            JDB.solveObjSetter(".ShoutAndBlade", jReadData, true)
            isLoadingData = false
            Debug.Notification("SAB: Load complete!")
            ShowMessage("$sab_mcm_shared_popup_msg_load_success", false)
            ForcePageReset()
        else
            isLoadingData = false
            ShowMessage("$sab_mcm_shared_popup_msg_load_fail", false)
        endif
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_options_button_load_desc")
	endEvent

endstate


state OPTIONS_FAC_GOLD

    event OnSliderOpenST(string state_id)
        int defaultValue = GetDefaultIntValueForOption("factionGold", state_id)
		SetSliderDialogStartValue(JDB.solveInt(".ShoutAndBlade.factionOptions." + state_id, defaultValue))
        SetSliderDialogRange(0, 100000)
	    SetSliderDialogInterval(10)
		SetSliderDialogDefaultValue(defaultValue)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int valueInt = value as int
        JDB.solveIntSetter(".ShoutAndBlade.factionOptions." + state_id, valueInt, true)
		SetSliderOptionValueST(valueInt)
	endEvent

	event OnDefaultST(string state_id)
        int valueInt = GetDefaultIntValueForOption("factionGold", state_id)
        JDB.solveIntSetter(".ShoutAndBlade.factionOptions." + state_id, valueInt, true)
		SetSliderOptionValueST(valueInt)
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)

        if state_id == "initialGold"
            SetInfoText("$sab_mcm_options_slider_fac_initialgold_desc")
        elseif state_id == "baseGoldAward"
            SetInfoText("$sab_mcm_options_slider_fac_goldaward_desc")
        elseif state_id == "createCmderCost"
            SetInfoText("$sab_mcm_options_slider_fac_createcmdercost_desc")
        elseif state_id == "minCmderGold"
            SetInfoText("$sab_mcm_options_slider_fac_mincmdergold_desc")
        endif
	endEvent

endstate



state OPTIONS_FAC_INTERVAL

    event OnSliderOpenST(string state_id)
        float defaultValue = GetDefaultFltValueForOption("factionInterval", state_id)
		SetSliderDialogStartValue(JDB.solveFlt(".ShoutAndBlade.factionOptions." + state_id, defaultValue))
        SetSliderDialogRange(0.0, 7.0)
	    SetSliderDialogInterval(0.005)
		SetSliderDialogDefaultValue(defaultValue)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(".ShoutAndBlade.factionOptions." + state_id, value, true)
		SetSliderOptionValueST(value, "{3}")
	endEvent

	event OnDefaultST(string state_id)
        float value = GetDefaultFltValueForOption("factionInterval", state_id)
        JDB.solveFltSetter(".ShoutAndBlade.factionOptions." + state_id, value, true)
		SetSliderOptionValueST(value, "{3}")
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)

        if state_id == "updateInterval"
            SetInfoText("$sab_mcm_options_slider_fac_updateinterval_desc")
        elseif state_id == "goldInterval"
            SetInfoText("$sab_mcm_options_slider_fac_goldinterval_desc")
        elseif state_id == "destCheckInterval"
            SetInfoText("$sab_mcm_options_slider_fac_destcheckinterval_desc")
        elseif state_id == "destChangeInterval"
            SetInfoText("$sab_mcm_options_slider_fac_destchangeinterval_desc")
        endif
	endEvent

endstate



state OPTIONS_FAC_POWER

    event OnSliderOpenST(string state_id)
        float defaultValue = GetDefaultFltValueForOption("factionPower", state_id)
		SetSliderDialogStartValue(JDB.solveFlt(".ShoutAndBlade.factionOptions." + state_id, defaultValue))
        SetSliderDialogRange(0.0, 100.0)
	    SetSliderDialogInterval(0.5)
		SetSliderDialogDefaultValue(defaultValue)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(".ShoutAndBlade.factionOptions." + state_id, value, true)
		SetSliderOptionValueST(value, "{1}")
	endEvent

	event OnDefaultST(string state_id)
        float value = GetDefaultFltValueForOption("factionPower", state_id)
        JDB.solveFltSetter(".ShoutAndBlade.factionOptions." + state_id, value, true)
		SetSliderOptionValueST(value, "{1}")
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)

        if state_id == "safeLocationPower"
            SetInfoText("$sab_mcm_options_slider_fac_safelocationpower_desc")
        endif
	endEvent

endstate



state OPTIONS_UNITS

    event OnSliderOpenST(string state_id)
        int defaultValue = GetDefaultIntValueForOption("units", state_id)
		SetSliderDialogStartValue(JDB.solveInt(".ShoutAndBlade.generalOptions." + state_id, defaultValue))
        SetSliderDialogRange(0, 120)
	    SetSliderDialogInterval(1)
		SetSliderDialogDefaultValue(defaultValue)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int valueInt = value as int
        JDB.solveIntSetter(".ShoutAndBlade.generalOptions." + state_id, valueInt, true)
		SetSliderOptionValueST(valueInt)
	endEvent

	event OnDefaultST(string state_id)
        int valueInt = GetDefaultIntValueForOption("units", state_id)
        JDB.solveIntSetter(".ShoutAndBlade.generalOptions." + state_id, valueInt, true)
		SetSliderOptionValueST(valueInt)
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)

        if state_id == "maxDeadBodies"
            SetInfoText("$sab_mcm_options_slider_unit_maxdeadbodies_desc")
        endif
	endEvent

endstate



state OPTIONS_CMDER_EXP

    event OnSliderOpenST(string state_id)
        float defaultValue = GetDefaultFltValueForOption("cmderExp", state_id)
		SetSliderDialogStartValue(JDB.solveFlt(".ShoutAndBlade.cmderOptions." + state_id, defaultValue))
        SetSliderDialogRange(0.0, 1000.0)
	    SetSliderDialogInterval(1)
		SetSliderDialogDefaultValue(defaultValue)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(".ShoutAndBlade.cmderOptions." + state_id, value, true)
		SetSliderOptionValueST(value)
	endEvent

	event OnDefaultST(string state_id)
        float value = GetDefaultFltValueForOption("cmderExp", state_id)
        JDB.solveFltSetter(".ShoutAndBlade.cmderOptions." + state_id, value, true)
		SetSliderOptionValueST(value)
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)

        if state_id == "initialExpPoints"
            SetInfoText("$sab_mcm_options_slider_cmder_initialxp")
        elseif state_id == "awardedXpPerInterval"
            SetInfoText("$sab_mcm_options_slider_cmder_awardedxp")
        endif
	endEvent

endstate



state OPTIONS_CMDER_INTERVAL

    event OnSliderOpenST(string state_id)
        float defaultValue = GetDefaultFltValueForOption("cmderInterval", state_id)
		SetSliderDialogStartValue(JDB.solveFlt(".ShoutAndBlade.cmderOptions." + state_id, defaultValue))
        SetSliderDialogRange(0.0, 7.0)
	    SetSliderDialogInterval(0.005)
		SetSliderDialogDefaultValue(defaultValue)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(".ShoutAndBlade.cmderOptions." + state_id, value, true)
		SetSliderOptionValueST(value, "{3}")
	endEvent

	event OnDefaultST(string state_id)
        float value = GetDefaultFltValueForOption("cmderInterval", state_id)
        JDB.solveFltSetter(".ShoutAndBlade.cmderOptions." + state_id, value, true)
		SetSliderOptionValueST(value, "{3}")
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)

        if state_id == "expAwardInterval"
            SetInfoText("$sab_mcm_options_slider_cmder_xpawardinterval")
        elseif state_id == "unitMaintenanceInterval"
            SetInfoText("$sab_mcm_options_slider_cmder_unitmaintenanceinterval")
        elseif state_id == "destCheckInterval"
            SetInfoText("$sab_mcm_options_slider_cmder_destcheckinterval")
        endif
	endEvent

endstate



state OPTIONS_CMDER_DISTANCE

    event OnSliderOpenST(string state_id)
        float defaultValue = GetDefaultFltValueForOption("cmderDistance", state_id)
		SetSliderDialogStartValue(JDB.solveFlt(".ShoutAndBlade.cmderOptions." + state_id, defaultValue))
        SetSliderDialogRange(0.0, 32768.0)
	    SetSliderDialogInterval(16.0)
		SetSliderDialogDefaultValue(defaultValue)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        JDB.solveFltSetter(".ShoutAndBlade.cmderOptions." + state_id, value, true)
		SetSliderOptionValueST(value)
	endEvent

	event OnDefaultST(string state_id)
        float value = GetDefaultFltValueForOption("cmderDistance", state_id)
        JDB.solveFltSetter(".ShoutAndBlade.cmderOptions." + state_id, value, true)
		SetSliderOptionValueST(value)
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)

        if state_id == "isNearbyDistance"
            SetInfoText("$sab_mcm_options_slider_cmder_isnearbydist")
        elseif state_id == "nearbyDistanceDividend"
            SetInfoText("$sab_mcm_options_slider_cmder_nearbydistancedividend")
        endif
	endEvent

endstate



state OPTIONS_CMDER_UNITS

    event OnSliderOpenST(string state_id)
        int defaultValue = GetDefaultIntValueForOption("cmderUnits", state_id)
		SetSliderDialogStartValue(JDB.solveInt(".ShoutAndBlade.cmderOptions." + state_id, defaultValue))
        SetSliderDialogRange(0, 120)
	    SetSliderDialogInterval(1)
		SetSliderDialogDefaultValue(defaultValue)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int valueInt = value as int
        JDB.solveIntSetter(".ShoutAndBlade.cmderOptions." + state_id, valueInt, true)
		SetSliderOptionValueST(valueInt)
	endEvent

	event OnDefaultST(string state_id)
        int valueInt = GetDefaultIntValueForOption("cmderUnits", state_id)
        JDB.solveIntSetter(".ShoutAndBlade.cmderOptions." + state_id, valueInt, true)
		SetSliderOptionValueST(valueInt)
	endEvent

	event OnHighlightST(string state_id)
        ToggleQuickHotkey(true)

        if state_id == "maxOwnedUnits"
            SetInfoText("$sab_mcm_options_slider_cmder_maxownedunits")
        elseif state_id == "maxSpawnsOutsideCombat"
            SetInfoText("$sab_mcm_options_slider_cmder_spawnsoutsidecombat")
        elseif state_id == "maxSpawnsWhenBesieging"
            SetInfoText("$sab_mcm_options_slider_cmder_spawnswhenbesieging")
        elseif state_id == "maxSpawnsInCombat"
            SetInfoText("$sab_mcm_options_slider_cmder_spawnsincombat")
        elseif state_id == "nearbyCmdersLimit"
            SetInfoText("$sab_mcm_options_slider_cmder_nearbycmderslimit")
        elseif state_id == "combatSpawnsDividend"
            SetInfoText("$sab_mcm_options_slider_cmder_combatspawnsdividend")
        endif
	endEvent

endstate



int Function GetDefaultIntValueForOption(string category, string entryName)
    if category == "factionGold"
        if entryName == "initialGold"
            return SAB_FactionDataHandler.GetDefaultFactionGold()
        elseif entryName == "baseGoldAward"
            return 500
        elseif entryName == "createCmderCost"
            return 250
        elseif entryName == "minCmderGold"
            return 600
        endif
    elseif category == "units"
        if entryName == "maxDeadBodies"
            return 12
        endif
    elseif category == "cmderUnits"
        if entryName == "maxOwnedUnits"
            return SAB_FactionDataHandler.GetDefaultFactionGold()
        elseif entryName == "maxSpawnsOutsideCombat"
            return 2
        elseif entryName == "maxSpawnsWhenBesieging"
            return 8
        elseif entryName == "maxSpawnsInCombat"
            return 8
        elseif entryName == "nearbyCmdersLimit"
            return 5
        elseif entryName == "combatSpawnsDividend"
            return 20
        endif
    endif
EndFunction

float Function GetDefaultFltValueForOption(string category, string entryName)
    if category == "factionInterval"
        if entryName == "updateInterval"
            return 0.025
        elseif entryName == "goldInterval"
            return 0.12
        elseif entryName == "destCheckInterval"
            return 0.15
        elseif entryName == "destChangeInterval"
            return 1.05
        endif
    elseif category == "factionPower"
        if entryName == "safeLocationPower"
            return 32.0
        endif
    elseif category == "cmderExp"
        if entryName == "initialExpPoints"
            return 600.0
        elseif entryName == "awardedXpPerInterval"
            return 500.0
        endif
    elseif category == "cmderInterval"
        if entryName == "expAwardInterval"
            return 0.08
        elseif entryName == "unitMaintenanceInterval"
            return 0.06
        elseif entryName == "destCheckInterval"
            return 0.01
        endif
    elseif category == "cmderDistance"
        if entryName == "isNearbyDistance"
            return 4096.0
        elseif entryName == "nearbyDistanceDividend"
            return 16384.0
        endif
    endif
EndFunction

;---------------------------------------------------------------------------------------------------------
; SHARED STUFF (used in more than one MCM page)
;---------------------------------------------------------------------------------------------------------

; returns a string with the unit's index and name, to be used in MCMs. Will fetch the unit data if it isn't provided
string Function GetMCMUnitDisplayByUnitIndex(int unitIndex, int jUnitData = -1)
	if jUnitData < 0
		jUnitData = jArray.getObj(MainQuest.UnitDataHandler.jSABUnitDatasArray, unitIndex)
	endif

	return ((unitIndex + 1) as string) + " - " + JMap.getStr(jUnitData, "Name", "Recruit")
EndFunction

; returns a string with the faction's index and name, to be used in MCMs. Will fetch the faction data if it isn't provided
string Function GetMCMFactionDisplayByFactionIndex(int factionIndex, int jFactionData = -1)
	if jFactionData < 0
		jFactionData = jArray.getObj(MainQuest.FactionDataHandler.jSABFactionDatasArray, factionIndex)
	endif

	return ((factionIndex + 1) as string) + " - " + JMap.getStr(jFactionData, "Name", "Faction")
EndFunction

