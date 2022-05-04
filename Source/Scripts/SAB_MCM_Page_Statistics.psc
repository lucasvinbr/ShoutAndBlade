scriptname SAB_MCM_Page_Statistics extends nl_mcm_module
{ MCM page for displaying various informations about the mod's current status }

SAB_MCM Property MainPage Auto

int curStatsTypeBeingShown = 0
int curStatsPage = 0

string[] statPages

event OnInit()
    RegisterModule("$sab_mcm_page_statistics", 6)
endevent

Event OnPageInit()
    statPages = new string[2]
    statPages[0] = "$sab_mcm_stats_menu_statspage_loc_ownerships"
    statPages[1] = "$sab_mcm_stats_menu_statspage_faction_statuses"
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

string Function GetStatPageName(int statPageIndex)
    if statPageIndex == 0
        return "$sab_mcm_mytroops_menu_ourdest_undefined"
    endif
EndFunction


Function SetupPage()

    if MainPage.isLoadingData || !MainPage.MainQuest.HasInitialized
        AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
        return
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)
    
    AddMenuOptionST("STATS_CUR_PAGE", "$sab_mcm_stats_menu_statspage", statPages[curStatsTypeBeingShown])

    AddEmptyOption()

    SAB_UnitDataHandler unitDataHandler = MainPage.MainQuest.UnitDataHandler

    if curStatsTypeBeingShown == 0 ; location statuses
        SetCursorFillMode(LEFT_TO_RIGHT)
        SAB_LocationScript[] locs = MainPage.MainQuest.LocationDataHandler.EnabledLocations
        int locIndex = locs.Length

        while locIndex > 0
            locIndex -= 1
            SAB_LocationScript locScript = locs[locIndex]
            AddHeaderOption(locScript.ThisLocation.GetName())
            AddEmptyOption()
            string ownerFacName = "$sab_mcm_locationedit_ownership_option_neutral"
            if locScript.factionScript != None
                ownerFacName = locScript.factionScript.GetFactionName()
            endif
            AddTextOptionST("STATS_DISPLAY___LOCOWNER", "$sab_mcm_stats_menu_statspage_loc_statuses_owner", ownerFacName)
            AddTextOptionST("STATS_DISPLAY___LOCUNITCOUNT", "$sab_mcm_stats_menu_statspage_loc_statuses_unitcount", locScript.totalOwnedUnitsAmount)
            AddTextOptionST("STATS_DISPLAY___LOCPOWER", "$sab_mcm_stats_menu_statspage_loc_statuses_power", unitDataHandler.GetTotalAutocalcPowerFromArmy(locScript.jOwnedUnitsMap))
            AddToggleOptionST("STATS_DISPLAY___LOCISCONTESTED", "$sab_mcm_stats_menu_statspage_loc_statuses_contested", locScript.IsBeingContested())
        endwhile
    
    elseif curStatsTypeBeingShown == 1 ; faction statuses
        SetCursorFillMode(LEFT_TO_RIGHT)
        SAB_FactionScript[] factions = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests
        int facIndex = factions.Length

        while facIndex > 0
            facIndex -= 1
            SAB_FactionScript facScript = factions[facIndex]

            if jMap.hasKey(facScript.jFactionData, "enabled")
                AddHeaderOption(facScript.GetFactionName())
                AddEmptyOption()
                
                AddTextOptionST("STATS_DISPLAY___FACGOLD", "$sab_mcm_stats_menu_statspage_faction_statuses_gold", jMap.getInt(facScript.jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold())))
                AddTextOptionST("STATS_DISPLAY___FACLOCCOUNT", "$sab_mcm_stats_menu_statspage_faction_statuses_num_locs", jValue.count(facScript.jOwnedLocationIndexesArray))
                AddTextOptionST("STATS_DISPLAY___FACNUMCMDERS", "$sab_mcm_stats_menu_statspage_faction_statuses_num_cmders", facScript.GetNumActiveCommanders())
                AddToggleOptionST("STATS_DISPLAY___FACARMYPOWER", "$sab_mcm_stats_menu_statspage_faction_statuses_power", facScript.GetTotalActiveCommandersAutocalcPower())
            endif
            
        endwhile
    endif

    
EndFunction



state STATS_CUR_PAGE

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(curStatsTypeBeingShown)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(statPages)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		SetMenuOptionValueST(statPages[index])
        curStatsTypeBeingShown = index
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
        int index = 0
        SetMenuOptionValueST(statPages[index])
		curStatsTypeBeingShown = index
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_stats_menu_statspage_desc")
	endEvent
    
    
endstate

state STATS_DISPLAY

    event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
	endEvent

endstate