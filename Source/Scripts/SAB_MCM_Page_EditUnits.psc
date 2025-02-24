scriptname SAB_MCM_Page_EditUnits extends nl_mcm_module

SAB_MCM Property MainPage Auto

Faction Property SAB_TestFaction_1 Auto
Faction Property SAB_TestFaction_2 Auto

int editedUnitIndex = 0
int jEditedUnitData = 0

int upgradeOptionsMenuPage = 0
int jEditedUnitUpgradesArray = 0

; the name of the jMap entry being hovered or edited in the currently opened dialog
string currentFieldBeingEdited = ""

float currentSliderDefaultValue = 0.0

int displayedRightSideMenu = 0
string[] rightSideMenuOptions

string[] editedUnitIdentifiersArray
string[] unitRaceEditOptions

event OnInit()
    RegisterModule("$sab_mcm_page_edit_units", 5)
endevent

Event OnPageInit()
    unitRaceEditOptions = new string[4]
    unitRaceEditOptions[0] = "$sab_mcm_unitedit_race_option_none"
    unitRaceEditOptions[1] = "$sab_mcm_unitedit_race_option_male"
    unitRaceEditOptions[2] = "$sab_mcm_unitedit_race_option_female"
    unitRaceEditOptions[3] = "$sab_mcm_unitedit_race_option_both"

    rightSideMenuOptions = new string[3]
    rightSideMenuOptions[0] = "$sab_mcm_unitedit_menu_rightside_costskills"
    rightSideMenuOptions[1] = "$sab_mcm_unitedit_menu_rightside_racesgenders"
    rightSideMenuOptions[2] = "$sab_mcm_unitedit_menu_rightside_upgrades"

    editedUnitIdentifiersArray = new string[128]

EndEvent

int Function GetVersion()
    return 2
