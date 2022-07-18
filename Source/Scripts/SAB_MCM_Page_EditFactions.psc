scriptname SAB_MCM_Page_EditFactions extends nl_mcm_module

SAB_MCM Property MainPage Auto

; since we want more than 128 custom units, we need two arrays (0 or 1 here)
int editedUnitsMenuPage = 0

string[] editedFactionIdentifiersArray
int editedFactionIndex = 0
int jEditedFactionData = 0

string[] editedUnitIdentifiersArray
int editedTroopLineIndex = 0
int jEditedTroopLine = 0


event OnInit()
    RegisterModule("$sab_mcm_page_edit_factions", 3)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[40]
    editedUnitIdentifiersArray = new string[128]

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_edit_factions")
    SetupPage()
EndEvent


;---------------------------------------------------------------------------------------------------------
; SHARED STUFF
;---------------------------------------------------------------------------------------------------------

; fetches the localization key based on the stateId. Should be overridden on the "base" states!
string function GetInfoTextLocaleKey(string stateId)
    return "$sab_mcm_unitedit_slider_health_desc"
endfunction

state SHARED_LOADING

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_shared_loading_desc")
	endEvent

endstate

;---------------------------------------------------------------------------------------------------------
; PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupPage()

    if MainPage.isLoadingData || !MainPage.MainQuest.HasInitialized
        AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
        return
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    jEditedFactionData = jArray.getObj(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, editedFactionIndex)
    ; set up fac if it doesn't exist
    if jEditedFactionData == 0
        jEditedFactionData = jMap.object()
        JArray.setObj(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, editedFactionIndex, jEditedFactionData)
    endif

    
    AddHeaderOption("$sab_mcm_factionedit_header_selectfac")
    AddMenuOptionST("FAC_EDIT_CUR_FAC", "$sab_mcm_factionedit_menu_currentfac", \
        (MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex, jEditedFactionData)))
    
    AddHeaderOption("$sab_mcm_unitedit_header_baseinfo")
    AddInputOptionST("FAC_EDIT_NAME", "$sab_mcm_factionedit_input_factionname", JMap.getStr(jEditedFactionData, "Name", "Faction"))
    AddToggleOptionST("FAC_EDIT_ENABLED", "$sab_mcm_factionedit_toggle_enabled", JMap.hasKey(jEditedFactionData, "enabled"))
    AddSliderOptionST("FAC_EDIT_GOLD", "$sab_mcm_factionedit_slider_factiongold", JMap.getInt(jEditedFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold())))
    AddTextOptionST("FAC_EDIT_CMDER_SPAWN", "$sab_mcm_factionedit_button_setcmderspawn", "")

    AddHeaderOption("$sab_mcm_factionedit_header_selectcmder")
    AddSliderOptionST("FAC_EDIT_UNIT_MENU_PAGE___CMDER", "$sab_mcm_unitedit_slider_menupage", editedUnitsMenuPage + 1)
    AddMenuOptionST("FAC_EDIT_UNIT_CMDER_MENU", "$sab_mcm_factionedit_menu_cmderunit", \
        MainPage.GetMCMUnitDisplayByUnitIndex(JMap.getInt(jEditedFactionData, "CmderUnitIndex", 0)))

    AddHeaderOption("$sab_mcm_factionedit_header_selectrecruit")
    AddSliderOptionST("FAC_EDIT_UNIT_MENU_PAGE___RECRUIT", "$sab_mcm_unitedit_slider_menupage", editedUnitsMenuPage + 1)
    AddMenuOptionST("FAC_EDIT_UNIT_RECRUIT_MENU", "$sab_mcm_factionedit_menu_recruitunit", \
        MainPage.GetMCMUnitDisplayByUnitIndex(JMap.getInt(jEditedFactionData, "RecruitUnitIndex", 0)))

    AddEmptyOption()
    AddTextOptionST("FAC_EDIT_SAVE", "$sab_mcm_factionedit_button_save", "")
    AddTextOptionST("FAC_EDIT_LOAD", "$sab_mcm_factionedit_button_load", "")

    SetCursorPosition(1)

    ; troop line editor in this side
    AddHeaderOption("$sab_mcm_factionedit_header_trooplines")

    ; make sure the troop lines array exists
    int jFactionTroopLinesArr = jMap.getObj(jEditedFactionData, "jTroopLinesArray")

    if jFactionTroopLinesArr == 0
        ; create the troop lines array
        jFactionTroopLinesArr = jArray.object()
        jMap.setObj(jEditedFactionData, "jTroopLinesArray", jFactionTroopLinesArr)
    endif

    jEditedTroopLine = jArray.getObj(jFactionTroopLinesArr, editedTroopLineIndex)

    if jEditedTroopLine == 0
        jEditedTroopLine = jArray.object()
        JArray.addObj(jFactionTroopLinesArr, jEditedTroopLine, editedTroopLineIndex)
    endif

    AddMenuOptionST("FAC_EDIT_TROOPLINE_SELECT_MENU", "$sab_mcm_factionedit_menu_troopline_select", \
        ((editedTroopLineIndex + 1) as string))

    AddEmptyOption()

    ; add slot customizers for each slot of the current line.
    ; up to 15 slots can be shown in the MCM
    bool displayAddEntryBtn = true
    int displayedLinesCount = jValue.count(jEditedTroopLine)
    if displayedLinesCount >= 15
        displayedLinesCount = 15
        displayAddEntryBtn = false
    endif
    int i = 0

    while i < displayedLinesCount
        string indexString = i as string
        AddTextOptionST("FAC_EDIT_TROOPLINE_ENTRY_REMOVE___" + indexString, "$sab_mcm_factionedit_button_troopline_entry_remove", (i + 1) as string)
        AddSliderOptionST("FAC_EDIT_UNIT_MENU_PAGE___TROOPLINE_ENTRY_" + indexString, "$sab_mcm_unitedit_slider_menupage", editedUnitsMenuPage + 1)
        AddMenuOptionST("FAC_EDIT_TROOPLINE_ENTRY_UNIT___" + indexString, "$sab_mcm_factionedit_menu_troopline_entry_select_unit", \
            MainPage.GetMCMUnitDisplayByUnitIndex(jArray.getInt(jEditedTroopLine, i, 0)))
        AddEmptyOption()

        i += 1
    endwhile

    if displayAddEntryBtn
        ; at the end of the troop line, there should be a "add slot" button, unless the line is too long already
        AddTextOptionST("FAC_EDIT_TROOPLINE_ENTRY_ADD", "$sab_mcm_factionedit_button_troopline_entry_add", "")
    endif
    
