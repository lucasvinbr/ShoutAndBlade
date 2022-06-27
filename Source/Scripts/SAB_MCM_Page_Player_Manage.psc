scriptname SAB_MCM_Page_Player_Manage extends nl_mcm_module

SAB_MCM Property MainPage Auto

Form Property Gold001 Auto

int currentSelectedUnitTypeIndex = -1

event OnInit()
    RegisterModule("$sab_mcm_page_mytroops", 0)
endevent

Event OnPageInit()

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

    SAB_PlayerCommanderScript plyr = MainPage.MainQuest.PlayerDataHandler.PlayerCommanderScript
    int jUnitDatasArray = MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray
    float expPointsAvailable = plyr.availableExpPoints
    int playerGoldAmount = plyr.playerActor.GetItemCount(Gold001)
    SAB_FactionScript playerFac = plyr.factionScript
    int jFacTroopLinesArr = -1
    int troopLinesCount = 0
    if playerFac != None
        jFacTroopLinesArr = jMap.getObj(playerFac.jFactionData, "jTroopLinesArray")
        troopLinesCount = jValue.count(jFacTroopLinesArr)
    endif
    int jPlyrUnitsMap = plyr.jOwnedUnitsMap

    ; set up a list of the current player units.
    ; show a message if there are no units
    int nextUnitIndex = JIntMap.nextKey(jPlyrUnitsMap, -1, -1)
    while nextUnitIndex != -1
        int nextUnitCount = jIntMap.getInt(jPlyrUnitsMap, nextUnitIndex)
        if nextUnitCount > 0
            int jUnitData = JArray.getObj(jUnitDatasArray, nextUnitIndex)
            if jUnitData != 0
                
                ; add unit button, possibly with the "upgradable" tag
                string entryTag = ""
                if currentSelectedUnitTypeIndex == nextUnitIndex
                    entryTag = "$sab_mcm_mytroops_troop_selected"
                endif
                AddTextOptionST("PLYR_PICKTROOP___" + nextUnitIndex, nextUnitCount + " " + JMap.getStr(jUnitData, "Name", "Recruit"), entryTag)
            endif
        endif

        nextUnitIndex = JIntMap.nextKey(jPlyrUnitsMap, nextUnitIndex, -1)
    endwhile

    ; right side: cur EXP amount, cur selected unit upgrade options
    SetCursorPosition(1)
    AddTextOptionST("PLYR_EXP", "$sab_mcm_mytroops_exp_available", expPointsAvailable, 0)
    AddTextOptionST("PLYR_GOLD", "$sab_mcm_mytroops_gold_available", playerGoldAmount, 0)

    string expHeaderText = "$sab_mcm_mytroops_header_no_unit"
    int jSelectedUnitData = jArray.getObj(jUnitDatasArray, currentSelectedUnitTypeIndex, 0)
    if currentSelectedUnitTypeIndex != -1 && jSelectedUnitData != 0 && jIntMap.getInt(jPlyrUnitsMap, currentSelectedUnitTypeIndex) > 0
        expHeaderText = JMap.getStr(jSelectedUnitData, "Name", "Recruit")
    else 
        currentSelectedUnitTypeIndex = -1
    endif
    AddHeaderOption(expHeaderText)

    if currentSelectedUnitTypeIndex != -1
        ; find all upgrade options for the unit
        int jUpgradeOptions = jArray.object()

        ; iterate through troop lines, looking for the passed unitIndex, and store the indexes of the "next step" units
        int relevantTroopLineLength = 0
        int i = 0
        int j = 0

        while i < troopLinesCount
            int jCurTroopLineArr = jArray.getObj(jFacTroopLinesArr, i)
            relevantTroopLineLength = jValue.count(jCurTroopLineArr) - 1 ; no need to look at the last index

            j = 0
            while j < relevantTroopLineLength
                if jArray.getInt(jCurTroopLineArr, j, -1) == currentSelectedUnitTypeIndex
                    JArray.addInt(jUpgradeOptions, jArray.getInt(jCurTroopLineArr, j + 1))
                endif
                j += 1
            endwhile

            i += 1
        endwhile

        ; add upgrade buttons for each upgrade option
        i = jValue.count(jUpgradeOptions)

        while i > 0
            i -= 1

            int upgradedUnitIndex = jArray.getInt(jUpgradeOptions, i, -1)
		    int jUpgradedUnitData = jArray.getObj(jUnitDatasArray, upgradedUnitIndex)

            if jUpgradedUnitData != 0
                int goldCostPerUpg = jMap.getInt(jUpgradedUnitData, "GoldCost", 10)
		        float expCostPerUpg = jMap.getFlt(jUpgradedUnitData, "ExpCost", 10.0)

                AddSliderOptionST("PLYR_UPGRADETO_NAME___" + upgradedUnitIndex, "Upgrade to " + JMap.getStr(jUpgradedUnitData, "Name", "Recruit"), 0, "")
                AddTextOptionST("PLYR_UPGRADETO_COST_GOLD___" + upgradedUnitIndex, "$sab_mcm_mytroops_upgrade_unit_cost_gold", goldCostPerUpg)
                AddTextOptionST("PLYR_UPGRADETO_COST_EXP___" + upgradedUnitIndex, "$sab_mcm_mytroops_upgrade_unit_cost_exp", expCostPerUpg)
                AddEmptyOption()
            endif
        endwhile
    endif
    
