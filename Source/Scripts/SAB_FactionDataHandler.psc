scriptname SAB_FactionDataHandler extends Quest
{script for setting up and getting data for SAB factions.}

SAB_FactionScript[] Property SAB_FactionQuests Auto
{list containing each faction's quest. entries' indexes should be the same as faction indexes}

Faction[] Property VanillaFactions Auto
{array containing vanilla factions of which we can edit relations with the mod factions}

Faction Property MercDealerFaction Auto
{Faction used in dialogue checks, to define if a faction can sell mercenaries or not}

string[] Property VanillaFactionDisplayNames Auto
{array contaning the names used for each faction of the vanillaFactions array. The names must be in the same order as the factions array!}

; an array of jMaps, each one defining a faction's data
int Property jSABFactionDatasArray Auto Hidden

Function InitializeJData()
    jSABFactionDatasArray = JArray.objectWithSize(100)
    JValue.retain(jSABFactionDatasArray, "ShoutAndBlade")
EndFunction

; makes sure the factionDatasArray has 100 elements
Function EnsureArrayCounts()
    int count = jArray.count(jSABFactionDatasArray)

    if count < 100
        int remainingCount = 100 - count
        int padArray = jArray.objectWithSize(remainingCount)

        JArray.addFromArray(jSABFactionDatasArray, padArray)
    elseif count > 100
        ; if there are too many records in the array, keep the first ones only
        jSABFactionDatasArray = jValue.releaseAndRetain(jSABFactionDatasArray, jArray.subArray(jSABFactionDatasArray, 0, 39), "ShoutAndBlade")
    endif
EndFunction

; fills a 100-sized string array with faction IDs accompanied by their names
Function SetupStringArrayWithFactionIdentifiers(string[] stringArray)

    int endingIndex = 100

    int i = 0

    while(i < endingIndex)

        int jFactionData = jArray.getObj(jSABFactionDatasArray, i)
        string facName = jMap.getStr(jFactionData, "Name", "Faction")

        stringArray[i] = ((i + 1) as string) + " - " + facName

        i += 1
    endwhile
EndFunction

; fills a 101-sized string array with faction ownership options (one option for each of the 100 factions, plus a "neutral/no faction" option)
Function SetupStringArrayWithOwnershipIdentifiers(string[] stringArray, string firstOptionText)

    int endingIndex = stringArray.Length

    stringArray[0] = firstOptionText

    int i = 1

    while(i < endingIndex)

        int jFactionData = jArray.getObj(jSABFactionDatasArray, i - 1)
        string facName = jMap.getStr(jFactionData, "Name", "Faction")

        stringArray[i] = (i as string) + " - " + facName

        i += 1
    endwhile
EndFunction

; returns a string array with a faction's troop lines' "preview".
; only the first 128 troop lines will be shown (do you really need that many troop lines? hahah)
string[] Function CreateStringArrayWithTroopLineIdentifiers(int jTargetFactionData)

    int jTroopLinesArray = jMap.getObj(jTargetFactionData, "jTroopLinesArray")

    if jTroopLinesArray == 0
        jTroopLinesArray = JArray.object()
        jMap.setObj(jTargetFactionData, "jTroopLinesArray", jTroopLinesArray)
    endif

    int troopLinesCount = JValue.count(jTroopLinesArray)
    int arraySize = troopLinesCount + 1

    if arraySize > 128
        arraySize = 128
    endif

    string[] stringArr = Utility.CreateStringArray(arraySize, "$sab_mcm_factionedit_menu_entry_troopline_create_new")

    ;write a "preview" of the beginning of each tree, using the units' indexes
    int i = 0

    ;vars used for each troop tree
    int troopLineLength
    int j
    string troopIndexes

    while(i < troopLinesCount)

        int jTroopLineArr = jArray.getObj(jTroopLinesArray, i)

        troopLineLength = jValue.count(jTroopLineArr)
        troopIndexes = ""
        j = 0

        while(j < troopLineLength)
            int troopIndex = JArray.getInt(jTroopLineArr, j) + 1
            troopIndexes = troopIndexes + (troopIndex as string)
            if j < troopLineLength - 1
                troopIndexes = troopIndexes + ", "
            endif

            j += 1
        endwhile

        stringArr[i] = ((i + 1) as string) + " - " + troopIndexes

        i += 1
    endwhile

    return stringArr
EndFunction


