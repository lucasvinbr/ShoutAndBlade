scriptname SAB_MCM_Page_Diplomacy extends nl_mcm_module

SAB_MCM Property MainPage Auto


string[] editedFactionIdentifiersArray
int editedFactionIndex = -1
int jEditedFactionData = 0
bool showOnlyFacsWithLocs = false

bool editMode = false
int curPageBeingShown = 0
int numPages = 0

int jDisplayedDataArray = 0

event OnInit()
    RegisterModule("$sab_mcm_diplomacy", 4)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[101]

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_diplomacy")
    SetupPage()
EndEvent



;---------------------------------------------------------------------------------------------------------
; PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupPage()

    if MainPage.isLoadingData || !MainPage.MainQuest.HasInitialized
        AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
        return
    endif

    SetCursorFillMode(LEFT_TO_RIGHT)

    int jFactionDatasArray = MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray
    SAB_FactionScript[] factions = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests

    if editedFactionIndex >= 0
        jEditedFactionData = jArray.getObj(jFactionDatasArray, editedFactionIndex)
        ; set up fac if it doesn't exist
        if jEditedFactionData == 0
            jEditedFactionData = jMap.object()
            JArray.setObj(jFactionDatasArray, editedFactionIndex, jEditedFactionData)
        endif

        AddMenuOptionST("FAC_EDIT_CUR_FAC", "$sab_mcm_vanillafacrel_menu_selectedfac", (MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex, jEditedFactionData)))
    else
        AddMenuOptionST("FAC_EDIT_CUR_FAC", "$sab_mcm_vanillafacrel_menu_selectedfac", "$sab_mcm_diplomacy_menu_entry_option_player")
    endif


    AddToggleOptionST("TOGGLE_EDITMODE", "$sab_mcm_diplomacy_toggle_edit_mode", editMode)
    AddToggleOptionST("TOGGLE_DISPLAY_ONLY_WITH_LOCS", "$sab_mcm_diplomacy_toggle_only_locs", showOnlyFacsWithLocs)

    AddEmptyOption()

    SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler

    if editedFactionIndex >= 0
        if editMode
            AddSliderOptionST("RELPLAYER_EDIT", "$sab_mcm_diplomacy_player_entry", DiplomacyHandler.GetPlayerRelationWithFac(editedFactionIndex), "{3}")
            AddToggleOptionST("RELPLAYER_LOCK", "$sab_mcm_diplomacy_entry_lock_toggle", DiplomacyHandler.GetIsPlayerRelationLockedWithFac(editedFactionIndex))
        else
            AddTextOptionST("RELPLAYER_DISPLAY", "$sab_mcm_diplomacy_player_entry", DiplomacyHandler.GetPlayerRelationWithFac(editedFactionIndex))
            AddEmptyOption()
        endif
    else
        AddEmptyOption()
        AddEmptyOption()
    endif

    AddEmptyOption()
    AddEmptyOption()

    int i = JArray.count(jFactionDatasArray)
    int validFacsCount = 0

    ; first we fill the data array, then we'll see about what we'll display
    jdisplayedDataArray = jValue.releaseAndRetain(jdisplayedDataArray, jArray.object(), "ShoutAndBlade")

    while i > 0
        i -= 1

        int jFacDataMap = jArray.getObj(jFactionDatasArray, i)

        if jFacDataMap != 0 && i != editedFactionIndex && jMap.hasKey(jFacDataMap, "enabled")

            SAB_FactionScript facScript = factions[i]

            if !showOnlyFacsWithLocs || jValue.count(facScript.jOwnedLocationIndexesArray) > 0
                string facName = jMap.getStr(jFacDataMap, "name", "Faction")

                float relationValue = 0.0
    
                if editedFactionIndex >= 0
                    relationValue = DiplomacyHandler.GetRelationBetweenFacs(editedFactionIndex, i)
                else
                    relationValue = DiplomacyHandler.GetPlayerRelationWithFac(i)
                endif

                bool isLocked = false
                if editedFactionIndex >= 0
                    isLocked = DiplomacyHandler.GetAreRelationsLockedBetweenFacs(editedFactionIndex, i)
                else
                    isLocked = DiplomacyHandler.GetIsPlayerRelationLockedWithFac(i)
                endif
        
                int jNewEntryMap = jMap.object()
                jArray.addObj(jDisplayedDataArray, jNewEntryMap)

                JMap.setInt(jNewEntryMap, "facIndex", i)
                JMap.setStr(jNewEntryMap, "name", facName)
                JMap.setFlt(jNewEntryMap, "relValue", relationValue)
                JMap.setInt(jNewEntryMap, "locked", isLocked as int)
                
                validFacsCount += 1
            endif
        endif
        
    endwhile

    ; find which entries to display, considering entry slot amount and cur page
    int slotsPerEntry = 1
    if editMode
        slotsPerEntry = 2
    endif
    int entriesPerPage = Math.Floor(100 / slotsPerEntry)

    ; create the MCM entries now
    int firstIndex = entriesPerPage * curPageBeingShown
    int lastIndex = firstIndex + entriesPerPage
    i = jArray.count(jDisplayedDataArray)

    if lastIndex > i
        lastIndex = i
    else 
        i = lastIndex
    endif

    while i > firstIndex
        i -= 1

        int jEntryData = jArray.getObj(jDisplayedDataArray, i)
        int facIndex = jMap.getInt(jEntryData, "facIndex")
        if editMode
            AddSliderOptionST("REL_EDIT___" + facIndex, jMap.getStr(jEntryData, "name"), jMap.getFlt(jEntryData, "relValue"), "{3}")
            AddToggleOptionST("REL_LOCK___" + facIndex, "$sab_mcm_diplomacy_entry_lock_toggle", jMap.getInt(jEntryData, "locked") == 1)
        else
            AddTextOptionST("REL_DISPLAY___" + facIndex, jMap.getStr(jEntryData, "name"), jMap.getFlt(jEntryData, "relValue"))
        endif
        
    endwhile

    int totalUsedSlots = (lastIndex - firstIndex) * slotsPerEntry
    if totalUsedSlots % 2 != 0
        AddEmptyOption()
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    AddEmptyOption()
    AddTextOptionST("FAC_EDIT_SAVE", "$sab_mcm_diplomacy_button_save", "")
    AddTextOptionST("FAC_EDIT_LOAD", "$sab_mcm_diplomacy_button_load", "")

    ; if there are too many entries, paginate!
    numPages = Math.Ceiling((validFacsCount as float) / entriesPerPage)
    if numPages > 1
        ; add pagintation slider
        SetCursorPosition(3)
        AddSliderOptionST("CUR_DISPLAYED_PAGE_SLIDER", "$sab_mcm_stats_slider_statspage", curPageBeingShown + 1)
    endif
    
