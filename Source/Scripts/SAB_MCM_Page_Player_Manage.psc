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
                bool canUpgrade = false
                if troopLinesCount > 0
                    ; iterate through troop lines until we find at least one upgrade option we can afford
                    int relevantTroopLineLength = 0
                    int i = 0
                    int j = 0

                    while i < troopLinesCount
                        int jCurTroopLineArr = jArray.getObj(jFacTroopLinesArr, i)
                        relevantTroopLineLength = jValue.count(jCurTroopLineArr) - 1 ; no need to look at the last index

                        j = 0
                        while j < relevantTroopLineLength
                            if jArray.getInt(jCurTroopLineArr, j, -1) == nextUnitIndex
                                int upgOptionIndex = jArray.getInt(jCurTroopLineArr, j + 1)
                                int jUpgOptionData = jArray.getObj(jUnitData, upgOptionIndex)

                                if jUpgOptionData != 0
                                    int goldCostPerUpg = jMap.getInt(jUpgOptionData, "GoldCost", 10)
		                            float expCostPerUpg = jMap.getFlt(jUpgOptionData, "ExpCost", 10.0)

                                    if goldCostPerUpg <= playerGoldAmount && expCostPerUpg <= expPointsAvailable
                                        ; we found one affordable upgrade! break loops and go check the next unit
                                        canUpgrade = true
                                        j = relevantTroopLineLength
                                        i = troopLinesCount
                                    endif
                                endif
                            endif
                            ; Utility.Wait(0.01)
                            j += 1
                        endwhile

                        i += 1
                    endwhile
                endif
                
                ; add unit button, possibly with the "upgradable" tag
                string upgradableTag = ""
                if canUpgrade
                    upgradableTag = "$sab_mcm_mytroops_troop_upgradable"
                endif
                AddTextOptionST("PLYR_PICKTROOP___" + nextUnitIndex, nextUnitCount + " " + JMap.getStr(jUnitData, "Name", "Recruit"), upgradableTag)
            endif
        endif

        nextUnitIndex = JIntMap.nextKey(jPlyrUnitsMap, nextUnitIndex, -1)
    endwhile

    ; right side: cur EXP amount, cur selected unit upgrade options
    SetCursorPosition(1)
    AddTextOptionST("PLYR_EXP", "$sab_mcm_mytroops_exp_available", expPointsAvailable, 0)

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

                AddTextOptionST("PLYR_UPGRADETO_NAME___" + upgradedUnitIndex, JMap.getStr(jUpgradedUnitData, "Name", "Recruit"), "")
                AddTextOptionST("PLYR_UPGRADETO_COST_GOLD___" + upgradedUnitIndex, "$sab_mcm_mytroops_upgrade_unit_cost_gold", goldCostPerUpg)
                AddTextOptionST("PLYR_UPGRADETO_COST_EXP___" + upgradedUnitIndex, "$sab_mcm_mytroops_upgrade_unit_cost_exp", expCostPerUpg)
                AddTextOptionST("PLYR_UPGRADE_ONE___" + upgradedUnitIndex, "$sab_mcm_mytroops_upgrade_unit_btn_upgrade_one", "")
                AddTextOptionST("PLYR_UPGRADE_TEN___" + upgradedUnitIndex, "$sab_mcm_mytroops_upgrade_unit_btn_upgrade_ten", "")
                AddTextOptionST("PLYR_UPGRADE_ALL___" + upgradedUnitIndex, "$sab_mcm_mytroops_upgrade_unit_btn_upgrade_all", "")
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

state PLYR_UPGRADETO_NAME

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
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

state PLYR_UPGRADE_ONE
    event OnSelectST(string state_id)
        int upgradeResultUnit = state_id as int
        UpgradeCurSelectedUnit(upgradeResultUnit, 1)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_upgrade_unit_btn_upgrade_one_desc")
	endEvent
endstate

state PLYR_UPGRADE_TEN
    event OnSelectST(string state_id)
        int upgradeResultUnit = state_id as int
        UpgradeCurSelectedUnit(upgradeResultUnit, 10)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_upgrade_unit_btn_upgrade_ten_desc")
	endEvent
endstate

state PLYR_UPGRADE_ALL
    event OnSelectST(string state_id)
        int jPlyrUnitsMap = MainPage.MainQuest.PlayerDataHandler.PlayerCommanderScript.jOwnedUnitsMap
        int curUnitCount = jIntMap.getInt(jPlyrUnitsMap, currentSelectedUnitTypeIndex)

        int upgradeResultUnit = state_id as int
        UpgradeCurSelectedUnit(upgradeResultUnit, curUnitCount)
	endEvent

	event OnHighlightST(string state_id)
        MainPage.ToggleQuickHotkey(true)
		SetInfoText("$sab_mcm_mytroops_upgrade_unit_btn_upgrade_all_desc")
	endEvent
endstate


Function UpgradeCurSelectedUnit(int upgradeResultUnit, int numUnitsToUpgrade)
    SAB_PlayerCommanderScript plyr = MainPage.MainQuest.PlayerDataHandler.PlayerCommanderScript
    int jUnitDatasArray = MainPage.MainQuest.UnitDataHandler.jSABUnitDatasArray
    float expPointsAvailable = plyr.availableExpPoints
    int playerGoldAmount = plyr.playerActor.GetItemCount(Gold001)

    int jUpgradedUnitData = jArray.getObj(jUnitDatasArray, upgradeResultUnit)
    int goldCostPerUpg = jMap.getInt(jUpgradedUnitData, "GoldCost", 10)
    float expCostPerUpg = jMap.getFlt(jUpgradedUnitData, "ExpCost", 10.0)

    int actualUpgradedNumber = numUnitsToUpgrade

    if goldCostPerUpg > 0
        actualUpgradedNumber = playerGoldAmount / goldCostPerUpg
        if actualUpgradedNumber > numUnitsToUpgrade
            actualUpgradedNumber = numUnitsToUpgrade
        endif	
    endif

    if expCostPerUpg > 0
        int upgradedAmountConsideringExp = (expPointsAvailable / expCostPerUpg) as int
        if upgradedAmountConsideringExp < actualUpgradedNumber
            actualUpgradedNumber = upgradedAmountConsideringExp
        endif
    endif

    plyr.AddUnitsOfType(upgradeResultUnit, actualUpgradedNumber)
    plyr.RemoveUnitsOfType(currentSelectedUnitTypeIndex, actualUpgradedNumber)

    if actualUpgradedNumber > 0
        plyr.availableExpPoints -= actualUpgradedNumber * expCostPerUpg
        plyr.playerActor.RemoveItem(Gold001, actualUpgradedNumber * goldCostPerUpg)
        ForcePageReset()
    endif
    
EndFunction
