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

; fills a 25-sized string array with faction IDs accompanied by their names
Function SetupStringArrayWithFactionIdentifiers(string[] stringArray)

    int endingIndex = 25

    int i = 0

    while(i < endingIndex)

        int jFactionData = jArray.getObj(jSABFactionDatasArray, i)
        string facName = jMap.getStr(jFactionData, "Name", "Faction")

        stringArray[i] = ((i + 1) as string) + " - " + facName

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

; factionData jmap entries:

; string Name
; int AvailableGold

; it's a key with a value we don't care about! We only check if it exists. If it exists it means "enabled" to us. If it doesn't, it's "disabled".
; if a faction isn't enabled, it won't "think" (it won't create new cmders, receive gold or give orders or anything)
; int enabled

; the index of a unit from the unit datas array. This unit will be used as the commanders of this faction
; int CmderUnitIndex

; the index of a unit from the unit datas array. This unit will be used as the base recruit of this faction
; int RecruitUnitIndex

; a list of troop lines, a jArray of jArrays; each array contains a list of unit indexes, ordered in their "evolution" order.
; at least one troop line should begin with the base recruit; other lines can begin with other units, and in that way we can get a "troop tree".
; we can have up to 128 troop lines, because that's when we'd have to set up another array for the UI
; int jTroopLinesArray