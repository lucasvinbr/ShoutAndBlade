scriptname SAB_MCM_Page_EditLocations extends nl_mcm_module

SAB_MCM Property MainPage Auto

string[] editedFactionIdentifiersArray

string[] editedLocationIdentifiersArray
int editedLocationIndex = 0
int editedLocationPage = 0
int jLocationsDataMap
int unitToAddToStartingGarr = 0
SAB_LocationScript editedLocationScript

bool saveOwnerships = false

string[] leftSideMenuOptions
int displayedLeftSideMenu = 0

; the marker we use as base for creating new ones
ObjectReference Property XMarker auto

event OnInit()
    RegisterModule("$sab_mcm_page_edit_locations", 7)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[101]

    leftSideMenuOptions = new string[2]
    leftSideMenuOptions[0] = "$sab_mcm_locationedit_menu_leftside_garrison"
    leftSideMenuOptions[1] = "$sab_mcm_locationedit_menu_leftside_positions"

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

    if locHandler.GetIsBusyEditingLocData()
        AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_locations_loading_desc", "$sab_mcm_locationedit_text_locations_loading", "")
        return
    endif

    editedLocationIdentifiersArray = locHandler.CreateStringArrayWithLocationIdentifiers(editedLocationPage)

    if editedLocationIdentifiersArray.Length <= 0
        AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_no_locs_found_desc", "$sab_mcm_locationedit_text_no_locs_found", "")
        return
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    jLocationsDataMap = locHandler.jLocationsConfigMap

    if editedLocationIndex >= editedLocationIdentifiersArray.Length
        editedLocationIndex = 0
    endif

    if editedLocationScript == None
        ; we've got to find a fallback!
        editedLocationIndex = 0
        editedLocationScript = locHandler.GetLocationByIndex(0)

        if editedLocationScript == None
            ; last resort: show error and don't show rest of the page
            AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_no_locs_found_desc", "$sab_mcm_locationedit_text_no_locs_found", "")
            return
        endif
    endif

    AddSliderOptionST("LOC_EDIT_MENU_PAGE", "$sab_mcm_unitedit_slider_menupage", editedLocationPage + 1)
    AddMenuOptionST("LOC_EDIT_CUR_LOC", "$sab_mcm_locationedit_menu_currentloc", editedLocationScript.GetLocName())

    AddInputOptionST("LOC_EDIT_LOC_DISPLAYNAME", "$sab_mcm_locationedit_input_loc_name", editedLocationScript.GetLocName())
    AddEmptyOption()

    string ownerFacName = "$sab_mcm_locationedit_ownership_option_neutral"

    if editedLocationScript.factionScript != None
        ownerFacName = editedLocationScript.factionScript.GetFactionName()
    endif

    AddToggleOptionST("LOC_EDIT_ENABLED", "$sab_mcm_locationedit_toggle_enabled", editedLocationScript.isCurrentlyEnabled)

    AddMenuOptionST("LOC_EDIT_LOC_OWNER", "$sab_mcm_locationedit_menu_ownership", ownerFacName)
    
    AddSliderOptionST("LOC_EDIT_MULTIPLIER___GoldReward", "$sab_mcm_locationedit_slider_gold_award_mult", editedLocationScript.GoldRewardMultiplier, "{1}")
    AddSliderOptionST("LOC_EDIT_MULTIPLIER___GarrisonSize", "$sab_mcm_locationedit_slider_garrison_size_mult", editedLocationScript.GarrisonSizeMultiplier, "{1}")

    AddEmptyOption()
    AddMenuOptionST("LOC_EDIT_LEFTSIDE_MENU", "$sab_mcm_locationedit_menu_leftside", leftSideMenuOptions[displayedLeftSideMenu])
    AddEmptyOption()

    if displayedLeftSideMenu == 0
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
        AddMenuOptionST("LOC_EDIT_UNIT_RECRUIT_MENU", "$sab_mcm_locationedit_menu_garrunit", MainPage.GetMCMUnitDisplayByUnitIndex(unitToAddToStartingGarr))
        AddSliderOptionST("LOC_EDIT_UNIT_GARR_SLIDER", "$sab_mcm_locationedit_slider_garrunit_add", 0, "")

        AddEmptyOption()

        AddTextOptionST("LOC_EDIT_SET_TO_STARTGARR", "$sab_mcm_locationedit_button_set_to_startgarr", "")
        AddEmptyOption()
        AddTextOptionST("LOC_EDIT_SET_STARTGARR_TO_CUR", "$sab_mcm_locationedit_button_set_startgarr_to_cur", "")

    elseif displayedLeftSideMenu == 1
        ; options for editing and displaying info on positions:
        ; -- set location (should warn that it can be destructive)
        ;   - prevent change if player's loc is none
        ;   - warn if loc is not a placeholder one
        ; - add interior cell as this loc's
        ; - warnings list: must set this or that marker etc
        ; all options should be grayed out or hidden if this location isn't marked as editable
        Actor plyr = Game.GetPlayer()
        Location curLoc = plyr.GetCurrentLocation()
        String locName = "none"
        if curLoc != None
            locName = curLoc.GetName()
        endif

        bool locIsEditable = editedLocationScript.isChangeable

        if !locIsEditable
            AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_not_editable_desc", "$sab_mcm_locationedit_text_not_editable", "")
        else
            AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_plyr_cur_loc_desc", "$sab_mcm_locationedit_text_plyr_cur_loc", locName)
            AddTextOptionST("LOC_EDIT_CUSTOM_SET_LOC", "$sab_mcm_locationedit_button_set_custom_loc", "")

            AddEmptyOption()

            ; -- set xmarker positions: location's marker, moveDest, distCalc
            ;   - for each one, also display player's cur distance to marker
            AddMarkerHandlerFunctions(plyr, editedLocationScript.GetReference(), "loc_marker")

            AddEmptyOption()

            AddMarkerHandlerFunctions(plyr, editedLocationScript.MoveDestination, "loc_marker_movedest")

            AddEmptyOption()

            AddMarkerHandlerFunctions(plyr, editedLocationScript.DistCalculationReference, "loc_marker_distcalc")

            AddEmptyOption()
            ; - add extra is nearby marker
            ;   - should have a "is nearby?" display here. if nearby, you can't add another extra, but you can remove
            bool playerIsInside = editedLocationScript.IsRefInThisLocationsInteriors(plyr)
            bool isNearby = playerIsInside || editedLocationScript.IsRefNearbyOutside(plyr)
            Cell curPlyrCell = plyr.GetParentCell()
            bool isInterior = curPlyrCell.IsInterior()

            AddTextOptionST("LOC_EDIT_CUSTOM_NEARBY", "$sab_mcm_locationedit_text_is_nearby_loc", isNearby)

            int numExtraMarkers = editedLocationScript.GetNumExtraNearbyOutsideMarkers()
            AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_button_custom_loc_num_extramarkers_desc", "$sab_mcm_locationedit_button_custom_loc_num_extramarkers", numExtraMarkers)
            if isNearby && !isInterior
                AddTextOptionST("LOC_EDIT_CUSTOM_EXTRA_NEARMARKER___remove", "$sab_mcm_locationedit_button_custom_loc_remove_extramarker", "")
            elseif !isInterior
                AddTextOptionST("LOC_EDIT_CUSTOM_EXTRA_NEARMARKER___add", "$sab_mcm_locationedit_button_custom_loc_add_extramarker", "")
            endif

            if numExtraMarkers > 0
                AddTextOptionST("LOC_EDIT_CUSTOM_EXTRA_NEARMARKER___clear", "$sab_mcm_locationedit_button_custom_loc_clear_extramarker", "")
            endif

            ; - add/remove interior cells from this loc
            int numInteriorCells = editedLocationScript.GetNumInteriorCells()
            AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_button_custom_loc_num_interiorcells_desc", "$sab_mcm_locationedit_button_custom_loc_num_interiorcells", numInteriorCells)

            if isInterior
                if isNearby
                    AddTextOptionST("LOC_EDIT_CUSTOM_INTERIORCELL___remove", "$sab_mcm_locationedit_button_custom_loc_remove_interiorcell", "")
                else
                    AddTextOptionST("LOC_EDIT_CUSTOM_INTERIORCELL___add", "$sab_mcm_locationedit_button_custom_loc_add_interiorcell", "")
                endif
            endif

            if numInteriorCells > 0
                AddTextOptionST("LOC_EDIT_CUSTOM_INTERIORCELL___clear", "$sab_mcm_locationedit_button_custom_loc_clear_interiorcell", "")
            endif
        endif

        
    endif
    
    SetCursorPosition(1)

    AddToggleOptionST("LOC_EDIT_TOGGLE_SAVE_OWNERSHIPS", "$sab_mcm_locationedit_toggle_save_ownerships", saveOwnerships)

    AddTextOptionST("LOC_EDIT_SAVE", "$sab_mcm_locationedit_button_save", "")
    AddTextOptionST("LOC_EDIT_SAVE_WITH_GARR", "$sab_mcm_locationedit_button_save_with_garrisons", "")
    AddTextOptionST("LOC_EDIT_LOAD", "$sab_mcm_locationedit_button_load", "")

    AddEmptyOption()
    AddEmptyOption()

    int jNearbyLocsArray = editedLocationScript.jNearbyLocationsArray
    int i = jArray.count(jNearbyLocsArray)
    int locIndex = 0

    While i > 0
        i -= 1

        locIndex = jArray.getInt(jNearbyLocsArray, i, -1)
            
        if locIndex >= 0
            SAB_LocationScript locScript = locHandler.GetEnabledLocationByIndex(locIndex)
            if locScript != None
                string locName = locScript.GetLocName()
                AddTextOptionST("LOC_NEARBY___" + locName, "$sab_mcm_locationedit_nearbyloc", locName)
            endif
        endif
    EndWhile

    AddTextOptionST("LOC_RECALC_NEARBY", "$sab_mcm_locationedit_recalculate_nearbyloc", "")

    AddEmptyOption()
    AddEmptyOption()

    locIndex = editedLocationScript.indexInUpdater
    AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_locindex_updater_desc", "$sab_mcm_locationedit_text_locindex_updater", locIndex)

    locIndex = editedLocationScript.indexInCloseByUpdater
    AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_locindex_nearbies_updater_desc", "$sab_mcm_locationedit_text_locindex_nearbies_updater", locIndex)

    AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_loc_currently_enabled_desc", "$sab_mcm_locationedit_text_loc_currently_enabled", editedLocationScript.isCurrentlyEnabled)
    AddTextOptionST("LOC_EDIT_NOOP___sab_mcm_locationedit_text_loc_currently_nearby_desc", "$sab_mcm_locationedit_text_loc_currently_nearby", editedLocationScript.isNearby)
    
