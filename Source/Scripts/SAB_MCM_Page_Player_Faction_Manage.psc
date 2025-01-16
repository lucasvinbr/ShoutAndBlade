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

string[] Function GetLocAsDestOptionsArray()
    
    string[] setLocAsDestOptions = new string[4]
    setLocAsDestOptions[0] = "$sab_mcm_myfaction_set_loc_as_dest_cancel"
    setLocAsDestOptions[1] = "$sab_mcm_myfaction_set_loc_as_dest_a"
    setLocAsDestOptions[2] = "$sab_mcm_myfaction_set_loc_as_dest_b"
    setLocAsDestOptions[3] = "$sab_mcm_myfaction_set_loc_as_dest_c"
    return setLocAsDestOptions

EndFunction

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

        int playerGold = Game.GetPlayer().GetItemCount(MainPage.MainQuest.PlayerDataHandler.Gold001)

        float relValue = MainPage.MainQuest.DiplomacyHandler.GetPlayerRelationWithFac(playerFactionIndex)

        AddTextOptionST("PLYR_CUR_FAC_REL_VALUE", "$sab_mcm_myfaction_relation", relValue)

        AddTextOptionST("PLYR_CUR_FAC_NUM_GOLD", "$sab_mcm_myfaction_numgold", facGold)

        AddTextOptionST("PLYR_CUR_FAC_TAKE_GOLD", "$sab_mcm_myfaction_takegold", "")
        AddTextOptionST("PLYR_CUR_FAC_GIVE_GOLD", "$sab_mcm_myfaction_givegold", "")

        AddEmptyOption()

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
            SAB_LocationScript locScript = locHandler.GetLocationByIndex(locIndex)
            
            if locIndex >= 0 && locScript != None
                string locName = locScript.GetLocName()

                if playerControlsFacOrders
                    AddMenuOptionST("PLYR_CUR_FAC_OWNEDLIST_PICKABLE___" + locIndex, locName, "")
                else
                    AddTextOptionST("PLYR_CUR_FAC_OWNEDLIST___" + locName, locName, "")
                endif
            endif
            
        EndWhile

        ; defense targets
        AddHeaderOption("$sab_mcm_myfaction_defensetargets")
        int jDefenseTargetsArray = facScript.FindDefenseTargets()

        i = jArray.count(jDefenseTargetsArray)

        While i > 0
            i -= 1

            int locIndex = jArray.getInt(jDefenseTargetsArray, i, -1)
            SAB_LocationScript locScript = locHandler.GetLocationByIndex(locIndex)
            
            if locIndex >= 0 && locScript != None
                string locName = locScript.GetLocName()
                string reason = "$sab_mcm_myfaction_defend_smallgarrison"
                if locScript.IsBeingContested()
                    reason = "$sab_mcm_myfaction_defend_underattack"
                endif

                if playerControlsFacOrders
                    AddMenuOptionST("PLYR_CUR_FAC_DEFTARGET_PICKABLE___" + locIndex, locName, reason)
                else
                    AddTextOptionST("PLYR_CUR_FAC_DEFTARGET___" + locName, locName, reason)
                endif
                
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
            SAB_LocationScript atkTargetLocScript = locHandler.GetLocationByIndex(locIndex)
            
            if locIndex >= 0 && atkTargetLocScript != None
                string locName = atkTargetLocScript.GetLocName()
                if jArray.findStr(jAlreadyAddedTargetsArray, locName) == -1
                    
                    if playerControlsFacOrders
                        AddMenuOptionST("PLYR_CUR_FAC_ATKTARGET_PICKABLE___" + locIndex, locName, GetLocationNameForOurDests(atkTargetLocScript))
                    else
                        AddTextOptionST("PLYR_CUR_FAC_ATKTARGET___" + locName, locName, GetLocationNameForOurDests(atkTargetLocScript))
                    endif
                    
                    AddTextOptionST("PLYR_CUR_FAC_ATKTARGET___" + locName + "_owner", "$sab_mcm_myfaction_targetloc_owner", atkTargetLocScript.GetOwnerFactionName())
                    AddToggleOptionST("PLYR_CUR_FAC_ATKTARGET___" + locName + "_iscontested", "$sab_mcm_myfaction_targetloc_iscontested", atkTargetLocScript.IsBeingContested(), OPTION_FLAG_DISABLED)
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

