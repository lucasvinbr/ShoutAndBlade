scriptname SAB_MCM_Page_Player_Faction_Manage extends nl_mcm_module

SAB_MCM Property MainPage Auto


string[] editedFactionIdentifiersArray
int playerFactionIndex = -1
int jPlayerFactionData = 0
int jFacVanillaRelationsMap = 0

Form Property Gold001 Auto


event OnInit()
    RegisterModule("$sab_mcm_page_myfaction", 1)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[41]

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
        ; show faction's move destinations
        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]

        AddTextOptionST("PLYR_CUR_FAC_DEST___A", "$sab_mcm_mytroops_menu_ourdest_a", GetLocationNameForOurDests(facScript.destinationScript_A))
        AddTextOptionST("PLYR_CUR_FAC_DEST___B", "$sab_mcm_mytroops_menu_ourdest_b", GetLocationNameForOurDests(facScript.destinationScript_B))
        AddTextOptionST("PLYR_CUR_FAC_DEST___C", "$sab_mcm_mytroops_menu_ourdest_c", GetLocationNameForOurDests(facScript.destinationScript_C))

        SetCursorPosition(1)

        ; faction's locations
        AddTextOptionST("PLYR_CUR_FAC_NUM_LOCS", "$sab_mcm_myfaction_numlocs", jArray.count(facScript.jOwnedLocationIndexesArray))
        

        ; defense targets
        AddHeaderOption("$sab_mcm_myfaction_defensetargets")
        int jDefenseTargetsArray = facScript.FindDefenseTargets()

        int i = jArray.count(jDefenseTargetsArray)
        SAB_LocationDataHandler locHandler = facScript.LocationDataHandler

        While i > 0
            i -= 1

            int locIndex = jArray.getInt(jDefenseTargetsArray, i, -1)
            
            if locIndex >= 0
                string locName = locHandler.Locations[locIndex].ThisLocation.GetName()
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

        i = jArray.count(jAttackTargetsArray)

        While i > 0
            i -= 1

            int locIndex = jArray.getInt(jAttackTargetsArray, i, -1)
            
            if locIndex >= 0
                string locName = locHandler.Locations[locIndex].ThisLocation.GetName()
                AddTextOptionST("PLYR_CUR_FAC_ATKTARGET___" + locName, locName, "")
            endif
            
        EndWhile

        jValue.release(jAttackTargetsArray)
    endif

EndFunction

event OnHighlightST(string state_id)
    MainPage.ToggleQuickHotkey(true)
    SetInfoText("$sab_mcm_mytroops_menu_ourdest_undefined")
endEvent

string Function GetLocationNameForOurDests(SAB_LocationScript locScript)
    if locScript != None
        return locScript.ThisLocation.GetName()
    else
        return "$sab_mcm_mytroops_menu_ourdest_undefined"
    endif
EndFunction


state PLYR_CUR_FAC_DEST
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