EndFunction

Function SetRelationValue(int targetFacIndex, float relationValue)
    SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler
    int playerFacIndex = -1

    if DiplomacyHandler.PlayerDataHandler.PlayerFaction != None
        playerFacIndex = DiplomacyHandler.PlayerDataHandler.PlayerFaction.GetFactionIndex()
    endif

    if editedFactionIndex >= 0
        DiplomacyHandler.SetRelationBetweenFacs(editedFactionIndex, targetFacIndex, relationValue, playerFacIndex, true)
    else
        DiplomacyHandler.SetPlayerRelationWithFac(editedFactionIndex, relationValue, true)
    endif
EndFunction

state REL_DISPLAY

    event OnSelectST(string state_id)

        int clickedFacIndex = state_id as int

        if clickedFacIndex >= 0
            editedFactionIndex = clickedFacIndex
            curPageBeingShown = 0
            ForcePageReset()
        endif
        
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_entry_desc")
	endEvent
    
endstate

state RELPLAYER_DISPLAY

    event OnSelectST(string state_id)
        editedFactionIndex = -1
        curPageBeingShown = 0
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_player_entry_desc")
	endEvent
    
endstate

state REL_EDIT

    event OnSliderOpenST(string state_id)
        int clickedFacIndex = state_id as int

        SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler
        
        float relationValue = 0.0
    
        if editedFactionIndex >= 0
            relationValue = DiplomacyHandler.GetRelationBetweenFacs(editedFactionIndex, clickedFacIndex)
        else
            relationValue = DiplomacyHandler.GetPlayerRelationWithFac(clickedFacIndex)
        endif

		SetSliderDialogStartValue(relationValue)
		SetSliderDialogDefaultValue(0.0)
		SetSliderDialogRange(JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.minRelationValue", -2.0), JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.maxRelationValue", 2.0))
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int clickedFacIndex = state_id as int

        SetRelationValue(clickedFacIndex, value)

		SetSliderOptionValueST(value, "{3}")
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        float value = 0.0

        int clickedFacIndex = state_id as int

        SetRelationValue(clickedFacIndex, value)

		SetSliderOptionValueST(value, "{3}")
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_diplomacy_entry_desc")
	endEvent
    
