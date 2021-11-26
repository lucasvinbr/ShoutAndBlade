scriptname SAB_MCM extends nl_mcm_module

SAB_MainQuest Property MainQuest Auto

event OnInit()
    RegisterModule("$sab_mcm_page_load_save", 4)
endevent

event OnPageInit()
    SetModName("Shout and Blade")
    SetLandingPage("$sab_mcm_page_edit_units")
endevent

event OnPageDraw()
    SetCursorFillMode(TOP_TO_BOTTOM)

    AddHeaderOption("Main Options")
    AddParagraph("Nothing here yet")
endevent

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
	
	OnPageInit()
EndEvent


; Event OnConfigInit()
;     ; Pages = new string[5]
;     ; Pages[0] = "$sab_mcm_page_mytroops"
;     ; Pages[1] = "$sab_mcm_page_edit_units"
;     ; Pages[2] = "$sab_mcm_page_edit_factions"
;     ; Pages[3] = "$sab_mcm_page_edit_zones"
;     ; Pages[4] = "$sab_mcm_page_load_save"


; EndEvent

; Event OnPageReset(string page)

;     if page == ""
;         page = lastOpenedModPage
;     endif

;     ; check page, add options according to which page was picked and all that
;     if page == Pages[0] || page == "" ; my troops
;         lastOpenedModPage = Pages[0]
;         SetupMyTroopsPage()
;     elseif page == Pages[1] ; edit units
;         lastOpenedModPage = Pages[1]
;         SetupEditUnitsPage()
;     elseif page == Pages[2] ; edit factions
;         lastOpenedModPage = Pages[2]
;         SetupEditFactionsPage()
;     elseif page == Pages[3] ; edit zones
;         lastOpenedModPage = Pages[3]
;         SetupEditZonesPage()
;     elseif page == Pages[4] ; load/save data
;         lastOpenedModPage = Pages[4]
;         SetupLoadSaveDataPage()
;     endif
; EndEvent

; ;---------------------------------------------------------------------------------------------------------
; ; SHARED STUFF (too much copying of the same stuff to separate)
; ;---------------------------------------------------------------------------------------------------------

; state SHARED_LOADING

;     event OnSelectST()
;         ; nothing
; 	endEvent

;     event OnDefaultST()
;         ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
;     endevent

; 	event OnHighlightST()
; 		SetInfoText("$sab_mcm_shared_loading_desc")
; 	endEvent

; endstate

; event OnSliderAcceptST(float value)
;     if CurrentPage == Pages[1] ; edit units
;         SetEditedUnitSliderValue(currentFieldBeingEdited, value)
;     endif
; endEvent

; event OnMenuOpenST()
;     if currentFieldTypeBeingEdited == "unitedit_racegender_menu"
;         SetupEditedUnitRaceMenuOnOpen(currentFieldBeingEdited)
;     endif
; endEvent

; event OnMenuAcceptST(int index)
;     if currentFieldTypeBeingEdited == "unitedit_racegender_menu"
;         SetEditedUnitRaceMenuValue(currentFieldBeingEdited, index)
;     endif
; endEvent

; event OnDefaultST()
;     if currentFieldTypeBeingEdited == "unitedit_slider"
;         SetEditedUnitSliderValue(currentFieldBeingEdited, currentSliderDefaultValue)
;     ElseIf currentFieldTypeBeingEdited == "unitedit_racegender_menu"
;         SetEditedUnitRaceMenuValue(currentFieldBeingEdited, 0)
;     endif
; endEvent



; ;---------------------------------------------------------------------------------------------------------
; ; MY TROOPS PAGE STUFF
; ;---------------------------------------------------------------------------------------------------------

; Function SetupMyTroopsPage()
;     if isLoadingData
;         AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
;         return
;     endif


; EndFunction




; ;---------------------------------------------------------------------------------------------------------
; ; EDIT UNITS PAGE STUFF
; ;---------------------------------------------------------------------------------------------------------

; Function SetupEditUnitsPage()

;     if isLoadingData
;         AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
;         return
;     endif

