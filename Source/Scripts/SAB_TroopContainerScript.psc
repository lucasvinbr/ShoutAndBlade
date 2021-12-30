Scriptname SAB_TroopContainerScript extends SAB_UpdatedReferenceAlias
{ script for any alias that has a list of troops they can spawn, recruit and upgrade. Should be updated regularly via alias updaters }

; a map of "unit index - amount" ints describing the units currently controlled by this commander
int property jOwnedUnitsMap auto

; a map of "unit index - amount" ints describing the living units currently spawned by this commander
int property jSpawnedUnitsMap auto

; an array of unit indexes, filled whenever we're looking for an unit index to spawn
int property jSpawnOptionsArray auto

; a simple counter for spawned living units, just to not have to iterate through the jMaps
int property spawnedUnitsAmount = 0 auto

; a simple counter for total owned living units, just to not have to iterate through the jMaps
int property totalOwnedUnitsAmount = 0 auto

; a reference to the SAB faction script of the ones controlling this container. Can be None if this is something that can become "neutral"
SAB_FactionScript property factionScript auto

; troop containers need a second updater for when they're close, so that they can spawn units fast
SAB_SpawnersUpdater Property CloseByUpdater Auto
int property indexInCloseByUpdater auto

; cached refs for not fetching all the time
Actor property playerActor auto

; experience points the cmder can use to upgrade their units
float property availableExpPoints auto

bool property isNearby = false auto

; measured in days (1.0 is a day)
float Property gameTimeOfLastExpAward = 0.0 Auto

; measured in days (1.0 is a day)
float Property gameTimeOfLastUnitUpgrade = 0.0 Auto

