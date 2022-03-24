scriptname SAB_MCM_Page_Player_Manage extends nl_mcm_module

SAB_MCM Property MainPage Auto


string[] editedFactionIdentifiersArray
int playerFactionIndex = -1
int jPlayerFactionData = 0
int jFacVanillaRelationsMap = 0

Form Property Gold001 Auto


event OnInit()
    RegisterModule("$sab_mcm_page_mytroops", 0)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[26]

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_mytroops")
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

    if playerFactionIndex > 0
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


    AddEmptyOption()
    AddTextOptionST("PLYR_DATA_SAVE", "$sab_mcm_factionedit_button_save", "")
    AddTextOptionST("PLYR_DATA_LOAD", "$sab_mcm_factionedit_button_load", "")
    
EndFunction

state PLYR_DATA_SAVE
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/factionData.json"
        JValue.writeToFile(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, filePath)
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

state PLYR_DATA_LOAD
    event OnSelectST(string state_id)
        MainPage.MainQuest.SpawnerScript.HideCustomizationGuy()
        string filePath = JContainers.userDirectory() + "SAB/factionData.json"
        MainPage.isLoadingData = true
        int jReadData = JValue.readFromFile(filePath)
        if jReadData != 0
            ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()
            MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray = JValue.releaseAndRetain(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, jReadData, "ShoutAndBlade")
            MainPage.MainQuest.FactionDataHandler.EnsureArrayCounts()
            MainPage.MainQuest.FactionDataHandler.UpdateAllFactionQuestsAccordingToJMap()
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


state PLYR_CUR_FAC

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(playerFactionIndex + 1)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.FactionDataHandler.SetupStringArrayWithOwnershipIdentifiers(editedFactionIdentifiersArray)
		SetMenuDialogOptions(editedFactionIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		SetMenuOptionValueST(editedFactionIdentifiersArray[index])

        int ownerIndex = index - 1
        Actor playerActor = Game.GetPlayer()

        ; make player leave previous faction, then join the new one
        if playerFactionIndex > -1
            SAB_FactionScript previousFac = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[playerFactionIndex]
            previousFac.RemoveActorFromOurFaction(playerActor)
        endif

        SAB_FactionScript newFac = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[ownerIndex]
        newFac.AddActorToOurFaction(playerActor)

        ;TODO remove this test once we've tested hehe
        playerActor.RemoveItem(Gold001, 1)

        playerFactionIndex = ownerIndex
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