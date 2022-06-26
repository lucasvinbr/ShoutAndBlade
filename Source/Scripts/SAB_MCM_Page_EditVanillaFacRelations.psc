scriptname SAB_MCM_Page_EditVanillaFacRelations extends nl_mcm_module

SAB_MCM Property MainPage Auto


string[] editedFactionIdentifiersArray
int editedFactionIndex = 0
int jEditedFactionData = 0
int jFacVanillaRelationsMap = 0

string[] relationOptions


event OnInit()
    RegisterModule("$sab_mcm_page_vanillafacrel", 5)
endevent

Event OnPageInit()

    editedFactionIdentifiersArray = new string[40]
    relationOptions = new string[4]
    relationOptions[0] = "$sab_mcm_vanillafacrel_value_neutral"
    relationOptions[1] = "$sab_mcm_vanillafacrel_value_enemy"
    relationOptions[2] = "$sab_mcm_vanillafacrel_value_ally"
    relationOptions[3] = "$sab_mcm_vanillafacrel_value_friend"

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_vanillafacrel")
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

    jEditedFactionData = jArray.getObj(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, editedFactionIndex)
    ; set up fac if it doesn't exist
    if jEditedFactionData == 0
        jEditedFactionData = jMap.object()
        JArray.setObj(MainPage.MainQuest.FactionDataHandler.jSABFactionDatasArray, editedFactionIndex, jEditedFactionData)
    endif

    
    AddMenuOptionST("FAC_EDIT_CUR_FAC", "$sab_mcm_vanillafacrel_menu_selectedfac", \
        (MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex, jEditedFactionData)))

    AddEmptyOption()

    SetCursorFillMode(LEFT_TO_RIGHT)

    Faction[] vanillaFacs = MainPage.MainQuest.FactionDataHandler.VanillaFactions
    string[] vanillaFacNames = MainPage.MainQuest.FactionDataHandler.VanillaFactionDisplayNames
    
    int i = vanillaFacs.Length
    jFacVanillaRelationsMap = jMap.getObj(jEditedFactionData, "jVanillaFactionRelationsMap")

    ; set up fac relations map if it doesn't exist
    if jFacVanillaRelationsMap == 0
        jFacVanillaRelationsMap = jMap.object()
        jMap.setObj(jEditedFactionData, "jVanillaFactionRelationsMap", jFacVanillaRelationsMap)
    endif

    while i > 0
        i -= 1

        string facName = vanillaFacNames[i]
        int jRelationEntryMap = jMap.getObj(jFacVanillaRelationsMap, facName)

        AddMenuOptionST("REL_EDIT___" + facName, facName, relationOptions[jMap.getInt(jRelationEntryMap, "RelationValue")])
    endwhile

    if vanillaFacs.Length % 2 != 0
        AddEmptyOption()
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    AddEmptyOption()
    AddTextOptionST("FAC_EDIT_SAVE", "$sab_mcm_factionedit_button_save", "")
    AddTextOptionST("FAC_EDIT_LOAD", "$sab_mcm_factionedit_button_load", "")
    
EndFunction


state REL_EDIT

	event OnMenuOpenST(string state_id)
        int jRelationEntryMap = jMap.getObj(jFacVanillaRelationsMap, state_id)
		SetMenuDialogStartIndex(jMap.getInt(jRelationEntryMap, "RelationValue"))
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(relationOptions)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        int jRelationEntryMap = jMap.getObj(jFacVanillaRelationsMap, state_id)
        if jRelationEntryMap == 0
            jRelationEntryMap = jMap.object()
            jMap.setObj(jFacVanillaRelationsMap, state_id, jRelationEntryMap)
        endif

        jMap.setInt(jRelationEntryMap, "RelationValue", index)
        SetActualFactionRelations(state_id, index)
        
		SetMenuOptionValueST(relationOptions[index])
	endEvent

	event OnDefaultST(string state_id)
        int jRelationEntryMap = jMap.getObj(jFacVanillaRelationsMap, state_id)
        if jRelationEntryMap == 0
            jRelationEntryMap = jMap.object()
            jMap.setObj(jFacVanillaRelationsMap, state_id, jRelationEntryMap)
        endif

        jMap.setInt(jRelationEntryMap, "RelationValue", 0)
        SetActualFactionRelations(state_id, 0)
		SetMenuOptionValueST(SetMenuOptionValueST(relationOptions[0]))
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_vanillafacrel_menu_relation_desc")
	endEvent
    
endstate

state FAC_EDIT_SAVE
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

state FAC_EDIT_LOAD
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


state FAC_EDIT_CUR_FAC

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedFactionIndex)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.FactionDataHandler.SetupStringArrayWithFactionIdentifiers(editedFactionIdentifiersArray)
		SetMenuDialogOptions(editedFactionIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
		editedFactionIndex = index
		SetMenuOptionValueST(index)
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedFactionIndex = 0
		SetMenuOptionValueST(MainPage.GetMCMFactionDisplayByFactionIndex(editedFactionIndex))
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_factionedit_menu_currentfac_desc")
	endEvent
    
endstate


string Function GetRelationValueString(int relationValue)
    if relationValue >= 0 && relationValue < relationOptions.Length
        return relationOptions[relationValue]
    endif

    return relationOptions[0]
EndFunction



Function SetActualFactionRelations(string facName, int relationValue)
    Faction targetVanillaFac = MainPage.MainQuest.FactionDataHandler.GetVanillaFactionByName(facName)

    if targetVanillaFac != None
        SAB_FactionScript curFacScript = MainPage.MainQuest.FactionDataHandler.SAB_FactionQuests[editedFactionIndex]
        curFacScript.SetRelationsWithFaction(targetVanillaFac, relationValue)
    endif
    
EndFunction