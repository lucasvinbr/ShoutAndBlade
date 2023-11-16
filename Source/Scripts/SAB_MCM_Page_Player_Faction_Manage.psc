scriptname SAB_MCM_Page_Player_Faction_Manage extends nl_mcm_module

SAB_MCM Property MainPage Auto


string[] editedFactionIdentifiersArray
int playerFactionIndex = -1
int jPlayerFactionData = 0
int jFacVanillaRelationsMap = 0
bool playerControlsFacOrders = false

Form Property Gold001 Auto


event OnInit()
    RegisterModule("$sab_mcm_page_myfaction", 1)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[101]

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_myfaction")
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

    string playerFacName = "$sab_mcm_locationedit_ownership_option_neutral"

    if playerFactionIndex >= 0
        jPlayerFactionData = jArray.getObj(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, playerFactionIndex)
        ; set up fac if it doesn't exist
        if jPlayerFactionData == 0
            jPlayerFactionData = jMap.object()
            JArray.setObj(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, playerFactionIndex, jPlayerFactionData)
        endif

        playerFacName = jMap.getStr(jPlayerFactionData, "Name", "Faction")
    endif
    
    
    AddMenuOptionST("PLYR_CUR_FAC", "$sab_mcm_vanillafacrel_menu_selectedfac", playerFacName)

    AddEmptyOption()

    if playerFactionIndex >= 0
        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]

        int facGold = jMap.getInt(facScript.jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))
        int numCmders = facScript.GetNumActiveCommanders()

        AddTextOptionST("PLYR_CUR_FAC_NUM_GOLD", "$sab_mcm_myfaction_numgold", facGold)
        AddTextOptionST("PLYR_CUR_FAC_NUM_CMDERS", "$sab_mcm_myfaction_numcmders", numCmders)

        AddToggleOptionST("PLYR_CUR_FAC_PLYR_CONTROLS", "$sab_mcm_myfaction_playercontrols", playerControlsFacOrders)

        ; show faction's move destinations
        AddTargetLocationInfo(facScript.destinationScript_A, "PLYR_CUR_FAC_DEST___A", "$sab_mcm_mytroops_menu_ourdest_a", true)
        AddTargetLocationInfo(facScript.destinationScript_B, "PLYR_CUR_FAC_DEST___B", "$sab_mcm_mytroops_menu_ourdest_b", true)
        AddTargetLocationInfo(facScript.destinationScript_C, "PLYR_CUR_FAC_DEST___C", "$sab_mcm_mytroops_menu_ourdest_c", true)

        SetCursorPosition(1)

        SAB_LocationDataHandler locHandler = facScript.LocationDataHandler

        ; faction's locations
        int i = jArray.count(facScript.jOwnedLocationIndexesArray)
        AddTextOptionST("PLYR_CUR_FAC_NUM_LOCS", "$sab_mcm_myfaction_numlocs", i)
        While i > 0
            i -= 1

            int locIndex = jArray.getInt(facScript.jOwnedLocationIndexesArray, i, -1)
            
            if locIndex >= 0
                string locName = locHandler.Locations[locIndex].GetLocName()

                AddTextOptionST("PLYR_CUR_FAC_OWNEDLIST___" + locName, locName, "")
            endif
            
        EndWhile

        ; defense targets
        AddHeaderOption("$sab_mcm_myfaction_defensetargets")
        int jDefenseTargetsArray = facScript.FindDefenseTargets()

        i = jArray.count(jDefenseTargetsArray)

        While i > 0
            i -= 1

            int locIndex = jArray.getInt(jDefenseTargetsArray, i, -1)
            
            if locIndex >= 0
                string locName = locHandler.Locations[locIndex].GetLocName()
                string reason = "$sab_mcm_myfaction_defend_smallgarrison"
                if locHandler.Locations[locIndex].IsBeingContested()
                    reason = "$sab_mcm_myfaction_defend_underattack"
                endif

                AddTextOptionST("PLYR_CUR_FAC_DEFTARGET___" + locName, locName, reason)
            endif
            
        EndWhile

        jValue.release(jDefenseTargetsArray)


        AddEmptyOption()
        ; attack targets
        AddHeaderOption("$sab_mcm_myfaction_attacktargets")
        int jAttackTargetsArray = facScript.FindAttackTargets()

        int jAlreadyAddedTargetsArray = jArray.object()
        i = jArray.count(jAttackTargetsArray)

        While i > 0
            i -= 1

            int locIndex = jArray.getInt(jAttackTargetsArray, i, -1)
            
            if locIndex >= 0
                string locName = locHandler.Locations[locIndex].GetLocName()
                if jArray.findStr(jAlreadyAddedTargetsArray, locName) == -1
                    AddTargetLocationInfo(locHandler.Locations[locIndex], "PLYR_CUR_FAC_ATKTARGET___" + locName, locName, false)
                    jArray.addStr(jAlreadyAddedTargetsArray, locName)
                endif
            endif
        EndWhile

        jValue.release(jAttackTargetsArray)
        JValue.release(jAlreadyAddedTargetsArray)
    endif

EndFunction

