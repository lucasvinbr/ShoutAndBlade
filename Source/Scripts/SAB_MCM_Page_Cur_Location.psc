scriptname SAB_MCM_Page_Cur_Location extends nl_mcm_module

SAB_MCM Property MainPage Auto

event OnInit()
    RegisterModule("$sab_mcm_page_cur_location", 3)
endevent

Event OnPageInit()

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_cur_location")
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

    ; show all locs in nearbies alias list (we expect - and hope! - it's less than 128)
    int i = MainPage.MainQuest.SpawnersUpdater.LocationUpdater.GetTopIndex()
    SAB_UpdatedReferenceAlias[] nearbyLocAliases = MainPage.MainQuest.SpawnersUpdater.LocationUpdater.GetAliasesArray(0)
    While i >= 0
        SAB_UpdatedReferenceAlias locAlias = nearbyLocAliases[i]
        SAB_LocationScript locref = locAlias as SAB_LocationScript
        if locref
            SetupOptionsForLoc(locref, i)
        endif
        
        i -= 1
    EndWhile
    
EndFunction

Function SetupOptionsForLoc(SAB_LocationScript loc, int locIndexInLocUpdater)
    string locName = loc.GetName()
    AddHeaderOption(locName)
    AddEmptyOption()

    AddTextOptionST("STATS_DISPLAY_OWNER_FAC___" + locIndexInLocUpdater, "$sab_mcm_curloc_owner_fac_name", loc.GetOwnerFactionName())
    AddTextOptionST("STATS_DISPLAY_NUM_UNITS___" + locIndexInLocUpdater, "$sab_mcm_curloc_num_units", loc.totalOwnedUnitsAmount)
    AddTextOptionST("BUTTON_CLAIMLOC___" + locIndexInLocUpdater, "$sab_mcm_curloc_button_claim_loc", "")
    AddEmptyOption()

    AddEmptyOption()
    AddEmptyOption()
EndFunction



state STATS_DISPLAY_OWNER_FAC

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_curloc_owner_fac_name_desc")
	endEvent

endstate

state STATS_DISPLAY_NUM_UNITS

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_curloc_num_units_desc")
	endEvent

endstate

state BUTTON_CLAIMLOC
    event OnSelectST(string state_id)
        int locIndex = state_id as int

        SAB_FactionScript playerFac = MainPage.MainQuest.PlayerDataHandler.PlayerFaction

        if playerFac == None
            ShowMessage("$sab_mcm_curloc_popup_cant_claim_not_in_fac", false)
            return
        endif

        SAB_UpdatedReferenceAlias[] nearbyLocAliases = MainPage.MainQuest.SpawnersUpdater.LocationUpdater.GetAliasesArray(0)
        SAB_UpdatedReferenceAlias locAlias = nearbyLocAliases[locIndex]
        SAB_LocationScript locref = locAlias as SAB_LocationScript

        if locref
            if locref.factionScript == None
                locref.BeTakenByFaction(playerFac)
                MainPage.MainQuest.DiplomacyHandler.AddOrSubtractPlayerRelationWithFac(playerFac.GetFactionIndex(), JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerTookLocForUs", 0.5))
                ShowMessage("$sab_mcm_curloc_popup_zone_claimed", false)
                ForcePageReset()
            else
                if locref.factionScript == playerFac
                    ShowMessage("$sab_mcm_curloc_popup_zone_already_yours", false)
                else
                    ShowMessage("$sab_mcm_curloc_popup_cant_claim_not_neutral", false)
                endif
            endif
        else
            ShowMessage("ERROR: no loc with passed index", false)
        endif

	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_curloc_button_claim_loc_desc")
	endEvent
endstate