endstate

state REL_LOCK
    event OnSelectST(string state_id)
        int clickedFacIndex = state_id as int
        SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler

        bool curValue = false
        if editedFactionIndex >= 0
            curValue = DiplomacyHandler.GetAreRelationsLockedBetweenFacs(editedFactionIndex, clickedFacIndex)
            DiplomacyHandler.SetLockedRelationsBetweenFacs(editedFactionIndex, clickedFacIndex, !curValue)
        else
            curValue = DiplomacyHandler.GetIsPlayerRelationLockedWithFac(clickedFacIndex)
            DiplomacyHandler.SetLockPlayerRelationsWithFac(clickedFacIndex, !curValue)
        endif

        SetToggleOptionValueST(!curValue)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        bool desiredValue = false

        int clickedFacIndex = state_id as int
        SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler

        if editedFactionIndex >= 0
            DiplomacyHandler.SetLockedRelationsBetweenFacs(editedFactionIndex, clickedFacIndex, desiredValue)
        else
            DiplomacyHandler.SetLockPlayerRelationsWithFac(clickedFacIndex, desiredValue)
        endif

        SetToggleOptionValueST(desiredValue)
        ForcePageReset()
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_entry_lock_toggle_desc")
	endEvent
endstate

state RELPLAYER_EDIT

    event OnSliderOpenST(string state_id)
        SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler
        
        float relationValue = DiplomacyHandler.GetPlayerRelationWithFac(editedFactionIndex)

		SetSliderDialogStartValue(relationValue)
		SetSliderDialogDefaultValue(0.0)
		SetSliderDialogRange(JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.minRelationValue", -2.0), JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.maxRelationValue", 2.0))
		SetSliderDialogInterval(0.01)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler

        DiplomacyHandler.SetPlayerRelationWithFac(editedFactionIndex, value, true)

		SetSliderOptionValueST(value, "{3}")
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        float value = 0.0

        SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler

        DiplomacyHandler.SetPlayerRelationWithFac(editedFactionIndex, value, true)

		SetSliderOptionValueST(value, "{3}")
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_diplomacy_entry_desc")
	endEvent
    
endstate

state RELPLAYER_LOCK
    event OnSelectST(string state_id)
        SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler

        bool curValue = DiplomacyHandler.GetIsPlayerRelationLockedWithFac(editedFactionIndex)
        DiplomacyHandler.SetLockPlayerRelationsWithFac(editedFactionIndex, !curValue)

        SetToggleOptionValueST(!curValue)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        bool desiredValue = false

        SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler

        DiplomacyHandler.SetLockPlayerRelationsWithFac(editedFactionIndex, desiredValue)

        SetToggleOptionValueST(desiredValue)
        ForcePageReset()
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_entry_lock_toggle_desc")
	endEvent
endstate

state FAC_EDIT_SAVE
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/diplomacyData_factions.json"
        JValue.writeToFile(MainPage.MainQuest.DiplomacyHandler.jSABFactionRelationsMap, filePath)

        string filePathPlayerDiplo = JContainers.userDirectory() + "SAB/diplomacyData_player.json"
        JValue.writeToFile(MainPage.MainQuest.DiplomacyHandler.jSABPlayerRelationsMap, filePathPlayerDiplo)

        string filePathFactionLocks = JContainers.userDirectory() + "SAB/diplomacyData_factions_locks.json"
        JValue.writeToFile(MainPage.MainQuest.DiplomacyHandler.jSABLockedFactionRelationsMap, filePathFactionLocks)

        string filePathPlayerDiploLocks = JContainers.userDirectory() + "SAB/diplomacyData_player_locks.json"
        JValue.writeToFile(MainPage.MainQuest.DiplomacyHandler.jSABLockedPlayerRelationsList, filePathPlayerDiploLocks)

        ShowMessage("Save: " + filePath, false)
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_button_save_desc")
	endEvent
endstate