; for each faction, attempts to set up their quest using the data stored in jSABUnitDatasArray
Function UpdateAllFactionQuestsAccordingToJMap()
    int i = jArray.count(jSABFactionDatasArray)

    While (i > 0)
        i -= 1
        
        int jFactionData = jArray.getObj(jSABFactionDatasArray, i)

        if jMap.hasKey(jFactionData, "enabled")
            SAB_FactionQuests[i].EnableFaction(jFactionData, i)
        ; else 
        ;     SAB_FactionQuests[i].DisableFaction()
        endif

        int jFactionVanillaRelationsData = jMap.getObj(jFactionData, "jVanillaFactionRelationsMap")

        if jFactionVanillaRelationsData != 0
            string entryKey = JMap.nextKey(jFactionVanillaRelationsData, "", "")
            while entryKey != ""
                int jRelationEntryMap = jMap.getObj(jFactionVanillaRelationsData, entryKey)    

                if jRelationEntryMap != 0
                    Faction targetVanillaFac = GetVanillaFactionByName(entryKey)

                    if targetVanillaFac != None
                        SAB_FactionQuests[i].SetRelationsWithFaction(targetVanillaFac, jMap.getInt(jRelationEntryMap, "RelationValue"))
                    endif
                endif

                entryKey = JMap.nextKey(jFactionVanillaRelationsData, entryKey, "")
            endwhile
        endif
        
    EndWhile
    
    ; SetupRaceGendersLvlActorAccordingToUnitData(jTestGuyData, SAB_UnitLooks_TestGuy)
    ; SetupGearListAccordingToUnitData(jTestGuyData, SAB_UnitGear_TestGuy)
EndFunction


Faction Function GetVanillaFactionByName(string facName)
    int i = VanillaFactionDisplayNames.Length

    while i > 0
        i -= 1
        if VanillaFactionDisplayNames[i] == facName
            return VanillaFactions[i]
        endif
    endwhile

    Debug.Trace("GetVanillaFactionByName: couldn't find vanilla fac with name " + facName)
    return None
EndFunction


; returns the target mod faction's index in the factions array (-1 for not found)
int Function GetFactionIndex(SAB_FactionScript factionScript)

    if factionScript == None
        return -1
    endif

    int i = SAB_FactionQuests.Length

    while i > 0
        i -= 1

        if(SAB_FactionQuests[i] == factionScript)
            return i
        endif
    EndWhile

    return -1
EndFunction

; checks each of the actor's factions against each of the SAB faction factions (yeah, it's probably a big workload).
; returns the first match, or None
SAB_FactionScript Function GetActorSabFaction(Actor act)
    if act == None
        return None
    endif
    
    Faction[] actFactions = act.GetFactions(-128, 127)
    int i = actFactions.Length
    int j = SAB_FactionQuests.Length

    while i > 0
        i -= 1
        j = SAB_FactionQuests.Length
        Faction testedFac = actFactions[i]

        if testedFac != MercDealerFaction
            while j > 0
                j -= 1
                SAB_FactionScript sabFac = SAB_FactionQuests[j]
                if sabFac.OurFaction == testedFac
                    return sabFac
                endif
            endwhile
        endif
    endwhile

    return None
endfunction

; since this is written a lot, this helps avoid having to edit the number everywhere
int Function GetDefaultFactionGold() global
    return 3000
EndFunction


; factionData jmap entries:

; string Name
; int AvailableGold

; it's a key with a value we don't care about! We only check if it exists. If it exists it means "enabled" to us. If it doesn't, it's "disabled".
; if a faction isn't enabled, it won't "think" (it won't create new cmders, receive gold or give orders or anything)
; int enabled

; it's a key with a value we don't care about! We only check if it exists. If it exists it means "enabled" to us. If it doesn't, it's "disabled".
; if a faction is marked as mercenary, their cmders should sell their troops to the player, if they're at least neutral
; int IsMercenary

; it's a key with a value we don't care about! We only check if it exists. If it exists it means "enabled" to us. If it doesn't, it's "disabled".
; if this is true, the faction should never capture a location. Its commanders should still walk around and all
; int CannotTakeLocations

; the index of a unit from the unit datas array. This unit will be used as the commanders of this faction
; int CmderUnitIndex

; the index of a unit from the unit datas array. This unit will be used as the base recruit of this faction
; int RecruitUnitIndex

; a map filled with {"RelationValue":0} objects, where the keys for each entry are faction names.
; RelationValue values are the same as the values used for set and getFactionReaction
; int jVanillaFactionRelationsMap