;     SetCursorFillMode(TOP_TO_BOTTOM)

;     jEditedUnitData = jArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex)

;     if jEditedUnitData == 0
;         jEditedUnitData = jMap.object()
;         JArray.setObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex, jEditedUnitData)
;     endif
    
;     AddHeaderOption("$sab_mcm_unitedit_header_selectunit")
;     AddSliderOptionST("UNITEDIT_MENU_PAGE", "$sab_mcm_unitedit_slider_menupage", editedUnitsMenuPage + 1)
;     AddMenuOptionST("UNITEDIT_CUR_UNIT", "$sab_mcm_unitedit_menu_currentunit", \
;         ((editedUnitIndex + 1) as string) + " - " + JMap.getStr(jEditedUnitData, "Name", "Recruit"))
    
;     AddHeaderOption("$sab_mcm_unitedit_header_baseinfo")
;     AddInputOptionST("UNITEDIT_NAME", "$sab_mcm_unitedit_input_unitname", JMap.getStr(jEditedUnitData, "Name", "Recruit"))
;     AddSliderOptionST("UNITEDIT_HEALTH", "$sab_mcm_unitedit_slider_health", JMap.getFlt(jEditedUnitData, "Health", 50.0))
;     AddSliderOptionST("UNITEDIT_STAMINA", "$sab_mcm_unitedit_slider_stamina", JMap.getFlt(jEditedUnitData, "Stamina", 50.0))
;     AddSliderOptionST("UNITEDIT_MAGICKA", "$sab_mcm_unitedit_slider_magicka", JMap.getFlt(jEditedUnitData, "Magicka", 50.0))

;     AddEmptyOption()
;     AddTextOptionST("UNITEDIT_OUTFIT", "$sab_mcm_unitedit_button_outfit", "")
;     AddEmptyOption()
;     AddMenuOptionST("UNITEDIT_COPY_ANOTHER_UNIT", "$sab_mcm_unitedit_button_copyfrom", \
;     "$sab_mcm_unitedit_button_copyfrom_value")
;     AddEmptyOption()
;     AddTextOptionST("UNITEDIT_TEST_SAVE", "(Debug) Save testGuy data", "")
;     AddTextOptionST("UNITEDIT_TEST_LOAD", "(Debug) Load testGuy data", "")

;     SetCursorPosition(1)

;     AddHeaderOption("$sab_mcm_unitedit_header_skills")
;     AddSliderOptionST("UNITEDIT_SKL_MARKSMAN", "$sab_mcm_unitedit_slider_marksman", JMap.getFlt(jEditedUnitData, "SkillMarksman", 15.0))
;     AddSliderOptionST("UNITEDIT_SKL_ONEHANDED", "$sab_mcm_unitedit_slider_onehanded", JMap.getFlt(jEditedUnitData, "SkillOneHanded", 15.0))
;     AddSliderOptionST("UNITEDIT_SKL_TWOHANDED", "$sab_mcm_unitedit_slider_twohanded", JMap.getFlt(jEditedUnitData, "SkillTwoHanded", 15.0))
;     AddSliderOptionST("UNITEDIT_SKL_LIGHTARMOR", "$sab_mcm_unitedit_slider_lightarmor", JMap.getFlt(jEditedUnitData, "SkillLightArmor", 15.0))
;     AddSliderOptionST("UNITEDIT_SKL_HEAVYARMOR", "$sab_mcm_unitedit_slider_heavyarmor", JMap.getFlt(jEditedUnitData, "SkillHeavyArmor", 15.0))
;     AddSliderOptionST("UNITEDIT_SKL_BLOCK", "$sab_mcm_unitedit_slider_block", JMap.getFlt(jEditedUnitData, "SkillBlock", 15.0))

;     AddEmptyOption()

