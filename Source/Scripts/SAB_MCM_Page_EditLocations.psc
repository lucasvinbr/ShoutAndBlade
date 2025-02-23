scriptname SAB_MCM_Page_EditLocations extends nl_mcm_module

SAB_MCM Property MainPage Auto

string[] editedFactionIdentifiersArray

string[] editedLocationIdentifiersArray
int editedLocationIndex = 0
int jLocationsDataMap
int unitToAddToStartingGarr = 0
SAB_LocationScript editedLocationScript

bool saveOwnerships = false

event OnInit()
    RegisterModule("$sab_mcm_page_edit_locations", 7)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[101]

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

    SAB_LocationDataHandler locHandler = MainPage.MainQuest.LocationDataHandler

    editedLocationIdentifiersArray = locHandler.CreateStringArrayWithLocationIdentifiers()

    if editedLocationIdentifiersArray.Length <= 0
        AddTextOptionST("NO_LOCS_FOUND", "$sab_mcm_locationedit_text_no_locs_found", "")
        return
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    jLocationsDataMap = locHandler.jLocationsConfigMap

    editedLocationScript = locHandler.GetLocationByIndex(editedLocationIndex)

    AddMenuOptionST("LOC_EDIT_CUR_LOC", "$sab_mcm_locationedit_menu_currentloc", editedLocationScript.GetLocName())

    AddInputOptionST("LOC_EDIT_LOC_DISPLAYNAME", "$sab_mcm_locationedit_input_loc_name", editedLocationScript.GetLocName())
    AddEmptyOption()

    string ownerFacName = "$sab_mcm_locationedit_ownership_option_neutral"

    if editedLocationScript.factionScript != None
        ownerFacName = editedLocationScript.factionScript.GetFactionName()
    endif

    AddToggleOptionST("LOC_EDIT_ENABLED", "$sab_mcm_locationedit_toggle_enabled", editedLocationScript.isEnabled)

    AddMenuOptionST("LOC_EDIT_LOC_OWNER", "$sab_mcm_locationedit_menu_ownership", ownerFacName)
    
    AddSliderOptionST("LOC_EDIT_MULTIPLIER___GoldReward", "$sab_mcm_locationedit_slider_gold_award_mult", editedLocationScript.GoldRewardMultiplier, "{1}")
    AddSliderOptionST("LOC_EDIT_MULTIPLIER___GarrisonSize", "$sab_mcm_locationedit_slider_garrison_size_mult", editedLocationScript.GarrisonSizeMultiplier, "{1}")

    

    ; set up a list of the current loc units.
    ; show a message if there are no units
    AddHeaderOption("$sab_mcm_locationedit_header_curgarrison")
    int jUnitDatasArray = MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray
    int jLocUnitsMap = editedLocationScript.jOwnedUnitsMap
    int nextUnitIndex = JIntMap.nextKey(jLocUnitsMap, -1, -1)
    bool atLeastOneUnitEntry = false
    while nextUnitIndex != -1
        int nextUnitCount = jIntMap.getInt(jLocUnitsMap, nextUnitIndex)
        if nextUnitCount > 0
            int jUnitData = JArray.getObj(jUnitDatasArray, nextUnitIndex)
            if jUnitData != 0
                AddTextOptionST("LOC_CURTROOP___" + nextUnitIndex, nextUnitCount + " " + JMap.getStr(jUnitData, "Name", "Recruit"), "")
                atLeastOneUnitEntry = true
            endif
        endif

        nextUnitIndex = JIntMap.nextKey(jLocUnitsMap, nextUnitIndex, -1)
    endwhile

    if !atLeastOneUnitEntry
        AddTextOptionST("EMPTY_LOC_PLACEHOLDER___CUR", " - ", "")
    endif

    AddEmptyOption()
    ; set up a list of the STARTING loc units.
    ; show a message if there are no units
    AddHeaderOption("$sab_mcm_locationedit_header_startgarrison")

    if editedLocationScript.jStartingUnitsMap == 0
        editedLocationScript.jStartingUnitsMap = jValue.releaseAndRetain(editedLocationScript.jStartingUnitsMap, jIntMap.object(), "ShoutAndBlade")
    endif

    jLocUnitsMap = editedLocationScript.jStartingUnitsMap
    nextUnitIndex = JIntMap.nextKey(jLocUnitsMap, -1, -1)
    atLeastOneUnitEntry = false
    while nextUnitIndex != -1
        int nextUnitCount = jIntMap.getInt(jLocUnitsMap, nextUnitIndex)
        if nextUnitCount > 0
            int jUnitData = JArray.getObj(jUnitDatasArray, nextUnitIndex)
            if jUnitData != 0
                AddSliderOptionST("LOC_STARTINGTROOP___" + nextUnitIndex, JMap.getStr(jUnitData, "Name", "Recruit"), nextUnitCount)
                atLeastOneUnitEntry = true
            endif
        endif

        nextUnitIndex = JIntMap.nextKey(jLocUnitsMap, nextUnitIndex, -1)
    endwhile

    if !atLeastOneUnitEntry
        AddTextOptionST("EMPTY_LOC_PLACEHOLDER___STARTING", " - ", "")
    endif

    AddEmptyOption()
    ; options for editing starting/cur garrison:
    ; - add units to starting garrison
    ; - set cur garrison to starting garrison
    AddHeaderOption("$sab_mcm_locationedit_header_editstartgarrison")
    AddSliderOptionST("LOC_EDIT_UNIT_MENU_PAGE___STARTGARRISON", "$sab_mcm_unitedit_slider_menupage", MainPage.editedUnitsMenuPage + 1)
    AddMenuOptionST("LOC_EDIT_UNIT_RECRUIT_MENU", "$sab_mcm_locationedit_menu_garrunit", \
        MainPage.GetMCMUnitDisplayByUnitIndex(unitToAddToStartingGarr))
    AddSliderOptionST("LOC_EDIT_UNIT_GARR_SLIDER", "$sab_mcm_locationedit_slider_garrunit_add", 0, "")

    AddEmptyOption()

    AddTextOptionST("LOC_EDIT_SET_TO_STARTGARR", "$sab_mcm_locationedit_button_set_to_startgarr", "")
    AddEmptyOption()
    AddTextOptionST("LOC_EDIT_SET_STARTGARR_TO_CUR", "$sab_mcm_locationedit_button_set_startgarr_to_cur", "")

    SetCursorPosition(1)

    AddToggleOptionST("LOC_EDIT_TOGGLE_SAVE_OWNERSHIPS", "$sab_mcm_locationedit_toggle_save_ownerships", saveOwnerships)

    AddTextOptionST("LOC_EDIT_SAVE", "$sab_mcm_locationedit_button_save", "")
    AddTextOptionST("LOC_EDIT_SAVE_WITH_GARR", "$sab_mcm_locationedit_button_save_with_garrisons", "")
    AddTextOptionST("LOC_EDIT_LOAD", "$sab_mcm_locationedit_button_load", "")

    AddEmptyOption()

    ; this isn't working as it should. New locations aren't registered in the addon's array
    ;AddTextOptionST("LOC_RELOAD_ADDONS", "$sab_mcm_locationedit_button_reload_addons", "")

    AddEmptyOption()

    int jNearbyLocsArray = editedLocationScript.jNearbyLocationsArray
    int i = jArray.count(jNearbyLocsArray)

    While i > 0
        i -= 1

        int locIndex = jArray.getInt(jNearbyLocsArray, i, -1)
            
        if locIndex >= 0
            SAB_LocationScript locScript = locHandler.GetLocationByIndex(locIndex)
            if locScript != None
                string locName = locScript.GetLocName()
                AddTextOptionST("LOC_NEARBY___" + locName, "$sab_mcm_locationedit_nearbyloc", locName)
            endif
        endif
    EndWhile

    AddTextOptionST("LOC_RECALC_NEARBY", "$sab_mcm_locationedit_recalculate_nearbyloc", "")
    
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
		MainPage.MainQuest.FactionDataHandler.SetupStringArrayWithOwnershipIdentifiers(editedFactionIdentifiersArray, "$sab_mcm_locationedit_ownership_option_neutral")
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

        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "OwnerFactionIndex", ownerIndex)
	endEvent

	event OnDefaultST(string state_id)
		SetMenuOptionValueST("$sab_mcm_locationedit_ownership_option_neutral")
        editedLocationScript.BecomeNeutral(true)

        int ownerIndex = -1
        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
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

        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "OwnerFactionIndex", newValueInt)
        SetToggleOptionValueST(newValue)
	endEvent

    event OnDefaultST(string state_id)
        bool newValue = true
        int newValueInt = 1

        MainPage.MainQuest.LocationDataHandler.SetLocationEnabled(editedLocationScript, newValue)

        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "OwnerFactionIndex", newValueInt)
        SetToggleOptionValueST(newValue)
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_toggle_enabled_desc")
	endEvent
