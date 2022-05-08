scriptname SAB_MCM_Page_Statistics extends nl_mcm_module
{ MCM page for displaying various informations about the mod's current status }

SAB_MCM Property MainPage Auto

int curInfoSetBeingShown = 0
int curStatsPage = 0
int numStatsPages = 0

int jdisplayedDataArray

bool isReloadingCurInfoSet = true

string[] infoSets

event OnInit()
    RegisterModule("$sab_mcm_page_statistics", 6)
endevent

Event OnPageInit()
    infoSets = new string[2]
    infoSets[0] = "$sab_mcm_stats_menu_statspage_loc_statuses"
    infoSets[1] = "$sab_mcm_stats_menu_statspage_faction_statuses"
EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_statistics")
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
    
    AddMenuOptionST("STATS_CUR_INFO_SET", "$sab_mcm_stats_menu_statspage", infoSets[curInfoSetBeingShown])

    AddTextOptionST("STATS_REFRESH_INFO_SET", "$sab_mcm_stats_button_refresh", "")

    if isReloadingCurInfoSet
        jdisplayedDataArray = jValue.releaseAndRetain(jdisplayedDataArray, jArray.object(), "ShoutAndBlade")
    endif

    if curInfoSetBeingShown == 0 ; location statuses
        SetupLocationStatistics()    
    elseif curInfoSetBeingShown == 1 ; faction statuses
        SetupFactionStatistics()
    endif

    ; if there are too many entries, paginate!
    if numStatsPages > 1
        ; add pagintation slider
        SetCursorPosition(1)
        AddSliderOptionST("STATS_CUR_DISPLAYED_PAGE_SLIDER", "$sab_mcm_stats_slider_statspage", curStatsPage + 1)
    endif

    isReloadingCurInfoSet = false
EndFunction


Function SetupLocationStatistics()
    SetCursorFillMode(LEFT_TO_RIGHT)
    SAB_UnitDataHandler unitDataHandler = MainPage.MainQuest.UnitDataHandler
    SAB_LocationScript[] locs = MainPage.MainQuest.LocationDataHandler.Locations
    int locIndex = locs.Length
    int slotsPerEntry = 6
    int entriesPerPage = Math.Floor(110 / slotsPerEntry)

    ;set up the jMaps first, and then paginate the results if needed
    if isReloadingCurInfoSet
        while locIndex > 0
            locIndex -= 1
            SAB_LocationScript locScript = locs[locIndex]
            if locScript != None && locScript.isEnabled
                int jNewEntryMap = jMap.object()
                jArray.addObj(jdisplayedDataArray, jNewEntryMap)

                JMap.setStr(jNewEntryMap, "name", locScript.ThisLocation.GetName())
                string ownerFacName = "$sab_mcm_locationedit_ownership_option_neutral"
                if locScript.factionScript != None
                    ownerFacName = locScript.factionScript.GetFactionName()
                endif
                JMap.setStr(jNewEntryMap, "ownerFacName", ownerFacName)
                JMap.setInt(jNewEntryMap, "unitCount", locScript.totalOwnedUnitsAmount)
                JMap.setStr(jNewEntryMap, "garrisonPower", unitDataHandler.GetTotalAutocalcPowerFromArmy(locScript.jOwnedUnitsMap))
                JMap.setStr(jNewEntryMap, "isContested", locScript.IsBeingContested())
            endif
        endwhile

        ; calculate how many pages we'll need to show the content
        curStatsPage = 0
        numStatsPages = Math.Ceiling(jArray.count(jdisplayedDataArray) / entriesPerPage)
    endif

    ; create the MCM entries now
    int firstIndex = entriesPerPage * curStatsPage
    int lastIndex = firstIndex + entriesPerPage
    locIndex = jArray.count(jdisplayedDataArray)

    if lastIndex > locIndex
        lastIndex = locIndex
    else 
        locIndex = lastIndex
    endif

    while locIndex > firstIndex
        locIndex -= 1
        int jEntryData = jArray.getObj(jdisplayedDataArray, locIndex)
        AddHeaderOption(jMap.getStr(jEntryData, "name", "Location (?)"))
        AddEmptyOption()
        AddTextOptionST("STATS_DISPLAY___LOCOWNER" + locIndex, "$sab_mcm_stats_menu_statspage_loc_statuses_owner", jMap.getStr(jEntryData, "ownerFacName", "?"))
        AddTextOptionST("STATS_DISPLAY___LOCUNITCOUNT" + locIndex, "$sab_mcm_stats_menu_statspage_loc_statuses_unitcount", JMap.getInt(jEntryData, "unitCount", 0))
        AddTextOptionST("STATS_DISPLAY___LOCPOWER" + locIndex, "$sab_mcm_stats_menu_statspage_loc_statuses_power", JMap.getStr(jEntryData, "garrisonPower", "0"))
        AddTextOptionST("STATS_DISPLAY___LOCISCONTESTED" + locIndex, "$sab_mcm_stats_menu_statspage_loc_statuses_contested", JMap.getStr(jEntryData, "isContested", "?"))
    endwhile
    
EndFunction


Function SetupFactionStatistics()
    SetCursorFillMode(LEFT_TO_RIGHT)
    SAB_FactionScript[] factions = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests
    int facIndex = factions.Length
    int slotsPerEntry = 6
    int entriesPerPage = Math.Floor(110 / slotsPerEntry)

    ;set up the jMaps first, and then paginate the results if needed
    if isReloadingCurInfoSet
        while facIndex > 0
            facIndex -= 1
            SAB_FactionScript facScript = factions[facIndex]
            if jMap.hasKey(facScript.jFactionData, "enabled")
                int jNewEntryMap = jMap.object()
                jArray.addObj(jdisplayedDataArray, jNewEntryMap)

                JMap.setStr(jNewEntryMap, "name", facScript.GetFactionName())
                
                JMap.setInt(jNewEntryMap, "factionGold", jMap.getInt(facScript.jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold())))
                JMap.setInt(jNewEntryMap, "numLocations", jValue.count(facScript.jOwnedLocationIndexesArray))
                JMap.setInt(jNewEntryMap, "numCmders", facScript.GetNumActiveCommanders())
                JMap.setStr(jNewEntryMap, "cmdersPower", facScript.GetTotalActiveCommandersAutocalcPower())
            endif
        endwhile

        ; calculate how many pages we'll need to show the content
        curStatsPage = 0
        numStatsPages = Math.Ceiling(jArray.count(jdisplayedDataArray) / entriesPerPage)
    endif

    ; create the MCM entries now
    int firstIndex = entriesPerPage * curStatsPage
    int lastIndex = firstIndex + entriesPerPage
    facIndex = jArray.count(jdisplayedDataArray)

    if lastIndex > facIndex
        lastIndex = facIndex
    else 
        facIndex = lastIndex
    endif

    while facIndex > firstIndex
        facIndex -= 1
        int jEntryData = jArray.getObj(jdisplayedDataArray, facIndex)
        AddHeaderOption(jMap.getStr(jEntryData, "name", "Faction (?)"))
        AddEmptyOption()
        AddTextOptionST("STATS_DISPLAY___FACGOLD" + facIndex, "$sab_mcm_stats_menu_statspage_faction_statuses_gold", jMap.getInt(jEntryData, "factionGold", 0))
        AddTextOptionST("STATS_DISPLAY___FACLOCCOUNT" + facIndex, "$sab_mcm_stats_menu_statspage_faction_statuses_num_locs", jMap.getInt(jEntryData, "numLocations", 0))
        AddTextOptionST("STATS_DISPLAY___FACNUMCMDERS" + facIndex, "$sab_mcm_stats_menu_statspage_faction_statuses_num_cmders", jMap.getInt(jEntryData, "numCmders", 0))
        AddTextOptionST("STATS_DISPLAY___FACARMYPOWER" + facIndex, "$sab_mcm_stats_menu_statspage_faction_statuses_power", jMap.getStr(jEntryData, "cmdersPower", "0.0"))
    endwhile
    