EndFunction

function AddMarkerHandlerFunctions(ObjectReference playerRef, ObjectReference marker, String markerType)
    float plyrDistance = playerRef.GetDistance(marker)
    AddTextOptionST("LOC_EDIT_CUSTOM_MARKERDIST___" + markerType, "$sab_mcm_locationedit_button_custom_" + markerType + "_dist", plyrDistance)
    AddTextOptionST("LOC_EDIT_CUSTOM_SET_MARKER___" + markerType, "$sab_mcm_locationedit_button_set_custom_" + markerType, "")
endfunction

; localized entry that does nothing (besides enabling the menu close via hotkey and showing its description)
state LOC_EDIT_NOOP
    event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$"+state_id)
	endEvent
endstate


state LOC_EDIT_MENU_PAGE
	event OnSliderOpenST(string state_id)
		SetSliderDialogStartValue(editedLocationPage + 1)
		SetSliderDialogDefaultValue(1)

        int numLocs = MainPage.MainQuest.LocationDataHandler.NextLocationIndex
        int numPages = Math.Ceiling((numLocs as float) / 128)
		SetSliderDialogRange(1, numPages)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
		editedLocationPage = (value as int) - 1
		SetSliderOptionValueST(editedLocationPage + 1)

        ; page must be rebuilt for the locs menu to be rebuilt as well
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedLocationPage = 0
		SetSliderOptionValueST(editedLocationPage + 1)

        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_slider_menupage_desc")
	endEvent
