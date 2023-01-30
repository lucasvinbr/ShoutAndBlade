scriptname SAB_MCM_Page_Diplomacy extends nl_mcm_module

SAB_MCM Property MainPage Auto


string[] editedFactionIdentifiersArray
int editedFactionIndex = -1
int jEditedFactionData = 0

event OnInit()
    RegisterModule("$sab_mcm_diplomacy", 5)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[41]

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

    SetCursorFillMode(TOP_TO_BOTTOM)

    int jFactionDatasArray = MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray

    if editedFactionIndex >= 0
        jEditedFactionData = jArray.getObj(jFactionDatasArray, editedFactionIndex)
        ; set up fac if it doesn't exist
        if jEditedFactionData == 0
            jEditedFactionData = jMap.object()
            JArray.setObj(jFactionDatasArray, editedFactionIndex, jEditedFactionData)
        endif

        AddMenuOptionST("FAC_EDIT_CUR_FAC", "$sab_mcm_vanillafacrel_menu_selectedfac", \
            (MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex, jEditedFactionData)))
    else
        AddMenuOptionST("FAC_EDIT_CUR_FAC", "$sab_mcm_vanillafacrel_menu_selectedfac", \
            "$sab_mcm_diplomacy_menu_entry_option_player")
    endif


    AddEmptyOption()

    SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler

    if editedFactionIndex >= 0
        AddTextOptionST("RELPLAYER_DISPLAY", "$sab_mcm_diplomacy_player_entry", DiplomacyHandler.GetPlayerRelationWithFac(editedFactionIndex))
    endif

    AddEmptyOption()

    SetCursorFillMode(LEFT_TO_RIGHT)

    int i = JArray.count(jFactionDatasArray)
    int validFacsCount = 0

    while i > 0
        i -= 1

        int jFacDataMap = jArray.getObj(jFactionDatasArray, i)

        if jFacDataMap != 0 && jMap.hasKey(jFacDataMap, "enabled")
            string facName = jMap.getStr(jFacDataMap, "name", "Faction")

            float relationValue = 0.0

            if editedFactionIndex >= 0
                relationValue = DiplomacyHandler.GetRelationBetweenFacs(editedFactionIndex, i)
            else
                relationValue = DiplomacyHandler.GetPlayerRelationWithFac(i)
            endif
    
            AddTextOptionST("REL_DISPLAY___" + facName, facName, relationValue)
            validFacsCount += 1
        endif
        
    endwhile

    if validFacsCount % 2 != 0
        AddEmptyOption()
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    AddEmptyOption()
    AddTextOptionST("FAC_EDIT_SAVE", "$sab_mcm_diplomacy_button_save", "")
    AddTextOptionST("FAC_EDIT_LOAD", "$sab_mcm_diplomacy_button_load", "")
    
EndFunction


state REL_DISPLAY

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_entry_desc")
	endEvent
    
endstate

state RELPLAYER_DISPLAY

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_diplomacy_player_entry_desc")
	endEvent
    
endstate

state FAC_EDIT_SAVE
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/diplomacyData_factions.json"
        JValue.writeToFile(MainPage.MainQuest.DiplomacyHandler.jSABFactionRelationsMap, filePath)
        string filePathPlayerDiplo = JContainers.userDirectory() + "SAB/diplomacyData_player.json"
        JValue.writeToFile(MainPage.MainQuest.DiplomacyHandler.jSABPlayerRelationsMap, filePathPlayerDiplo)
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
        MainPage.isLoadingData = true
        int jReadData = JValue.readFromFile(filePath)
        int jReadDataPlayerDiplo = JValue.readFromFile(filePathPlayerDiplo)
        if jReadData != 0 && jReadDataPlayerDiplo != 0
            ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()
            SAB_DiplomacyDataHandler DiplomacyHandler = MainPage.MainQuest.DiplomacyHandler
            DiplomacyHandler.jSABFactionRelationsMap = JValue.releaseAndRetain(DiplomacyHandler.jSABFactionRelationsMap, jReadData, "ShoutAndBlade")
            DiplomacyHandler.jSABPlayerRelationsMap = JValue.releaseAndRetain(DiplomacyHandler.jSABPlayerRelationsMap, jReadDataPlayerDiplo, "ShoutAndBlade")
            DiplomacyHandler.UpdateAllRelationsAccordingToJMaps()
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
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedFactionIndex = -1
        if editedFactionIndex == -1
            SetMenuOptionValueST("$sab_mcm_diplomacy_menu_entry_option_player")
        else
            SetMenuOptionValueST(MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex))
        endif
		
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_menu_currentfac_desc")
	endEvent
    
endstate
