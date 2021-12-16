scriptname SAB_FactionDataHandler extends Quest
{script for setting up and getting data for SAB factions.}

FormList Property SAB_FactionQuests Auto
{list containing each faction's quest. entries' indexes should be the same as faction indexes}

; an array of jMaps, each one defining a faction's data
int Property jSABFactionDatasArray Auto

Function InitializeJData()
    jSABFactionDatasArray = JArray.objectWithSize(25)
    JValue.retain(jSABFactionDatasArray, "ShoutAndBlade")
EndFunction

; makes sure the factionDatasArray has 25 elements
Function EnsureArrayCounts()
    int count = jArray.count(jSABFactionDatasArray)

    if count < 25
        int remainingCount = 25 - count
        int padArray = jArray.objectWithSize(remainingCount)

        JArray.addFromArray(jSABFactionDatasArray, padArray)
    elseif count > 25
        ; if there are too many records in the array, keep the first ones only
        jSABFactionDatasArray = jValue.releaseAndRetain(jSABFactionDatasArray, jArray.subArray(jSABFactionDatasArray, 0, 24), "ShoutAndBlade")
    endif
EndFunction

; returns a string array with a faction's troop trees' "preview".
; only the first 128 troop trees will be shown (do you really need that many troop trees? hahah)
string[] Function SetupStringArrayWithTroopTreeIdentifiers(int jTargetFactionData)

    int jTroopTreesArray = jMap.getObj(jTargetFactionData, "jTroopTreesArray")

    if jTroopTreesArray == 0
        jTroopTreesArray = JArray.object()
        jMap.setObj(jTargetFactionData, "jTroopTreesArray", jTroopTreesArray)
    endif

    int arraySize = JValue.count(jTroopTreesArray)

    if arraySize > 128
        arraySize = 128
    endif

    string[] stringArr = Utility.CreateStringArray(arraySize, "-")

    ;write a "preview" of the beginning of each tree, using the units' indexes
    int i = 0

    ;vars used for each troop tree
    int troopTreeLength
    int j
    string troopIndexes

    while(i < arraySize)

        int jTroopTreeArr = jArray.getObj(jTroopTreesArray, i)

        troopTreeLength = jValue.count(jTroopTreeArr)
        troopIndexes = ""
        j = 0

        while(j < troopTreeLength)
            int troopIndex = JArray.getInt(jTroopTreeArr, j)
            troopIndexes = troopIndexes + (troopIndex as string)
            if j < troopTreeLength - 1
                troopIndexes = troopIndexes + ", "
            endif
        endwhile

        stringArr[i] = ((i + 1) as string) + " - " + troopIndexes

        i += 1
    endwhile

    return stringArr
EndFunction

; factionData jmap entries:

; string Name
; int AvailableGold

; the index of a unit from the unit datas array. This unit will be used as the commanders of this faction
; int CmderUnitIndex

; the index of a unit from the unit datas array. This unit will be used as the base recruit of this faction
; int RecruitUnitIndex

; a list of troop trees, a jArray of jArrays; each array contains a list of unit indexes, ordered in their "evolution" order.
; we can have up to 128 troop trees, because that's when we'd have to set up another array for the UI
; int jTroopTreesArray