endstate

state LOC_EDIT_LOC_DISPLAYNAME

	event OnInputOpenST(string state_id)
        string locName = editedLocationScript.GetLocName()
		SetInputDialogStartText(locName)
	endEvent

	event OnInputAcceptST(string state_id, string inputs)
        MainPage.ToggleQuickHotkey(true)
        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
        endif

        editedLocationScript.OverrideDisplayName = inputs
        JMap.setStr(jLocDataMap, "OverrideDisplayName", inputs)
        SetInputOptionValueST(inputs)

        ;force a reset to update other fields that use the name
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)

        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
        endif

        string inputs = editedLocationScript.ThisLocation.GetName()
        editedLocationScript.OverrideDisplayName = inputs
        JMap.setStr(jLocDataMap, "OverrideDisplayName", inputs)
        SetInputOptionValueST(inputs)

        ;force a reset to update other fields that use the name
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(false)
		SetInfoText("$sab_mcm_locationedit_input_loc_name_desc")
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
        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
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
        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
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

state LOC_NEARBY

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_nearbyloc_desc")
	endEvent

endstate

state LOC_RECALC_NEARBY
    event OnSelectST(string state_id)
        MainPage.MainQuest.LocationDataHandler.CalculateLocationDistances()
        ShowMessage("$sab_mcm_locationedit_recalculate_nearbyloc_desc", false)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_recalculate_nearbyloc_desc")
	endEvent