;     AddHeaderOption("$sab_mcm_unitedit_header_races")
;     AddMenuOptionST("UNITEDIT_RACE_ARGONIAN", "$sab_mcm_unitedit_race_arg", GetEditedUnitRaceStatus(jEditedUnitData, "RaceArgonian"))
;     AddMenuOptionST("UNITEDIT_RACE_KHAJIIT", "$sab_mcm_unitedit_race_kha", GetEditedUnitRaceStatus(jEditedUnitData, "RaceKhajiit"))
;     AddMenuOptionST("UNITEDIT_RACE_ORC", "$sab_mcm_unitedit_race_orc", GetEditedUnitRaceStatus(jEditedUnitData, "RaceOrc"))
;     AddMenuOptionST("UNITEDIT_RACE_BRETON", "$sab_mcm_unitedit_race_bre", GetEditedUnitRaceStatus(jEditedUnitData, "RaceBreton"))
;     AddMenuOptionST("UNITEDIT_RACE_IMPERIAL", "$sab_mcm_unitedit_race_imp", GetEditedUnitRaceStatus(jEditedUnitData, "RaceImperial"))
;     AddMenuOptionST("UNITEDIT_RACE_NORD", "$sab_mcm_unitedit_race_nor", GetEditedUnitRaceStatus(jEditedUnitData, "RaceNord"))
;     AddMenuOptionST("UNITEDIT_RACE_REDGUARD", "$sab_mcm_unitedit_race_red", GetEditedUnitRaceStatus(jEditedUnitData, "RaceRedguard"))
;     AddMenuOptionST("UNITEDIT_RACE_DARKELF", "$sab_mcm_unitedit_race_daf", GetEditedUnitRaceStatus(jEditedUnitData, "RaceDarkElf"))
;     AddMenuOptionST("UNITEDIT_RACE_HIGHELF", "$sab_mcm_unitedit_race_hif", GetEditedUnitRaceStatus(jEditedUnitData, "RaceHighElf"))
;     AddMenuOptionST("UNITEDIT_RACE_WOODELF", "$sab_mcm_unitedit_race_wof", GetEditedUnitRaceStatus(jEditedUnitData, "RaceWoodElf"))
    
; EndFunction


; state UNITEDIT_MENU_PAGE
; 	event OnSliderOpenST()
; 		SetSliderDialogStartValue(editedUnitsMenuPage + 1)
; 		SetSliderDialogDefaultValue(1)
; 		SetSliderDialogRange(1, 2)
; 		SetSliderDialogInterval(1)
; 	endEvent

; 	event OnSliderAcceptST(float value)
; 		editedUnitsMenuPage = (value as int) - 1
; 		SetSliderOptionValueST(editedUnitsMenuPage + 1)
; 	endEvent

; 	event OnDefaultST()
; 		editedUnitsMenuPage = 0
; 		SetSliderOptionValueST(editedUnitsMenuPage + 1)
; 	endEvent

; 	event OnHighlightST()
; 		SetInfoText("$sab_mcm_unitedit_slider_menupage_desc")
; 	endEvent
; endState


; state UNITEDIT_CUR_UNIT

; 	event OnMenuOpenST()
; 		SetMenuDialogStartIndex(editedUnitIndex % 128)
; 		SetMenuDialogDefaultIndex(0)
;         SAB_Main.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, editedUnitsMenuPage)
; 		SetMenuDialogOptions(editedUnitIdentifiersArray)
; 	endEvent

; 	event OnMenuAcceptST(int index)
;         int trueIndex = index + editedUnitsMenuPage * 128
; 		editedUnitIndex = trueIndex
; 		SetMenuOptionValueST(trueIndex)
;         ForcePageReset()
; 	endEvent

; 	event OnDefaultST()
; 		editedUnitIndex = 0 + editedUnitsMenuPage * 128
; 		SetMenuOptionValueST(editedUnitIndex)
; 	endEvent

; 	event OnHighlightST()
; 		SetInfoText("$sab_mcm_unitedit_menu_currentunit_desc")
; 	endEvent
    
; endstate

; state UNITEDIT_NAME

; 	event OnInputOpenST()
;         string unitName = JMap.getStr(jEditedUnitData, "Name", "Recruit")
;         ; string unitName = JMap.getStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit")
; 		SetInputDialogStartText(unitName)
; 	endEvent

