scriptname SAB_MCM_Page_EditUnits extends nl_mcm_module

SAB_MCM Property MainPage Auto

; since we want more than 128 custom units, we need two arrays (0 or 1 here)
int editedUnitsMenuPage = 0

int editedUnitIndex = 0
int jEditedUnitData = 0

bool isLoadingData = false

; the name of the jMap entry being hovered or edited in the currently opened dialog
string currentFieldBeingEdited = ""

; a descriptive type of the field being hovered or edited (like "race menu in edit unit panel").
; Used because I'm too lazy to write the same thing too many times
string currentFieldTypeBeingEdited = ""
float currentSliderDefaultValue = 0.0

string[] editedUnitIdentifiersArray
string[] unitRaceEditOptions

event OnInit()
    RegisterModule("$sab_mcm_page_edit_units", 1)
endevent

Event OnPageInit()
    unitRaceEditOptions = new string[4]
    unitRaceEditOptions[0] = "$sab_mcm_unitedit_race_option_none"
    unitRaceEditOptions[1] = "$sab_mcm_unitedit_race_option_male"
    unitRaceEditOptions[2] = "$sab_mcm_unitedit_race_option_female"
    unitRaceEditOptions[3] = "$sab_mcm_unitedit_race_option_both"

    editedUnitIdentifiersArray = new string[128]

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetupEditUnitsPage()
EndEvent


;---------------------------------------------------------------------------------------------------------
; SHARED STUFF (too much copying of the same stuff to separate)
;---------------------------------------------------------------------------------------------------------

state SHARED_LOADING

    event OnSelectST(string state_id)
        ; nothing
	endEvent

    event OnDefaultST(string state_id)
        ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
    endevent

	event OnHighlightST(string state_id)
		SetInfoText("$sab_mcm_shared_loading_desc")
	endEvent

endstate

event OnSliderAcceptST(string state_id, float value)
    SetEditedUnitSliderValue(currentFieldBeingEdited, value)
endEvent

event OnMenuOpenST(string state_id)
    if currentFieldTypeBeingEdited == "unitedit_racegender_menu"
        SetupEditedUnitRaceMenuOnOpen(currentFieldBeingEdited)
    endif
endEvent

event OnMenuAcceptST(string state_id, int index)
    if currentFieldTypeBeingEdited == "unitedit_racegender_menu"
        SetEditedUnitRaceMenuValue(currentFieldBeingEdited, index)
    endif
endEvent

event OnDefaultST(string state_id)
    if currentFieldTypeBeingEdited == "unitedit_slider"
        SetEditedUnitSliderValue(currentFieldBeingEdited, currentSliderDefaultValue)
    ElseIf currentFieldTypeBeingEdited == "unitedit_racegender_menu"
        SetEditedUnitRaceMenuValue(currentFieldBeingEdited, 0)
    endif
endEvent