EndFunction


state FAC_EDIT_UNIT_MENU_PAGE
	event OnSliderOpenST(string state_id)
		SetSliderDialogStartValue(editedUnitsMenuPage + 1)
		SetSliderDialogDefaultValue(1)
		SetSliderDialogRange(1, 2)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
		editedUnitsMenuPage = (value as int) - 1
		SetSliderOptionValueST(editedUnitsMenuPage + 1)
	endEvent

	event OnDefaultST(string state_id)
		editedUnitsMenuPage = 0
		SetSliderOptionValueST(editedUnitsMenuPage + 1)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_slider_menupage_desc")
	endEvent
endState



state FAC_EDIT_CUR_FAC

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedFactionIndex)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.FactionDataHandler.SetupStringArrayWithFactionIdentifiers(editedFactionIdentifiersArray)
		SetMenuDialogOptions(editedFactionIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		editedFactionIndex = index
		SetMenuOptionValueST(index)
        editedTroopLineIndex = 0 ; also reset current troop line index when switching facs
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
        editedTroopLineIndex = 0 ; also reset current troop line index when switching facs
		editedFactionIndex = 0
		SetMenuOptionValueST(MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex))
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_menu_currentfac_desc")
	endEvent
    
endstate



state FAC_EDIT_NAME

	event OnInputOpenST(string state_id)
        string facName = JMap.getStr(jEditedFactionData, "Name", "Faction")
		SetInputDialogStartText(facName)
	endEvent

	event OnInputAcceptST(string state_id, string inputs)
        MainPage.ToggleQuickHotkey(true)
        JMap.setStr(jEditedFactionData, "Name", inputs)
        SetInputOptionValueST(inputs)

        ;force a reset to update other fields that use the name
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)

        JMap.setStr(jEditedFactionData, "Name", "Faction")

		SetInputOptionValueST("Faction")

        ;force a reset to update other fields that use the name
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(false)
		SetInfoText("$sab_mcm_factionedit_input_factionname_desc")
	endEvent
    