state FAC_EDIT_LOAD
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/diplomacyData_factions.json"
        string filePathPlayerDiplo = JContainers.userDirectory() + "SAB/diplomacyData_player.json"
        string filePathFacLocks = JContainers.userDirectory() + "SAB/diplomacyData_factions_locks.json"
        string filePathPlayerDiploLocks = JContainers.userDirectory() + "SAB/diplomacyData_player_locks.json"
        MainPage.isLoadingData = true
        int jReadData = JValue.readFromFile(filePath)
        int jReadDataPlayerDiplo = JValue.readFromFile(filePathPlayerDiplo)
        int jReadDataFacLocks = jValue.readFromFile(filePathFacLocks)
        int jReadDataPlayerDiploLocks = JValue.readFromFile(filePathPlayerDiploLocks)
        if jReadData != 0 && jReadDataPlayerDiplo != 0
            ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()
            SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler
            DiplomacyHandler.jSABFactionRelationsMap = JValue.releaseAndRetain(DiplomacyHandler.jSABFactionRelationsMap, jReadData, "ShoutAndBlade")
            DiplomacyHandler.jSABPlayerRelationsMap = JValue.releaseAndRetain(DiplomacyHandler.jSABPlayerRelationsMap, jReadDataPlayerDiplo, "ShoutAndBlade")
            DiplomacyHandler.UpdateAllRelationsAccordingToJMaps()
            if jReadDataFacLocks != 0
                DiplomacyHandler.jSABLockedFactionRelationsMap = jValue.releaseAndRetain(DiplomacyHandler.jSABLockedFactionRelationsMap, jReadDataFacLocks, "ShoutAndBlade")
            endif
            if jReadDataPlayerDiploLocks != 0
                DiplomacyHandler.jSABLockedPlayerRelationsList = jValue.releaseAndRetain(DiplomacyHandler.jSABLockedPlayerRelationsList, jReadDataPlayerDiploLocks, "ShoutAndBlade")
            endif
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
		SetInfoText("$sab_mcm_diplomacy_button_load_desc")
	endEvent
endstate


state FAC_EDIT_CUR_FAC

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedFactionIndex + 1)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.FactionDataHandler.SetupStringArrayWithOwnershipIdentifiers(editedFactionIdentifiersArray, "$sab_mcm_diplomacy_menu_entry_option_player")
		SetMenuDialogOptions(editedFactionIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		editedFactionIndex = index - 1
        if editedFactionIndex == -1
            SetMenuOptionValueST("$sab_mcm_diplomacy_menu_entry_option_player")
        else
            SetMenuOptionValueST(MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex))
        endif

        curPageBeingShown = 0
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedFactionIndex = -1
        if editedFactionIndex == -1
            SetMenuOptionValueST("$sab_mcm_diplomacy_menu_entry_option_player")
        else
            SetMenuOptionValueST(MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex))
        endif
		
        curPageBeingShown = 0
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_menu_currentfac_desc")
	endEvent
    
endstate

state TOGGLE_DISPLAY_ONLY_WITH_LOCS
    event OnSelectST(string state_id)
        showOnlyFacsWithLocs = !showOnlyFacsWithLocs
        SetToggleOptionValueST(showOnlyFacsWithLocs)
        curPageBeingShown = 0
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        showOnlyFacsWithLocs = false
        SetToggleOptionValueST(showOnlyFacsWithLocs)
        curPageBeingShown = 0
        ForcePageReset()
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_toggle_only_locs_desc")
	endEvent
endstate

state TOGGLE_EDITMODE
    event OnSelectST(string state_id)
        editMode = !editMode
        SetToggleOptionValueST(editMode)
        curPageBeingShown = 0
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        editMode = false
        SetToggleOptionValueST(editMode)
        curPageBeingShown = 0
        ForcePageReset()
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_toggle_edit_mode_desc")
	endEvent
endstate


state CUR_DISPLAYED_PAGE_SLIDER
	event OnSliderOpenST(string state_id)
        float initialValue = curPageBeingShown + 1

		SetSliderDialogStartValue(initialValue)
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(1, numPages)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        float actualValue = value - 1

        curPageBeingShown = actualValue as int

		SetSliderOptionValueST(value)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        float value = 1.0
        float actualValue = value - 1

        curPageBeingShown = actualValue as int

		SetSliderOptionValueST(value)
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_stats_slider_statspage_desc")
	endEvent
endState