scriptname SAB_MCM extends SKI_ConfigBase

SAB_MainQuest Property SAB_Main Auto

; since we want more than 128 custom units, we need two arrays (0 or 1 here)
int editedUnitsMenuPage = 0

int editedUnitIndex = 0
int editedFactionIndex = 0
int editedZoneIndex = 0

; the name of the jMap entry being hovered or edited in the currently opened dialog
string currentFieldBeingEdited = ""

; a descriptive type of the field being hovered or edited (like "race menu in edit unit panel").
; Used because I'm too lazy to write the same thing too many times
string currentFieldTypeBeingEdited = ""
float currentSliderDefaultValue = 0.0

string[] editedUnitsArray

string[] unitRaceEditOptions


Event OnConfigInit()
    Pages = new string[5]
    Pages[0] = "$sab_mcm_page_mytroops"
    Pages[1] = "$sab_mcm_page_edit_units"
    Pages[2] = "$sab_mcm_page_edit_factions"
    Pages[3] = "$sab_mcm_page_edit_zones"
    Pages[4] = "$sab_mcm_page_load_save"

    unitRaceEditOptions = new string[4]
    unitRaceEditOptions[0] = "$sab_mcm_unitedit_race_option_none"
    unitRaceEditOptions[1] = "$sab_mcm_unitedit_race_option_male"
    unitRaceEditOptions[2] = "$sab_mcm_unitedit_race_option_female"
    unitRaceEditOptions[3] = "$sab_mcm_unitedit_race_option_both"

    editedUnitsArray = new string[128]
EndEvent

