scriptname SAB_UnitDataHandler extends Quest
{script for setting up and getting data for units/soldiers.}

LeveledActor Property SAB_LooksList_Argonian_M Auto
LeveledActor Property SAB_LooksList_Argonian_F Auto
LeveledActor Property SAB_LooksList_Orc_M Auto
LeveledActor Property SAB_LooksList_Orc_F Auto
LeveledActor Property SAB_LooksList_Khajiit_M Auto
LeveledActor Property SAB_LooksList_Khajiit_F Auto
LeveledActor Property SAB_LooksList_Breton_M Auto
LeveledActor Property SAB_LooksList_Breton_F Auto
LeveledActor Property SAB_LooksList_Imperial_M Auto
LeveledActor Property SAB_LooksList_Imperial_F Auto
LeveledActor Property SAB_LooksList_Nord_M Auto
LeveledActor Property SAB_LooksList_Nord_F Auto
LeveledActor Property SAB_LooksList_Redguard_M Auto
LeveledActor Property SAB_LooksList_Redguard_F Auto
LeveledActor Property SAB_LooksList_DarkElf_M Auto
LeveledActor Property SAB_LooksList_DarkElf_F Auto
LeveledActor Property SAB_LooksList_HighElf_M Auto
LeveledActor Property SAB_LooksList_HighElf_F Auto
LeveledActor Property SAB_LooksList_WoodElf_M Auto
LeveledActor Property SAB_LooksList_WoodElf_F Auto

FormList Property SAB_UnitActorBases Auto
{list containing each unit's actorBase, used for spawning. entries' indexes should be the same as unit indexes}

FormList Property SAB_UnitGearSets Auto
{list containing each unit's "gear" leveledItem. entries' indexes should be the same as unit indexes}

