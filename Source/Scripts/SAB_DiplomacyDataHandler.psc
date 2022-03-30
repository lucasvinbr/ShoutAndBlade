scriptname SAB_DiplomacyDataHandler extends Quest
{script for setting up and getting data for SAB faction relations.}

SAB_FactionDataHandler Property FactionDataHandler Auto

; an array of jMaps, each one defining two factions' relation
int Property jSABFactionRelationsMap Auto Hidden

; an intMap representing each faction's relation with the player
int Property jSABPlayerRelationsMap Auto Hidden

Function InitializeJData()
    jSABFactionRelationsMap = JIntMap.object()
    JValue.retain(jSABFactionRelationsMap, "ShoutAndBlade")

    jSABPlayerRelationsMap = JIntMap.object()
    JValue.retain(jSABPlayerRelationsMap, "ShoutAndBlade")
EndFunction

; returns a relationValue constrained to the maximum and minimum relation value limits
float Function ClampRelationValue(float relationValue)
    if relationValue > JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.maxRelationValue", 2.0)
        return JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.maxRelationValue", 2.0)
    elseif relationValue < JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.minRelationValue", -2.0)
        return JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.minRelationValue", -2.0)
    endif

    return relationValue
EndFunction



float Function GetPlayerRelationWithFac(int factionIndex)
    return JIntMap.getFlt(jSABPlayerRelationsMap, factionIndex, 0.0)
EndFunction

float Function AddOrSubtractPlayerRelationWithFac(int factionIndex, float valueToAdd)
    float curRelation = JIntMap.getFlt(jSABPlayerRelationsMap, factionIndex, 0.0)
    float newValue = ClampRelationValue(curRelation + valueToAdd)
    JIntMap.setFlt(jSABPlayerRelationsMap, factionIndex, newValue)

    return newValue
EndFunction


float Function GetRelationBetweenFacs(int factionOneIndex, int factionTwoIndex)
    if factionOneIndex == factionTwoIndex
        return 0.0
    endif

    int factionWithSmallerIndex = factionOneIndex
    int factionWithBiggerIndex = 0

    if factionOneIndex < factionTwoIndex
        factionWithBiggerIndex = factionTwoIndex
    else
        factionWithSmallerIndex = factionTwoIndex
        factionWithBiggerIndex = factionOneIndex
    endif

    int jSmallerFacRelationsMap = jIntMap.getObj(jSABFactionRelationsMap, factionWithSmallerIndex)

    if jSmallerFacRelationsMap == 0
        jSmallerFacRelationsMap = jIntMap.object()
        JIntMap.setObj(jSABFactionRelationsMap, factionWithSmallerIndex, jSmallerFacRelationsMap)
    endif

    return JIntMap.getFlt(jSmallerFacRelationsMap, factionWithBiggerIndex, 0.0)
EndFunction

float Function AddOrSubtractRelationBetweenFacs(int factionOneIndex, int factionTwoIndex, float valueToAdd)
    if factionOneIndex == factionTwoIndex
        return 0.0
    endif

    int factionWithSmallerIndex = factionOneIndex
    int factionWithBiggerIndex = 0

    if factionOneIndex < factionTwoIndex
        factionWithBiggerIndex = factionTwoIndex
    else
        factionWithSmallerIndex = factionTwoIndex
        factionWithBiggerIndex = factionOneIndex
    endif

    int jSmallerFacRelationsMap = jIntMap.getObj(jSABFactionRelationsMap, factionWithSmallerIndex)

    if jSmallerFacRelationsMap == 0
        jSmallerFacRelationsMap = jIntMap.object()
        JIntMap.setObj(jSABFactionRelationsMap, factionWithSmallerIndex, jSmallerFacRelationsMap)
    endif

    float curRelation = JIntMap.getFlt(jSmallerFacRelationsMap, factionWithBiggerIndex, 0.0)
    float newValue = ClampRelationValue(curRelation + valueToAdd)
    JIntMap.setFlt(jSmallerFacRelationsMap, factionWithBiggerIndex, newValue)

    return newValue
EndFunction

; factionData jmap entries:

; a jIntMap, with faction indexes as keys, representing each faction's relation with the others.
; each entry of this first jIntMap contains another jIntMap, also with factionIndexes as keys, each entry containing a relationValue float.
; relation entries shouldn't be redundant, so always look for the relation value in the smaller faction index!
; int jFactionRelationsMap

; a jIntMap, with faction indexes as keys, representing each faction's relation with the player
; int jPlayerRelationsMap