EndFunction


state STATS_CUR_INFO_SET

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(curInfoSetBeingShown)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(infoSets)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		SetMenuOptionValueST(infoSets[index])
        curInfoSetBeingShown = index
        isReloadingCurInfoSet = true
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
        int index = 0
        SetMenuOptionValueST(infoSets[index])
		curInfoSetBeingShown = index
        isReloadingCurInfoSet = true
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_stats_menu_statspage_desc")
	endEvent
    
    
endstate

state STATS_REFRESH_INFO_SET
    event OnSelectST(string state_id)
        isReloadingCurInfoSet = true
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_stats_button_refresh_desc")
	endEvent
endstate


state STATS_CUR_DISPLAYED_PAGE_SLIDER
	event OnSliderOpenST(string state_id)
        float initialValue = curStatsPage + 1

		SetSliderDialogStartValue(initialValue)
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(1, numStatsPages)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        float actualValue = value - 1

        curStatsPage = actualValue as int

		SetSliderOptionValueST(value)
	endEvent

	event OnDefaultST(string state_id)
        float value = 1.0
        float actualValue = value - 1

        curStatsPage = actualValue as int

		SetSliderOptionValueST(value)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_stats_slider_statspage_desc")
	endEvent
endState


state STATS_DISPLAY

    event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
	endEvent

endstate