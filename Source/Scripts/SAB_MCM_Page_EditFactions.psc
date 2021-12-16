scriptname SAB_MCM_Page_EditFactions extends nl_mcm_module

SAB_MCM Property MainPage Auto

; since we want more than 128 custom units, we need two arrays (0 or 1 here)
int editedUnitsMenuPage = 0

int editedFactionIndex = 0
int jEditedFactionData = 0

; the name of the jMap entry being hovered or edited in the currently opened dialog
string currentFieldBeingEdited = ""

; a descriptive type of the field being hovered or edited (like "race menu in edit unit panel").
; Used because I'm too lazy to write the same thing too many times
string currentFieldTypeBeingEdited = ""
float currentSliderDefaultValue = 0.0

event OnInit()
    RegisterModule("$sab_mcm_page_edit_factions", 2)
endevent

Event OnPageInit()

    ;editedTroopTreeDescriptionsArray = new string[128]

EndEvent

Event OnVersionUpdate(Int a_version)
	OnPageInit()
EndEvent

Event OnPageDraw()
    SetLandingPage("$sab_mcm_page_edit_units")
    SetupPage()
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
; PAGE STUFF
;---------------------------------------------------------------------------------------------------------

Function SetupPage()

    if MainPage.isLoadingData
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
    
    AddHeaderOption("$sab_mcm_factionedit_header_selectfac")
    AddMenuOptionST("FAC_EDIT_CUR_FAC", "$sab_mcm_factionedit_menu_currentfac", \
        ((editedFactionIndex + 1) as string) + " - " + JMap.getStr(jEditedFactionData, "Name", "Faction"))
    
    AddHeaderOption("$sab_mcm_unitedit_header_baseinfo")
    AddInputOptionST("FAC_EDIT_NAME", "$sab_mcm_factionedit_input_factionname", JMap.getStr(jEditedFactionData, "Name", "Faction"))
    AddSliderOptionST("FAC_EDIT_GOLD", "$sab_mcm_factionedit_slider_factiongold", JMap.getInt(jEditedFactionData, "AvailableGold", 500))

    AddHeaderOption("$sab_mcm_factionedit_header_selectcmder")
    AddSliderOptionST("FAC_EDIT_UNIT_MENU_PAGE", "$sab_mcm_unitedit_slider_menupage", editedUnitsMenuPage + 1)
    AddMenuOptionST("FAC_EDIT_UNIT_CMDER_MENU", "$sab_mcm_factionedit_menu_cmderunit", \
        MainPage.GetMCMUnitDisplayByUnitIndex(JMap.getInt(jEditedFactionData, "CmderUnitIndex", 0)))

    AddHeaderOption("$sab_mcm_factionedit_header_selectrecruit")
    AddSliderOptionST("FAC_EDIT_UNIT_MENU_PAGE", "$sab_mcm_unitedit_slider_menupage", editedUnitsMenuPage + 1)
    AddMenuOptionST("FAC_EDIT_UNIT_RECRUIT_MENU", "$sab_mcm_factionedit_menu_recruitunit", \
        MainPage.GetMCMUnitDisplayByUnitIndex(JMap.getInt(jEditedFactionData, "RecruitUnitIndex", 0)))

    AddEmptyOption()
    AddTextOptionST("UNITEDIT_TESTSPAWN___FAC1", "$sab_mcm_unitedit_button_spawn_testfac", "1")
    AddTextOptionST("UNITEDIT_TESTSPAWN___FAC2", "$sab_mcm_unitedit_button_spawn_testfac", "2")
    AddEmptyOption()
    AddTextOptionST("UNITEDIT_TEST_SAVE", "(Debug) Save testGuy data", "")
    AddTextOptionST("UNITEDIT_TEST_LOAD", "(Debug) Load testGuy data", "")

    SetCursorPosition(1)

    ; TODO troop line editor in this side
    AddHeaderOption("$sab_mcm_unitedit_header_skills")
    AddSliderOptionST("UNITEDIT_SKL___SkillMarksman", "$sab_mcm_unitedit_slider_marksman", JMap.getFlt(jEditedFactionData, "SkillMarksman", 15.0))
    AddSliderOptionST("UNITEDIT_SKL___SkillOneHanded", "$sab_mcm_unitedit_slider_onehanded", JMap.getFlt(jEditedFactionData, "SkillOneHanded", 15.0))
    AddSliderOptionST("UNITEDIT_SKL___SkillTwoHanded", "$sab_mcm_unitedit_slider_twohanded", JMap.getFlt(jEditedFactionData, "SkillTwoHanded", 15.0))
    AddSliderOptionST("UNITEDIT_SKL___SkillLightArmor", "$sab_mcm_unitedit_slider_lightarmor", JMap.getFlt(jEditedFactionData, "SkillLightArmor", 15.0))
    AddSliderOptionST("UNITEDIT_SKL___SkillHeavyArmor", "$sab_mcm_unitedit_slider_heavyarmor", JMap.getFlt(jEditedFactionData, "SkillHeavyArmor", 15.0))
    AddSliderOptionST("UNITEDIT_SKL___SkillBlock", "$sab_mcm_unitedit_slider_block", JMap.getFlt(jEditedFactionData, "SkillBlock", 15.0))

    AddEmptyOption()
    
EndFunction

