scriptname SAB_DiplomacyDataHandler extends Quest
{script for setting up and getting data for SAB faction relations.}

SAB_FactionDataHandler Property FactionDataHandler Auto

SAB_PlayerDataHandler Property PlayerDataHandler Auto

; an intMap, each one defining two factions' relation
int Property jSABFactionRelationsMap Auto Hidden

; an intMap representing each faction's relation with the player
int Property jSABPlayerRelationsMap Auto Hidden

Function InitializeJData()
    jSABFactionRelationsMap = JIntMap.object()
    JValue.retain(jSABFactionRelationsMap, "ShoutAndBlade")

    jSABPlayerRelationsMap = JIntMap.object()
    JValue.retain(jSABPlayerRelationsMap, "ShoutAndBlade")
EndFunction

; for each faction, attempts to set up their quest using the data stored in jSABFactionRelationsMap
Function UpdateAllRelationsAccordingToJMaps()

    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int curEditedFacKey = jIntMap.nextKey(jSABFactionRelationsMap, 0, 0)
    while curEditedFacKey != 0
        int jRelationEntryMap = jIntMap.getObj(jSABFactionRelationsMap, curEditedFacKey)    

        if jRelationEntryMap != 0
            int otherFacKey = jIntMap.nextKey(jRelationEntryMap, 0, 0)

            While otherFacKey != 0
                ; we've got the indexes of two factions, now it's time to get the actual relation value and make it mean something
                float relValue = ClampRelationValue(jIntMap.getFlt(jRelationEntryMap, otherFacKey))
                ApplyRelationBetweenFactions(curEditedFacKey, otherFacKey, relValue)

                otherFacKey = jIntMap.nextKey(jRelationEntryMap, otherFacKey, 0)
            EndWhile
        endif

        curEditedFacKey = jIntMap.nextKey(jSABFactionRelationsMap, curEditedFacKey, 0)
    endwhile

    int i = facQuests.Length

    While i > 0
        i -= 1

        float playerRel = ClampRelationValue(JIntMap.getFlt(jSABPlayerRelationsMap, i))

        if playerRel != 0.0
            ApplyRelationBetweenPlayerAndFac(i, playerRel)
        endif
    EndWhile

EndFunction

; makes the relation value have an effect in actor interactions
Function ApplyRelationBetweenFactions(int factionOneIndex, int factionTwoIndex, float relationValue)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests
    facQuests[factionOneIndex].SetRelationsWithFaction(facQuests[factionTwoIndex].OurFaction, RelationValueToFactionStanding(relationValue))
EndFunction

Function ApplyRelationBetweenPlayerAndFac(int factionIndex, float relationValue)
    FactionDataHandler.SAB_FactionQuests[factionIndex].SetRelationsWithFaction(PlayerDataHandler.VanillaPlayerFaction, RelationValueToFactionStanding(relationValue))
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

; returns true if faction one and two have a relation value above or equal to the ally relation level threshold.
; also returns true if faction one and two are the same
bool Function AreFactionsAllied(int factionOneIndex, int factionTwoIndex)
    if factionOneIndex == factionTwoIndex
        return true
    endif

    float relValue = GetRelationBetweenFacs(factionOneIndex, factionTwoIndex)

    return relValue >= JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.allyRelationLevel", 1.0)
EndFunction

; returns true if faction one and two have a relation value below or equal to the enemy relation level threshold.
; also returns false if faction one and two are the same
bool Function AreFactionsEnemies(int factionOneIndex, int factionTwoIndex)
    if factionOneIndex == factionTwoIndex
        return false
    endif

    float relValue = GetRelationBetweenFacs(factionOneIndex, factionTwoIndex)

    return relValue <= JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.enemyRelationLevel", 0.0)
EndFunction


; uses actual faction standings to check if factions are allied or at least friendly.
; also returns true if faction one and two are the same, false if one or both the factions are None
bool Function AreFactionsInGoodStanding(SAB_FactionScript factionOne, SAB_FactionScript factionTwo)
    if factionOne == factionTwo
        return true
    endif

    if factionOne == None || factionTwo == None
        return false
    endif

    return factionOne.OurFaction.GetReaction(factionTwo.OurFaction) >= 2 ; ally or friend
EndFunction

; returns true if the standing has just changed
bool Function AddOrSubtractPlayerRelationWithFac(int factionIndex, float valueToAdd)
    float curRelation = JIntMap.getFlt(jSABPlayerRelationsMap, factionIndex, 0.0)
    float newValue = ClampRelationValue(curRelation + valueToAdd)
    JIntMap.setFlt(jSABPlayerRelationsMap, factionIndex, newValue)

    ApplyRelationBetweenPlayerAndFac(factionIndex, newValue)

    return DoValuesIndicateDifferentStandings(curRelation, newValue)