EndFunction

state PLYR_PICKTROOP
    
    event OnSelectST(string state_id)
        int pickedUnit = state_id as int
        currentSelectedUnitTypeIndex = pickedUnit
        ForcePageReset()
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_exp_available_desc")
	endEvent

endstate

state PLYR_EXP

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_exp_available_desc")
	endEvent

endstate

state PLYR_GOLD

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_gold_available_desc")
	endEvent

endstate

state PLYR_UPGRADETO_NAME

    event OnSliderOpenST(string state_id)
        int upgradeResultUnit = state_id as int
        int jPlyrUnitsMap = MainPage.MainQuest.PlayerDataHandler.PlayerCommanderScript.jOwnedUnitsMap
        int curUnitCount = jIntMap.getInt(jPlyrUnitsMap, currentSelectedUnitTypeIndex)

		SetSliderDialogStartValue(0)
		SetSliderDialogDefaultValue(0)
        int maxUpgradeableUnits = GetNumPossibleUpgradesToTargetUnitType(upgradeResultUnit, curUnitCount)
		SetSliderDialogRange(0, maxUpgradeableUnits)
		SetSliderDialogInterval(1)
	endEvent

	event OnSliderAcceptST(string state_id, float value)
        int upgradeResultUnit = state_id as int
        UpgradeCurSelectedUnit(upgradeResultUnit, value as int)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
        SetInfoText("$sab_mcm_mytroops_upgrade_unit_slider_desc")
	endEvent

endstate

state PLYR_UPGRADETO_COST_GOLD

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_upgrade_unit_cost_gold_desc")
	endEvent

endstate

state PLYR_UPGRADETO_COST_EXP

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_upgrade_unit_cost_exp_desc")
	endEvent

endstate


Function UpgradeCurSelectedUnit(int upgradeResultUnitIndex, int numUnitsToUpgrade)
    SAB_PlayerCommanderScript plyr = MainPage.MainQuest.PlayerDataHandler.PlayerCommanderScript
    int jUnitDatasArray = MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray

    int jUpgradedUnitData = jArray.getObj(jUnitDatasArray, upgradeResultUnitIndex)
    int goldCostPerUpg = jMap.getInt(jUpgradedUnitData, "GoldCost", 10)
    float expCostPerUpg = jMap.getFlt(jUpgradedUnitData, "ExpCost", 10.0)

    int actualUpgradedNumber = GetNumPossibleUpgradesToTargetUnitType(upgradeResultUnitIndex, numUnitsToUpgrade)

    plyr.AddUnitsOfType(upgradeResultUnitIndex, actualUpgradedNumber)
    plyr.RemoveUnitsOfType(currentSelectedUnitTypeIndex, actualUpgradedNumber)

    if actualUpgradedNumber > 0
        plyr.availableExpPoints -= actualUpgradedNumber * expCostPerUpg
        plyr.playerActor.RemoveItem(Gold001, actualUpgradedNumber * goldCostPerUpg)
        ForcePageReset()
    endif
    
EndFunction

; returns the max number of units we can afford to upgrade to the target type
int Function GetNumPossibleUpgradesToTargetUnitType(int targetType, int numAvailableUnitsToUpgrade)
    SAB_PlayerCommanderScript plyr = MainPage.MainQuest.PlayerDataHandler.PlayerCommanderScript
    int jUnitDatasArray = MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray
    float expPointsAvailable = plyr.availableExpPoints
    int playerGoldAmount = plyr.playerActor.GetItemCount(Gold001)

    int jUpgradedUnitData = jArray.getObj(jUnitDatasArray, targetType)
    int goldCostPerUpg = jMap.getInt(jUpgradedUnitData, "GoldCost", 10)
    float expCostPerUpg = jMap.getFlt(jUpgradedUnitData, "ExpCost", 10.0)

    int actualUpgradedNumber = numAvailableUnitsToUpgrade

    if goldCostPerUpg > 0
        actualUpgradedNumber = playerGoldAmount / goldCostPerUpg
        if actualUpgradedNumber > numAvailableUnitsToUpgrade
            actualUpgradedNumber = numAvailableUnitsToUpgrade
        endif	
    endif

    if expCostPerUpg > 0
        int upgradedAmountConsideringExp = (expPointsAvailable / expCostPerUpg) as int
        if upgradedAmountConsideringExp < actualUpgradedNumber
            actualUpgradedNumber = upgradedAmountConsideringExp
        endif
    endif

    return actualUpgradedNumber
EndFunction