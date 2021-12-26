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

	if isLoadingData
        AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
        return
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    AddKeyMapOptionST("KEY_OPENMCM", "$sab_mcm_main_keymap_openmcm", key_openMCM)

	SetCursorPosition(1)

    AddTextOptionST("MAIN_TEST_LOAD", "(Debug) Load all data", "")
    
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
        string unitFilePath = JContainers.userDirectory() + "SAB/unitData.json"
        isLoadingData = true
        ForcePageReset()
        int loadSuccesses = 0
        int expectedLoadSuccesses = 2

        ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)


        int jReadUnitData = JValue.readFromFile(unitFilePath)
        if jReadUnitData != 0
            ;force a page reset to disable all action buttons!
            MainQuest.UnitDataHandler.jSABUnitDatasArray = JValue.releaseAndRetain(MainQuest.UnitDataHandler.jSABUnitDatasArray, jReadUnitData, "ShoutAndBlade")
            MainQuest.UnitDataHandler.EnsureUnitDataArrayCount()
            MainQuest.UnitDataHandler.UpdateAllGearAndRaceListsAccordingToJMap()
            loadSuccesses += 1
            Debug.Notification("SAB: unit data load complete! (" + loadSuccesses + " of " + expectedLoadSuccesses + ")")
        else
            Debug.Notification("SAB: Unit data load failed!")
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
		SetInfoText("Test Load Guy")
	endEvent
endstate

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

