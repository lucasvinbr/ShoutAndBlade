scriptname SAB_MCM_Page_Statistics extends nl_mcm_module
{ MCM page for displaying various informations about the mod's current status }

SAB_MCM Property MainPage Auto

int curInfoSetBeingShown = 0
int curStatsPage = 0
int numStatsPages = 0

int jdisplayedDataArray

bool isReloadingCurInfoSet = true
bool showLoadingMsgOnNextReset = true

string[] infoSets

event OnInit()
    RegisterModule("$sab_mcm_page_statistics", 8)
endevent

Event OnPageInit()
    infoSets = new string[3]
    infoSets[0] = "$sab_mcm_stats_menu_statspage_loc_statuses"
    infoSets[1] = "$sab_mcm_stats_menu_statspage_faction_statuses"
    infoSets[2] = "$sab_mcm_stats_menu_statspage_debug"
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

    ; show a loading message to look a bit less like we froze
    if showLoadingMsgOnNextReset
        AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
        showLoadingMsgOnNextReset = false
        ForcePageReset()
        return
    endif

    if isReloadingCurInfoSet
        jdisplayedDataArray = jValue.releaseAndRetain(jdisplayedDataArray, jArray.object(), "ShoutAndBlade")
    endif

    if curInfoSetBeingShown == 0 ; location statuses
        SetupLocationStatistics()    
    elseif curInfoSetBeingShown == 1 ; faction statuses
        SetupFactionStatistics()
    elseif curInfoSetBeingShown == 2 ; debug
        SetupDebugStatistics()
    endif

    debug.Trace("numstatspages: " + numStatsPages)
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
                JMap.setStr(jNewEntryMap, "garrisonPower", locScript.currentAutocalcPower)
                JMap.setStr(jNewEntryMap, "isContested", locScript.IsBeingContested())
            endif
        endwhile

        ; calculate how many pages we'll need to show the content
        curStatsPage = 0
        numStatsPages = Math.Ceiling((jArray.count(jdisplayedDataArray) as float) / entriesPerPage)
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
        numStatsPages = Math.Ceiling((jArray.count(jdisplayedDataArray) as float) / entriesPerPage)
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

Function SetupDebugStatistics()
    SetCursorFillMode(LEFT_TO_RIGHT)

    if isReloadingCurInfoSet
        curStatsPage = 0
        numStatsPages = 1
    endif

    SAB_CrowdReducer crowdReducer = MainPage.MainQuest.CrowdReducer

    AddTextOptionST("STATS_DISPLAY___NEARBYCMDERS", "$sab_mcm_stats_menu_statspage_debug_nearbycmders", crowdReducer.NumNearbyCmders)
    AddTextOptionST("STATS_DISPLAY___NEARBYLOCS_ALIAS", "$sab_mcm_stats_menu_statspage_debug_nearbylocs_aliases", MainPage.MainQuest.SpawnersUpdater.LocationUpdater.numActives)
    AddTextOptionST("STATS_DISPLAY___NEARBYLOCS_ALIAS_TOPFILLEDINDEX", "$sab_mcm_stats_menu_statspage_debug_nearbylocs_topfilledindex", MainPage.MainQuest.SpawnersUpdater.LocationUpdater.GetTopIndex())
    AddTextOptionST("STATS_DISPLAY___NEARBYCMDERS_ALIAS", "$sab_mcm_stats_menu_statspage_debug_nearbycmders_aliases", MainPage.MainQuest.SpawnersUpdater.CmderUpdater.numActives)

    int nearbyCmdersTopFilledIndex = MainPage.MainQuest.SpawnersUpdater.CmderUpdater.GetTopIndex()
    AddTextOptionST("STATS_DISPLAY___NEARBYCMDERS_ALIAS_TOPFILLEDINDEX", "$sab_mcm_stats_menu_statspage_debug_nearbycmders_topfilledindex", nearbyCmdersTopFilledIndex)

    FormList cmdersList = crowdReducer.NearbyCmdersList
    Actor plyrRef = game.GetPlayer()
    int i = crowdReducer.NumNearbyCmders
    ; show all cmders in list
    While i > 0
        i -= 1
        ObjectReference cmderRef = cmdersList.GetAt(i) as ObjectReference
        AddTextOptionST("STATS_DISPLAY___NEARBYCMDERS" + i, cmderRef.GetFormID(), plyrRef.GetDistance(cmderRef))
    EndWhile

    i = AddEmptyOption()

    if i % 2 == 0
        AddEmptyOption()
    endif

    ; show all cmders in nearbies alias list (we expect - and hope! - it's less than 128)
    i = nearbyCmdersTopFilledIndex
    SAB_UpdatedReferenceAlias[] nearbyCmderAliases = MainPage.MainQuest.SpawnersUpdater.CmderUpdater.GetAliasesArray(0)
    While i > 0
        i -= 1
        SAB_UpdatedReferenceAlias cmderAlias = nearbyCmderAliases[i]
        SAB_CommanderScript cmderRef = cmderAlias as SAB_CommanderScript
        if cmderRef && cmderRef.IsValid()
            AddTextOptionST("STATS_DISPLAY___NEARBYCMDER_ALIAS" + i, cmderRef, i + " - dist: " + plyrRef.GetDistance(cmderRef.GetReference()))
        elseif cmderAlias
            AddTextOptionST("STATS_DISPLAY___NEARBYCMDER_ALIAS" + i, cmderAlias, i + " - valid alias")
        else
            AddTextOptionST("STATS_DISPLAY___NEARBYCMDER_ALIAS" + i, cmderAlias, i + " - none?")
        endif
        
    EndWhile

    MainPage.MainQuest.SpawnersUpdater.CmderUpdater.DebugPrintVacantSlotsInfo()
    
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
        showLoadingMsgOnNextReset = true
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
        int index = 0
        SetMenuOptionValueST(infoSets[index])
		curInfoSetBeingShown = index
        isReloadingCurInfoSet = true
        showLoadingMsgOnNextReset = true
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
        showLoadingMsgOnNextReset = true
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
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
        float value = 1.0
        float actualValue = value - 1

        curStatsPage = actualValue as int

		SetSliderOptionValueST(value)
        ForcePageReset()
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