endstate

state FAC_EDIT_ENABLED
    event OnSelectST(string state_id)
        if JMap.hasKey(jEditedFactionData, "enabled")
            jMap.removeKey(jEditedFactionData, "enabled")
        else
            JMap.setInt(jEditedFactionData, "enabled", 1)
            MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[editedFactionIndex].EnableFaction(jEditedFactionData, editedFactionIndex)
        endif

        SetToggleOptionValueST(jMap.hasKey(jEditedFactionData, "enabled"))
	endEvent

    event OnDefaultST(string state_id)
        jMap.removeKey(jEditedFactionData, "enabled")
        SetToggleOptionValueST(jMap.hasKey(jEditedFactionData, "enabled"))
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_toggle_enabled_desc")
	endEvent
endstate

state FAC_EDIT_GOLD
	event OnSliderOpenST(string state_id)
        int defaultValue = JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold())
		SetSliderDialogStartValue(JMap.getInt(jEditedFactionData, "AvailableGold", defaultValue))
		SetSliderDialogDefaultValue(defaultValue)
		SetSliderDialogRange(0, 100000)
		SetSliderDialogInterval(10)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int valueInt = value as int
        jMap.setInt(jEditedFactionData, "AvailableGold", valueInt)
		SetSliderOptionValueST(valueInt)
	endEvent

	event OnDefaultST(string state_id)
        int valueInt = JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold())
        jMap.setInt(jEditedFactionData, "AvailableGold", valueInt)
		SetSliderOptionValueST(valueInt)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_slider_factiongold_desc")
	endEvent
endState

state FAC_EDIT_CMDER_SPAWN
    event OnSelectST(string state_id)
        Actor player = Game.GetPlayer()
        MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[editedFactionIndex].SetCmderSpawnLocation(player)
        ShowMessage("$sab_mcm_factionedit_popup_setcmderspawn", false)
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_button_setcmderspawn_desc")
	endEvent
endstate

state FAC_EDIT_UNIT_CMDER_MENU

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(JMap.getInt(jEditedFactionData, "CmderUnitIndex", 0) % 128)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, editedUnitsMenuPage)
		SetMenuDialogOptions(editedUnitIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        int trueIndex = index + editedUnitsMenuPage * 128
		JMap.setInt(jEditedFactionData, "CmderUnitIndex", trueIndex)
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(trueIndex))
	endEvent

	event OnDefaultST(string state_id)
		JMap.setInt(jEditedFactionData, "CmderUnitIndex", 0)
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(0))
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_menu_cmderunit_desc")
	endEvent
    
endstate

state FAC_EDIT_UNIT_RECRUIT_MENU

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(JMap.getInt(jEditedFactionData, "RecruitUnitIndex", 0) % 128)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, editedUnitsMenuPage)
		SetMenuDialogOptions(editedUnitIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        int trueIndex = index + editedUnitsMenuPage * 128
		JMap.setInt(jEditedFactionData, "RecruitUnitIndex", trueIndex)
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(trueIndex))
	endEvent

	event OnDefaultST(string state_id)
		JMap.setInt(jEditedFactionData, "RecruitUnitIndex", 0)
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(0))
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_menu_recruitunit_desc")
	endEvent
    