; measured in days (1.0 is a day). This is used to know whether a unit is ours or of the previous container filling this alias
float Property gameTimeOfLastSetup Auto

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	jOwnedUnitsMap = jValue.releaseAndRetain(jOwnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnedUnitsMap = jValue.releaseAndRetain(jSpawnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnOptionsArray = jValue.releaseAndRetain(jSpawnOptionsArray, jArray.object(), "ShoutAndBlade")
	availableExpPoints = 0.0
	totalOwnedUnitsAmount = 0
	spawnedUnitsAmount = 0
	factionScript = factionScriptRef
	indexInUpdater = AliasUpdater.RegisterAliasForUpdates(self)
	isNearby = false
	indexInCloseByUpdater = -1
	playerActor = Game.GetPlayer()
	gameTimeOfLastExpAward = 0.0
	gameTimeOfLastUnitUpgrade = 0.0
	gameTimeOfLastSetup = curGameTime
EndFunction

; sets isNearby and enables or disables closeBy updates
Function ToggleNearbyUpdates(bool updatesEnabled)
	
	debug.Trace("troop container: toggleNearbyUpdates " + updatesEnabled)
	debug.Trace("troop container: indexInCloseByUpdater " + indexInCloseByUpdater)
	if updatesEnabled
		isNearby = true
		if indexInCloseByUpdater == -1
			indexInCloseByUpdater = CloseByUpdater.CmderUpdater.RegisterAliasForUpdates(self)
			debug.Trace("troop container: began closebyupdating!")
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater != -1
			CloseByUpdater.CmderUpdater.UnregisterAliasFromUpdates(indexInCloseByUpdater)
			indexInCloseByUpdater = -1
			debug.Trace("troop container: stopped closebyupdating!")
		endif
	endif

EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)

	if updateIndex == 1
		return RunCloseByUpdate()
	endif

	if curGameTime != 0.0 && gameTimeOfLastExpAward == 0.0
		; set initial values for "gameTime" variables, to avoid them from getting huge accumulated awards
		gameTimeOfLastExpAward = curGameTime
		gameTimeOfLastUnitUpgrade = curGameTime
		gameTimeOfLastSetup = curGameTime
	endif
	
endfunction

bool function RunCloseByUpdate()
	;debug.Trace("real time updating commander!")
	if spawnedUnitsAmount < 20 ; TODO make this configurable
		; spawn random unit from "storage"
		int indexToSpawn = GetUnitIndexToSpawn()
		if indexToSpawn >= 0
			SpawnUnit(indexToSpawn)
		endif
	endif

	return true
	
endfunction

; if we don't have too many units already, attempts to get some more basic recruits with the faction gold
Function TryRecruitUnits()
	; debug.Trace("commander: try recruit units!")
	int maxUnitSlots = GetMaxOwnedUnitsAmount() ; TODO make this configurable via MCM

	if totalOwnedUnitsAmount < maxUnitSlots
		int recruitedUnits = factionScript.PurchaseRecruits(maxUnitSlots - totalOwnedUnitsAmount)

		int unitIndex = jMap.getInt(factionScript.jFactionData, "RecruitUnitIndex")
		int currentStoredAmount = jIntMap.getInt(jOwnedUnitsMap, unitIndex)
		jIntMap.setInt(jOwnedUnitsMap, unitIndex, currentStoredAmount + recruitedUnits)
		totalOwnedUnitsAmount += recruitedUnits
	endif
	
EndFunction

; attempts to get upgrades to one of the unit types we have, using the faction gold
Function TryUpgradeUnits()
	debug.Trace("troop container: try upgrade units!")

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


; attempts to transfer some of our units (picked randomly) to the other container, respecting their maxOwnedUnitsAmount
Function TryTransferUnitsToAnotherContainer(SAB_TroopContainerScript otherContainer)
	debug.Trace("troop container: try transfer units!")

	; we should only transfer units not currently spawned
	; so if all units are spawned, no transfers should be made
	if spawnedUnitsAmount >= totalOwnedUnitsAmount
		return
	endif

	; we should only transfer units if the other container isn't full
	int availableSlotsInOtherContainer = otherContainer.GetMaxOwnedUnitsAmount() - otherContainer.totalOwnedUnitsAmount

	if availableSlotsInOtherContainer <= 0
		return
	endif

	int unitIndexToTransfer = GetUnitIndexToSpawn()

	int ownedUnitCount = jIntMap.getInt(jOwnedUnitsMap, unitIndexToTransfer)
	int spawnedUnitCount = jIntMap.getInt(jSpawnedUnitsMap, unitIndexToTransfer)

	if ownedUnitCount > spawnedUnitCount
		int unitAmountToTransfer = ownedUnitCount - spawnedUnitCount
		if unitAmountToTransfer > availableSlotsInOtherContainer
			unitAmountToTransfer = availableSlotsInOtherContainer
		endif

		if unitIndexToTransfer >= 0
			
			; remove units from this container...
			jIntMap.setInt(jOwnedUnitsMap, unitIndexToTransfer, ownedUnitCount - unitAmountToTransfer)
			if ownedUnitCount - unitAmountToTransfer <= 0
				jIntMap.removeKey(jOwnedUnitsMap, unitIndexToTransfer)
			endif
			totalOwnedUnitsAmount -= unitAmountToTransfer

			; and add them to the other!
			ownedUnitCount = jIntMap.getInt(otherContainer.jOwnedUnitsMap, unitIndexToTransfer)
			JIntMap.setInt(otherContainer.jOwnedUnitsMap, unitIndexToTransfer, ownedUnitCount + unitAmountToTransfer)
			otherContainer.totalOwnedUnitsAmount += unitAmountToTransfer

			debug.Trace("transferred " + unitAmountToTransfer + " units of index " + unitIndexToTransfer)
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
		else
			Debug.Trace("GetUnitIndexToSpawn: container has spawned " + spawnedUnitCount + " of " + ownedUnitCount)
		endif

		curKey = jIntMap.nextKey(jOwnedUnitsMap, curKey, endKey=-1)
		Utility.Wait(0.01)
	endwhile

	int spawnOptionsCount = jValue.count(jSpawnOptionsArray)
	if spawnOptionsCount > 0
		return jArray.getInt(jSpawnOptionsArray, Utility.RandomInt(0, spawnOptionsCount - 1))
	endif

	Debug.Trace("GetUnitIndexToSpawn: ended up with -1 as index!")
	Debug.Trace("GetUnitIndexToSpawn: spawnOptionsCount = " + spawnOptionsCount)
	return -1
endfunction

; this should probably be overridden
ObjectReference Function GetSpawnLocationForUnit()
	return GetReference()
EndFunction

Function SpawnUnit(int unitIndex)
	Debug.Trace("troop container: spawn unit begin!")
	ObjectReference spawnLocation = GetSpawnLocationForUnit()

	ReferenceAlias spawnedUnit = factionScript.SpawnUnitForTroopContainer(self, unitIndex, spawnLocation, gameTimeOfLastSetup)

	if spawnedUnit != None
		; add spawned unit index to spawneds list
		int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
		jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount + 1)

		spawnedUnitsAmount += 1
	endif
EndFunction

; removes the despawned unit from the spawnedUnits list, but not from the ownedUnits, so that it can spawn again later
Function OwnedUnitHasDespawned(int unitIndex, float timeOwnerWasSetup)

	if gameTimeOfLastSetup > timeOwnerWasSetup
		return
	endif

	int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
	jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount + 1)

	spawnedUnitsAmount -= 1
EndFunction

; removes the dead unit from the ownedUnits and spawnedUnits lists
Function OwnedUnitHasDied(int unitIndex, float timeOwnerWasSetup)

	if gameTimeOfLastSetup > timeOwnerWasSetup
		return
	endif

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

; this container has been completely defeated in an autocalc battle and has no units left!
; this function should do whatever happens in that case
Function HandleAutocalcDefeat()
	Debug.Trace("Override me!")
EndFunction

; returns the maximum amount of units this container should be able to own
int Function GetMaxOwnedUnitsAmount()
	return 30
endfunction