; 	event OnInputAcceptST(string inputs)
;         JMap.setStr(jEditedUnitData, "Name", inputs)
;         ; JMap.setStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", inputs)
;         SetInputOptionValueST(inputs)

;         ;force a reset to update other fields that use the name
;         ForcePageReset()
; 	endEvent

; 	event OnDefaultST()

;         JMap.setStr(jEditedUnitData, "Name", "Recruit")
;         ; JMap.setStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit")

; 		SetInputOptionValueST("Recruit")

;         ;force a reset to update other fields that use the name
;         ForcePageReset()
; 	endEvent

; 	event OnHighlightST()
; 		SetInfoText("$sab_mcm_unitedit_input_unitname_desc")
; 	endEvent
    
; endstate

; state UNITEDIT_HEALTH
; 	event OnSliderOpenST()
;         SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "Health"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_health_desc")
; 	endEvent
; endState

; state UNITEDIT_STAMINA
; 	event OnSliderOpenST()
;         SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "Stamina"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_stamina_desc")
; 	endEvent
; endState

; state UNITEDIT_MAGICKA
; 	event OnSliderOpenST()
;         SetupEditedUnitBaseAVSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "Magicka"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_magicka_desc")
; 	endEvent
; endState

; state UNITEDIT_OUTFIT

;     event OnSelectST()
;         ; run a raceGenders update on the unit and the outfitter guy, to avoid spawning a "raceless" guy
;         SAB_Main.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
;             (jEditedUnitData, (SAB_Main.UnitDataHandler.SAB_UnitAllowedRacesGenders.GetAt(editedUnitIndex) as LeveledActor))
;         SAB_Main.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
;             (jEditedUnitData, SAB_Main.UnitDataHandler.SAB_UnitLooks_TestGuy)

;         ; also set the test guy's outfit to the target unit's outfit
;         SAB_Main.UnitDataHandler.SetupGearListAccordingToUnitData \
;             (jEditedUnitData, SAB_Main.UnitDataHandler.SAB_UnitGear_TestGuy)

;         SAB_Main.SpawnerScript.SpawnCustomizationGuy(jEditedUnitData, editedUnitIndex)
;         ShowMessage("$sab_mcm_unitedit_popup_msg_outfitguyspawned", false)
; 	endEvent

;     event OnDefaultST()
;         ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
;     endevent

; 	event OnHighlightST()
; 		SetInfoText("$sab_mcm_unitedit_button_outfit_desc")
; 	endEvent

; endstate

; state UNITEDIT_COPY_ANOTHER_UNIT

; 	event OnMenuOpenST()
; 		SetMenuDialogStartIndex(editedUnitIndex % 128)
; 		SetMenuDialogDefaultIndex(0)
;         SAB_Main.UnitDataHandler.SetupStringArrayWithUnitIdentifiers(editedUnitIdentifiersArray, editedUnitsMenuPage)
; 		SetMenuDialogOptions(editedUnitIdentifiersArray)
; 	endEvent

; 	event OnMenuAcceptST(int index)
;         if ShowMessage("$sab_mcm_unitedit_popup_msg_confirm_unitcopy")
;             int trueIndex = index + editedUnitsMenuPage * 128
;             SAB_Main.UnitDataHandler.CopyUnitDataFromAnotherIndex(editedUnitIndex, trueIndex)
;             SetMenuOptionValueST(trueIndex)
;             ForcePageReset()
;         endif
; 	endEvent

; 	event OnDefaultST()
; 		; do nothing
; 	endEvent

; 	event OnHighlightST()
; 		SetInfoText("$sab_mcm_unitedit_button_copyfrom_desc")
; 	endEvent
    
; endstate

; state UNITEDIT_SKL_MARKSMAN

;     event OnSliderOpenST()
;         SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "SkillMarksman"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_marksman_desc")
; 	endEvent

; endstate

; state UNITEDIT_SKL_ONEHANDED

;     event OnSliderOpenST()
;         SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "SkillOneHanded"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_onehanded_desc")
; 	endEvent

; endstate

; state UNITEDIT_SKL_TWOHANDED