endstate


state LOC_CURTROOP

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_locationedit_garrison_entry_desc")
	endEvent

endstate

state EMPTY_LOC_PLACEHOLDER
    event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
	endEvent
endstate

state LOC_STARTINGTROOP

    event OnSliderOpenST(string state_id)
        int pickedUnit = state_id as int
        int jStartUnitsMap = editedLocationScript.jStartingUnitsMap
        int curUnitCount = jIntMap.getInt(jStartUnitsMap, pickedUnit)

		SetSliderDialogStartValue(curUnitCount)
		SetSliderDialogDefaultValue(0)
		SetSliderDialogRange(0, 150)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int pickedUnit = state_id as int
        int pickedValue = value as int
        int jStartUnitsMap = editedLocationScript.jStartingUnitsMap
        If pickedValue > 0
            JIntMap.setInt(jStartUnitsMap, pickedUnit, pickedValue)
        else
            JIntMap.removeKey(jStartUnitsMap, pickedUnit)
        endif

        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_locationedit_slider_garrunit_desc")
	endEvent

endstate

state LOC_EDIT_UNIT_MENU_PAGE
	event OnSliderOpenST(string state_id)
		SetSliderDialogStartValue(MainPage.editedUnitsMenuPage + 1)
		SetSliderDialogDefaultValue(1)
		SetSliderDialogRange(1, 4) ; 512 units
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
		MainPage.editedUnitsMenuPage = (value as int) - 1
		SetSliderOptionValueST(MainPage.editedUnitsMenuPage + 1)
	endEvent

	event OnDefaultST(string state_id)
		MainPage.editedUnitsMenuPage = 0
		SetSliderOptionValueST(MainPage.editedUnitsMenuPage + 1)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_slider_menupage_desc")
	endEvent