endstate

state FAC_EDIT_SAVE
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/factionData.json"
        JValue.writeToFile(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, filePath)
        ShowMessage("Save: " + filePath, false)
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_button_save_desc")
	endEvent
endstate

state FAC_EDIT_LOAD
    event OnSelectST(string state_id)
        MainPage.MainQuest.SpawnerScript.HideCustomizationGuy()
        string filePath = JContainers.userDirectory() + "SAB/factionData.json"
        MainPage.isLoadingData = true
        int jReadData = JValue.readFromFile(filePath)
        if jReadData != 0
            ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()
            MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray = JValue.releaseAndRetain(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, jReadData, "ShoutAndBlade")
            MainPage.MainQuest.FactionDataHandler.EnsureArrayCounts()
            MainPage.MainQuest.FactionDataHandler.UpdateAllFactionQuestsAccordingToJMap()
            MainPage.isLoadingData = false
            Debug.Notification("SAB: Load complete!")
            ShowMessage("$sab_mcm_shared_popup_msg_load_success", false)
            ForcePageReset()
        else
            MainPage.isLoadingData = false
            ShowMessage("$sab_mcm_shared_popup_msg_load_fail", false)
        endif
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_button_load_desc")
	endEvent
endstate

state FAC_EDIT_TROOPLINE_SELECT_MENU

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedTroopLineIndex)
		SetMenuDialogDefaultIndex(0)
        string[] troopLinesIdentifiers = MainPage.MainQuest.FactionDataHandler.CreateStringArrayWithTroopLineIdentifiers(jEditedFactionData)
		SetMenuDialogOptions(troopLinesIdentifiers)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		editedTroopLineIndex = index
		SetMenuOptionValueST(editedTroopLineIndex + 1)
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedTroopLineIndex = 0
		SetMenuOptionValueST(editedTroopLineIndex + 1)
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_menu_troopline_select_desc")
	endEvent
    
endstate

state FAC_EDIT_TROOPLINE_ENTRY_REMOVE
    event OnSelectST(string state_id)
        int entryIndex = state_id as int
        JArray.eraseIndex(jEditedTroopLine, entryIndex)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_button_troopline_entry_remove_desc")
	endEvent
endstate

state FAC_EDIT_TROOPLINE_ENTRY_UNIT

	event OnMenuOpenST(string state_id)
        int entryIndex = state_id as int
		SetMenuDialogStartIndex(jArray.getInt(jEditedTroopLine, entryIndex, 0) % 128)
		SetMenuDialogDefaultIndex(JMap.getInt(jEditedFactionData, "RecruitUnitIndex") % 128)
        MainPage.MainQuest.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, editedUnitsMenuPage)
		SetMenuDialogOptions(editedUnitIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        int entryIndex = state_id as int
        int trueIndex = index + editedUnitsMenuPage * 128
		jArray.setInt(jEditedTroopLine, entryIndex, trueIndex)
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(trueIndex))
	endEvent

	event OnDefaultST(string state_id)
        int entryIndex = state_id as int
        int recruitIndex = JMap.getInt(jEditedFactionData, "RecruitUnitIndex")
		jArray.setInt(jEditedTroopLine, entryIndex, recruitIndex)
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(recruitIndex))
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_menu_troopline_entry_select_unit_desc")
	endEvent
    
endstate

state FAC_EDIT_TROOPLINE_ENTRY_ADD
    event OnSelectST(string state_id)
        int entryIndex = state_id as int
        int recruitIndex = JMap.getInt(jEditedFactionData, "RecruitUnitIndex")

        if entryIndex > 0
            recruitIndex = jArray.getInt(jEditedTroopLine, entryIndex - 1, recruitIndex)
        endif

        JArray.addInt(jEditedTroopLine, recruitIndex)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_button_troopline_entry_add_desc")
	endEvent
endstate