;     event OnSliderOpenST()
;         SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "SkillTwoHanded"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_twohanded_desc")
; 	endEvent

; endstate

; state UNITEDIT_SKL_LIGHTARMOR

;     event OnSliderOpenST()
;         SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "SkillLightArmor"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_lightarmor_desc")
; 	endEvent

; endstate

; state UNITEDIT_SKL_HEAVYARMOR

;     event OnSliderOpenST()
;         SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "SkillHeavyArmor"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_heavyarmor_desc")
; 	endEvent

; endstate

; state UNITEDIT_SKL_BLOCK

;     event OnSliderOpenST()
;         SetupEditedUnitSkillSliderOnOpen(currentFieldBeingEdited)
; 	endEvent

; 	event OnHighlightST()
;         currentFieldBeingEdited = "SkillBlock"
;         currentFieldTypeBeingEdited = "unitedit_slider"
; 		SetInfoText("$sab_mcm_unitedit_slider_block_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_ARGONIAN

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceArgonian"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_KHAJIIT

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceKhajiit"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_ORC

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceOrc"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_BRETON

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceBreton"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_IMPERIAL

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceImperial"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_NORD

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceNord"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_REDGUARD

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceRedguard"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_DARKELF

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceDarkElf"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_HIGHELF

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceHighElf"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_RACE_WOODELF

;     event OnHighlightST()
;         currentFieldBeingEdited = "RaceWoodElf"
;         currentFieldTypeBeingEdited = "unitedit_racegender_menu"
; 		SetInfoText("$sab_mcm_unitedit_race_generic_desc")
; 	endEvent

; endstate

; state UNITEDIT_TEST_SAVE
;     event OnSelectST()
;         string filePath = JContainers.userDirectory() + "SAB/unitData.json"
;         JValue.writeToFile(SAB_Main.UnitDataHandler.jSABUnitDatasArray, filePath)
;         ShowMessage("Save: " + filePath, false)
; 	endEvent

;     event OnDefaultST()
;         ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
;     endevent

; 	event OnHighlightST()
; 		SetInfoText("Test Save Guy")
; 	endEvent
; endstate

; state UNITEDIT_TEST_LOAD
;     event OnSelectST()
;         SAB_Main.SpawnerScript.HideCustomizationGuy()
;         string filePath = JContainers.userDirectory() + "SAB/unitData.json"
;         isLoadingData = true
;         int jReadData = JValue.readFromFile(filePath)
;         if jReadData != 0
;             ShowMessage("$sab_mcm_shared_popup_msg_load_started", false)
;             ;force a page reset to disable all action buttons!
;             ForcePageReset()
;             SAB_Main.UnitDataHandler.jSABUnitDatasArray = JValue.releaseAndRetain(SAB_Main.UnitDataHandler.jSABUnitDatasArray, jReadData, "ShoutAndBlade")
;             SAB_Main.UnitDataHandler.EnsureUnitDataArrayCount()
;             SAB_Main.UnitDataHandler.UpdateAllGearAndRaceListsAccordingToJMap()
;             isLoadingData = false
;             ShowMessage("$sab_mcm_shared_popup_msg_load_success", false)
;             ForcePageReset()
;         else
;             isLoadingData = false
;             ShowMessage("$sab_mcm_shared_popup_msg_load_fail", false)
;         endif
; 	endEvent

;     event OnDefaultST()
;         ; nothing, just here to not fall back to the default "reset slider" procedure set up in the "common" section
;     endevent

; 	event OnHighlightST()
; 		SetInfoText("Test Load Guy")
; 	endEvent
; endstate

; ; sets up common base actor value (health, magicka, stamina) sliders
; Function SetupEditedUnitBaseAVSliderOnOpen(string jUnitMapKey)
;     currentFieldBeingEdited = jUnitMapKey
;     currentSliderDefaultValue = 50.0
;     float curValue = JMap.getFlt(jEditedUnitData, jUnitMapKey, currentSliderDefaultValue)
;     ; float curValue = JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, currentSliderDefaultValue)
;     SetSliderDialogStartValue(curValue)
;     SetSliderDialogDefaultValue(currentSliderDefaultValue)
;     SetSliderDialogRange(10.0, 500.0)
;     SetSliderDialogInterval(5)
; EndFunction

