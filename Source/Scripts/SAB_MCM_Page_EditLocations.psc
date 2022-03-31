scriptname SAB_MCM_Page_EditLocations extends nl_mcm_module

SAB_MCM Property MainPage Auto

string[] editedFactionIdentifiersArray

string[] editedLocationIdentifiersArray
int editedLocationIndex = 0
int jLocationsDataMap
SAB_LocationScript editedLocationScript


event OnInit()
    RegisterModule("$sab_mcm_page_edit_locations", 3)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[41]

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_edit_locations")
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

    editedLocationIdentifiersArray = MainPage.MainQuest.LocationDataHandler.CreateStringArrayWithLocationIdentifiers()

    if editedLocationIdentifiersArray.Length <= 0
        AddTextOptionST("NO_LOCS_FOUND", "$sab_mcm_locationedit_text_no_locs_found", "")
        return
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    jLocationsDataMap = MainPage.MainQuest.LocationDataHandler.jLocationsConfigMap

    editedLocationScript = MainPage.MainQuest.LocationDataHandler.Locations[editedLocationIndex]

    AddMenuOptionST("LOC_EDIT_CUR_LOC", "$sab_mcm_locationedit_menu_currentloc", editedLocationScript.ThisLocation.GetName())

    AddEmptyOption()

    string ownerFacName = "$sab_mcm_locationedit_ownership_option_neutral"

    if editedLocationScript.factionScript != None
        ownerFacName = editedLocationScript.factionScript.GetFactionName()
    endif

    AddToggleOptionST("LOC_EDIT_ENABLED", "$sab_mcm_locationedit_toggle_enabled", editedLocationScript.isEnabled)

    AddMenuOptionST("LOC_EDIT_LOC_OWNER", "$sab_mcm_locationedit_menu_ownership", ownerFacName)
    
    AddSliderOptionST("LOC_EDIT_MULTIPLIER___GoldReward", "$sab_mcm_locationedit_slider_gold_award_mult", editedLocationScript.GoldRewardMultiplier, "{1}")
    AddSliderOptionST("LOC_EDIT_MULTIPLIER___GarrisonSize", "$sab_mcm_locationedit_slider_garrison_size_mult", editedLocationScript.GarrisonSizeMultiplier, "{1}")

    SetCursorPosition(1)

    AddEmptyOption()
    AddTextOptionST("LOC_EDIT_SAVE", "$sab_mcm_locationedit_button_save", "")
    AddTextOptionST("LOC_EDIT_LOAD", "$sab_mcm_locationedit_button_load", "")
    
EndFunction


state LOC_EDIT_CUR_LOC

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedLocationIndex)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(editedLocationIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		editedLocationIndex = index
		SetMenuOptionValueST(index)
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedLocationIndex = 0
		SetMenuOptionValueST(editedLocationIndex)
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_menu_currentloc_desc")
	endEvent
    
endstate


state LOC_EDIT_LOC_OWNER

	event OnMenuOpenST(string state_id)
        int ownerIndex = MainPage.MainQuest.FactionDataHandler.GetFactionIndex(editedLocationScript.factionScript)
		SetMenuDialogStartIndex(ownerIndex + 1)
        SetMenuDialogDefaultIndex(0)
		MainPage.MainQuest.FactionDataHandler.SetupStringArrayWithOwnershipIdentifiers(editedFactionIdentifiersArray)
		SetMenuDialogOptions(editedFactionIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		SetMenuOptionValueST(editedFactionIdentifiersArray[index])

        int ownerIndex = index - 1

        if index == 0
            editedLocationScript.BecomeNeutral(true)
        else
            SAB_FactionScript newOwner = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[ownerIndex]
            editedLocationScript.BeTakenByFaction(newOwner, true)
        endif

        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "OwnerFactionIndex", ownerIndex)
	endEvent

	event OnDefaultST(string state_id)
		SetMenuOptionValueST("$sab_mcm_locationedit_ownership_option_neutral")
        editedLocationScript.BecomeNeutral(true)

        int ownerIndex = -1
        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "OwnerFactionIndex", ownerIndex)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_menu_ownership_desc")
	endEvent
    
endstate


state LOC_EDIT_ENABLED
    event OnSelectST(string state_id)
        bool newValue = !editedLocationScript.isEnabled
        int newValueInt = 0

        MainPage.MainQuest.LocationDataHandler.SetLocationEnabled(editedLocationScript, newValue)

        if newValue
            newValueInt = 1
        endif

        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "OwnerFactionIndex", newValueInt)
        SetToggleOptionValueST(newValue)
	endEvent

    event OnDefaultST(string state_id)
        bool newValue = true
        int newValueInt = 1

        MainPage.MainQuest.LocationDataHandler.SetLocationEnabled(editedLocationScript, newValue)

        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "OwnerFactionIndex", newValueInt)
        SetToggleOptionValueST(newValue)
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_toggle_enabled_desc")
	endEvent
endstate


state LOC_EDIT_MULTIPLIER
	event OnSliderOpenST(string state_id)
        float initialValue = editedLocationScript.GoldRewardMultiplier

        if state_id == "GarrisonSize"
            initialValue = editedLocationScript.GarrisonSizeMultiplier
        endif

		SetSliderDialogStartValue(initialValue)
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.1, 10.0)
		SetSliderDialogInterval(0.1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName(), jLocDataMap)
        endif

        if state_id == "GarrisonSize"
            editedLocationScript.GarrisonSizeMultiplier = value
            JMap.setFlt(jLocDataMap, "GarrisonSizeMultiplier", value)
        else
            editedLocationScript.GoldRewardMultiplier = value
            JMap.setFlt(jLocDataMap, "GoldRewardMultiplier", value)
        endif

		SetSliderOptionValueST(value, "{1}")
	endEvent

	event OnDefaultST(string state_id)
        float value = 1.0
        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.ThisLocation.GetName(), jLocDataMap)
        endif

        if state_id == "GarrisonSize"
            editedLocationScript.GarrisonSizeMultiplier = value
            JMap.setFlt(jLocDataMap, "GarrisonSizeMultiplier", value)
        else
            editedLocationScript.GoldRewardMultiplier = value
            JMap.setFlt(jLocDataMap, "GoldRewardMultiplier", value)
        endif

		SetSliderOptionValueST(value)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)

        if state_id == "GarrisonSize"
            SetInfoText("$sab_mcm_locationedit_slider_garrison_size_mult_desc")
        else
            SetInfoText("$sab_mcm_locationedit_slider_gold_award_mult_desc")
        endif
		
	endEvent
endState

state NO_LOCS_FOUND

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_text_no_locs_found_desc")
	endEvent

endstate

state LOC_EDIT_SAVE
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/locationData.json"
        MainPage.MainQuest.LocationDataHandler.WriteCurrentLocOwnershipsToJmap()
        JValue.writeToFile(MainPage.MainQuest.LocationDataHandler.jLocationsConfigMap, filePath)
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

state LOC_EDIT_LOAD
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/locationData.json"
        MainPage.isLoadingData = true
        int jReadData = JValue.readFromFile(filePath)
        if jReadData != 0
            ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()
            MainPage.MainQuest.LocationDataHandler.jLocationsConfigMap = JValue.releaseAndRetain(MainPage.MainQuest.LocationDataHandler.jLocationsConfigMap, jReadData, "ShoutAndBlade")
            MainPage.MainQuest.LocationDataHandler.UpdateLocationsAccordingToJMap()
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