EndFunction

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_edit_units")
    SetupEditUnitsPage()
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
; EDIT UNITS PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupEditUnitsPage()

    if MainPage.isLoadingData || !MainPage.MainQuest.HasInitialized
        AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
        return
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    jEditedUnitData = jArray.getObj(MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex)

    if jEditedUnitData == 0
        jEditedUnitData = jMap.object()
        JArray.setObj(MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex, jEditedUnitData)
    endif

    jEditedUnitUpgradesArray = jMap.getObj(jEditedUnitData, "jUpgradeOptionsArray")

    if jEditedUnitUpgradesArray == 0
        jEditedUnitUpgradesArray = jArray.object()
        jMap.setObj(jEditedUnitData, "jUpgradeOptionsArray", jEditedUnitUpgradesArray)
    endif
    
    AddHeaderOption("$sab_mcm_unitedit_header_selectunit")
    AddSliderOptionST("UNITEDIT_MENU_PAGE", "$sab_mcm_unitedit_slider_menupage", MainPage.editedUnitsMenuPage + 1)
    AddMenuOptionST("UNITEDIT_CUR_UNIT", "$sab_mcm_unitedit_menu_currentunit", \
        ((editedUnitIndex + 1) as string) + " - " + JMap.getStr(jEditedUnitData, "Name", "Recruit"))
    
    AddHeaderOption("$sab_mcm_unitedit_header_baseinfo")
    AddInputOptionST("UNITEDIT_NAME", "$sab_mcm_unitedit_input_unitname", JMap.getStr(jEditedUnitData, "Name", "Recruit"))
    AddSliderOptionST("UNITEDIT_BASEAV___Health", "$sab_mcm_unitedit_slider_health", JMap.getFlt(jEditedUnitData, "Health", 50.0))
    AddSliderOptionST("UNITEDIT_BASEAV___Stamina", "$sab_mcm_unitedit_slider_stamina", JMap.getFlt(jEditedUnitData, "Stamina", 50.0))
    AddSliderOptionST("UNITEDIT_BASEAV___Magicka", "$sab_mcm_unitedit_slider_magicka", JMap.getFlt(jEditedUnitData, "Magicka", 50.0))
    AddToggleOptionST("UNITEDIT_ISRANGED", "$sab_mcm_unitedit_toggle_ranged", JMap.getInt(jEditedUnitData, "IsRanged", 0) != 0, 0)

    AddEmptyOption()
    AddSliderOptionST("UNITEDIT_AUTOCALC_STRENGTH", "$sab_mcm_unitedit_slider_autocalc_strength", JMap.getFlt(jEditedUnitData, "AutocalcStrength", 1.0), "{1}")
    AddEmptyOption()
    AddTextOptionST("UNITEDIT_OUTFIT", "$sab_mcm_unitedit_button_outfit", "")
    AddEmptyOption()
    AddMenuOptionST("UNITEDIT_COPY_ANOTHER_UNIT", "$sab_mcm_unitedit_button_copyfrom", "$sab_mcm_unitedit_button_copyfrom_value")
    AddEmptyOption()
    AddEmptyOption()
    AddTextOptionST("UNITEDIT_TEST_SAVE", "$sab_mcm_unitedit_button_save", "")
    AddTextOptionST("UNITEDIT_TEST_LOAD", "$sab_mcm_unitedit_button_load", "")

    SetCursorPosition(1)

    AddTextOptionST("UNITEDIT_TESTSPAWN___FAC1", "$sab_mcm_unitedit_button_spawn_testfac", "1")
    AddTextOptionST("UNITEDIT_TESTSPAWN___FAC2", "$sab_mcm_unitedit_button_spawn_testfac", "2")

    AddEmptyOption()
    AddMenuOptionST("UNITEDIT_RIGTHSIDE_MENU", "$sab_mcm_unitedit_menu_rightside", rightSideMenuOptions[displayedRightSideMenu])

    if displayedRightSideMenu == 0

        AddHeaderOption("$sab_mcm_unitedit_header_costs")
        AddSliderOptionST("UNITEDIT_COST_GOLD", "$sab_mcm_unitedit_slider_cost_gold", JMap.getFlt(jEditedUnitData, "GoldCost", 10.0))
        AddSliderOptionST("UNITEDIT_COST_EXP", "$sab_mcm_unitedit_slider_cost_exp", JMap.getFlt(jEditedUnitData, "ExpCost", 10.0))

        AddHeaderOption("$sab_mcm_unitedit_header_skills")
        AddSliderOptionST("UNITEDIT_SKL___SkillMarksman", "$sab_mcm_unitedit_slider_marksman", JMap.getFlt(jEditedUnitData, "SkillMarksman", 15.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillOneHanded", "$sab_mcm_unitedit_slider_onehanded", JMap.getFlt(jEditedUnitData, "SkillOneHanded", 15.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillTwoHanded", "$sab_mcm_unitedit_slider_twohanded", JMap.getFlt(jEditedUnitData, "SkillTwoHanded", 15.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillLightArmor", "$sab_mcm_unitedit_slider_lightarmor", JMap.getFlt(jEditedUnitData, "SkillLightArmor", 15.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillHeavyArmor", "$sab_mcm_unitedit_slider_heavyarmor", JMap.getFlt(jEditedUnitData, "SkillHeavyArmor", 15.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillBlock", "$sab_mcm_unitedit_slider_block", JMap.getFlt(jEditedUnitData, "SkillBlock", 15.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillDestruction", "$sab_mcm_unitedit_slider_destruction", JMap.getFlt(jEditedUnitData, "SkillDestruction", 5.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillAlteration", "$sab_mcm_unitedit_slider_alteration", JMap.getFlt(jEditedUnitData, "SkillAlteration", 5.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillConjuration", "$sab_mcm_unitedit_slider_conjuration", JMap.getFlt(jEditedUnitData, "SkillConjuration", 5.0))
        AddSliderOptionST("UNITEDIT_SKL___SkillIllusion", "$sab_mcm_unitedit_slider_illusion", JMap.getFlt(jEditedUnitData, "SkillIllusion", 5.0))

    elseif displayedRightSideMenu == 1

        AddHeaderOption("$sab_mcm_unitedit_header_races")
        AddMenuOptionST("UNITEDIT_RACE___RaceArgonian", "$sab_mcm_unitedit_race_arg", GetEditedUnitRaceStatus(jEditedUnitData, "RaceArgonian"))
        AddMenuOptionST("UNITEDIT_RACE___RaceKhajiit", "$sab_mcm_unitedit_race_kha", GetEditedUnitRaceStatus(jEditedUnitData, "RaceKhajiit"))
        AddMenuOptionST("UNITEDIT_RACE___RaceOrc", "$sab_mcm_unitedit_race_orc", GetEditedUnitRaceStatus(jEditedUnitData, "RaceOrc"))
        AddMenuOptionST("UNITEDIT_RACE___RaceBreton", "$sab_mcm_unitedit_race_bre", GetEditedUnitRaceStatus(jEditedUnitData, "RaceBreton"))
        AddMenuOptionST("UNITEDIT_RACE___RaceImperial", "$sab_mcm_unitedit_race_imp", GetEditedUnitRaceStatus(jEditedUnitData, "RaceImperial"))
        AddMenuOptionST("UNITEDIT_RACE___RaceNord", "$sab_mcm_unitedit_race_nor", GetEditedUnitRaceStatus(jEditedUnitData, "RaceNord"))
        AddMenuOptionST("UNITEDIT_RACE___RaceRedguard", "$sab_mcm_unitedit_race_red", GetEditedUnitRaceStatus(jEditedUnitData, "RaceRedguard"))
        AddMenuOptionST("UNITEDIT_RACE___RaceDarkElf", "$sab_mcm_unitedit_race_daf", GetEditedUnitRaceStatus(jEditedUnitData, "RaceDarkElf"))
        AddMenuOptionST("UNITEDIT_RACE___RaceHighElf", "$sab_mcm_unitedit_race_hif", GetEditedUnitRaceStatus(jEditedUnitData, "RaceHighElf"))
        AddMenuOptionST("UNITEDIT_RACE___RaceWoodElf", "$sab_mcm_unitedit_race_wof", GetEditedUnitRaceStatus(jEditedUnitData, "RaceWoodElf"))
    
        ; race addons
        ; TODO add pagination if too many
        int jRaceAddonsMap = MainPage.MainQuest.UnitDataHandler.jRaceAddonsMap

        if jValue.isExists(jRaceAddonsMap)
            int jUnitAddonRacesMap = jMap.getObj(jEditedUnitData, "jUnitRaceAddonsMap")
            string addonRaceId = JMap.nextKey(jRaceAddonsMap, previousKey="", endKey="")
            while addonRaceId != ""
                int jAddonData = JMap.getObj(jRaceAddonsMap, addonRaceId)

                AddMenuOptionST("UNITEDIT_ADDON_RACE___" + addonRaceId, jMap.getStr(jAddonData, "displayName", "NONAME - " + addonRaceId), GetEditedUnitAddonRaceStatus(jUnitAddonRacesMap, addonRaceId))

                addonRaceId = JMap.nextKey(jRaceAddonsMap, addonRaceId, endKey="")
            endwhile
        endif

    elseif displayedRightSideMenu == 2

        AddHeaderOption("$sab_mcm_unitedit_header_upgrade_options")
        ; add slot customizers for each upgrade option.
        ; up to 10 slots can be shown in the MCM
        bool displayAddEntryBtn = true
        int displayedLinesCount = jValue.count(jEditedUnitUpgradesArray)
        if displayedLinesCount >= 10
            displayedLinesCount = 10
            displayAddEntryBtn = false
        endif
        int i = 0

        while i < displayedLinesCount
            string indexString = i as string
            AddTextOptionST("UNITEDIT_UPGRADES_REMOVE___" + indexString, "$sab_mcm_unitedit_button_upgrade_option_remove", (i + 1) as string)
            AddSliderOptionST("UNITEDIT_UPGRADES_MENU_PAGE___TROOPLINE_ENTRY_" + indexString, "$sab_mcm_unitedit_slider_menupage", upgradeOptionsMenuPage + 1)
            AddMenuOptionST("UNITEDIT_UPGRADES_SELECT___" + indexString, "$sab_mcm_unitedit_menu_upgrade_option_select", \
                MainPage.GetMCMUnitDisplayByUnitIndex(jArray.getInt(jEditedUnitUpgradesArray, i, 0)))
            AddEmptyOption()

            i += 1
        endwhile

        if displayAddEntryBtn
            ; at the end of the upgrades, there should be a "add upgrade" button, unless there are too many options already
            AddTextOptionST("UNITEDIT_UPGRADES_ADD", "$sab_mcm_unitedit_button_upgrade_option_add", "")
        endif

    endif

EndFunction


state UNITEDIT_MENU_PAGE
	event OnSliderOpenST(string state_id)
		SetSliderDialogStartValue(MainPage.editedUnitsMenuPage + 1)
		SetSliderDialogDefaultValue(1)
		SetSliderDialogRange(1, 4) ; 512 units
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
		MainPage.editedUnitsMenuPage = (value as int) - 1
		SetSliderOptionValueST(MainPage.editedUnitsMenuPage + 1)
	endEvent

	event OnDefaultST(string state_id)
		MainPage.editedUnitsMenuPage = 0
		SetSliderOptionValueST(MainPage.editedUnitsMenuPage + 1)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_slider_menupage_desc")
	endEvent
endState


state UNITEDIT_CUR_UNIT

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedUnitIndex % 128)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, MainPage.editedUnitsMenuPage)
		SetMenuDialogOptions(editedUnitIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        int trueIndex = index + MainPage.editedUnitsMenuPage * 128
		editedUnitIndex = trueIndex
		SetMenuOptionValueST(trueIndex)
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedUnitIndex = 0 + MainPage.editedUnitsMenuPage * 128
		SetMenuOptionValueST(editedUnitIndex)
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_menu_currentunit_desc")
	endEvent
    
endstate

state UNITEDIT_NAME

	event OnInputOpenST(string state_id)
        string unitName = JMap.getStr(jEditedUnitData, "Name", "Recruit")
        ; string unitName = JMap.getStr(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit")
		SetInputDialogStartText(unitName)
	endEvent

	event OnInputAcceptST(string state_id, string inputs)
        MainPage.ToggleQuickHotkey(true)
        JMap.setStr(jEditedUnitData, "Name", inputs)
        ; JMap.setStr(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, "Name", inputs)
        SetInputOptionValueST(inputs)

        ;force a reset to update other fields that use the name
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)

        JMap.setStr(jEditedUnitData, "Name", "Recruit")
        ; JMap.setStr(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit")

		SetInputOptionValueST("Recruit")

        ;force a reset to update other fields that use the name
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(false)
		SetInfoText("$sab_mcm_unitedit_input_unitname_desc")
	endEvent
    
endstate

state UNITEDIT_BASEAV

    event OnSliderOpenST(string state_id)
        SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
	endEvent

    event OnSliderAcceptST(string state_id, float value)
        SetEditedUnitSliderValue(currentFieldBeingEdited, value)
    endEvent

    event OnDefaultST(string state_id)
        SetEditedUnitSliderValue(currentFieldBeingEdited, currentSliderDefaultValue)
    endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        currentFieldBeingEdited = state_id
		SetInfoText(GetInfoTextLocaleKey(state_id))
	endEvent

    string function GetInfoTextLocaleKey(string stateId)
        if stateId == "Health"
            return "$sab_mcm_unitedit_slider_health_desc"
        elseif stateId == "Stamina"
            return "$sab_mcm_unitedit_slider_stamina_desc"
        elseif stateId == "Magicka"
            return "$sab_mcm_unitedit_slider_magicka_desc"
        endif
    endfunction
    
endstate

state UNITEDIT_ISRANGED
    event OnSelectST(string state_id)
        int curValue = JMap.getInt(jEditedUnitData, "IsRanged", 0)

        if curValue != 0
            curValue = 0
        else
            curValue = 1
        endif

        JMap.setInt(jEditedUnitData, "IsRanged", curValue)

        SetToggleOptionValueST(curValue != 0)
	endEvent

    event OnDefaultST(string state_id)
        int curValue = 0
        JMap.setInt(jEditedUnitData, "IsRanged", curValue)
        SetToggleOptionValueST(curValue != 0)
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_toggle_ranged_desc")
	endEvent
endstate

state UNITEDIT_OUTFIT

    event OnSelectST(string state_id)
        ; run a raceGenders update on the unit and the outfitter guy, to avoid spawning a "raceless" guy
        MainPage.MainQuest.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
            (jEditedUnitData, (MainPage.MainQuest.UnitDataHandler.SAB_UnitAllowedRacesGenders.GetAt(editedUnitIndex) as LeveledActor))
        MainPage.MainQuest.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
            (jEditedUnitData, MainPage.MainQuest.UnitDataHandler.SAB_UnitLooks_TestGuy)

        ; also set the test guy's outfit to the target unit's outfit
        MainPage.MainQuest.UnitDataHandler.SetupGearListAccordingToUnitData \
            (jEditedUnitData, \
            MainPage.MainQuest.UnitDataHandler.SAB_UnitGear_TestGuy, \
            MainPage.MainQuest.UnitDataHandler.SAB_UnitDuplicateItems_TestGuy)

        MainPage.MainQuest.SpawnerScript.SpawnCustomizationGuy(jEditedUnitData, editedUnitIndex)
        ShowMessage("$sab_mcm_unitedit_popup_msg_outfitguyspawned", false)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_button_outfit_desc")
	endEvent

endstate

state UNITEDIT_COPY_ANOTHER_UNIT

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedUnitIndex % 128)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, MainPage.editedUnitsMenuPage)
		SetMenuDialogOptions(editedUnitIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        if ShowMessage("$sab_mcm_unitedit_popup_msg_confirm_unitcopy")
            int trueIndex = index + MainPage.editedUnitsMenuPage * 128
            MainPage.MainQuest.UnitDataHandler.CopyUnitDataFromAnotherIndex(editedUnitIndex, trueIndex)
            SetMenuOptionValueST(trueIndex)
            ForcePageReset()
        endif
	endEvent

	event OnDefaultST(string state_id)
		; do nothing
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_button_copyfrom_desc")
	endEvent
    
endstate

state UNITEDIT_TESTSPAWN

    event OnSelectST(string state_id)
        ; run a raceGenders update on the unit, to avoid spawning a "raceless" guy (they won't spawn in that case)
        MainPage.MainQuest.UnitDataHandler.GuardRaceGendersLvlActorAtIndex(editedUnitIndex)

        Faction desiredOwnerFaction = SAB_TestFaction_1

        if state_id == "FAC2"
            desiredOwnerFaction = SAB_TestFaction_2
        endif

        MainPage.MainQuest.SpawnerScript.SpawnUnit(Game.GetPlayer(), desiredOwnerFaction, editedUnitIndex, jEditedUnitData)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_button_spawn_testfac_desc")
	endEvent

endstate

state UNITEDIT_SKL

    event OnSliderOpenST(string state_id)
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

    event OnSliderAcceptST(string state_id, float value)
        SetEditedUnitSliderValue(currentFieldBeingEdited, value)
    endEvent

    event OnDefaultST(string state_id)
        SetEditedUnitSliderValue(currentFieldBeingEdited, currentSliderDefaultValue)
    endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        currentFieldBeingEdited = state_id
		SetInfoText(GetInfoTextLocaleKey(state_id))
	endEvent

    string function GetInfoTextLocaleKey(string stateId)
        if stateId == "SkillMarksman"
            return "$sab_mcm_unitedit_slider_marksman_desc"
        elseif stateId == "SkillOneHanded"
            return "$sab_mcm_unitedit_slider_onehanded_desc"
        elseif stateId == "SkillTwoHanded"
            return "$sab_mcm_unitedit_slider_twohanded_desc"
        elseif stateId == "SkillLightArmor"
            return "$sab_mcm_unitedit_slider_lightarmor_desc"
        elseif stateId == "SkillHeavyArmor"
            return "$sab_mcm_unitedit_slider_heavyarmor_desc"
        elseif stateId == "SkillBlock"
            return "$sab_mcm_unitedit_slider_block_desc"
        elseif stateId == "SkillDestruction"
            return "$sab_mcm_unitedit_slider_destruction_desc"
        elseif stateId == "SkillAlteration"
            return "$sab_mcm_unitedit_slider_alteration_desc"
        elseif stateId == "SkillConjuration"
            return "$sab_mcm_unitedit_slider_conjuration_desc"
        elseif stateId == "SkillIllusion"
            return "$sab_mcm_unitedit_slider_illusion_desc"
        endif
    endfunction

endstate


state UNITEDIT_COST_GOLD

    event OnSliderOpenST(string state_id)
        currentFieldBeingEdited = "GoldCost"
        currentSliderDefaultValue = 10.0
        float curValue = JMap.getFlt(jEditedUnitData, "GoldCost", currentSliderDefaultValue)
        SetSliderDialogStartValue(curValue)
        SetSliderDialogDefaultValue(currentSliderDefaultValue)
        SetSliderDialogRange(0.0, 1000.0)
        SetSliderDialogInterval(1)
	endEvent

    event OnSliderAcceptST(string state_id, float value)
        SetEditedUnitSliderValue(currentFieldBeingEdited, value)
    endEvent

    event OnDefaultST(string state_id)
        SetEditedUnitSliderValue(currentFieldBeingEdited, currentSliderDefaultValue)
    endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        currentFieldBeingEdited = "GoldCost"
		SetInfoText("$sab_mcm_unitedit_slider_cost_gold_desc")
	endEvent

endstate


state UNITEDIT_COST_EXP

    event OnSliderOpenST(string state_id)
        currentFieldBeingEdited = "ExpCost"
        currentSliderDefaultValue = 10.0
        float curValue = JMap.getFlt(jEditedUnitData, "ExpCost", currentSliderDefaultValue)
        SetSliderDialogStartValue(curValue)
        SetSliderDialogDefaultValue(currentSliderDefaultValue)
        SetSliderDialogRange(0.0, 1000.0)
        SetSliderDialogInterval(1)
	endEvent

    event OnSliderAcceptST(string state_id, float value)
        SetEditedUnitSliderValue(currentFieldBeingEdited, value)
    endEvent

    event OnDefaultST(string state_id)
        SetEditedUnitSliderValue(currentFieldBeingEdited, currentSliderDefaultValue)
    endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        currentFieldBeingEdited = "ExpCost"
		SetInfoText("$sab_mcm_unitedit_slider_cost_exp_desc")
	endEvent

endstate


state UNITEDIT_AUTOCALC_STRENGTH

    event OnSliderOpenST(string state_id)
        currentFieldBeingEdited = "AutocalcStrength"
        currentSliderDefaultValue = 1.0
        float curValue = JMap.getFlt(jEditedUnitData, "AutocalcStrength", currentSliderDefaultValue)
        SetSliderDialogStartValue(curValue)
        SetSliderDialogDefaultValue(currentSliderDefaultValue)
        SetSliderDialogRange(0.1, 100.0)
        SetSliderDialogInterval(0.1)
	endEvent

    event OnSliderAcceptST(string state_id, float value)
        SetEditedUnitSliderValue(currentFieldBeingEdited, value, "{1}")
    endEvent

    event OnDefaultST(string state_id)
        SetEditedUnitSliderValue(currentFieldBeingEdited, currentSliderDefaultValue, "{1}")
    endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        currentFieldBeingEdited = "AutocalcStrength"
		SetInfoText("$sab_mcm_unitedit_slider_autocalc_strength_desc")
	endEvent

endstate


state UNITEDIT_RACE

    event OnMenuOpenST(string state_id)
        SetupEditedUnitRaceMenuOnOpen(currentFieldBeingEdited)
    endEvent
    
    event OnMenuAcceptST(string state_id, int index)
        SetEditedUnitRaceMenuValue(currentFieldBeingEdited, index)
    endEvent

    event OnDefaultST(string state_id)
        SetEditedUnitRaceMenuValue(currentFieldBeingEdited, 0)
    endEvent

    event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        currentFieldBeingEdited = state_id
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_ADDON_RACE

    event OnMenuOpenST(string state_id)
        SetupEditedUnitAddonRaceMenuOnOpen(currentFieldBeingEdited)
    endEvent
    
    event OnMenuAcceptST(string state_id, int index)
        SetEditedUnitAddonRaceMenuValue(currentFieldBeingEdited, index)
    endEvent

    event OnDefaultST(string state_id)
        SetEditedUnitAddonRaceMenuValue(currentFieldBeingEdited, 0)
    endEvent

    event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        currentFieldBeingEdited = state_id
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate


state UNITEDIT_UPGRADES_MENU_PAGE
	event OnSliderOpenST(string state_id)
		SetSliderDialogStartValue(upgradeOptionsMenuPage + 1)
		SetSliderDialogDefaultValue(1)
		SetSliderDialogRange(1, 4) ; 512 units
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
		upgradeOptionsMenuPage = (value as int) - 1
		SetSliderOptionValueST(upgradeOptionsMenuPage + 1)
	endEvent

	event OnDefaultST(string state_id)
		upgradeOptionsMenuPage = 0
		SetSliderOptionValueST(upgradeOptionsMenuPage + 1)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_slider_menupage_desc")
	endEvent
endState

state UNITEDIT_UPGRADES_ADD
    event OnSelectST(string state_id)
        int upgOptionIndex = editedUnitIndex + 1 + jArray.count(jEditedUnitUpgradesArray)

        JArray.addInt(jEditedUnitUpgradesArray, upgOptionIndex)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_button_upgrade_option_add_desc")
	endEvent
endstate

state UNITEDIT_UPGRADES_SELECT

	event OnMenuOpenST(string state_id)
        int entryIndex = state_id as int
		SetMenuDialogStartIndex(jArray.getInt(jEditedUnitUpgradesArray, entryIndex, 0) % 128)
		SetMenuDialogDefaultIndex(jArray.getInt(jEditedUnitUpgradesArray, entryIndex, 0) % 128)
        MainPage.MainQuest.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, upgradeOptionsMenuPage)
		SetMenuDialogOptions(editedUnitIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        int entryIndex = state_id as int
        int trueIndex = index + upgradeOptionsMenuPage * 128
		jArray.setInt(jEditedUnitUpgradesArray, entryIndex, trueIndex)
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(trueIndex))
	endEvent

	event OnDefaultST(string state_id)
        int entryIndex = state_id as int
        int defaultOption = jArray.getInt(jEditedUnitUpgradesArray, entryIndex, 0)
		jArray.setInt(jEditedUnitUpgradesArray, entryIndex, defaultOption)
		SetMenuOptionValueST(MainPage.GetMCMUnitDisplayByUnitIndex(defaultOption))
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_menu_upgrade_option_select_desc")
	endEvent
    
endstate

state UNITEDIT_UPGRADES_REMOVE
    event OnSelectST(string state_id)
        int entryIndex = state_id as int
        JArray.eraseIndex(jEditedUnitUpgradesArray, entryIndex)
        ForcePageReset()
	endEvent

    event OnDefaultST(string state_id)
        ; nothing
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_button_upgrade_option_remove_desc")
	endEvent
endstate


state UNITEDIT_RIGTHSIDE_MENU

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(displayedRightSideMenu)
		SetMenuDialogDefaultIndex(displayedRightSideMenu)
		SetMenuDialogOptions(rightSideMenuOptions)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        displayedRightSideMenu = index
		SetMenuOptionValueST(rightSideMenuOptions[displayedRightSideMenu])
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
        displayedRightSideMenu = 0
		SetMenuOptionValueST(rightSideMenuOptions[displayedRightSideMenu])
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_menu_rightside_desc")
	endEvent
    
endstate


state UNITEDIT_TEST_SAVE
    event OnSelectST(string state_id)
        string filePath = JContainers.userDirectory() + "SAB/unitData.json"
        JValue.writeToFile(MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray, filePath)
        ShowMessage("Save: " + filePath, false)
	endEvent

    event OnDefaultST(string state_id)
        ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
    endevent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_button_save_desc")
	endEvent
endstate

state UNITEDIT_TEST_LOAD
    event OnSelectST(string state_id)
        MainPage.MainQuest.SpawnerScript.HideCustomizationGuy()
        string filePath = JContainers.userDirectory() + "SAB/unitData.json"
        MainPage.isLoadingData = true
        int jReadData = JValue.readFromFile(filePath)
        if jReadData != 0
            ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()
            MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray = JValue.releaseAndRetain(MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray, jReadData, "ShoutAndBlade")
            MainPage.MainQuest.UnitDataHandler.EnsureUnitDataArrayCount()
            MainPage.MainQuest.UnitDataHandler.UpdateAllGearAndRaceListsAccordingToJMap()
            MainPage.isLoadingData = false
            Debug.Notification("SAB: Load complete!")
            ShowMessage("$sab_mcm_shared_popup_msg_load_success", false)
            ForcePageReset()
        else
            MainPage.isLoadingData = false
            ShowMessage("$sab_mcm_shared_popup_msg_load_fail", false)
        endif
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_unitedit_button_load_desc")
	endEvent
endstate

; sets up common base actor value (health, magicka, stamina) sliders
Function SetupEditedUnitBaseAVSliderOnOpen(string jUnitMapKey)
    currentFieldBeingEdited = jUnitMapKey
    currentSliderDefaultValue = 50.0
    float curValue = JMap.getFlt(jEditedUnitData, jUnitMapKey, currentSliderDefaultValue)
    ; float curValue = JMap.getFlt(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, currentSliderDefaultValue)
    SetSliderDialogStartValue(curValue)
    SetSliderDialogDefaultValue(currentSliderDefaultValue)
    SetSliderDialogRange(10.0, 2000.0)
    SetSliderDialogInterval(5)
EndFunction

; sets up skill actor value (oneHanded, Block, Marksman) sliders
Function SetupEditedUnitSkillSliderOnOpen(string jUnitMapKey)
    currentFieldBeingEdited = jUnitMapKey
    currentSliderDefaultValue = 15.0
    float curValue = JMap.getFlt(jEditedUnitData, jUnitMapKey, currentSliderDefaultValue)
    ; float curValue = JMap.getFlt(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, currentSliderDefaultValue)
    SetSliderDialogStartValue(curValue)
    SetSliderDialogDefaultValue(currentSliderDefaultValue)
    SetSliderDialogRange(1.0, 300.0)
    SetSliderDialogInterval(1)
EndFunction

; sets up an allowed race/gender menu
Function SetupEditedUnitRaceMenuOnOpen(string jUnitMapKey)
    currentFieldBeingEdited = jUnitMapKey
    int curValue = JMap.getInt(jEditedUnitData, jUnitMapKey, 0)
    ; int curValue = JMap.getInt(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, 0)
    SetMenuDialogStartIndex(curValue)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(unitRaceEditOptions)
EndFunction

; sets up an allowed addon race/gender menu
Function SetupEditedUnitAddonRaceMenuOnOpen(string raceId)
    currentFieldBeingEdited = raceId

    int jUnitRaceAddonsMap = jMap.getObj(jEditedUnitData, "jUnitRaceAddonsMap")
    if !JValue.isExists(jUnitRaceAddonsMap)
        jUnitRaceAddonsMap = jMap.object()
        jMap.setObj(jEditedUnitData, "jUnitRaceAddonsMap", jUnitRaceAddonsMap)
    endif

    int curValue = jMap.getInt(jUnitRaceAddonsMap, raceId)

    SetMenuDialogStartIndex(curValue)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(unitRaceEditOptions)

EndFunction

Function SetEditedUnitSliderValue(string jUnitMapKey, float value, string formatString = "{0}")
    JMap.setFlt(jEditedUnitData, jUnitMapKey, value)
    ; JMap.setFlt(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, value)
    SetSliderOptionValueST(value, formatString)
EndFunction

Function SetEditedUnitRaceMenuValue(string jUnitMapKey, int value)
    JMap.setInt(jEditedUnitData, jUnitMapKey, value)
    ; JMap.setInt(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, value)

    MainPage.MainQuest.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
        (jEditedUnitData, MainPage.MainQuest.UnitDataHandler.SAB_UnitAllowedRacesGenders.GetAt(editedUnitIndex) as LeveledActor)
    ; SAB_MCM.SAB_Main.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
    ;     (SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, SAB_MCM.SAB_Main.UnitDataHandler.SAB_UnitLooks_TestGuy)
    

    SetMenuOptionValueST(unitRaceEditOptions[value])
EndFunction

Function SetEditedUnitAddonRaceMenuValue(string raceId, int value)
    int jUnitRaceAddonsMap = jMap.getObj(jEditedUnitData, "jUnitRaceAddonsMap")

    if !JValue.isExists(jUnitRaceAddonsMap)
        jUnitRaceAddonsMap = jMap.object()
        jMap.setObj(jEditedUnitData, "jUnitRaceAddonsMap", jUnitRaceAddonsMap)
    endif

    jMap.setInt(jUnitRaceAddonsMap, raceId, value)

    If value == 0
        jMap.removeKey(jUnitRaceAddonsMap, raceId)
    EndIf

    MainPage.MainQuest.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
        (jEditedUnitData, MainPage.MainQuest.UnitDataHandler.SAB_UnitAllowedRacesGenders.GetAt(editedUnitIndex) as LeveledActor)

    SetMenuOptionValueST(unitRaceEditOptions[value])
EndFunction

; returns the text equivalent to the target race/gender status ("male only" for 1, for example).
; Returns "None" for 0 and invalid values
string Function GetEditedUnitRaceStatus(int jUnitData, string raceKey)

    int raceStatus = JMap.getInt(jUnitData, raceKey, 0)

    if raceStatus >= 0 && raceStatus < unitRaceEditOptions.Length
        return unitRaceEditOptions[raceStatus]
    endif

    return "$sab_mcm_unitedit_race_option_none"

endfunction

; returns the text equivalent to the target race/gender status ("male only" for 1, for example).
; Returns "None" for 0 and invalid values
string Function GetEditedUnitAddonRaceStatus(int jUnitAddonRacesMap, string raceId)

    if !JValue.isExists(jUnitAddonRacesMap)
        return "$sab_mcm_unitedit_race_option_none"
    endif

    int raceStatus = JMap.getInt(jUnitAddonRacesMap, raceId, 0)

    if raceStatus >= 0 && raceStatus < unitRaceEditOptions.Length
        return unitRaceEditOptions[raceStatus]
    endif

    return "$sab_mcm_unitedit_race_option_none"

endfunction