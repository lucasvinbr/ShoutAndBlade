Scriptname SAB_CommanderScript extends ReferenceAlias  

; a map of "unit index - amount" ints describing the units currently controlled by this commander
int jOwnedUnitsMap

; a map of "unit index - amount" ints describing the living units currently spawned by this commander
int jSpawnedUnitsMap

; an array of unit indexes, filled whenever we're looking for an unit index to spawn
int jSpawnOptionsArray

; a simple counter for spawned living units, just to not have to iterate through the jMaps
int spawnedUnitsAmount = 0

; a simple counter for total owned living units, just to not have to iterate through the jMaps
int totalOwnedUnitsAmount = 0

; a cached reference to the SAB spawner script so that we don't have to make lots of fetching whenever we want to spawn someone
SAB_FactionScript factionScript

int Property CmderFollowFactionRank Auto
{ the rank in the "cmderFollowerFaction" referring to this commander. Units in this rank should follow this cmder }

string Property CmderDestinationType Auto
{ can be "A", "B" or "C". Defines which of the 3 faction destinations this cmder will always go to }

; experience points the cmder can use to upgrade their units
float availableExpPoints

bool isNearby = false


Function Setup(SAB_FactionScript factionScriptRef)
	jOwnedUnitsMap = jValue.releaseAndRetain(jOwnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnedUnitsMap = jValue.releaseAndRetain(jSpawnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnOptionsArray = jValue.releaseAndRetain(jSpawnOptionsArray, jArray.object(), "ShoutAndBlade")
	availableExpPoints = 0.0
	totalOwnedUnitsAmount = 0
	spawnedUnitsAmount = 0
	factionScript = factionScriptRef
	; TryRecruitUnits()
	RegisterForSingleUpdateGameTime(0.25 + Utility.RandomFloat(0.01, 0.09))
EndFunction

Event OnCellAttach()
	debug.Trace("commander: on cell attach!")
	isNearby = true
	RegisterForSingleUpdate(0.5)
EndEvent

Event OnAttachedToCell()
	debug.Trace("commander: on attached to cell!")
	isNearby = true
	RegisterForSingleUpdate(0.5)
EndEvent

Event OnCellDetach()
	debug.Trace("commander: on cell detach!")
	isNearby = false
	UnregisterForUpdate()
EndEvent

Event OnDetachedFromCell()
	debug.Trace("commander: on detached from cell!")
	isNearby = false
	UnregisterForUpdate()
EndEvent

Event OnUpdateGameTime()
	;debug.Trace("game time updating commander (pre check)!")
	availableExpPoints += 500.0 ; TODO make this configurable
	Actor meActor = GetReference() as Actor

	if meActor == None
		debug.Trace("WARNING: attempted to update commander which reference was None!")
		ClearCmderData()
		return
	endif


	if !meActor.IsDead()
		if !meActor.IsInCombat()
			;debug.Trace("game time updating commander!")

			; if we have enough units, upgrade. If we don't, recruit some more
			if totalOwnedUnitsAmount >= 30 * 0.7
				TryUpgradeUnits()
			else 
				TryRecruitUnits()
			endif
			
			Utility.Wait(0.01)
			meActor.EvaluatePackage()

			float distToPlayer = game.GetPlayer().GetDistance(meActor)
			debug.Trace("dist to player from cmder of faction " + jMap.getStr(factionScript.jFactionData, "name", "Faction") + ": " + distToPlayer)

			if !isNearby
				if distToPlayer <= 2500.0
					isNearby = true
					RegisterForSingleUpdate(0.5)
				endif
			endif
			
		endif
	else 
		if ClearAliasIfOutOfTroops()
			return
		else
			float distToPlayer = game.GetPlayer().GetDistance(meActor)

			debug.Trace("dist to player from dead cmder of faction " + jMap.getStr(factionScript.jFactionData, "name", "Faction") + ": " + distToPlayer)

			if !isNearby
				if distToPlayer <= 2500.0
					isNearby = true
					RegisterForSingleUpdate(0.5)
				endif
			endif
		endif
	endif

	RegisterForSingleUpdateGameTime(0.25 + Utility.RandomFloat(0.01, 0.09)) ; TODO make this configurable
EndEvent

Event OnUpdate()
	;debug.Trace("real time updating commander!")
	if spawnedUnitsAmount < 20 ; TODO make this configurable
		; spawn random unit from "storage"
		int indexToSpawn = GetUnitIndexToSpawn()
		if indexToSpawn >= 0
			SpawnUnit(indexToSpawn)
		endif
	endif

	if isNearby
		RegisterForSingleUpdate(0.7 + Utility.RandomFloat(0.01, 0.2))
	endif
	
EndEvent

; if we don't have too many units already, attempts to get some more basic recruits with the faction gold
Function TryRecruitUnits()
	; debug.Trace("commander: try recruit units!")
	int maxUnitSlots = 30 ; TODO make this configurable via MCM

	if totalOwnedUnitsAmount < maxUnitSlots
		int recruitedUnits = factionScript.PurchaseRecruits(maxUnitSlots - totalOwnedUnitsAmount)

		int unitIndex = jMap.getInt(factionScript.jFactionData, "RecruitUnitIndex")
		int currentStoredAmount = jIntMap.getInt(jOwnedUnitsMap, unitIndex)
		jIntMap.setInt(jOwnedUnitsMap, unitIndex, currentStoredAmount + recruitedUnits)
		totalOwnedUnitsAmount += recruitedUnits
	endif
	
EndFunction

;
Function TryUpgradeUnits()
	;debug.Trace("commander: try upgrade units!")

	; we should only upgrade units not currently spawned
	; so if all units are spawned, no upgrades should be made
	if spawnedUnitsAmount >= totalOwnedUnitsAmount
		return
	endif

	int unitIndexToTrain = GetUnitIndexToSpawn()

	int ownedUnitCount = jIntMap.getInt(jOwnedUnitsMap, unitIndexToTrain)
	int spawnedUnitCount = jIntMap.getInt(jSpawnedUnitsMap, unitIndexToTrain)

	if ownedUnitCount > spawnedUnitCount
		int jUpgradeResultMap = factionScript.TryUpgradeUnits(unitIndexToTrain, ownedUnitCount - spawnedUnitCount, availableExpPoints)

		if jUpgradeResultMap != 0
			int upgradedAmount = jMap.getInt(jUpgradeResultMap, "NewUnitAmount")
			int newUnitIndex = jMap.getInt(jUpgradeResultMap, "NewUnitIndex")
			availableExpPoints = jMap.getFlt(jUpgradeResultMap, "RemainingExp")

			; add units to the new index and remove from the old one
			int curNewUnitStoredAmount = jIntMap.getInt(jOwnedUnitsMap, newUnitIndex)
			jIntMap.setInt(jOwnedUnitsMap, newUnitIndex, curNewUnitStoredAmount + upgradedAmount)
			
			jIntMap.setInt(jOwnedUnitsMap, unitIndexToTrain, ownedUnitCount - upgradedAmount)

			if ownedUnitCount - upgradedAmount <= 0
				jIntMap.removeKey(jOwnedUnitsMap, unitIndexToTrain)
			endif

			jValue.release(jUpgradeResultMap)
		endif
	endif

endFunction

; returns a valid random unit index from our ownedUnits list, or -1 if it fails for some reason (no units available to spawn, for example)
int Function GetUnitIndexToSpawn()
	jArray.clear(jSpawnOptionsArray)

	int curKey = jIntMap.nextKey(jOwnedUnitsMap, previousKey = -1, endKey = -1)
	while curKey != -1
		int ownedUnitCount = jIntMap.getInt(jOwnedUnitsMap, curKey)
		int spawnedUnitCount = jIntMap.getInt(jSpawnedUnitsMap, curKey)
		
		if spawnedUnitCount < ownedUnitCount
			jArray.addInt(jSpawnOptionsArray, curKey)
		endif

		curKey = jIntMap.nextKey(jOwnedUnitsMap, curKey, endKey=-1)
		Utility.Wait(0.01)
	endwhile

	int spawnOptionsCount = jValue.count(jSpawnOptionsArray)
	if spawnOptionsCount > 0
		return jArray.getInt(jSpawnOptionsArray, Utility.RandomInt(0, spawnOptionsCount - 1))
	endif

	return -1
endfunction


Function SpawnUnit(int unitIndex)
	ObjectReference spawnLocation = GetReference()

	if (spawnLocation as Actor).IsInCombat()
		spawnLocation = factionScript.UnitSpawnPoint.GetReference()
	endif

	ReferenceAlias spawnedUnit = factionScript.SpawnUnitForCmder(self, unitIndex, spawnLocation)

	if spawnedUnit != None
		; add spawned unit index to spawneds list
		int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
		jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount + 1)

		spawnedUnitsAmount += 1
	endif
EndFunction

; removes the despawned unit from the spawnedUnits list, but not from the ownedUnits, so that it can spawn again later
Function OwnedUnitHasDespawned(int unitIndex)
	int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
	jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount + 1)

	spawnedUnitsAmount -= 1
