scriptname SAB_MCM extends SKI_ConfigBase

SAB_MainQuest Property SAB_Main Auto

;since we want more than 128 custom units, we need two arrays (0 or 1 here)
int editedUnitsMenuPage = 0
int editedUnitIndex = 0
int editedFactionIndex = 0
int editedZoneIndex = 0

string[] editedUnitsArray

Event OnConfigInit()
    Pages = new string[5]
    Pages[0] = "My troops"
    Pages[1] = "Edit units"
    Pages[2] = "Edit factions"
    Pages[3] = "Edit zones"
    Pages[4] = "Load/Save data"

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
    
    AddHeaderOption("Select Unit Below")
    AddSliderOptionST("UNITEDIT_MENU_PAGE", "Browse Units Page", editedUnitsMenuPage)
    AddMenuOptionST("UNITEDIT_CUR_UNIT", "Current Unit", JMap.getStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit"))
    
    AddHeaderOption("Base Info")
    AddInputOptionST("UNITEDIT_NAME", "Unit Name", JMap.getStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit"))
    AddSliderOptionST("UNITEDIT_HEALTH", "Health", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "Health", 50.0))
    AddSliderOptionST("UNITEDIT_STAMINA", "Stamina", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "Stamina", 50.0))
    AddSliderOptionST("UNITEDIT_MAGICKA", "Magicka", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "Magicka", 50.0))

    AddEmptyOption()
    AddTextOptionST("UNITEDIT_OUTFIT", "Spawn Outfit Customizer", "")
    AddEmptyOption()

    SetCursorPosition(1)

    AddHeaderOption("Skills")
    AddSliderOptionST("UNITEDIT_SKL_MARKSMAN", "Archery", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillMarksman", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_ONEHANDED", "One-handed", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillOneHanded", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_TWOHANDED", "Two-handed", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillTwoHanded", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_LIGHTARMOR", "Light Armor", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillLightArmor", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_HEAVYARMOR", "Heavy Armor", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillHeavyArmor", 15.0))
    AddSliderOptionST("UNITEDIT_SKL_BLOCK", "Block", JMap.getFlt(SAB_Main.UnitDataHandler.jTestGuyData, "SkillBlock", 15.0))

    AddEmptyOption()

    AddHeaderOption("Allowed Races/Genders")
    AddTextOptionST("UNITEDIT_RACE_ARGONIAN", "Argonian", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceArgonian"))
    AddTextOptionST("UNITEDIT_RACE_KHAJIIT", "Khajiit", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceKhajiit"))
    AddTextOptionST("UNITEDIT_RACE_ORC", "Orc", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceOrc"))
    AddTextOptionST("UNITEDIT_RACE_BRETON", "Breton", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceBreton"))
    AddTextOptionST("UNITEDIT_RACE_IMPERIAL", "Imperial", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceImperial"))
    AddTextOptionST("UNITEDIT_RACE_NORD", "Nord", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceNord"))
    AddTextOptionST("UNITEDIT_RACE_REDGUARD", "Redguard", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceRedguard"))
    AddTextOptionST("UNITEDIT_RACE_DARKELF", "Dark Elf", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceDarkElf"))
    AddTextOptionST("UNITEDIT_RACE_HIGHELF", "High Elf", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceHighElf"))
    AddTextOptionST("UNITEDIT_RACE_WOODELF", "Wood Elf", GetEditedUnitRaceStatus(SAB_Main.UnitDataHandler.jTestGuyData, "RaceWoodElf"))
    
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
		SetInfoText("Since there are more than 128 unit slots and the menu can only show 128 at a time, we must divide them by pages. This slider sets the page to be shown in the 'select unit' menu.")
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
		SetInfoText("Selects the unit to edit. All the edit fields below will be editing this unit.")
	endEvent
    
endstate

state UNITEDIT_NAME

	event OnInputOpenST()
        ;string unitName = JMap.getStr(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), "Name", "Recruit")
        string unitName = JMap.getStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit")
		SetInputDialogStartText(unitName)
		SetMenuDialogOptions(new string[128]) ;TODO fill options with unit names and stuff
	endEvent

	event OnInputAcceptST(string inputs)
        ; JMap.setStr(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), "Name", input)
        JMap.setStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", inputs)
        SetInputOptionValueST(inputs)
	endEvent

	event OnDefaultST()

        ;JMap.setStr(JArray.getObj(SAB_Main.UnitDataHandler.jSABUnitDatasArray, editedUnitIndex), "Name", "Recruit")
        JMap.setStr(SAB_Main.UnitDataHandler.jTestGuyData, "Name", "Recruit")

		SetInputOptionValueST("Recruit")
	endEvent

	event OnHighlightST()
		SetInfoText("Sets the unit's name.")
	endEvent
    
endstate

; returns the text equivalent to the target race/gender status ("male only" for 1, for example).
; Returns "None" for 0 and invalid values
string Function GetEditedUnitRaceStatus(int jUnitData, string raceKey)

    int raceStatus = JMap.getInt(jUnitData, raceKey, 0)

    if raceStatus == 0
        return "None"
    elseif raceStatus == 1
        return "Male only"
    elseif raceStatus == 2
        return "Female only"
    elseif raceStatus == 3
        return "Both genders"
    endif

    return "None"

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