endState

state LOC_EDIT_CUR_LOC

	event OnMenuOpenST(string state_id)
        if editedLocationIndex >= editedLocationIdentifiersArray.Length
            SetMenuDialogStartIndex(0)
        else
            SetMenuDialogStartIndex(editedLocationIndex)
        endif
		
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(editedLocationIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		editedLocationIndex = index
		SetMenuOptionValueST(editedLocationIndex)
        editedLocationScript = MainPage.MainQuest.LocationDataHandler.GetLocationByPagedIndexInSortedNamesArr(editedLocationIndex, editedLocationPage)
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedLocationIndex = 0
		SetMenuOptionValueST(editedLocationIndex)
        editedLocationScript = MainPage.MainQuest.LocationDataHandler.GetLocationByPagedIndexInSortedNamesArr(editedLocationIndex, editedLocationPage)
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
        bool newValue = !editedLocationScript.isCurrentlyEnabled
        int newValueInt = 0

        MainPage.isLoadingData = true
        ShowMessage("$sab_mcm_shared_popup_msg_long_process_started", false)
        ;force a page reset to disable all action buttons!
        ForcePageReset()

        MainPage.MainQuest.LocationDataHandler.SetLocationEnabled(editedLocationScript, newValue, true)

        if newValue
            newValueInt = 1
        endif

        int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

        if jLocDataMap == 0
            jLocDataMap = jMap.object()
            jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
        endif

        jMap.setInt(jLocDataMap, "IsEnabled", newValueInt)
        
        Debug.Trace("SAB: loc enable/disable complete!")
        Debug.Notification("SAB: loc enable/disable complete!")
        MainPage.isLoadingData = false
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
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

        MainPage.MainQuest.LocationDataHandler.RebuildSortedLocNamesArrays()

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

        MainPage.MainQuest.LocationDataHandler.RebuildSortedLocNamesArrays()

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

state LOC_NEARBY

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_nearbyloc_desc")
	endEvent

endstate

state LOC_RECALC_NEARBY
    event OnSelectST(string state_id)
        MainPage.isLoadingData = true
        ShowMessage("$sab_mcm_shared_popup_msg_long_process_started", false)
        ;force a page reset to disable all action buttons!
        ForcePageReset()

        MainPage.MainQuest.LocationDataHandler.CalculateLocationDistances()
        Debug.Trace("SAB: Recalculate loc distances complete!")
        Debug.Notification("SAB: Recalculate loc distances complete!")
        MainPage.isLoadingData = false
        ForcePageReset()
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


state LOC_EDIT_LEFTSIDE_MENU

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(displayedLeftSideMenu)
		SetMenuDialogDefaultIndex(displayedLeftSideMenu)
		SetMenuDialogOptions(leftSideMenuOptions)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        displayedLeftSideMenu = index
		SetMenuOptionValueST(leftSideMenuOptions[displayedLeftSideMenu])
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
        displayedLeftSideMenu = 0
		SetMenuOptionValueST(leftSideMenuOptions[displayedLeftSideMenu])
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_menu_leftside_desc")
	endEvent
    
endstate

state LOC_EDIT_CUSTOM_SET_LOC
    event OnSelectST(string state_id)
        if !editedLocationScript.isChangeable
            return
        endif
        ; - set location (should warn that it can be destructive)
        ;   - prevent change if player's loc is none
        ;   - warn if loc is not a placeholder one
        Location curLoc = Game.GetPlayer().GetCurrentLocation()

        if curLoc == None
            ShowMessage("$sab_mcm_locationedit_popup_set_custom_loc_invalid", false)
            return
        endif

        bool warnBeforeChange = false
        if !editedLocationScript.IsPlaceholderLocation()
            warnBeforeChange = true
        endif

        if !warnBeforeChange || ShowMessage("$sab_mcm_locationedit_popup_msg_confirm_set_custom_loc")
            ; set location! the old loc's data will be removed when we save loc data again
            
            MainPage.isLoadingData = true
            ShowMessage("$sab_mcm_shared_popup_msg_long_process_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()

            MainPage.MainQuest.LocationDataHandler.SetLocationEnabled(editedLocationScript, false, true)
            jMap.removeKey(jLocationsDataMap, editedLocationScript.GetLocId())

            ; TODO prevent setting location to this one if a loc with this id already exists
            editedLocationScript.ThisLocation = curLoc

            int jLocDataMap = JMap.getObj(jLocationsDataMap, editedLocationScript.GetLocId())

            if jLocDataMap == 0
                jLocDataMap = jMap.object()
                jMap.setObj(jLocationsDataMap, editedLocationScript.GetLocId(), jLocDataMap)
            endif

            jMap.setInt(jLocDataMap, "IsEnabled", 0)

            Debug.Trace("SAB: custom loc change complete!")
            Debug.Notification("SAB: custom loc change complete!")
            MainPage.isLoadingData = false

            ForcePageReset()

        endif
        
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_button_set_custom_loc_desc")
	endEvent
endstate


state LOC_EDIT_CUSTOM_MARKERDIST
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_button_custom_"+ state_id +"_dist")
	endEvent
endState

state LOC_EDIT_CUSTOM_SET_MARKER
    event OnSelectST(string state_id)
        if !editedLocationScript.isChangeable
            return
        endif

        ; figure out which marker we're editing. default to main marker
        string markerJDataName = "jRefPosMap"
        ObjectReference marker = editedLocationScript.GetReference()

        if state_id == "loc_marker_movedest"
            marker = editedLocationScript.MoveDestination
            markerJDataName = "jMoveDestPosMap"
        elseif state_id == "loc_marker_distcalc"
            marker = editedLocationScript.DistCalculationReference
            markerJDataName = "jDistCalcPosMap"
        endif

        marker.MoveTo(Game.GetPlayer())
        MainPage.MainQuest.LocationDataHandler.WriteEditableLocMarkerDataToJmap(editedLocationScript, marker, markerJDataName)
        
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_locationedit_button_set_custom_"+ state_id +"_desc")
	endEvent
endstate

state LOC_EDIT_CUSTOM_EXTRA_NEARMARKER
    event OnSelectST(string state_id)
        if !editedLocationScript.isChangeable
            return
        endif

        if state_id == "add"
            ; create new marker at player's pos
            ObjectReference newMarker = Game.GetPlayer().PlaceAtMe(XMarker.GetBaseObject(), 1)

            editedLocationScript.AddExtraNearbyMarker(newMarker)
        elseif state_id == "remove"
            ; find nearest marker and remove it
            if editedLocationScript.RemoveNearestExtraNearbyMarker(Game.GetPlayer())
                ; message box?
            endif
        else
            ; confirm clearing... then clear!
            if ShowMessage("$sab_mcm_locationedit_popup_msg_confirm_clear_extramarkers")
                editedLocationScript.ClearExtraNearbyMarkersArr()
            endif
        endif
        
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)

        if state_id == "add"
            SetInfoText("$sab_mcm_locationedit_button_custom_loc_add_extramarker_desc")
        elseif state_id == "remove"
            SetInfoText("$sab_mcm_locationedit_button_custom_loc_remove_extramarker_desc")
        else
            SetInfoText("$sab_mcm_locationedit_button_custom_loc_clear_extramarker_desc")
        endif
		
	endEvent
endstate

state LOC_EDIT_CUSTOM_INTERIORCELL
    event OnSelectST(string state_id)
        if !editedLocationScript.isChangeable
            return
        endif

        Cell curPlyrCell = Game.GetPlayer().GetParentCell()
        bool isInterior = curPlyrCell.IsInterior()

        if state_id == "add"
            if !curPlyrCell || !isInterior
                return
            endif
            editedLocationScript.AddInteriorCell(curPlyrCell)
        elseif state_id == "remove"
            if !curPlyrCell || !isInterior
                return
            endif
            if editedLocationScript.RemoveInteriorCell(curPlyrCell)
                ; message box?
            endif
        else
            ; confirm clearing... then clear!
            if ShowMessage("$sab_mcm_locationedit_popup_msg_confirm_clear_interiorcells")
                editedLocationScript.ClearInteriorCellsArr()
            endif
        endif
        
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)

        if state_id == "add"
            SetInfoText("$sab_mcm_locationedit_button_custom_loc_add_interiorcell_desc")
        elseif state_id == "remove"
            SetInfoText("$sab_mcm_locationedit_button_custom_loc_remove_interiorcell_desc")
        else
            SetInfoText("$sab_mcm_locationedit_button_custom_loc_clear_interiorcell_desc")
        endif
		
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
        MainPage.MainQuest.LocationDataHandler.WriteLocDatasToJmap(saveOwnerships, false)
        JValue.writeToFile(MainPage.MainQuest.LocationDataHandler.jLocationsConfigMap, filePath)
        ShowMessage("Saved: " + filePath, false)
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
        MainPage.MainQuest.LocationDataHandler.WriteLocDatasToJmap(saveOwnerships, true)
        JValue.writeToFile(MainPage.MainQuest.LocationDataHandler.jLocationsConfigMap, filePath)
        ShowMessage("Saved: " + filePath, false)
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
            Debug.Trace("SAB: Load complete!")
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