; adds MCM entries for the target location (if not null):
; it should show the location's name, the current owner and whether it's under attack or not
Function AddTargetLocationInfo(SAB_LocationScript locScript, string entryStateId, string baseEntryName, bool editableIfPlayerControls)
    if playerControlsFacOrders && editableIfPlayerControls
        AddMenuOptionST(entryStateId, baseEntryName, GetLocationNameForOurDests(locScript))
    else
        AddTextOptionST(entryStateId, baseEntryName, GetLocationNameForOurDests(locScript))
    endif
    
    if locScript != None
        AddTextOptionST(entryStateId + "_owner", "$sab_mcm_myfaction_targetloc_owner", locScript.GetOwnerFactionName())
        AddToggleOptionST(entryStateId + "_iscontested", "$sab_mcm_myfaction_targetloc_iscontested", locScript.IsBeingContested(), OPTION_FLAG_DISABLED)
    endif
EndFunction

event OnHighlightST(string state_id)
    MainPage.ToggleQuickHotkey(true)
    SetInfoText("$sab_mcm_mytroops_menu_ourdest_undefined")
endEvent

string Function GetLocationNameForOurDests(SAB_LocationScript locScript)
    if locScript != None
        return locScript.GetLocName()
    else
        return "$sab_mcm_mytroops_menu_ourdest_undefined"
    endif
EndFunction


state PLYR_CUR_FAC_DEST
    event OnMenuOpenST(string state_id)
		SetMenuDialogDefaultIndex(0)

        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
        SAB_LocationDataHandler locHandler = MainPage.MainQuest.LocationDataHandler
        int curLocIndex = 0

        if state_id == "a"
            curLocIndex = locHandler.GetEnabledLocationIndex(facScript.destinationScript_A)
        elseif state_id == "b"
            curLocIndex = locHandler.GetEnabledLocationIndex(facScript.destinationScript_B)
        elseif state_id == "c"
            curLocIndex = locHandler.GetEnabledLocationIndex(facScript.destinationScript_C)
        endif

        if curLocIndex < 0
            curLocIndex = 0
        endif

        SetMenuDialogStartIndex(curLocIndex)

        string[] editedLocationIdentifiersArray = locHandler.CreateStringArrayWithEnabledLocationIdentifiers()

		SetMenuDialogOptions(editedLocationIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		; find loc by index, then set target dest in fac script
        SAB_LocationDataHandler locHandler = MainPage.MainQuest.LocationDataHandler
        SAB_LocationScript targetLoc = locHandler.EnabledLocations[index]

        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
        facScript.PlayerSetFacDestination(state_id, targetLoc)

        SetMenuOptionValueST(targetLoc.GetLocName())
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_menu_ourdest_desc")
	endEvent
endstate

state PLYR_CUR_FAC_NUM_LOCS
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_numlocs_desc")
	endEvent
endstate

state PLYR_CUR_FAC_NUM_CMDERS
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_myfaction_numcmders_desc")
	endEvent
endstate

state PLYR_CUR_FAC_NUM_GOLD
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_myfaction_numgold_desc")
	endEvent
endstate

state PLYR_CUR_FAC_ATKTARGET
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_attacktargets_desc")
	endEvent
endstate

state PLYR_CUR_FAC_DEFTARGET
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_defensetargets_desc")
	endEvent
endstate

state PLYR_CUR_FAC_PLYR_CONTROLS
    event OnSelectST(string state_id)
        playerControlsFacOrders = !playerControlsFacOrders

        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
        facScript.playerIsControllingDestinations = playerControlsFacOrders
        SetToggleOptionValueST(playerControlsFacOrders)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        playerControlsFacOrders = false

        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
        facScript.playerIsControllingDestinations = playerControlsFacOrders
        SetToggleOptionValueST(playerControlsFacOrders)
        ForcePageReset()
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_playercontrols_desc")
	endEvent
endstate

state PLYR_CUR_FAC

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(playerFactionIndex + 1)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.FactionDataHandler.SetupStringArrayWithOwnershipIdentifiers(editedFactionIdentifiersArray, "$sab_mcm_locationedit_ownership_option_neutral")
		SetMenuDialogOptions(editedFactionIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		SetMenuOptionValueST(editedFactionIdentifiersArray[index])

        int ownerIndex = index - 1
        Actor playerActor = Game.GetPlayer()

        ; make player leave previous faction, then join the new one
        SAB_FactionScript newFac = None

        if ownerIndex != -1
            newFac = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[ownerIndex]
        endif

        MainPage.MainQuest.PlayerDataHandler.JoinFaction(newFac)

        playerFactionIndex = ownerIndex

        ForcePageReset()
        ; jMap.setInt(jLocDataMap, "OwnerFactionIndex", ownerIndex)
	endEvent

	event OnDefaultST(string state_id)
		SetMenuOptionValueST("$sab_mcm_locationedit_ownership_option_neutral")

        int ownerIndex = -1
        Actor playerActor = Game.GetPlayer()

        ; make player leave previous faction
        if playerFactionIndex > -1
            SAB_FactionScript previousFac = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
            previousFac.RemoveActorFromOurFaction(playerActor)
        endif

        playerFactionIndex = ownerIndex
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_menu_set_player_fac_desc")
	endEvent
    
    
endstate


Function SetActualFactionRelations(string facName, int relationValue)
    Faction targetVanillaFac = MainPage.MainQuest.FactionDataHandler.GetVanillaFactionByName(facName)

    if targetVanillaFac != None
        SAB_FactionScript curFacScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
        curFacScript.SetRelationsWithFaction(targetVanillaFac, relationValue)
    endif
    
EndFunction