FormList Property SAB_UnitDuplicateItemSets Auto
{list containing each unit's "repeated items" leveledItem. 
This leveled item is filled with gear entries that have more than one as the item count (usually the case for arrows).
entries' indexes should be the same as unit indexes}

FormList Property SAB_UnitAllowedRacesGenders Auto
{list containing each actor's "looks" leveledActor. entries' indexes should be the same as unit indexes}

; an array of jMaps, each one defining a unit's data
int Property jSABUnitDatasArray Auto Hidden

; a unit data jMap just for testing
int Property jTestGuyData Auto Hidden

LeveledActor Property SAB_UnitLooks_TestGuy Auto
LeveledItem Property SAB_UnitGear_TestGuy Auto
LeveledItem Property SAB_UnitDuplicateItems_TestGuy Auto

Function InitializeJData()
    jSABUnitDatasArray = JArray.objectWithSize(512)
    JValue.retain(jSABUnitDatasArray, "ShoutAndBlade")

    jTestGuyData = JMap.object()
    JValue.retain(jTestGuyData, "ShoutAndBlade")
EndFunction

; makes sure the unitDatasArray has 512 elements
Function EnsureUnitDataArrayCount()
    int count = jArray.count(jSABUnitDatasArray)

    if count < 512
        int remainingCount = 512 - count
        int padArray = jArray.objectWithSize(remainingCount)

        JArray.addFromArray(jSABUnitDatasArray, padArray)
    elseif count > 512
        ; if there are too many records in the array, keep the first 512 only
        jSABUnitDatasArray = jValue.releaseAndRetain(jSABUnitDatasArray, jArray.subArray(jSABUnitDatasArray, 0, 511), "ShoutAndBlade")
    endif
EndFunction

; fetches the unit data and its race/gender leveledActor by its index, 
; and updates the leveled actor according to the data found in the unit's jmap
Function SetupRaceGendersAccordingToUnitIndex(int unitIndex)
    int jUnitData = JArray.getObj(jSABUnitDatasArray, unitIndex)
    Form unitLooks = SAB_UnitAllowedRacesGenders.GetAt(unitIndex)
    
    if unitLooks != None
        SetupRaceGendersLvlActorAccordingToUnitData(jUnitData, unitLooks as LeveledActor)
    endif
endfunction

; makes sure the leveled actor at index of the unitRaceGenders list is valid
; (with at least one race/gender type in it)
Function GuardRaceGendersLvlActorAtIndex(int index)
    
    LeveledActor unitLooks = SAB_UnitAllowedRacesGenders.GetAt(index) as LeveledActor

    if unitLooks.GetNumForms() == 0
        SetupRaceGendersLvlActorAccordingToUnitData(jArray.getObj(jSABUnitDatasArray, index), unitLooks)
    endif

EndFunction

; updates the provided lvlActor with the provided junitData's race/gender info
Function SetupRaceGendersLvlActorAccordingToUnitData(int jUnitData, LeveledActor lvlActor)
    
    ; Debug.Trace("lvlactor " + lvlActor.GetName())

    lvlActor.Revert()

    int addedEntries = 0

    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceBreton", SAB_LooksList_Breton_M, SAB_LooksList_Breton_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceImperial", SAB_LooksList_Imperial_M, SAB_LooksList_Imperial_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \ 
     (jUnitData, lvlActor, "RaceNord", SAB_LooksList_Nord_M, SAB_LooksList_Nord_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceRedguard", SAB_LooksList_Redguard_M, SAB_LooksList_Redguard_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceDarkElf", SAB_LooksList_DarkElf_M, SAB_LooksList_DarkElf_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceHighElf", SAB_LooksList_HighElf_M, SAB_LooksList_HighElf_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \ 
     (jUnitData, lvlActor, "RaceWoodElf", SAB_LooksList_WoodElf_M, SAB_LooksList_WoodElf_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceArgonian", SAB_LooksList_Argonian_M, SAB_LooksList_Argonian_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceKhajiit", SAB_LooksList_Khajiit_M, SAB_LooksList_Khajiit_F)
    addedEntries = addedEntries + AddRaceGenderToLvlActorAccordingToUnitDataKey \
     (jUnitData, lvlActor, "RaceOrc", SAB_LooksList_Orc_M, SAB_LooksList_Orc_F)

    if addedEntries == 0
        ; if no entries have been selected,
        ; add one lvlActor anyway, to avoid spawning people with 0 appearances
        ; Debug.Notification("SetupRaceGendersLvlActorAccordingToUnitData: added argonianF to have something in the list")
        lvlActor.AddForm(SAB_LooksList_Argonian_F, 1)
    endif

EndFunction

;returns number of lvlActors added to the target LvlActor
int Function AddRaceGenderToLvlActorAccordingToUnitDataKey(int jUnitData, LeveledActor lvlActor, string dataKey, LeveledActor male, LeveledActor female)
    int raceGenderValue = JMap.getInt(jUnitData, dataKey, 0)

    ;0 is "none", 1 is "male only", 2 is "female only", 3 is "both"
    if raceGenderValue == 0
        return 0
    elseif raceGenderValue == 3
        lvlActor.AddForm(male, 1)
        lvlActor.AddForm(female, 1)
        return 2
    elseif raceGenderValue == 2
        lvlActor.AddForm(female, 1)
        return 1
    elseif raceGenderValue == 1
        lvlActor.AddForm(male, 1)
        return 1
    endif

    return 0

EndFunction

Function SetupGearListAccordingToUnitData(int jUnitData, LeveledItem gearList, LeveledItem duplicateGearList)
    int jUnitGearArray = jMap.getObj(jUnitData, "jGearArray")

    if jUnitGearArray == 0
        jUnitGearArray = JArray.object()
        jMap.setObj(jUnitData, "jGearArray", jUnitGearArray)
    endif

    gearList.Revert()
    duplicateGearList.Revert()

    int i = jArray.count(jUnitGearArray)

    While (i > 0)
        i -= 1

        int jItemEntry = jArray.getObj(jUnitGearArray, i)
        int itemAmount = jMap.getInt(jItemEntry, "amount")
        Form itemForm = jMap.getForm(jItemEntry, "itemForm")
        
        if itemAmount > 0 && itemForm != None
            gearList.AddForm(itemForm, 1, 1)
            
            if itemAmount > 1
                duplicateGearList.AddForm(itemForm, 1, itemAmount - 1)
            endif
        endif

    EndWhile
EndFunction

; for each unit, attempts to set up their gear and looks leveledItems/Actors using the data stored in jSABUnitDatasArray
Function UpdateAllGearAndRaceListsAccordingToJMap()
    int i = jArray.count(jSABUnitDatasArray)

    While (i > 0)
        i -= 1
        
        int jUnitData = jArray.getObj(jSABUnitDatasArray, i)

        if jUnitData != 0
            SetupRaceGendersLvlActorAccordingToUnitData(jUnitData, SAB_UnitAllowedRacesGenders.GetAt(i) as LeveledActor)
            SetupGearListAccordingToUnitData(jUnitData, \
                SAB_UnitGearSets.GetAt(i) as LeveledItem, SAB_UnitDuplicateItemSets.GetAt(i) as LeveledItem)
        endif
        
    EndWhile
    
    ; SetupRaceGendersLvlActorAccordingToUnitData(jTestGuyData, SAB_UnitLooks_TestGuy)
    ; SetupGearListAccordingToUnitData(jTestGuyData, SAB_UnitGear_TestGuy)
EndFunction

int Function GetUnitIndexByUnitName(string name)
    int i = JArray.count(jSABUnitDatasArray)

    while i > 0
        i -= 1

        int unitData = JArray.getObj(jSABUnitDatasArray, i)
        if unitData != 0
            string unitName = jMap.getStr(unitData, "Name", "")

            if unitName == name
                return i
            endif
        endif
    endwhile

    return -1
EndFunction

; fills a 128-sized string array with unit IDs accompanied by their names.
; can get either the first or the second "page" of 128 units
Function SetupStringArrayWithUnitIdentifiers(string[] stringArray, int page)
    int startingIndex = page * 128
    int endingIndex = (page + 1) * 128

    int i = startingIndex
    int i_clamped

    while(i < endingIndex)

        int jUnitData = jArray.getObj(jSABUnitDatasArray, i)
        string unitName = jMap.getStr(jUnitData, "Name", "Recruit")

        i_clamped = i % 128

        stringArray[i_clamped] = ((i + 1) as string) + " - " + unitName

        i += 1
    endwhile
EndFunction

Function CopyUnitDataFromAnotherIndex(int indexToCopyTo, int indexToCopyFrom)
    int jUnitCopyFrom = jArray.getObj(jSABUnitDatasArray, indexToCopyFrom)
    int jUnitCopy = jValue.deepCopy(jUnitCopyFrom)
    JArray.setObj(jSABUnitDatasArray, indexToCopyTo, jUnitCopy)

    SetupRaceGendersLvlActorAccordingToUnitData(jUnitCopy, SAB_UnitAllowedRacesGenders.GetAt(indexToCopyTo) as LeveledActor)
    SetupGearListAccordingToUnitData(jUnitCopy, \
        SAB_UnitGearSets.GetAt(indexToCopyTo) as LeveledItem, SAB_UnitDuplicateItemSets.GetAt(indexToCopyTo) as LeveledItem)
EndFunction

; expects a map of "unit index - amount" ints.
; returns the sum of all units' autocalc power values
float Function GetTotalAutocalcPowerFromArmy(int jArmyMap)
    float totalValue = 0.0
    float curUnitPower = 0.0
    int curKey = jIntMap.nextKey(jArmyMap, previousKey = -1, endKey = -1)

	while curKey != -1
		int ownedUnitCount = jIntMap.getInt(jArmyMap, curKey)
		
        if ownedUnitCount > 0
            int jUnitData = jArray.getObj(jSABUnitDatasArray, curKey)
            curUnitPower = jMap.getFlt(jUnitData, "AutocalcStrength", 1.0)
            totalValue += curUnitPower * ownedUnitCount
        endif

		curKey = jIntMap.nextKey(jArmyMap, curKey, endKey=-1)
	endwhile

    return totalValue
EndFunction

; expects a map of "unit index - amount" ints.
; returns the sum of all units' gold cost values (does not consider upgrades, only the current costs!)
int Function GetTotalCurrentGoldCostFromArmy(int jArmyMap)
    int totalValue = 0
    int curUnitCost = 0
    int curKey = jIntMap.nextKey(jArmyMap, previousKey = -1, endKey = -1)

	while curKey != -1
		int ownedUnitCount = jIntMap.getInt(jArmyMap, curKey)
		
        if ownedUnitCount > 0
            int jUnitData = jArray.getObj(jSABUnitDatasArray, curKey)
            curUnitCost = jMap.getInt(jUnitData, "GoldCost", 10)
            totalValue += curUnitCost * ownedUnitCount
        endif

		curKey = jIntMap.nextKey(jArmyMap, curKey, endKey=-1)
	endwhile

    return totalValue
EndFunction

; unitData jmap entries:

; string Name
; float Health
; float Stamina
; float Magicka
; float SkillMarksman
; float SkillOneHanded
; float SkillTwoHanded
; float SkillLightArmor
; float SkillHeavyArmor
; float SkillBlock

; cost for recruiting or upgrading to this unit
; float GoldCost

; experience cost for upgrading to this unit
; float ExpCost

; in autocalc battles, this defines how strong this unit is
; float AutocalcStrength

; an array of jMaps. Each jMap in the array has two fields: "itemForm" (form) and "amount" (int)
; int jGearArray

; true if this key exists and is greater than 0
; int IsRanged

;allowed races/genders - 0 is "none", 1 is "male only", 2 is "female only", 3 is "both"

; int RaceBreton
; int RaceImperial
; int RaceNord
; int RaceRedguard

; int RaceDarkElf
; int RaceHighElf
; int RaceWoodElf

; int RaceArgonian
; int RaceKhajiit
; int RaceOrc