;---------------------------------------------------------------------------------------------------------
; EDIT UNITS PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupEditUnitsPage()

    if isLoadingData
        AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
        return
    endif

    SetCursorFillMode(TOP_TO_BOTTOM)

    jEditedUnitData = jArray.getObj(MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex)

    if jEditedUnitData == 0
        jEditedUnitData = jMap.object()
        JArray.setObj(MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex, jEditedUnitData)
    endif
    
    AddHeaderOption("$sab_mcm_unitedit_header_selectunit")
    AddSliderOptionST("UNITEDIT_MENU_PAGE", "$sab_mcm_unitedit_slider_menupage", editedUnitsMenuPage + 1)
    AddMenuOptionST("UNITEDIT_CUR_UNIT", "$sab_mcm_unitedit_menu_currentunit", \
        ((editedUnitIndex + 1) as string) + " - " + JMap.getStr(jEditedUnitData, "Name", "Recruit"))
    
    AddHeaderOption("$sab_mcm_unitedit_header_baseinfo")
    AddInputOptionST("UNITEDIT_NAME", "$sab_mcm_unitedit_input_unitname", JMap.getStr(jEditedUnitData, "Name", "Recruit"))
    AddSliderOptionST("UNITEDIT_HEALTH", "$sab_mcm_unitedit_slider_health", JMap.getFlt(jEditedUnitData, "Health", 50.0))
    AddSliderOptionST("UNITEDIT_STAMINA", "$sab_mcm_unitedit_slider_stamina", JMap.getFlt(jEditedUnitData, "Stamina", 50.0))
    AddSliderOptionST("UNITEDIT_MAGICKA", "$sab_mcm_unitedit_slider_magicka", JMap.getFlt(jEditedUnitData, "Magicka", 50.0))

    AddEmptyOption()
    AddTextOptionST("UNITEDIT_OUTFIT", "$sab_mcm_unitedit_button_outfit", "")
    AddEmptyOption()
    AddMenuOptionST("UNITEDIT_COPY_ANOTHER_UNIT", "$sab_mcm_unitedit_button_copyfrom", \
    "$sab_mcm_unitedit_button_copyfrom_value")
    AddEmptyOption()
    AddTextOptionST("UNITEDIT_TEST_SAVE", "(Debug) Save testGuy data", "")
    AddTextOptionST("UNITEDIT_TEST_LOAD", "(Debug) Load testGuy data", "")

    SetCursorPosition(1)

    AddHeaderOption("$sab_mcm_unitedit_header_skills")
    AddSliderOptionST("UNITEDIT_SKL_MARKSMAN", "$sab_mcm_unitedit_slider_marksman", JMap.getFlt(jEditedUnitData, "SkillMarksman", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_ONEHANDED", "$sab_mcm_unitedit_slider_onehanded", JMap.getFlt(jEditedUnitData, "SkillOneHanded", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_TWOHANDED", "$sab_mcm_unitedit_slider_twohanded", JMap.getFlt(jEditedUnitData, "SkillTwoHanded", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_LIGHTARMOR", "$sab_mcm_unitedit_slider_lightarmor", JMap.getFlt(jEditedUnitData, "SkillLightArmor", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_HEAVYARMOR", "$sab_mcm_unitedit_slider_heavyarmor", JMap.getFlt(jEditedUnitData, "SkillHeavyArmor", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_BLOCK", "$sab_mcm_unitedit_slider_block", JMap.getFlt(jEditedUnitData, "SkillBlock", 15.0))

    AddEmptyOption()

    AddHeaderOption("$sab_mcm_unitedit_header_races")
    AddMenuOptionST("UNITEDIT_RACE_ARGONIAN", "$sab_mcm_unitedit_race_arg", GetEditedUnitRaceStatus(jEditedUnitData, "RaceArgonian"))
    AddMenuOptionST("UNITEDIT_RACE_KHAJIIT", "$sab_mcm_unitedit_race_kha", GetEditedUnitRaceStatus(jEditedUnitData, "RaceKhajiit"))
    AddMenuOptionST("UNITEDIT_RACE_ORC", "$sab_mcm_unitedit_race_orc", GetEditedUnitRaceStatus(jEditedUnitData, "RaceOrc"))
    AddMenuOptionST("UNITEDIT_RACE_BRETON", "$sab_mcm_unitedit_race_bre", GetEditedUnitRaceStatus(jEditedUnitData, "RaceBreton"))
    AddMenuOptionST("UNITEDIT_RACE_IMPERIAL", "$sab_mcm_unitedit_race_imp", GetEditedUnitRaceStatus(jEditedUnitData, "RaceImperial"))
    AddMenuOptionST("UNITEDIT_RACE_NORD", "$sab_mcm_unitedit_race_nor", GetEditedUnitRaceStatus(jEditedUnitData, "RaceNord"))
    AddMenuOptionST("UNITEDIT_RACE_REDGUARD", "$sab_mcm_unitedit_race_red", GetEditedUnitRaceStatus(jEditedUnitData, "RaceRedguard"))
    AddMenuOptionST("UNITEDIT_RACE_DARKELF", "$sab_mcm_unitedit_race_daf", GetEditedUnitRaceStatus(jEditedUnitData, "RaceDarkElf"))
    AddMenuOptionST("UNITEDIT_RACE_HIGHELF", "$sab_mcm_unitedit_race_hif", GetEditedUnitRaceStatus(jEditedUnitData, "RaceHighElf"))
    AddMenuOptionST("UNITEDIT_RACE_WOODELF", "$sab_mcm_unitedit_race_wof", GetEditedUnitRaceStatus(jEditedUnitData, "RaceWoodElf"))
    
EndFunction


state UNITEDIT_MENU_PAGE
	event OnSliderOpenST(string state_id)
		SetSliderDialogStartValue(editedUnitsMenuPage + 1)
		SetSliderDialogDefaultValue(1)
		SetSliderDialogRange(1, 2)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
		editedUnitsMenuPage = (value as int) - 1
		SetSliderOptionValueST(editedUnitsMenuPage + 1)
	endEvent

	event OnDefaultST(string state_id)
		editedUnitsMenuPage = 0
		SetSliderOptionValueST(editedUnitsMenuPage + 1)
	endEvent

	event OnHighlightST(string state_id)
		SetInfoText("$sab_mcm_unitedit_slider_menupage_desc")
	endEvent
endState


state UNITEDIT_CUR_UNIT

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedUnitIndex % 128)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, editedUnitsMenuPage)
		SetMenuDialogOptions(editedUnitIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        int trueIndex = index + editedUnitsMenuPage * 128
		editedUnitIndex = trueIndex
		SetMenuOptionValueST(trueIndex)
        ForcePageReset()
	endEvent

	event OnDefaultST(string state_id)
		editedUnitIndex = 0 + editedUnitsMenuPage * 128
		SetMenuOptionValueST(editedUnitIndex)
	endEvent

	event OnHighlightST(string state_id)
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
		SetInfoText("$sab_mcm_unitedit_input_unitname_desc")
	endEvent
    
endstate

state UNITEDIT_HEALTH
	event OnSliderOpenST(string state_id)
        SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "Health"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_health_desc")
	endEvent
endState

state UNITEDIT_STAMINA
	event OnSliderOpenST(string state_id)
        SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "Stamina"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_stamina_desc")
	endEvent
endState

state UNITEDIT_MAGICKA
	event OnSliderOpenST(string state_id)
        SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "Magicka"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_magicka_desc")
	endEvent
endState

state UNITEDIT_OUTFIT

    event OnSelectST(string state_id)
        ; run a raceGenders update on the unit and the outfitter guy, to avoid spawning a "raceless" guy
        MainPage.MainQuest.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
            (jEditedUnitData, (MainPage.MainQuest.UnitDataHandler.SAB_UnitAllowedRacesGenders.GetAt(editedUnitIndex) as LeveledActor))
        MainPage.MainQuest.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
            (jEditedUnitData, MainPage.MainQuest.UnitDataHandler.SAB_UnitLooks_TestGuy)

        ; also set the test guy's outfit to the target unit's outfit
        MainPage.MainQuest.UnitDataHandler.SetupGearListAccordingToUnitData \
            (jEditedUnitData, MainPage.MainQuest.UnitDataHandler.SAB_UnitGear_TestGuy)

        MainPage.MainQuest.SpawnerScript.SpawnCustomizationGuy(jEditedUnitData, editedUnitIndex)
        ShowMessage("$sab_mcm_unitedit_popup_msg_outfitguyspawned", false)
	endEvent

    event OnDefaultST(string state_id)
        ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
    endevent

	event OnHighlightST(string state_id)
		SetInfoText("$sab_mcm_unitedit_button_outfit_desc")
	endEvent

endstate

state UNITEDIT_COPY_ANOTHER_UNIT

	event OnMenuOpenST(string state_id)
		SetMenuDialogStartIndex(editedUnitIndex % 128)
		SetMenuDialogDefaultIndex(0)
        MainPage.MainQuest.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, editedUnitsMenuPage)
		SetMenuDialogOptions(editedUnitIdentifiersArray)
	endEvent

	event OnMenuAcceptST(string state_id, int index)
        if ShowMessage("$sab_mcm_unitedit_popup_msg_confirm_unitcopy")
            int trueIndex = index + editedUnitsMenuPage * 128
            MainPage.MainQuest.UnitDataHandler.CopyUnitDataFromAnotherIndex(editedUnitIndex, trueIndex)
            SetMenuOptionValueST(trueIndex)
            ForcePageReset()
        endif
	endEvent

	event OnDefaultST(string state_id)
		; do nothing
	endEvent

	event OnHighlightST(string state_id)
		SetInfoText("$sab_mcm_unitedit_button_copyfrom_desc")
	endEvent
    
endstate

state UNITEDIT_SKL_MARKSMAN

    event OnSliderOpenST(string state_id)
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "SkillMarksman"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_marksman_desc")
	endEvent

endstate

state UNITEDIT_SKL_ONEHANDED

    event OnSliderOpenST(string state_id)
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "SkillOneHanded"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_onehanded_desc")
	endEvent

endstate

state UNITEDIT_SKL_TWOHANDED

    event OnSliderOpenST(string state_id)
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "SkillTwoHanded"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_twohanded_desc")
	endEvent

endstate

state UNITEDIT_SKL_LIGHTARMOR

    event OnSliderOpenST(string state_id)
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "SkillLightArmor"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_lightarmor_desc")
	endEvent

endstate

state UNITEDIT_SKL_HEAVYARMOR

    event OnSliderOpenST(string state_id)
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "SkillHeavyArmor"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_heavyarmor_desc")
	endEvent

endstate

state UNITEDIT_SKL_BLOCK

    event OnSliderOpenST(string state_id)
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST(string state_id)
        currentFieldBeingEdited = "SkillBlock"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_block_desc")
	endEvent

endstate

state UNITEDIT_RACE_ARGONIAN

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceArgonian"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_KHAJIIT

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceKhajiit"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_ORC

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceOrc"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_BRETON

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceBreton"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_IMPERIAL

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceImperial"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_NORD

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceNord"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_REDGUARD

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceRedguard"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_DARKELF

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceDarkElf"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_HIGHELF

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceHighElf"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_WOODELF

    event OnHighlightST(string state_id)
        currentFieldBeingEdited = "RaceWoodElf"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
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
		SetInfoText("Test Save Guy")
	endEvent
endstate

state UNITEDIT_TEST_LOAD
    event OnSelectST(string state_id)
        MainPage.MainQuest.SpawnerScript.HideCustomizationGuy()
        string filePath = JContainers.userDirectory() + "SAB/unitData.json"
        isLoadingData = true
        int jReadData = JValue.readFromFile(filePath)
        if jReadData != 0
            ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
            ;force a page reset to disable all action buttons!
            ForcePageReset()
            MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray = JValue.releaseAndRetain(MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray, jReadData, "ShoutAndBlade")
            MainPage.MainQuest.UnitDataHandler.EnsureUnitDataArrayCount()
            MainPage.MainQuest.UnitDataHandler.UpdateAllGearAndRaceListsAccordingToJMap()
            isLoadingData = false
            ShowMessage("$sab_mcm_shared_popup_msg_load_success", false)
            ForcePageReset()
        else
            isLoadingData = false
            ShowMessage("$sab_mcm_shared_popup_msg_load_fail", false)
        endif
	endEvent

    event OnDefaultST(string state_id)
        ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
    endevent

	event OnHighlightST(string state_id)
		SetInfoText("Test Load Guy")
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
    SetSliderDialogRange(10.0, 500.0)
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
    SetSliderDialogRange(10.0, 100.0)
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

Function SetEditedUnitSliderValue(string jUnitMapKey, float value)
    JMap.setFlt(jEditedUnitData, jUnitMapKey, value)
    ; JMap.setFlt(SAB_MCM.SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, value)
    SetSliderOptionValueST(value)
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


; returns the text equivalent to the target race/gender status ("male only" for 1, for example).
; Returns "None" for 0 and invalid values
string Function GetEditedUnitRaceStatus(int jUnitData, string raceKey)

    int raceStatus = JMap.getInt(jUnitData, raceKey, 0)

    if raceStatus >= 0 && raceStatus < unitRaceEditOptions.Length
        return unitRaceEditOptions[raceStatus]
    endif

    return "$sab_mcm_unitedit_race_option_none"

endfunction