Event OnVersionUpdate(Int a_version)
    ; (brought from tomycubed's Sands of Time mod)
	; a_version is the new version set in GetVersion() above
	; CurrentVersion is the old version currently running - new game will be 0
	Debug.Notification("SAB MCMenu current version = : "+CurrentVersion+" New version =: "+a_version)
	
	If (CurrentVersion < a_version)
		Debug.Trace(Self + ": Updating script to version "+a_version)
		Debug.Notification("Updating SAB McMenu to version: "+a_version)
		Debug.Notification("SAB Update: Recommended to start new game")
	EndIf
	
	OnConfigInit()
EndEvent

Event OnPageReset(string page)
    ; check page, add options according to which page was picked and all that
    if page == Pages[0] || page == "" ; my troops
        SetupMyTroopsPage()
    elseif page == Pages[1] ; edit units
        SetupEditUnitsPage()
    elseif page == Pages[2] ; edit factions
        SetupEditFactionsPage()
    elseif page == Pages[3] ; edit zones
        SetupEditZonesPage()
    elseif page == Pages[4] ; load/save data
        SetupLoadSaveDataPage()
    endif
EndEvent




;---------------------------------------------------------------------------------------------------------
; SHARED STUFF (too much copying of the same stuff to separate)
;---------------------------------------------------------------------------------------------------------


event OnSliderAcceptST(float value)
    if CurrentPage == Pages[1] ; edit units
        SetEditedUnitSliderValue(currentFieldBeingEdited, value)
    endif
endEvent

event OnMenuOpenST()
    if currentFieldTypeBeingEdited == "unitedit_racegender_menu"
        SetupEditedUnitRaceMenuOnOpen(currentFieldBeingEdited)
    endif
endEvent

event OnMenuAcceptST(int index)
    if currentFieldTypeBeingEdited == "unitedit_racegender_menu"
        SetEditedUnitRaceMenuValue(currentFieldBeingEdited, index)
    endif
endEvent

event OnDefaultST()
    if currentFieldTypeBeingEdited == "unitedit_slider"
        SetEditedUnitSliderValue(currentFieldBeingEdited, currentSliderDefaultValue)
    ElseIf currentFieldTypeBeingEdited == "unitedit_racegender_menu"
        SetEditedUnitRaceMenuValue(currentFieldBeingEdited, 0)
    endif
endEvent



;---------------------------------------------------------------------------------------------------------
; MY TROOPS PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupMyTroopsPage()
    ; code
EndFunction




;---------------------------------------------------------------------------------------------------------
; EDIT UNITS PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupEditUnitsPage()
    SetCursorFillMode(TOP_TO_BOTTOM)

    ;string editedUnitName = GetEditedUnitName()
    
    AddHeaderOption("$sab_mcm_unitedit_header_selectunit")
    AddSliderOptionST("UNITEDIT_MENU_PAGE", "$sab_mcm_unitedit_slider_menupage", editedUnitsMenuPage + 1)
    AddMenuOptionST("UNITEDIT_CUR_UNIT", "$sab_mcm_unitedit_menu_currentunit", JMap.getStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit"))
    
    AddHeaderOption("$sab_mcm_unitedit_header_baseinfo")
    AddInputOptionST("UNITEDIT_NAME", "$sab_mcm_unitedit_input_unitname", JMap.getStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit"))
    AddSliderOptionST("UNITEDIT_HEALTH", "$sab_mcm_unitedit_slider_health", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "Health", 50.0))
    AddSliderOptionST("UNITEDIT_STAMINA", "$sab_mcm_unitedit_slider_stamina", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "Stamina", 50.0))
    AddSliderOptionST("UNITEDIT_MAGICKA", "$sab_mcm_unitedit_slider_magicka", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "Magicka", 50.0))

    AddEmptyOption()
    AddTextOptionST("UNITEDIT_OUTFIT", "$sab_mcm_unitedit_button_outfit", "")
    AddEmptyOption()
    AddTextOptionST("UNITEDIT_TEST_SAVE", "(Debug) Save testGuy data", "")
    AddTextOptionST("UNITEDIT_TEST_LOAD", "(Debug) Load testGuy data", "")

    SetCursorPosition(1)

    AddHeaderOption("$sab_mcm_unitedit_header_skills")
    AddSliderOptionST("UNITEDIT_SKL_MARKSMAN", "$sab_mcm_unitedit_slider_marksman", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillMarksman", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_ONEHANDED", "$sab_mcm_unitedit_slider_onehanded", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillOneHanded", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_TWOHANDED", "$sab_mcm_unitedit_slider_twohanded", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillTwoHanded", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_LIGHTARMOR", "$sab_mcm_unitedit_slider_lightarmor", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillLightArmor", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_HEAVYARMOR", "$sab_mcm_unitedit_slider_heavyarmor", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillHeavyArmor", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_BLOCK", "$sab_mcm_unitedit_slider_block", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillBlock", 15.0))

    AddEmptyOption()

    AddHeaderOption("$sab_mcm_unitedit_header_races")
    AddMenuOptionST("UNITEDIT_RACE_ARGONIAN", "$sab_mcm_unitedit_race_arg", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceArgonian"))
    AddMenuOptionST("UNITEDIT_RACE_KHAJIIT", "$sab_mcm_unitedit_race_kha", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceKhajiit"))
    AddMenuOptionST("UNITEDIT_RACE_ORC", "$sab_mcm_unitedit_race_orc", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceOrc"))
    AddMenuOptionST("UNITEDIT_RACE_BRETON", "$sab_mcm_unitedit_race_bre", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceBreton"))
    AddMenuOptionST("UNITEDIT_RACE_IMPERIAL", "$sab_mcm_unitedit_race_imp", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceImperial"))
    AddMenuOptionST("UNITEDIT_RACE_NORD", "$sab_mcm_unitedit_race_nor", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceNord"))
    AddMenuOptionST("UNITEDIT_RACE_REDGUARD", "$sab_mcm_unitedit_race_red", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceRedguard"))
    AddMenuOptionST("UNITEDIT_RACE_DARKELF", "$sab_mcm_unitedit_race_daf", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceDarkElf"))
    AddMenuOptionST("UNITEDIT_RACE_HIGHELF", "$sab_mcm_unitedit_race_hif", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceHighElf"))
    AddMenuOptionST("UNITEDIT_RACE_WOODELF", "$sab_mcm_unitedit_race_wof", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceWoodElf"))
    
EndFunction


state UNITEDIT_MENU_PAGE
	event OnSliderOpenST()
		SetSliderDialogStartValue(editedUnitsMenuPage + 1)
		SetSliderDialogDefaultValue(1)
		SetSliderDialogRange(1, 2)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(float value)
		editedUnitsMenuPage = (value as int) - 1
		SetSliderOptionValueST(editedUnitsMenuPage)
	endEvent

	event OnDefaultST()
		editedUnitsMenuPage = 0
		SetSliderOptionValueST(editedUnitsMenuPage + 1)
	endEvent

	event OnHighlightST()
		SetInfoText("$sab_mcm_unitedit_slider_menupage_desc")
	endEvent
endState


state UNITEDIT_CUR_UNIT

	event OnMenuOpenST()
		SetMenuDialogStartIndex(editedUnitIndex % 128)
		SetMenuDialogDefaultIndex(0)
		SetMenuDialogOptions(new string[128]) ;TODO fill options with unit names and stuff
	endEvent

	event OnMenuAcceptST(int index)
        int trueIndex = index + editedUnitsMenuPage * 128
		editedUnitIndex = trueIndex
		SetMenuOptionValueST(trueIndex)
	endEvent

	event OnDefaultST()
		editedUnitIndex = 0 + editedUnitsMenuPage * 128
		SetMenuOptionValueST(editedUnitIndex)
	endEvent

	event OnHighlightST()
		SetInfoText("$sab_mcm_unitedit_menu_currentunit_desc")
	endEvent
    
endstate

state UNITEDIT_NAME

	event OnInputOpenST()
        ;string unitName = JMap.getStr(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), "Name", "Recruit")
        string unitName = JMap.getStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit")
		SetInputDialogStartText(unitName)
	endEvent

	event OnInputAcceptST(string inputs)
        ; JMap.setStr(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), "Name", input)
        JMap.setStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", inputs)
        SetInputOptionValueST(inputs)

        ;force a reset to update other fields that use the name
        ForcePageReset()
	endEvent

	event OnDefaultST()

        ;JMap.setStr(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), "Name", "Recruit")
        JMap.setStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit")

		SetInputOptionValueST("Recruit")

        ;force a reset to update other fields that use the name
        ForcePageReset()
	endEvent

	event OnHighlightST()
		SetInfoText("$sab_mcm_unitedit_input_unitname_desc")
	endEvent
    
endstate

state UNITEDIT_HEALTH
	event OnSliderOpenST()
        SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "Health"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_health_desc")
	endEvent
endState

state UNITEDIT_STAMINA
	event OnSliderOpenST()
        SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "Stamina"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_stamina_desc")
	endEvent
endState

state UNITEDIT_MAGICKA
	event OnSliderOpenST()
        SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "Magicka"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_magicka_desc")
	endEvent
endState

state UNITEDIT_OUTFIT

    event OnSelectST()
        ; run a raceGenders update on the unit, to avoid spawning a "raceless" guy
        SAB_Main.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
            (SAB_Main.UnitDataHandler.jTestGuyData, SAB_Main.UnitDataHandler.SAB_UnitLooks_TestGuy)
        SAB_Main.SpawnerScript.SpawnCustomizationGuy(SAB_Main.UnitDataHandler.jTestGuyData, editedUnitIndex)
        ShowMessage("$sab_mcm_unitedit_popup_msg_outfitguyspawned", false)
	endEvent

    event OnDefaultST()
        ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
    endevent

	event OnHighlightST()
		SetInfoText("$sab_mcm_unitedit_button_outfit_desc")
	endEvent

endstate

state UNITEDIT_SKL_MARKSMAN

    event OnSliderOpenST()
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "SkillMarksman"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_marksman_desc")
	endEvent

endstate

state UNITEDIT_SKL_ONEHANDED

    event OnSliderOpenST()
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "SkillOneHanded"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_onehanded_desc")
	endEvent

endstate

state UNITEDIT_SKL_TWOHANDED

    event OnSliderOpenST()
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "SkillTwoHanded"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_twohanded_desc")
	endEvent

endstate

state UNITEDIT_SKL_LIGHTARMOR

    event OnSliderOpenST()
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "SkillLightArmor"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_lightarmor_desc")
	endEvent

endstate

state UNITEDIT_SKL_HEAVYARMOR

    event OnSliderOpenST()
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "SkillHeavyArmor"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_heavyarmor_desc")
	endEvent

endstate

state UNITEDIT_SKL_BLOCK

    event OnSliderOpenST()
        SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
	endEvent

	event OnHighlightST()
        currentFieldBeingEdited = "SkillBlock"
        currentFieldTypeBeingEdited = "unitedit_slider"
		SetInfoText("$sab_mcm_unitedit_slider_block_desc")
	endEvent

endstate

state UNITEDIT_RACE_ARGONIAN

    event OnHighlightST()
        currentFieldBeingEdited = "RaceArgonian"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_KHAJIIT

    event OnHighlightST()
        currentFieldBeingEdited = "RaceKhajiit"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_ORC

    event OnHighlightST()
        currentFieldBeingEdited = "RaceOrc"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_BRETON

    event OnHighlightST()
        currentFieldBeingEdited = "RaceBreton"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_IMPERIAL

    event OnHighlightST()
        currentFieldBeingEdited = "RaceImperial"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_NORD

    event OnHighlightST()
        currentFieldBeingEdited = "RaceNord"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_REDGUARD

    event OnHighlightST()
        currentFieldBeingEdited = "RaceRedguard"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_DARKELF

    event OnHighlightST()
        currentFieldBeingEdited = "RaceDarkElf"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_HIGHELF

    event OnHighlightST()
        currentFieldBeingEdited = "RaceHighElf"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_RACE_WOODELF

    event OnHighlightST()
        currentFieldBeingEdited = "RaceWoodElf"
        currentFieldTypeBeingEdited = "unitedit_racegender_menu"
		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
	endEvent

endstate

state UNITEDIT_TEST_SAVE
    event OnSelectST()
        string filePath = JContainers.userDirectory() + "SAB/testGuyData.json"
        JValue.writeToFile(SAB_Main.UnitDataHandler.jTestGuyData, filePath)
        ShowMessage("Save finished. Saved to: " + filePath, false)
	endEvent

    event OnDefaultST()
        ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
    endevent

	event OnHighlightST()
		SetInfoText("Test Save Guy")
	endEvent
endstate

state UNITEDIT_TEST_LOAD
    event OnSelectST()
        string filePath = JContainers.userDirectory() + "SAB/testGuyData.json"
        int jReadData = JValue.readFromFile(filePath)
        if jReadData != 0
            SAB_Main.UnitDataHandler.jTestGuyData = JValue.releaseAndRetain(SAB_Main.UnitDataHandler.jTestGuyData, jReadData, "ShoutAndBlade")
            SAB_Main.UnitDataHandler.UpdateGearAndRaceListsAccordingToJMap()
            ShowMessage("Load successful!", false)
            ForcePageReset()
        else
            ShowMessage("Load failed! The file probably does not exist", false)
        endif
	endEvent

    event OnDefaultST()
        ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
    endevent

	event OnHighlightST()
		SetInfoText("Test Load Guy")
	endEvent
endstate

; sets up common base actor value (health, magicka, stamina) sliders
Function SetupEditedUnitBaseAVSliderOnOpen(string jUnitMapKey)
    currentFieldBeingEdited = jUnitMapKey
    currentSliderDefaultValue = 50.0
    ;float curValue = JMap.getFlt(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), jUnitMapKey, currentSliderDefaultValue)
    float curValue = JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, currentSliderDefaultValue)
    SetSliderDialogStartValue(curValue)
    SetSliderDialogDefaultValue(currentSliderDefaultValue)
    SetSliderDialogRange(10.0, 500.0)
    SetSliderDialogInterval(5)
EndFunction

; sets up skill actor value (oneHanded, Block, Marksman) sliders
Function SetupEditedUnitSkillSliderOnOpen(string jUnitMapKey)
    currentFieldBeingEdited = jUnitMapKey
    currentSliderDefaultValue = 15.0
    ;float curValue = JMap.getFlt(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), jUnitMapKey, currentSliderDefaultValue)
    float curValue = JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, currentSliderDefaultValue)
    SetSliderDialogStartValue(curValue)
    SetSliderDialogDefaultValue(currentSliderDefaultValue)
    SetSliderDialogRange(10.0, 100.0)
    SetSliderDialogInterval(1)
EndFunction

; sets up an allowed race/gender menu
Function SetupEditedUnitRaceMenuOnOpen(string jUnitMapKey)
    currentFieldBeingEdited = jUnitMapKey
    ;int curValue = JMap.getInt(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), jUnitMapKey, 0)
    int curValue = JMap.getInt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, 0)
    SetMenuDialogStartIndex(curValue)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(unitRaceEditOptions)
EndFunction

Function SetEditedUnitSliderValue(string jUnitMapKey, float value)
    ; JMap.setFlt(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), jUnitMapKey, value)
    JMap.setFlt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, value)
    SetSliderOptionValueST(value)
EndFunction

Function SetEditedUnitRaceMenuValue(string jUnitMapKey, int value)
    ; JMap.setInt(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), jUnitMapKey, value)
    JMap.setInt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, value)

    ;SAB_Main.UnitDataHandler.SetupRaceGendersAccordingToUnitIndex(editedUnitIndex)
    SAB_Main.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
        (SAB_Main.UnitDataHandler.jTestGuyData, SAB_Main.UnitDataHandler.SAB_UnitLooks_TestGuy)

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

string Function GetEditedUnitName()
    string value = "--NO UNIT SELECTED--"
    
    if editedUnitIndex != 0
        int junitData = JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex)

        if junitData == 0
            return value
        endif

        return JMap.getStr(junitData, "Name", "Recruit")
    endif

    return value
EndFunction


;---------------------------------------------------------------------------------------------------------
; EDIT FACTIONS PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupEditFactionsPage()
    ; code
EndFunction



;---------------------------------------------------------------------------------------------------------
; EDIT ZONES PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupEditZonesPage()
    ; code
EndFunction



;---------------------------------------------------------------------------------------------------------
; LOAD/SAVE PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupLoadSaveDataPage()
    ; code
EndFunction