; ; sets up skill actor value (oneHanded, Block, Marksman) sliders
; Function SetupEditedUnitSkillSliderOnOpen(string jUnitMapKey)
;     currentFieldBeingEdited = jUnitMapKey
;     currentSliderDefaultValue = 15.0
;     float curValue = JMap.getFlt(jEditedUnitData, jUnitMapKey, currentSliderDefaultValue)
;     ; float curValue = JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, currentSliderDefaultValue)
;     SetSliderDialogStartValue(curValue)
;     SetSliderDialogDefaultValue(currentSliderDefaultValue)
;     SetSliderDialogRange(10.0, 100.0)
;     SetSliderDialogInterval(1)
; EndFunction

; ; sets up an allowed race/gender menu
; Function SetupEditedUnitRaceMenuOnOpen(string jUnitMapKey)
;     currentFieldBeingEdited = jUnitMapKey
;     int curValue = JMap.getInt(jEditedUnitData, jUnitMapKey, 0)
;     ; int curValue = JMap.getInt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, 0)
;     SetMenuDialogStartIndex(curValue)
;     SetMenuDialogDefaultIndex(0)
;     SetMenuDialogOptions(unitRaceEditOptions)
; EndFunction

; Function SetEditedUnitSliderValue(string jUnitMapKey, float value)
;     JMap.setFlt(jEditedUnitData, jUnitMapKey, value)
;     ; JMap.setFlt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, value)
;     SetSliderOptionValueST(value)
; EndFunction

; Function SetEditedUnitRaceMenuValue(string jUnitMapKey, int value)
;     JMap.setInt(jEditedUnitData, jUnitMapKey, value)
;     ; JMap.setInt(SAB_Main.UnitDataHandler.jTestGuyData, jUnitMapKey, value)

;     SAB_Main.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
;         (jEditedUnitData, SAB_Main.UnitDataHandler.SAB_UnitAllowedRacesGenders.GetAt(editedUnitIndex) as LeveledActor)
;     ; SAB_Main.UnitDataHandler.SetupRaceGendersLvlActorAccordingToUnitData \ 
;     ;     (SAB_Main.UnitDataHandler.jTestGuyData, SAB_Main.UnitDataHandler.SAB_UnitLooks_TestGuy)
    

;     SetMenuOptionValueST(unitRaceEditOptions[value])
; EndFunction


; ; returns the text equivalent to the target race/gender status ("male only" for 1, for example).
; ; Returns "None" for 0 and invalid values
; string Function GetEditedUnitRaceStatus(int jUnitData, string raceKey)

;     int raceStatus = JMap.getInt(jUnitData, raceKey, 0)

;     if raceStatus >= 0 && raceStatus < unitRaceEditOptions.Length
;         return unitRaceEditOptions[raceStatus]
;     endif

;     return "$sab_mcm_unitedit_race_option_none"

; endfunction


; ;---------------------------------------------------------------------------------------------------------
; ; EDIT FACTIONS PAGE STUFF
; ;---------------------------------------------------------------------------------------------------------

; Function SetupEditFactionsPage()
;     if isLoadingData
;         AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
;         return
;     endif


; EndFunction



; ;---------------------------------------------------------------------------------------------------------
; ; EDIT ZONES PAGE STUFF
; ;---------------------------------------------------------------------------------------------------------

; Function SetupEditZonesPage()
;     if isLoadingData
;         AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
;         return
;     endif


; EndFunction



; ;---------------------------------------------------------------------------------------------------------
; ; LOAD/SAVE PAGE STUFF
; ;---------------------------------------------------------------------------------------------------------

; Function SetupLoadSaveDataPage()
;     if isLoadingData
;         AddTextOptionST("SHARED_LOADING", "$sab_mcm_shared_loading", "")
;         return
;     endif


; EndFunction