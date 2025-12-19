scriptname SAB_DiplomacyDataHandler extends Quest
{script for setting up and getting data for SAB faction relations.}

SAB_FactionDataHandler Property FactionDataHandler Auto

SAB_PlayerDataHandler Property PlayerDataHandler Auto

; an intMap, each one defining two factions' relation
int Property jSABFactionRelationsMap Auto Hidden

; an intMap representing each faction's relation with the player
int Property jSABPlayerRelationsMap Auto Hidden

; an intMap, with each entry defining a faction, 
; and being an array of faction indexes with which the
; faction has locked relation values (they won't change)
int Property jSABLockedFactionRelationsMap Auto Hidden

; a jArray of ints, each entry defining a faction index
; with which the player has locked relation values (they won't change)
int Property jSABLockedPlayerRelationsList Auto Hidden

; a jIntMap representing a queue of faction indexes of which the player has killed units.
; this is used to avoid updating them all at the same time, decreasing the chance of stack dumps.
; keys are faction indexes, values are pending kills
int jPendingUnitKillsMap = -1

bool isGlobalReactToPlayerKillRunning = false

Function InitializeJData()
    jSABFactionRelationsMap = JIntMap.object()
    JValue.retain(jSABFactionRelationsMap, "ShoutAndBlade")

    jSABPlayerRelationsMap = JIntMap.object()
    JValue.retain(jSABPlayerRelationsMap, "ShoutAndBlade")

    jSABLockedFactionRelationsMap = JIntMap.object()
    JValue.retain(jSABLockedFactionRelationsMap, "ShoutAndBlade")

    jSABLockedPlayerRelationsList = jArray.object()
    JValue.retain(jSABLockedPlayerRelationsList, "ShoutAndBlade")
EndFunction


Event OnUpdate()
	
    if isGlobalReactToPlayerKillRunning
        return
    endif

    if jIntMap.count(jPendingUnitKillsMap) > 0
        int facKey = JIntMap.getNthKey(jPendingUnitKillsMap, 0)
        ; run fac relations updates due to player killing units, one at a time
        int facKilledsAmount = JIntMap.getInt(jPendingUnitKillsMap, facKey, 0)

        if facKey != -1
            if facKilledsAmount > 0
                JIntMap.setInt(jPendingUnitKillsMap, facKey, JIntMap.getInt(jPendingUnitKillsMap, facKey, 0) - facKilledsAmount)
                GlobalReactToPlayerKillingUnit(facKey, facKilledsAmount)

                if JIntMap.getInt(jPendingUnitKillsMap, facKey, 0) <= 0
                    JIntMap.removeKey(jPendingUnitKillsMap, facKey)
                endif
            endif
        endif
    endif
    
    RegisterForSingleUpdate(10.0)
EndEvent


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

        SetPlayerRelationWithFac(i, playerRel)
    EndWhile

EndFunction

; makes the relation value have an effect in actor interactions
Function ApplyRelationBetweenFactions(int factionOneIndex, int factionTwoIndex, float relationValue)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests
    facQuests[factionOneIndex].SetIngameRelationsWithFaction(facQuests[factionTwoIndex].OurFaction, RelationValueToFactionStanding(relationValue))
EndFunction

Function ApplyRelationBetweenPlayerAndFac(int factionIndex, float relationValue)
    FactionDataHandler.SAB_FactionQuests[factionIndex].SetIngameRelationsWithFaction(PlayerDataHandler.VanillaPlayerFaction, RelationValueToFactionStanding(relationValue))
EndFunction

; returns a relationValue constrained to the maximum and minimum relation value limits
float Function ClampRelationValue(float relationValue)
    if relationValue > JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.maxRelationValue", 2.0)
        return JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.maxRelationValue", 2.0) ; TODO make this configurable
    elseif relationValue < JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.minRelationValue", -2.0)
        return JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.minRelationValue", -2.0) ; TODO make this configurable
    endif

    return relationValue
EndFunction

float Function GetPlayerRelationWithFac(int factionIndex)
    return JIntMap.getFlt(jSABPlayerRelationsMap, factionIndex, 0.0)
EndFunction

bool Function GetIsPlayerRelationLockedWithFac(int factionIndex)
    if jSABLockedPlayerRelationsList == 0
        jSABLockedPlayerRelationsList = jArray.object()
        JValue.retain(jSABLockedPlayerRelationsList, "ShoutAndBlade")
    endif

    if jArray.findInt(jSABLockedPlayerRelationsList, factionIndex) != -1
        return true
    endif

    return false
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

bool Function GetAreRelationsLockedBetweenFacs(int factionOneIndex, int factionTwoIndex)
    if jSABLockedFactionRelationsMap == 0
        jSABLockedFactionRelationsMap = JIntMap.object()
        JValue.retain(jSABLockedFactionRelationsMap, "ShoutAndBlade")
    endif

    if factionOneIndex == factionTwoIndex
        return false
    endif

    int factionWithSmallerIndex = factionOneIndex
    int factionWithBiggerIndex = 0

    if factionOneIndex < factionTwoIndex
        factionWithBiggerIndex = factionTwoIndex
    else
        factionWithSmallerIndex = factionTwoIndex
        factionWithBiggerIndex = factionOneIndex
    endif

    ; if fac index exists in lockeds array, return true
    int jSmallerFacLockedsList = jIntMap.getObj(jSABLockedFactionRelationsMap, factionWithSmallerIndex)
    if jSmallerFacLockedsList != 0
        if jArray.findInt(jSmallerFacLockedsList, factionWithBiggerIndex) != -1
            return true
        endif
    endif

    return false
EndFunction

; returns a jArray with the facIndexes of all allied factions of the target fac. The jArray must be released after its use!
int Function GetAlliedFactionsOfTargetFac(int targetFacIndex)
    int jReturnedArray = jArray.object()
    jValue.retain(jReturnedArray, "ShoutAndBlade")

    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length

    While i > 0
        i -= 1

        if i != targetFacIndex
            if AreFactionsAllied(i, targetFacIndex)
                jArray.addInt(jReturnedArray, i)
            endif
        endif
    EndWhile

    return jReturnedArray
EndFunction

; returns a jArray with the facIndexes of all enemy factions of the target fac. The jArray must be released after its use!
int Function GetEnemyFactionsOfTargetFac(int targetFacIndex)
    int jReturnedArray = jArray.object()
    jValue.retain(jReturnedArray, "ShoutAndBlade")

    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length

    While i > 0
        i -= 1

        if i != targetFacIndex
            if AreFactionsEnemies(i, targetFacIndex)
                jArray.addInt(jReturnedArray, i)
            endif
        endif
    EndWhile

    return jReturnedArray
EndFunction

; returns true if faction one and two have a relation value above or equal to the ally relation level threshold.
; returns true if faction one and two are the same
bool Function AreFactionsAllied(int factionOneIndex, int factionTwoIndex)
    if factionOneIndex == factionTwoIndex
        return true
    endif

    float relValue = GetRelationBetweenFacs(factionOneIndex, factionTwoIndex)

    return relValue >= JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.allyRelationLevel", 1.0) ; TODO make this configurable
EndFunction

; returns true if faction one and two have a relation value below the enemy relation level threshold.
; returns false if faction one and two are the same
bool Function AreFactionsEnemies(int factionOneIndex, int factionTwoIndex)
    if factionOneIndex == factionTwoIndex
        return false
    endif

    float relValue = GetRelationBetweenFacs(factionOneIndex, factionTwoIndex)

    return relValue < JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.enemyRelationLevel", 0.0) ; TODO make this configurable
EndFunction

; returns true if faction one and two have a relation value above or equal to the enemy relation level threshold,
; and below the ally relation level threshold.
; returns false if faction one and two are the same
bool Function AreFactionsNeutral(int factionOneIndex, int factionTwoIndex)
    if factionOneIndex == factionTwoIndex
        return false
    endif

    float relValue = GetRelationBetweenFacs(factionOneIndex, factionTwoIndex)

    return (relValue >= JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.enemyRelationLevel", 0.0) && relValue < JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.allyRelationLevel", 1.0)) 
EndFunction

; uses actual faction standings to check if factions are allied or at least friendly.
; returns true if faction one and two are the same, false if one or both the factions are None
bool Function AreFactionsInGoodStanding(SAB_FactionScript factionOne, SAB_FactionScript factionTwo)
    if factionOne == factionTwo
        return true
    endif

    if factionOne == None || factionTwo == None
        return false
    endif

    return factionOne.OurFaction.GetReaction(factionTwo.OurFaction) >= 2 ; ally or friend
EndFunction

; true if the faction's relation towards the player is below the enemy threshold. False if neutral or better
bool Function IsFactionEnemyOfPlayer(int factionIndex)

    return GetPlayerRelationWithFac(factionIndex) < JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.enemyRelationLevel", 0.0) ; TODO make this configurable

EndFunction

; true if the faction's relation towards the player is above the ally threshold. False if neutral or worse
bool Function IsFactionAllyOfPlayer(int factionIndex)

    return GetPlayerRelationWithFac(factionIndex) >= JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.allyRelationLevel", 1.0) ; TODO make this configurable

EndFunction

; returns true if the standing has just changed
bool Function AddOrSubtractPlayerRelationWithFac(int factionIndex, float valueToAdd, bool ignoreLocked = false)
    if factionIndex < 0
        return false
    endif

    ; check if relation isn't locked before trying to change it!
    if !ignoreLocked
        if jSABLockedPlayerRelationsList == 0
            jSABLockedPlayerRelationsList = jArray.object()
            JValue.retain(jSABLockedPlayerRelationsList, "ShoutAndBlade")
        endif

        ; if fac index exists in lockeds array, abort
        if jArray.findInt(jSABLockedPlayerRelationsList, factionIndex) != -1
            return false
        endif
    endif

    float curRelation = JIntMap.getFlt(jSABPlayerRelationsMap, factionIndex, 0.0)
    float newValue = ClampRelationValue(curRelation + valueToAdd)
    JIntMap.setFlt(jSABPlayerRelationsMap, factionIndex, newValue)

    ApplyRelationBetweenPlayerAndFac(factionIndex, newValue)

    bool standingsChanged = DoValuesIndicateDifferentStandings(curRelation, newValue)

    if standingsChanged
        NotifyPlayerRelationChangeTowardsFac(factionIndex, newValue)
    endif

    return standingsChanged
EndFunction

; returns true if the standing has just changed
bool Function SetPlayerRelationWithFac(int factionIndex, float newRelationValue, bool ignoreLocked = false)
    if factionIndex < 0
        return false
    endif

    ; check if relation isn't locked before trying to change it!
    if !ignoreLocked
        if jSABLockedPlayerRelationsList == 0
            jSABLockedPlayerRelationsList = jArray.object()
            JValue.retain(jSABLockedPlayerRelationsList, "ShoutAndBlade")
        endif

        ; if fac index exists in lockeds array, abort
        if jArray.findInt(jSABLockedPlayerRelationsList, factionIndex) != -1
            return false
        endif
    endif

    float curRelation = JIntMap.getFlt(jSABPlayerRelationsMap, factionIndex, 0.0)
    float newValue = ClampRelationValue(newRelationValue)
    JIntMap.setFlt(jSABPlayerRelationsMap, factionIndex, newValue)

    ApplyRelationBetweenPlayerAndFac(factionIndex, newValue)

    bool standingsChanged = DoValuesIndicateDifferentStandings(curRelation, newValue)

    return standingsChanged
EndFunction

Function SetLockPlayerRelationsWithFac(int factionIndex, bool lock)
    if factionIndex < 0
        return
    endif

    if jSABLockedPlayerRelationsList == 0
        jSABLockedPlayerRelationsList = jArray.object()
        JValue.retain(jSABLockedPlayerRelationsList, "ShoutAndBlade")
    endif

    ; if fac index exists in lockeds array...
    if jArray.findInt(jSABLockedPlayerRelationsList, factionIndex) != -1
        if !lock
            jArray.eraseInteger(jSABLockedPlayerRelationsList, factionIndex)
        endif
    else
        if lock
            jArray.addInt(jSABLockedPlayerRelationsList, factionIndex)
        endif
    endif
EndFunction

bool Function AddOrSubtractRelationBetweenFacs(int factionOneIndex, int factionTwoIndex, float valueToAdd, int playerFacIndex, bool ignoreLocked = false)
    if factionOneIndex < 0 || factionTwoIndex < 0
        return false
    endif

    if factionOneIndex == factionTwoIndex
        return false
    endif

    int factionWithSmallerIndex = factionOneIndex
    int factionWithBiggerIndex = 0

    if factionOneIndex < factionTwoIndex
        factionWithBiggerIndex = factionTwoIndex
    else
        factionWithSmallerIndex = factionTwoIndex
        factionWithBiggerIndex = factionOneIndex
    endif

    ; check if relation isn't locked before trying to change it!
    if !ignoreLocked
        if jSABLockedFactionRelationsMap == 0
            jSABLockedFactionRelationsMap = JIntMap.object()
            JValue.retain(jSABLockedFactionRelationsMap, "ShoutAndBlade")
        endif

        ; if fac index exists in lockeds array, abort
        int jSmallerFacLockedsList = jIntMap.getObj(jSABLockedFactionRelationsMap, factionWithSmallerIndex)
        if jSmallerFacLockedsList != 0
            if jArray.findInt(jSmallerFacLockedsList, factionWithBiggerIndex) != -1
                return false
            endif
        endif
        
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

    bool relationHasChanged = DoValuesIndicateDifferentStandings(curRelation, newValue)

    ; if one of them is the player's faction, override the player's relation levels
    if playerFacIndex == factionOneIndex
        SetPlayerRelationWithFac(factionTwoIndex, newValue)
    elseif playerFacIndex == factionTwoIndex
        SetPlayerRelationWithFac(factionOneIndex, newValue)
    endif

    return relationHasChanged
EndFunction

bool Function SetRelationBetweenFacs(int factionOneIndex, int factionTwoIndex, float newRelationValue, int playerFacIndex, bool ignoreLocked = false)
    if factionOneIndex < 0 || factionTwoIndex < 0
        return false
    endif

    if factionOneIndex == factionTwoIndex
        return false
    endif

    int factionWithSmallerIndex = factionOneIndex
    int factionWithBiggerIndex = 0

    if factionOneIndex < factionTwoIndex
        factionWithBiggerIndex = factionTwoIndex
    else
        factionWithSmallerIndex = factionTwoIndex
        factionWithBiggerIndex = factionOneIndex
    endif

    ; check if relation isn't locked before trying to change it!
    if !ignoreLocked
        if jSABLockedFactionRelationsMap == 0
            jSABLockedFactionRelationsMap = JIntMap.object()
            JValue.retain(jSABLockedFactionRelationsMap, "ShoutAndBlade")
        endif

        ; if fac index exists in lockeds array, abort
        int jSmallerFacLockedsList = jIntMap.getObj(jSABLockedFactionRelationsMap, factionWithSmallerIndex)
        if jSmallerFacLockedsList != 0
            if jArray.findInt(jSmallerFacLockedsList, factionWithBiggerIndex) != -1
                return false
            endif
        endif
        
    endif

    int jSmallerFacRelationsMap = jIntMap.getObj(jSABFactionRelationsMap, factionWithSmallerIndex)

    if jSmallerFacRelationsMap == 0
        jSmallerFacRelationsMap = jIntMap.object()
        JIntMap.setObj(jSABFactionRelationsMap, factionWithSmallerIndex, jSmallerFacRelationsMap)
    endif

    float curRelation = JIntMap.getFlt(jSmallerFacRelationsMap, factionWithBiggerIndex, 0.0)
    float newValue = ClampRelationValue(newRelationValue)
    JIntMap.setFlt(jSmallerFacRelationsMap, factionWithBiggerIndex, newValue)

    ApplyRelationBetweenFactions(factionOneIndex, factionTwoIndex, newValue)

    bool relationHasChanged = DoValuesIndicateDifferentStandings(curRelation, newValue)

    ; if one of them is the player's faction, override the player's relation levels
    if playerFacIndex == factionOneIndex
        SetPlayerRelationWithFac(factionTwoIndex, newValue)
    elseif playerFacIndex == factionTwoIndex
        SetPlayerRelationWithFac(factionOneIndex, newValue)
    endif

    return relationHasChanged
EndFunction

Function SetLockedRelationsBetweenFacs(int factionOneIndex, int factionTwoIndex, bool lock)
    if factionOneIndex < 0 || factionTwoIndex < 0
        return
    endif

    if factionOneIndex == factionTwoIndex
        return
    endif

    int factionWithSmallerIndex = factionOneIndex
    int factionWithBiggerIndex = 0

    if factionOneIndex < factionTwoIndex
        factionWithBiggerIndex = factionTwoIndex
    else
        factionWithSmallerIndex = factionTwoIndex
        factionWithBiggerIndex = factionOneIndex
    endif

    ; check if relation isn't locked before trying to change it!
    if jSABLockedFactionRelationsMap == 0
        jSABLockedFactionRelationsMap = JIntMap.object()
        JValue.retain(jSABLockedFactionRelationsMap, "ShoutAndBlade")
    endif

    
    int jSmallerFacLockedsList = jIntMap.getObj(jSABLockedFactionRelationsMap, factionWithSmallerIndex)
    if jSmallerFacLockedsList == 0
        jSmallerFacLockedsList = jArray.object()
        jIntMap.setObj(jSABLockedFactionRelationsMap, factionWithSmallerIndex, jSmallerFacLockedsList)
    endif

    ; if fac index exists in lockeds array...
    if jArray.findInt(jSmallerFacLockedsList, factionWithBiggerIndex) != -1
        if !lock
            jArray.eraseInteger(jSmallerFacLockedsList, factionWithBiggerIndex)
        endif
    else
        if lock
            jArray.addInt(jSmallerFacLockedsList, factionWithBiggerIndex)
        endif
    endif
EndFunction

; defender and allies of the defender get angry at attackers.
; enemies of the defender become closer to attackers
Function GlobalReactToWarDeclaration(int attackingFacIndex, int defenderFacIndex)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length
    int playerFacIndex = -1

    if PlayerDataHandler.PlayerFaction != None
        playerFacIndex = PlayerDataHandler.PlayerFaction.GetFactionIndex()
    endif

    While i > 0
        i -= 1

        if i != defenderFacIndex
            if i == attackingFacIndex
                ; relation deduction must be enough to make them hate each other right away
                float relationDeduction = GetRelationBetweenFacs(attackingFacIndex, defenderFacIndex)
                if relationDeduction > 0
                    relationDeduction = relationDeduction * -1
                endif

                relationDeduction += JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_warDeclared", -1.0) ; TODO make this configurable

                AddOrSubtractRelationBetweenFacs(attackingFacIndex, defenderFacIndex, relationDeduction, playerFacIndex, false)
            elseif AreFactionsAllied(i, defenderFacIndex)
                AddOrSubtractRelationBetweenFacs(i, attackingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_warDeclaredOnAlly", -0.55), playerFacIndex, false) ; TODO make this configurable
            elseif AreFactionsEnemies(i, defenderFacIndex)
                AddOrSubtractRelationBetweenFacs(i, attackingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_warDeclaredOnEnemy", 0.4), playerFacIndex, false) ; TODO make this configurable
            endif
        endif
    EndWhile
EndFunction

; reduce relations with all allies of fac,
; to make them eventually fight each other if no other enemies are left
Function GlobalAllianceDecayWithFac(int dacayingFacIndex)
    if dacayingFacIndex < 0
        return
    endif

    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length
    int playerFacIndex = -1

    if PlayerDataHandler.PlayerFaction != None
        playerFacIndex = PlayerDataHandler.PlayerFaction.GetFactionIndex()
    endif

    While i > 0
        i -= 1

        if i != dacayingFacIndex
            if AreFactionsAllied(i, dacayingFacIndex)
                AddOrSubtractRelationBetweenFacs(i, dacayingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_allianceDecay", -0.1), playerFacIndex, false) ; TODO make this configurable
            endif
        endif
    EndWhile
EndFunction


; defender and allies of the defender get angry at attackers.
; enemies of the defender become closer to attackers
Function GlobalReactToLocationAttacked(int attackingFacIndex, int defenderFacIndex)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length
    int playerFacIndex = -1

    if PlayerDataHandler.PlayerFaction != None
        playerFacIndex = PlayerDataHandler.PlayerFaction.GetFactionIndex()
    endif

    While i > 0
        i -= 1

        if i != defenderFacIndex
            if i == attackingFacIndex
                AddOrSubtractRelationBetweenFacs(attackingFacIndex, defenderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_attackLocation", -0.8), playerFacIndex, false) ; TODO make this configurable
            elseif AreFactionsAllied(i, defenderFacIndex)
                AddOrSubtractRelationBetweenFacs(i, attackingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_attackAlliedLocation", -0.2), playerFacIndex, false) ; TODO make this configurable
            elseif AreFactionsEnemies(i, defenderFacIndex)
                AddOrSubtractRelationBetweenFacs(i, attackingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_attackEnemyLocation", 0.1), playerFacIndex, false) ; TODO make this configurable
            endif
        endif
    EndWhile
EndFunction

; defender and allies of the defender get angry at attackers.
; enemies of the defender become closer to attackers
Function GlobalReactToAutocalcBattle(int attackingFacIndex, int defenderFacIndex)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length
    int playerFacIndex = -1

    if PlayerDataHandler.PlayerFaction != None
        playerFacIndex = PlayerDataHandler.PlayerFaction.GetFactionIndex()
    endif

    While i > 0
        i -= 1

        if i != defenderFacIndex
            if i == attackingFacIndex
                AddOrSubtractRelationBetweenFacs(attackingFacIndex, defenderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_attacked_autocalc", -0.5), playerFacIndex, false) ; TODO make this configurable
            elseif AreFactionsAllied(i, defenderFacIndex)
                AddOrSubtractRelationBetweenFacs(i, attackingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_attacked_ally_autocalc", -0.2), playerFacIndex, false) ; TODO make this configurable
            elseif AreFactionsEnemies(i, defenderFacIndex)
                AddOrSubtractRelationBetweenFacs(i, attackingFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_attacked_enemy_autocalc", 0.1), playerFacIndex, false) ; TODO make this configurable
            endif
        endif
    EndWhile
EndFunction


; killed and allies of the killed get angry at player.
; enemies of the killed become closer to player.
; this queues the reaction, to avoid stack dumps due to too many units being killed
Function QueueGlobalReactToPlayerKillingUnit(int killedUnitFacIndex)
    if jPendingUnitKillsMap == -1
        debug.Trace("initial set up for relation kills queue")
        ; the queue array hasn't been set up yet!
        ; set it up and start the updates
        jPendingUnitKillsMap = jIntMap.object()
        JValue.retain(jPendingUnitKillsMap, "ShoutAndBlade")

        RegisterForSingleUpdate(0.05)
    endif

    int numPendingKillsFromFac = jIntMap.getInt(jPendingUnitKillsMap, killedUnitFacIndex, 0)
    JIntMap.setInt(jPendingUnitKillsMap, killedUnitFacIndex, numPendingKillsFromFac + 1)

EndFunction

; killed and allies of the killed get angry at player.
; enemies of the killed become closer to player
Function GlobalReactToPlayerKillingUnit(int killedUnitFacIndex, int killedUnitAmount)

    isGlobalReactToPlayerKillRunning = true
    debug.Trace("global react to unit kills START! killedFac: "+ killedUnitFacIndex +", killedAmount: " + killedUnitAmount)

    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length
    int playerFacIndex = -1

    if PlayerDataHandler.PlayerFaction != None
        playerFacIndex = PlayerDataHandler.PlayerFaction.GetFactionIndex()
    endif

    AddOrSubtractPlayerRelationWithFac(killedUnitFacIndex, killedUnitAmount * JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyUnit", -0.05), false) ; TODO make this configurable

    While i > 0
        i -= 1

        if i != killedUnitFacIndex
            if i == playerFacIndex
                AddOrSubtractRelationBetweenFacs(playerFacIndex, killedUnitFacIndex, killedUnitAmount * JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyUnit", -0.05), playerFacIndex, false) ; TODO make this configurable
                AddOrSubtractPlayerRelationWithFac(playerFacIndex, killedUnitAmount * JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysUnit", 0.01), false)
            elseif AreFactionsAllied(i, killedUnitFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, killedUnitAmount * JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyAllysUnit", -0.02), false) ; TODO make this configurable
                AddOrSubtractRelationBetweenFacs(i, playerFacIndex, killedUnitAmount * JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyAllysUnit", -0.02), playerFacIndex, false) ; TODO make this configurable
            elseif AreFactionsEnemies(i, killedUnitFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, killedUnitAmount * JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysUnit", 0.01), false) ; TODO make this configurable
                AddOrSubtractRelationBetweenFacs(i, playerFacIndex, killedUnitAmount * JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysUnit", 0.01), playerFacIndex, false) ; TODO make this configurable
            endif
        endif
    EndWhile

    isGlobalReactToPlayerKillRunning = false
    debug.Trace("global react to unit kills END! killedFac: "+ killedUnitFacIndex +", killedAmount: " + killedUnitAmount)
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

    AddOrSubtractPlayerRelationWithFac(killedCmderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyCmder", -0.15), false) ; TODO make this configurable

    While i > 0
        i -= 1

        if i != killedCmderFacIndex
            if i == playerFacIndex
                AddOrSubtractRelationBetweenFacs(playerFacIndex, killedCmderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyCmder", -0.15), playerFacIndex, false) ; TODO make this configurable
                AddOrSubtractPlayerRelationWithFac(playerFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysCmder", 0.05), false)
            elseif AreFactionsAllied(i, killedCmderFacIndex)
                AddOrSubtractPlayerRelationWithFac(killedCmderFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyAllysCmder", -0.06), false) ; TODO make this configurable
                AddOrSubtractRelationBetweenFacs(i, playerFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerKilledMyAllysCmder", -0.06), playerFacIndex, false) ; TODO make this configurable
            elseif AreFactionsEnemies(i, killedCmderFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysCmder", 0.05), false) ; TODO make this configurable
                AddOrSubtractRelationBetweenFacs(i, playerFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerKilledMyEnemysCmder", 0.05), playerFacIndex, false) ; TODO make this configurable
            endif
        endif
    EndWhile
EndFunction


; joined faction likes it,
; allies of joined faction like it
; enemies of joined faction dislike it,
Function GlobalReactToPlayerJoiningFaction(int joinedFacIndex)
    if joinedFacIndex < 0
        return
    endif

    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length

    AddOrSubtractPlayerRelationWithFac(joinedFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerJoinedMe", 0.45), false) ; TODO make this configurable

    While i > 0
        i -= 1

        if i != joinedFacIndex
            if AreFactionsAllied(i, joinedFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerJoinedAlly", 0.26), false) ; TODO make this configurable
            elseif AreFactionsEnemies(i, joinedFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerJoinedEnemy", -0.35), false) ; TODO make this configurable
            endif
        endif
    EndWhile
EndFunction


; left faction dislikes it,
; allies of left faction dislike it,
; enemies of left faction like it
Function GlobalReactToPlayerLeavingFaction(int leftFacIndex)
    if leftFacIndex < 0
        return
    endif

    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests

    int i = facQuests.Length

    AddOrSubtractPlayerRelationWithFac(leftFacIndex, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerLeftMe", -0.55), false) ; TODO make this configurable

    While i > 0
        i -= 1

        if i != leftFacIndex
            if AreFactionsAllied(i, leftFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relDmg_playerLeftAlly", -0.26), false) ; TODO make this configurable
            elseif AreFactionsEnemies(i, leftFacIndex)
                AddOrSubtractPlayerRelationWithFac(i, JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.relAdd_playerLeftEnemy", 0.1), false) ; TODO make this configurable
            endif
        endif
    EndWhile
EndFunction


; converts a relation value to one of the numbers used by the faction script to define ingame standings
int Function RelationValueToFactionStanding(float relValue)
    if relValue >= JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.allyRelationLevel", 1.0) ; TODO make this configurable
		return 2 ; ally
	elseif relValue < JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.enemyRelationLevel", 0.0) ; TODO make this configurable
		return 1 ; enemy
	else
		return 0 ; neutral
	endif
EndFunction

; returns a word describing what the relation value means
string Function GetRelationValueDescriptionWord(float relValue)
    if relValue >= JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.allyRelationLevel", 1.0) ; TODO make this configurable
		return "friendly" ; ally
	elseif relValue < JDB.solveFlt(".ShoutAndBlade.diplomacyOptions.enemyRelationLevel", 0.0) ; TODO make this configurable
		return "hostile" ; enemy
	else
		return "neutral" ; neutral
	endif
EndFunction

; returns true if one value would mean one thing and the other one, another, in the sense of faction standings.
; for example, this would return true if one value indicates a neutral relation and the other one an allied relation 
bool Function DoValuesIndicateDifferentStandings(float relValueOne, float relValueTwo)
    if relValueOne == relValueTwo
        return false
    endif

    return RelationValueToFactionStanding(relValueOne) != RelationValueToFactionStanding(relValueTwo)
EndFunction

Function NotifyPlayerRelationChangeTowardsFac(int facIndex, float newRelationValue)
    SAB_FactionScript[] facQuests = FactionDataHandler.SAB_FactionQuests
    string msg = "The "+ facQuests[facIndex].GetFactionName() +" are now "+ GetRelationValueDescriptionWord(newRelationValue) +" towards you."
    if JDB.solveInt(".ShoutAndBlade.diplomacyOptions.showRelChangeNotify", 1) >= 1
        Debug.Notification(msg)
    endif
    
    if JDB.solveInt(".ShoutAndBlade.diplomacyOptions.showRelChangeMessageBox", 0) >= 1
        Debug.MessageBox(msg)
    endif

    facQuests[facIndex].UpdatePlayerAccessToOurLocs()
    
EndFunction


; factionData jmap entries:

; a jIntMap, with faction indexes as keys, representing each faction's relation with the others.
; each entry of this first jIntMap contains another jIntMap, also with factionIndexes as keys, each entry containing a relationValue float.
; relation entries shouldn't be redundant, so always look for the relation value in the smaller faction index!
; int jFactionRelationsMap

; a jIntMap, with faction indexes as keys, representing each faction's relation with the player
; int jPlayerRelationsMap