Function MenuSetFacDest(string state_id, int index)
    ; find loc by index, then set target dest in fac script
    SAB_LocationDataHandler locHandler = MainPage.MainQuest.LocationDataHandler
    int curLocIndex = state_id as int
    SAB_LocationScript targetLoc = locHandler.GetLocationByIndex(curLocIndex)

    string pickedDestType = "cancel"
    if index == 1
        pickedDestType = "a"
    elseif index == 2
        pickedDestType = "b"
    elseif index == 3
        pickedDestType = "c"
    endif

    If pickedDestType == "cancel"
        return
    EndIf

    SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
    facScript.PlayerSetFacDestination(pickedDestType, targetLoc)

    ForcePageReset()
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
        SAB_LocationScript targetLoc = locHandler.GetEnabledLocationByIndex(index)

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

state PLYR_CUR_FAC_REL_VALUE
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_myfaction_relation_desc")
	endEvent
endstate

state PLYR_CUR_FAC_TAKE_GOLD
    event OnSelectST(string state_id)
        Form gold = MainPage.MainQuest.PlayerDataHandler.Gold001
        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
        int facGold = jMap.getInt(facScript.jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))
        int goldAmount = 1000

        bool isAlly = MainPage.MainQuest.DiplomacyHandler.IsFactionAllyOfPlayer(playerFactionIndex)

        If facGold >= goldAmount
            if isAlly
                facScript.AddGold(-goldAmount)
                Game.GetPlayer().AddItem(gold, goldAmount)
                MainPage.MainQuest.DiplomacyHandler.AddOrSubtractPlayerRelationWithFac(playerFactionIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerTookGold", -0.1))
                ForcePageReset()
            else
                ShowMessage("$sab_mcm_myfaction_popup_cant_takegold_not_friendly", false)
            endif
        else
            ShowMessage("$sab_mcm_myfaction_popup_cant_takegold_not_enough", false)
        endif

        int playerGold = Game.GetPlayer().GetItemCount(gold)

	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_myfaction_takegold_desc")
	endEvent
endstate

state PLYR_CUR_FAC_GIVE_GOLD
    event OnSelectST(string state_id)
        Form gold = MainPage.MainQuest.PlayerDataHandler.Gold001
        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
        int playerGold = Game.GetPlayer().GetItemCount(gold)
        int goldAmount = 1000

        If playerGold >= goldAmount
            facScript.AddGold(goldAmount)
            Game.GetPlayer().RemoveItem(gold, goldAmount)
            MainPage.MainQuest.DiplomacyHandler.AddOrSubtractPlayerRelationWithFac(playerFactionIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerGaveGold", 0.1))
            ForcePageReset()
        else
            ShowMessage("$sab_mcm_myfaction_popup_cant_givegold_not_enough", false)
        endif

	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_myfaction_givegold_desc")
	endEvent
endstate

state PLYR_CUR_FAC_ATKTARGET
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_attacktargets_desc")
	endEvent
endstate

state PLYR_CUR_FAC_ATKTARGET_PICKABLE
    event OnMenuOpenST(string state_id)
		SetMenuDialogDefaultIndex(0)
        SetMenuDialogStartIndex(0)
		SetMenuDialogOptions(GetLocAsDestOptionsArray())
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		MenuSetFacDest(state_id, index)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_attacktargets_pickable_desc")
	endEvent
endstate

state PLYR_CUR_FAC_DEFTARGET
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_defensetargets_desc")
	endEvent
endstate

state PLYR_CUR_FAC_DEFTARGET_PICKABLE
    event OnMenuOpenST(string state_id)
		SetMenuDialogDefaultIndex(0)
        SetMenuDialogStartIndex(0)
		SetMenuDialogOptions(GetLocAsDestOptionsArray())
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		MenuSetFacDest(state_id, index)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_defensetargets_pickable_desc")
	endEvent
endstate

state PLYR_CUR_FAC_OWNEDLIST
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_ownedloc_desc")
	endEvent
endstate

state PLYR_CUR_FAC_OWNEDLIST_PICKABLE
    event OnMenuOpenST(string state_id)
		SetMenuDialogDefaultIndex(0)
        SetMenuDialogStartIndex(0)
		SetMenuDialogOptions(GetLocAsDestOptionsArray())
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		MenuSetFacDest(state_id, index)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_myfaction_ownedloc_pickable_desc")
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