endState

state LOC_EDIT_UNIT_RECRUIT_MENU

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(unitToAddToStartingGarr % 128)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(MainPage.MainQuest.UnitDataHandler.GetStringArrayWithUnitIdentifiers(MainPage.editedUnitsMenuPage))
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        int trueIndex = index + MainPage.editedUnitsMenuPage * 128
		unitToAddToStartingGarr = trueIndex
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(trueIndex))
	endEvent

	event OnDefaultST(string state_id)
		unitToAddToStartingGarr = 0
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(0))
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_menu_garrunit_desc")
	endEvent
    
endstate

state LOC_EDIT_UNIT_GARR_SLIDER

    event OnSliderOpenST(string state_id)
        int pickedUnit = unitToAddToStartingGarr
        int jStartUnitsMap = editedLocationScript.jStartingUnitsMap

		SetSliderDialogStartValue(0)
		SetSliderDialogDefaultValue(0)
		SetSliderDialogRange(0, 150)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int pickedUnit = unitToAddToStartingGarr
        int pickedValue = value as int
        int jStartUnitsMap = editedLocationScript.jStartingUnitsMap
        int curUnitCount = jIntMap.getInt(jStartUnitsMap, pickedUnit, 0)
        If pickedValue > 0
            JIntMap.setInt(jStartUnitsMap, pickedUnit, curUnitCount + pickedValue)
        endif

        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_locationedit_slider_garrunit_add_desc")
	endEvent

endstate

state LOC_EDIT_SET_TO_STARTGARR
    event OnSelectST(string state_id)
        JIntMap.clear(editedLocationScript.jOwnedUnitsMap)
        int jStartUnitsMap = editedLocationScript.jStartingUnitsMap
        editedLocationScript.SetOwnedUnits(jStartUnitsMap)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_button_set_to_startgarr_desc")
	endEvent
endstate 

state LOC_EDIT_SET_STARTGARR_TO_CUR
    event OnSelectST(string state_id)
        int jStartUnitsMap = editedLocationScript.jStartingUnitsMap
        JIntMap.addPairs(jStartUnitsMap, editedLocationScript.jOwnedUnitsMap, true)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_button_set_startgarr_to_cur_desc")
	endEvent
endstate 


state LOC_EDIT_TOGGLE_SAVE_OWNERSHIPS
    event OnSelectST(string state_id)
        saveOwnerships = !saveOwnerships
        SetToggleOptionValueST(saveOwnerships)
	endEvent

    event OnDefaultST(string state_id)
        saveOwnerships = true
        SetToggleOptionValueST(saveOwnerships)
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_toggle_save_ownerships_desc")
	endEvent
endstate

state LOC_EDIT_SAVE
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/locationData.json"
        if saveOwnerships
            MainPage.MainQuest.LocationDataHandler.WriteCurrentLocOwnershipsToJmap()
        endif
        MainPage.MainQuest.LocationDataHandler.WriteCurrentLocNamesToJmap()
        MainPage.MainQuest.LocationDataHandler.WriteCurrentLocStartGarrsToJmap()
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

state LOC_EDIT_SAVE_WITH_GARR
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/locationData.json"
        if saveOwnerships
            MainPage.MainQuest.LocationDataHandler.WriteCurrentLocOwnershipsToJmap()
        endif
        MainPage.MainQuest.LocationDataHandler.WriteCurrentLocNamesToJmap()
        MainPage.MainQuest.LocationDataHandler.WriteCurrentLocGarrsToStartGarrsJmap()
        JValue.writeToFile(MainPage.MainQuest.LocationDataHandler.jLocationsConfigMap, filePath)
        ShowMessage("Save: " + filePath, false)
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_button_save_with_garrisons_desc")
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


state LOC_RELOAD_ADDONS
    event OnSelectST(string state_id)
        MainPage.MainQuest.LocationDataHandler.ReaddLocationsFromAddons()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_button_reload_addons_desc")
	endEvent
endstate