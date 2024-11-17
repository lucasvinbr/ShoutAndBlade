scriptname SAB_MCM_Page_Faction_Tracker extends nl_mcm_module

SAB_MCM Property MainPage Auto


string[] editedFactionIdentifiersArray
int trackedFactionIndex = -1
int jTrackedFactionData = 0
int jFacVanillaRelationsMap = 0

Form Property Gold001 Auto


event OnInit()
    RegisterModule("$sab_mcm_page_factiontracker", 2)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[101]

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_factiontracker")
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

    string trackedFacName = "$sab_mcm_locationedit_ownership_option_neutral"

    if trackedFactionIndex >= 0
        jTrackedFactionData = jArray.getObj(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, trackedFactionIndex)
        ; set up fac if it doesn't exist
        if jTrackedFactionData == 0
            jTrackedFactionData = jMap.object()
            JArray.setObj(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, trackedFactionIndex, jTrackedFactionData)
        endif

        trackedFacName = jMap.getStr(jTrackedFactionData, "Name", "Faction")
    endif
    
    
    AddMenuOptionST("PLYR_CUR_FAC", "$sab_mcm_vanillafacrel_menu_selectedfac", trackedFacName)

    AddEmptyOption()

    if trackedFactionIndex >= 0
        SAB_FactionScript facScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[trackedFactionIndex]

        ; int facGold = jMap.getInt(facScript.jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))
        int numCmders = facScript.GetNumActiveCommanders()

        ;AddTextOptionST("PLYR_CUR_FAC_NUM_GOLD", "$sab_mcm_myfaction_numgold", facGold)
        AddTextOptionST("PLYR_CUR_FAC_NUM_CMDERS", "$sab_mcm_myfaction_numcmders", numCmders)

        AddEmptyOption()

        int i = -1
        ; faction's allies and enemies
        SAB_DiplomacyDataHandler diploHandler = facScript.DiplomacyDataHandler
        int jAlliedFacsArray = diploHandler.GetAlliedFactionsOfTargetFac(trackedFactionIndex)
        int jEnemyFacsArray = diploHandler.GetEnemyFactionsOfTargetFac(trackedFactionIndex)
        int jFacDatasArray = MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray

        AddHeaderOption("$sab_mcm_factiontracker_header_alliedfacs")
        i = jArray.count(jAlliedFacsArray)
        While i > 0
            i -= 1

            int allyFacIndex = jArray.getInt(jAlliedFacsArray, i, -1)
            
            if allyFacIndex >= 0
                int facData = jArray.getObj(jFacDatasArray, allyFacIndex)
                string alliedFacName = jMap.getStr(facData, "Name", "Faction")

                AddTextOptionST("PLYR_CUR_FAC_ALLIEDLIST___" + allyFacIndex, alliedFacName, "")
            endif
            
        EndWhile
        jValue.release(jAlliedFacsArray)

        AddHeaderOption("$sab_mcm_factiontracker_header_enemyfacs")
        i = jArray.count(jEnemyFacsArray)
        While i > 0
            i -= 1

            int enemyFacIndex = jArray.getInt(jEnemyFacsArray, i, -1)
            
            if enemyFacIndex >= 0
                int facData = jArray.getObj(jFacDatasArray, enemyFacIndex)
                string enemyFacName = jMap.getStr(facData, "Name", "Faction")

                AddTextOptionST("PLYR_CUR_FAC_ENEMYLIST___" + enemyFacIndex, enemyFacName, "")
            endif
            
        EndWhile
        jValue.release(jEnemyFacsArray)


        SetCursorPosition(1)

        SAB_LocationDataHandler locHandler = facScript.LocationDataHandler

        ; faction's locations
        i = jArray.count(facScript.jOwnedLocationIndexesArray)
        AddTextOptionST("PLYR_CUR_FAC_NUM_LOCS", "$sab_mcm_myfaction_numlocs", i)
        While i > 0
            i -= 1

            int locIndex = jArray.getInt(facScript.jOwnedLocationIndexesArray, i, -1)
            
            if locIndex >= 0
                string locName = locHandler.Locations[locIndex].GetLocName()

                AddTextOptionST("PLYR_CUR_FAC_OWNEDLIST___" + locName, locName, "")
            endif
            
        EndWhile

        AddEmptyOption()

    endif

EndFunction

; adds MCM entries for the target location (if not null):
; it should show the location's name, the current owner and whether it's under attack or not
Function AddTargetLocationInfo(SAB_LocationScript locScript, string entryStateId, string baseEntryName)
    AddTextOptionST(entryStateId, baseEntryName, GetLocationNameForOurDests(locScript))
    if locScript != None
        AddTextOptionST(entryStateId + "_owner", "$sab_mcm_myfaction_targetloc_owner", locScript.GetOwnerFactionName())
        AddToggleOptionST(entryStateId + "_iscontested", "$sab_mcm_myfaction_targetloc_iscontested", locScript.IsBeingContested(), OPTION_FLAG_DISABLED)
    endif
EndFunction

event OnHighlightST(string state_id)
    MainPage.ToggleQuickHotkey(true)
endEvent

string Function GetLocationNameForOurDests(SAB_LocationScript locScript)
    if locScript != None
        return locScript.GetLocName()
    else
        return "$sab_mcm_mytroops_menu_ourdest_undefined"
    endif
EndFunction


state PLYR_CUR_FAC_ALLIEDLIST

    event OnSelectST(string state_id)
        int jFactionDatasArray = MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray

        int clickedFacIndex = state_id as int

        if clickedFacIndex >= 0
            trackedFactionIndex = clickedFacIndex
            ForcePageReset()
        endif
        
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factiontracker_alliedfac_desc")
	endEvent
    
endstate

state PLYR_CUR_FAC_ENEMYLIST

    event OnSelectST(string state_id)
        int jFactionDatasArray = MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray

        int clickedFacIndex = state_id as int

        if clickedFacIndex >= 0
            trackedFactionIndex = clickedFacIndex
            ForcePageReset()
        endif
        
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factiontracker_enemyfac_desc")
	endEvent
    
endstate

state PLYR_CUR_FAC

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(trackedFactionIndex + 1)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.FactionDataHandler.SetupStringArrayWithOwnershipIdentifiers(editedFactionIdentifiersArray, "-")
		SetMenuDialogOptions(editedFactionIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		SetMenuOptionValueST(editedFactionIdentifiersArray[index])

        int ownerIndex = index - 1

        trackedFactionIndex = ownerIndex

        ForcePageReset()
        ; jMap.setInt(jLocDataMap, "OwnerFactionIndex", ownerIndex)
	endEvent

	event OnDefaultST(string state_id)
		SetMenuOptionValueST("-")

        int ownerIndex = -1

        trackedFactionIndex = ownerIndex
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factiontracker_menu_set_tracked_fac_desc")
	endEvent
    
    
endstate

state PLYR_CUR_FAC_NUM_LOCS
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factiontracker_numlocs_desc")
	endEvent
endstate

state PLYR_CUR_FAC_NUM_CMDERS
	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_factiontracker_numcmders_desc")
	endEvent
endstate