EndFunction

; removes the dead unit from the ownedUnits and spawnedUnits lists
Function OwnedUnitHasDied(int unitIndex)
	int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
	jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount - 1)

	spawnedUnitsAmount -= 1
	totalOwnedUnitsAmount -= 1

	int currentStoredAmount = jIntMap.getInt(jOwnedUnitsMap, unitIndex)
	jIntMap.setInt(jOwnedUnitsMap, unitIndex, currentStoredAmount - 1)

	if currentStoredAmount - 1 <= 0
		jIntMap.removeKey(jOwnedUnitsMap, unitIndex)
	endif
EndFunction

Event OnPackageEnd(Package akOldPackage)
	; this is kind of reliable
	factionScript.CmderReachedDestination(self)
EndEvent

Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	debug.Trace("commander: combat state changed!")
	if aeCombatState == 1 || aeCombatState == 2 ; engaging or searching
		if !isNearby
			isNearby = true
			RegisterForSingleUpdate(0.5)
		endif
		; if the current spawn is too far away,
		; update the faction's unit spawn point to where this cmder started combat
		ObjectReference unitSpawn = factionScript.UnitSpawnPoint.GetReference()
		ObjectReference cmderRef = GetReference()
		if unitSpawn.GetDistance(cmderRef) > 800.0
			unitSpawn.MoveTo(cmderRef)
		endif
	endif
EndEvent

event OnDeath(Actor akKiller)	
	debug.Trace("commander: dead!")
	ClearAliasIfOutOfTroops()
endEvent

; returns true if out of troops and cleared
bool Function ClearAliasIfOutOfTroops()
	debug.Trace("commander (" + jMap.getStr(factionScript.jFactionData, "name", "Faction") + "): clear alias if out of troops!")
	if totalOwnedUnitsAmount <= 0
		ClearCmderData()
		return true
	endif

	return false
EndFunction

; clears the alias and stops updates
Function ClearCmderData()
	debug.Trace("commander: clear cmder data!")
	Clear()
	UnregisterForUpdate()
	UnregisterForUpdateGameTime()
	isNearby = false
EndFunction