EndFunction


bool Function AddOrSubtractRelationBetweenFacs(int factionOneIndex, int factionTwoIndex, float valueToAdd)
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

    ApplyRelationBetweenFactions(factionOneIndex, factionTwoIndex, newValue)

    return DoValuesIndicateDifferentStandings(curRelation, newValue)
EndFunction


; defender and allies of the defender get angry at attackers.
; enemies of the defender become closer to attackers
Function GlobalReactToLocationAttacked(int attackingFacIndex, int defenderFacIndex)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length

    While i > 0
        i -= 1

        if i != defenderFacIndex
            if i == attackingFacIndex
                AddOrSubtractRelationBetweenFacs(attackingFacIndex, defenderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_attackLocation", -0.3))
            elseif AreFactionsAllied(i, defenderFacIndex)
                AddOrSubtractRelationBetweenFacs(i, attackingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_attackAlliedLocation", -0.15))
            elseif AreFactionsEnemies(i, defenderFacIndex)
                AddOrSubtractRelationBetweenFacs(i, attackingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_attackEnemyLocation", 0.1))
            endif
        endif
    EndWhile
EndFunction


; killed and allies of the killed get angry at player.
; enemies of the killed become closer to player
Function GlobalReactToPlayerKillingUnit(int killedUnitFacIndex)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length
    int playerFacIndex = -1

    if PlayerDataHandler.PlayerFaction != None
        playerFacIndex = PlayerDataHandler.PlayerFaction.GetFactionIndex()
    endif

    AddOrSubtractPlayerRelationWithFac(killedUnitFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyUnit", -0.05))

    While i > 0
        i -= 1

        if i != killedUnitFacIndex
            if i == playerFacIndex
                AddOrSubtractRelationBetweenFacs(playerFacIndex, killedUnitFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyUnit", -0.05))
            elseif AreFactionsAllied(i, killedUnitFacIndex)
                AddOrSubtractPlayerRelationWithFac(killedUnitFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyAllysUnit", -0.02))
                AddOrSubtractRelationBetweenFacs(i, playerFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyAllysUnit", -0.02))
            elseif AreFactionsEnemies(i, killedUnitFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysUnit", 0.01))
                AddOrSubtractRelationBetweenFacs(i, playerFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysUnit", 0.01))
            endif
        endif
    EndWhile
EndFunction

; killed and allies of the killed get angry at player.
; enemies of the killed become closer to player
Function GlobalReactToPlayerKillingCmder(int killedCmderFacIndex)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length
    int playerFacIndex = -1

    if PlayerDataHandler.PlayerFaction != None
        playerFacIndex = PlayerDataHandler.PlayerFaction.GetFactionIndex()
    endif

    AddOrSubtractPlayerRelationWithFac(killedCmderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyCmder", -0.15))

    While i > 0
        i -= 1

        if i != killedCmderFacIndex
            if i == playerFacIndex
                AddOrSubtractRelationBetweenFacs(playerFacIndex, killedCmderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyCmder", -0.15))
            elseif AreFactionsAllied(i, killedCmderFacIndex)
                AddOrSubtractPlayerRelationWithFac(killedCmderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyAllysCmder", -0.06))
                AddOrSubtractRelationBetweenFacs(i, playerFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyAllysCmder", -0.06))
            elseif AreFactionsEnemies(i, killedCmderFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysCmder", 0.05))
                AddOrSubtractRelationBetweenFacs(i, playerFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysCmder", 0.05))
            endif
        endif
    EndWhile
EndFunction



; converts a relation value to one of the numbers used by the faction script to define ingame standings
int Function RelationValueToFactionStanding(float relValue)
    if relValue >= JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.allyRelationLevel", 1.0)
		return 2 ; ally
	elseif relValue < JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.enemyRelationLevel", 0.0)
		return 1 ; enemy
	else
		return 0 ; neutral
	endif
EndFunction

; returns true if one value would mean one thing and the other one, another, in the sense of faction standings.
; for example, this would return true if one value indicates a neutral relation and the other one an allied relation 
bool Function DoValuesIndicateDifferentStandings(float relValueOne, float relValueTwo)
    return RelationValueToFactionStanding(relValueOne) != RelationValueToFactionStanding(relValueTwo)
EndFunction

; factionData jmap entries:

; a jIntMap, with faction indexes as keys, representing each faction's relation with the others.
; each entry of this first jIntMap contains another jIntMap, also with factionIndexes as keys, each entry containing a relationValue float.
; relation entries shouldn't be redundant, so always look for the relation value in the smaller faction index!
; int jFactionRelationsMap

; a jIntMap, with faction indexes as keys, representing each faction's relation with the player
; int jPlayerRelationsMap