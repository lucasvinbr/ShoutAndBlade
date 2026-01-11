Scriptname SAB_TroopContainerScript extends SAB_UpdatedReferenceAlias
{ script for any alias that has a list of troops they can spawn, recruit and upgrade. Should be updated regularly via alias updaters }

; a map of "unit index - amount" ints describing the units currently controlled by this container
int property jOwnedUnitsMap auto Hidden

; a map of "unit index - amount" ints describing the living units currently spawned by this container
int property jSpawnedUnitsMap auto Hidden

; a map of "unit index - amount" ints describing the units that can still be spawned by this container
int Property jSpawnOptionsMap Auto Hidden

; a simple counter for spawned living units, just to not have to iterate through the jMaps
int property spawnedUnitsAmount = 0 auto Hidden

; a simple counter for total owned living units, just to not have to iterate through the jMaps
int property totalOwnedUnitsAmount = 0 auto Hidden

; a cached calculation of this container's troops' combined autocalc power
float property currentAutocalcPower = 0.0 auto Hidden

; a reference to the SAB faction script of the ones controlling this container. Can be None if this is something that can become "neutral"
SAB_FactionScript property factionScript auto Hidden

; troop containers need a second updater for when they're close, so that they can spawn units fast
SAB_SpawnersUpdater Property CloseByUpdater Auto
int property indexInCloseByUpdater = -1 auto Hidden

; cached refs for not fetching all the time
Actor property playerActor auto Hidden

; experience points the cmder can use to upgrade their units
float property availableExpPoints auto Hidden

; a container considered to be nearby should be spawning their units
bool property isNearby = false auto Hidden

; measured in days (1.0 is a day)
float Property gameTimeOfLastExpAward = 0.0 Auto Hidden

; measured in days (1.0 is a day)
float Property gameTimeOfLastUnitUpgrade = 0.0 Auto Hidden

; measured in days (1.0 is a day). This is used to know whether a unit is ours or of the previous container filling this alias
float Property gameTimeOfLastSetup Auto Hidden

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	jOwnedUnitsMap = jValue.releaseAndRetain(jOwnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnedUnitsMap = jValue.releaseAndRetain(jSpawnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnOptionsMap = jValue.releaseAndRetain(jSpawnOptionsMap, jIntMap.object(), "ShoutAndBlade")
	availableExpPoints = 0.0
	totalOwnedUnitsAmount = 0
	currentAutocalcPower = 0.0
	spawnedUnitsAmount = 0
	factionScript = factionScriptRef
	if indexInUpdater == -1
		indexInUpdater = AliasUpdater.RegisterAliasForUpdates(self, indexInUpdater)
	endif
	playerActor = Game.GetPlayer()
	gameTimeOfLastExpAward = 0.0
	gameTimeOfLastUnitUpgrade = -10.0 ; assign a big negative value to make sure the container recruits/upgrades ASAP
	gameTimeOfLastSetup = curGameTime
EndFunction

SAB_UnitDataHandler Function GetUnitDataHandler()
	return factionScript.SpawnerScript.UnitDataHandler
EndFunction

; sets isNearby and enables or disables closeBy updates
Function ToggleNearbyUpdates(bool updatesEnabled)
	
	; debug.Trace("troop container: toggleNearbyUpdates " + updatesEnabled)
	; debug.Trace("troop container: indexInCloseByUpdater " + indexInCloseByUpdater)
	if updatesEnabled
		isNearby = true
		if indexInCloseByUpdater == -1
			indexInCloseByUpdater = -2
			indexInCloseByUpdater = CloseByUpdater.CmderUpdater.RegisterAliasForUpdates(self, indexInCloseByUpdater)
			; debug.Trace("troop container: began closebyupdating!")
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater > -1
			int indexToUnregister = indexInCloseByUpdater
			indexInCloseByUpdater = -1
			CloseByUpdater.CmderUpdater.UnregisterAliasFromUpdates(indexToUnregister)
			; debug.Trace("troop container: stopped closebyupdating!")
		endif
	endif

EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)

	If isUpdating
		return false
	EndIf

	isUpdating = true

	if updateIndex == 1
		bool hasUpdated = RunCloseByUpdate()

		isUpdating = false
		
		return hasUpdated
	endif

	if curGameTime != 0.0 && gameTimeOfLastExpAward == 0.0
		; set initial values for "gameTime" variables, to avoid them from getting huge accumulated awards
		gameTimeOfLastExpAward = curGameTime
		gameTimeOfLastUnitUpgrade = curGameTime
		gameTimeOfLastSetup = curGameTime
	endif
	isUpdating = false
endfunction

bool function RunCloseByUpdate()

	; CullUnitsIfAboveSpawnLimit()
	;debug.Trace("real time updating commander!")
	if spawnedUnitsAmount < GetMaxSpawnedUnitsAmount()
		; spawn random units from "storage"
		SpawnUnitBatch()
	endif

	return true
	
endfunction


; adds units of the provided type to this container.
; doesn't make container limit checks or anything!
Function AddUnitsOfType(int unitTypeIndex, int amount)
	int currentStoredAmount = jIntMap.getInt(jOwnedUnitsMap, unitTypeIndex)
	jIntMap.setInt(jOwnedUnitsMap, unitTypeIndex, currentStoredAmount + amount)

	int currentSpawnableAmount = jIntMap.getInt(jSpawnOptionsMap, unitTypeIndex)
	JIntMap.setInt(jSpawnOptionsMap, unitTypeIndex, currentSpawnableAmount + amount)

	int jUnitMap = jArray.getObj(GetUnitDataHandler().jSABUnitDatasArray, unitTypeIndex)
	float unitPower = jMap.getFlt(jUnitMap, "AutocalcStrength", 1.0)

	currentAutocalcPower += amount * unitPower
	totalOwnedUnitsAmount += amount
EndFunction

; tries to remove units from this container, even if they are currently spawned
Function RemoveUnitsOfType(int unitTypeIndex, int amountToRemove)
	if amountToRemove <= 0
		return
	endif
	int spawnedsCount = JIntMap.getInt(jSpawnedUnitsMap, unitTypeIndex)
	int reservesCount = JIntMap.getInt(jSpawnOptionsMap, unitTypeIndex)
	
	; debug.Trace("total unis " + (spawnedsCount + reservesCount))
	; debug.Trace("we want to remove " + amountToRemove)

	if	amountToRemove > spawnedsCount + reservesCount
		amountToRemove = spawnedsCount + reservesCount
	endif

	; debug.Trace("clamped to " + amountToRemove)

	; we try to only mess with the reserves if possible
	if reservesCount > 0
		int reservesToRemove = reservesCount
		if amountToRemove < reservesToRemove
			reservesToRemove = amountToRemove
		endif

		totalOwnedUnitsAmount -= reservesToRemove

		int jUnitMap = jArray.getObj(GetUnitDataHandler().jSABUnitDatasArray, unitTypeIndex)
		float unitPower = jMap.getFlt(jUnitMap, "AutocalcStrength", 1.0)

		currentAutocalcPower -= unitPower

		int currentStoredAmount = jIntMap.getInt(jOwnedUnitsMap, unitTypeIndex)
		jIntMap.setInt(jOwnedUnitsMap, unitTypeIndex, currentStoredAmount - reservesToRemove)

		if currentStoredAmount - reservesToRemove <= 0
			jIntMap.removeKey(jOwnedUnitsMap, unitTypeIndex)
		endif

		int currentSpawnableAmount = jIntMap.getInt(jSpawnOptionsMap, unitTypeIndex)
		jIntMap.setInt(jSpawnOptionsMap, unitTypeIndex, currentSpawnableAmount - reservesToRemove)

		if currentSpawnableAmount - reservesToRemove <= 0
			jIntMap.removeKey(jSpawnOptionsMap, unitTypeIndex)
		endif

		amountToRemove -= reservesToRemove
	endif

	; if there are more units to remove, we've got to search for them in the spawned units list and despawn them
	while amountToRemove > 0
		SAB_UnitScript unitToRemove = factionScript.GetSpawnedUnitOfTypeFromContainer(self, unitTypeIndex)

		if unitToRemove != None
			unitToRemove.DespawnAndDontReturnToContainer()
		endif

		amountToRemove -= 1 ; assume we removed successfully, or else we may keep checking forever
	endwhile
EndFunction

; clears the container, then adds all units from the provided jIntMap
Function SetOwnedUnits(int jUnitsMap)
	JIntMap.clear(jOwnedUnitsMap)
	totalOwnedUnitsAmount = 0
	currentAutocalcPower = 0.0
	
	int unitmapKey = JIntMap.nextKey(jUnitsMap, -1, -1)
	while unitmapKey != -1
		int unitAmount = JIntMap.getInt(jUnitsMap, unitmapKey, 0)

		If unitAmount > 0
			AddUnitsOfType(unitmapKey, unitAmount)
		EndIf

		unitmapKey = JIntMap.nextKey(jUnitsMap, unitmapKey, -1)
	endwhile

EndFunction

; if we don't have too many units already, attempts to get some more basic recruits with the faction gold
Function TryRecruitUnits()
	; debug.Trace("commander: try recruit units!")

	if factionScript == None
		return
	endif

	int maxUnitSlots = GetMaxOwnedUnitsAmount()

	if totalOwnedUnitsAmount < maxUnitSlots
		int recruitedUnits = factionScript.PurchaseRecruits(maxUnitSlots - totalOwnedUnitsAmount)

		int unitIndex = jMap.getInt(factionScript.jFactionData, "RecruitUnitIndex")
		AddUnitsOfType(unitIndex, recruitedUnits)
	endif
	
EndFunction



; attempts to get upgrades to one of the unit types we have, using the faction gold
Function TryUpgradeUnits(bool alsoConsiderSpawned = false)
	; debug.Trace("troop container: try upgrade units!")

	if factionScript == None
		return
	endif

	
	if spawnedUnitsAmount >= totalOwnedUnitsAmount && !alsoConsiderSpawned
		; we should only upgrade units not currently spawned
		; so if all units are spawned, no upgrades should be made
		return
	endif

	int unitIndexToTrain = GetUnitIndexToSpawn()

	if unitIndexToTrain <= -1
		return
	endif

	int ownedUnitCount = jIntMap.getInt(jOwnedUnitsMap, unitIndexToTrain)
	int spawnedUnitCount = jIntMap.getInt(jSpawnedUnitsMap, unitIndexToTrain)
	int spawnableUnitCount = jIntMap.getInt(jSpawnOptionsMap, unitIndexToTrain)

	int upgradeablesCount = ownedUnitCount - spawnedUnitCount

	if alsoConsiderSpawned
		upgradeablesCount = ownedUnitCount
	endif

	if ownedUnitCount > spawnedUnitCount
		int jUpgradeResultMap = factionScript.TryUpgradeUnits(unitIndexToTrain, upgradeablesCount, availableExpPoints)

		if jUpgradeResultMap != 0
			availableExpPoints = jMap.getFlt(jUpgradeResultMap, "RemainingExp")
			int jUpgradedUnitsArray = jMap.getObj(jUpgradeResultMap, "UpgradedUnits")
			
			int jSABUnitDatasArray = GetUnitDataHandler().jSABUnitDatasArray
			int jOldUnitMap = jArray.getObj(jSABUnitDatasArray, unitIndexToTrain)
			float oldUnitPower = jMap.getFlt(jOldUnitMap, "AutocalcStrength", 1.0)

			float autocalcPowerChange = 0.0

			; parse the upgraded units list, replacing the old units with the upgraded ones
			if jUpgradedUnitsArray != 0
				int i = jValue.count(jUpgradedUnitsArray)

				while i > 0
					i -= 1

					int jUpgradedUnitMap = jArray.getObj(jUpgradedUnitsArray, i)

					if jUpgradedUnitMap != 0
						int upgradedAmount = jMap.getInt(jUpgradedUnitMap, "NewUnitAmount")
						int newUnitIndex = jMap.getInt(jUpgradedUnitMap, "NewUnitIndex")

						; add units to the new index and remove from the old one
						AddUnitsOfType(newUnitIndex, upgradedAmount)
    					RemoveUnitsOfType(unitIndexToTrain, upgradedAmount)

					endif
					
				endwhile

			endif

			jValue.release(jUpgradeResultMap)
			JValue.zeroLifetime(jUpgradeResultMap)

			currentAutocalcPower += autocalcPowerChange
		endif

		
	endif

endFunction



; attempts to transfer some of our units (picked randomly) to the other container, respecting their maxOwnedUnitsAmount
Function TryTransferUnitsToAnotherContainer(SAB_TroopContainerScript otherContainer)
	; debug.Trace("troop container: try transfer units!")

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

	if unitIndexToTransfer <= -1
		return
	endif

	int ownedUnitCount = jIntMap.getInt(jOwnedUnitsMap, unitIndexToTransfer)
	int spawnableUnitCount = jIntMap.getInt(jSpawnOptionsMap, unitIndexToTransfer)
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

			int jUnitMap = jArray.getObj(GetUnitDataHandler().jSABUnitDatasArray, unitIndexToTransfer)
			float unitPower = jMap.getFlt(jUnitMap, "AutocalcStrength", 1.0)

			currentAutocalcPower -= unitAmountToTransfer * unitPower

			jIntMap.setInt(jSpawnOptionsMap, unitIndexToTransfer, spawnableUnitCount - unitAmountToTransfer)
			if spawnableUnitCount - unitAmountToTransfer <= 0
				jIntMap.removeKey(jSpawnOptionsMap, unitIndexToTransfer)
			endif

			; and add them to the other!
			otherContainer.AddUnitsOfType(unitIndexToTransfer, unitAmountToTransfer)

			; debug.Trace("transferred " + unitAmountToTransfer + " units of index " + unitIndexToTransfer)
		endif
	endif

endFunction

; returns a valid random unit index from our spawnableUnits list, or -1 if it fails for some reason (no units available to spawn, for example)
int Function GetUnitIndexToSpawn()

	int spawnOptionsCount = jIntMap.count(jSpawnOptionsMap)

	if spawnOptionsCount <= 0
		return -1
	endif

	return JIntMap.getNthKey(jSpawnOptionsMap, Utility.RandomInt(0, spawnOptionsCount - 1))

endfunction



; this should probably be overridden
ObjectReference Function GetMoveDestAfterSpawnForUnit()
	return GetReference()
EndFunction

; this should probably be overridden
ObjectReference Function GetSpawnPointForUnit()
	return GetReference()
EndFunction


int Function GetActualSpawnableUnitsCount()
	int i = jIntMap.count(jSpawnOptionsMap)
	int count = 0

	while i > 0
		i -= 1
		int unitIndex = jIntMap.getNthKey(jSpawnOptionsMap, i)
		int ownedUnitCount = jIntMap.getInt(jSpawnOptionsMap, unitIndex)
		
		count += ownedUnitCount

	endwhile

	return count
EndFunction

int Function GetActualTotalUnitsCount()
	int i = jIntMap.count(jOwnedUnitsMap)
	int count = 0

	while i > 0
		i -= 1
		int unitIndex = jIntMap.getNthKey(jOwnedUnitsMap, i)
		int ownedUnitCount = jIntMap.getInt(jOwnedUnitsMap, unitIndex)
		
		count += ownedUnitCount

	endwhile

	return count
EndFunction

int Function GetActualSpawnedUnitsCount()
	int i = jIntMap.count(jSpawnedUnitsMap)
	int count = 0

	while i > 0
		i -= 1
		int unitIndex = jIntMap.getNthKey(jSpawnedUnitsMap, i)
		int ownedUnitCount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
		
		count += ownedUnitCount

	endwhile

	return count
EndFunction

; attempts to spawn a group of units in one of our spawn points
Function SpawnUnitBatch()
	int maxBatchSize = 8
	int spawnedCount = 0

	ObjectReference spawnPoint = GetSpawnPointForUnit()
	ObjectReference moveDestAfterSpawn = GetMoveDestAfterSpawnForUnit()
	int spawnedsLimit = GetMaxSpawnedUnitsAmount()

	while spawnedCount < maxBatchSize && spawnedUnitsAmount < spawnedsLimit 
		int unitIndexToSpawn = GetUnitIndexToSpawn()

		if unitIndexToSpawn >= 0
			if SpawnUnitAtLocationWithDefaultFollowRank(unitIndexToSpawn, spawnPoint, moveDestAfterSpawn, false) == None
				; stop spawning, the spawn failed (maybe too many units of our fac are around already)
				spawnedCount = maxBatchSize
			endif
			spawnedCount += 1
		else 
			; stop spawning, we're out of spawnable units
			spawnedCount = maxBatchSize 
		endif

		; update the max spawneds amount, in case it has changed due to stuff like cmders entering combat
		spawnedsLimit = GetMaxSpawnedUnitsAmount()
		
	endwhile

	factionScript.DeployPendingUnits(moveDestAfterSpawn, IsOnAlert())
EndFunction

; attempts to spawn a group of units at a specific point
Function SpawnUnitBatchAtLocation(ObjectReference spawnPoint, ObjectReference moveDestAfterSpawn)
	int maxBatchSize = 8
	int spawnedCount = 0

	int spawnedsLimit = GetMaxSpawnedUnitsAmount()

	while spawnedCount < maxBatchSize && spawnedUnitsAmount < spawnedsLimit 
		int unitIndexToSpawn = GetUnitIndexToSpawn()

		if unitIndexToSpawn >= 0
			if SpawnUnitAtLocationWithDefaultFollowRank(unitIndexToSpawn, spawnPoint, moveDestAfterSpawn, false) == None
				; stop spawning, the spawn failed (too many of our fac around?)
				spawnedCount = maxBatchSize 
			endif
			spawnedCount += 1
		else 
			; stop spawning, we're out of spawnable units
			spawnedCount = maxBatchSize 
		endif

		; update the max spawneds amount, in case it has changed due to stuff like cmders entering combat
		spawnedsLimit = GetMaxSpawnedUnitsAmount()
		
	endwhile

	factionScript.DeployPendingUnits(moveDestAfterSpawn, IsOnAlert())
EndFunction

Function SpawnRandomUnitAtPos(ObjectReference spawnPoint, ObjectReference targetLocation)

	if spawnedUnitsAmount < GetMaxSpawnedUnitsAmount()
		int indexToSpawn = GetUnitIndexToSpawn()

		if indexToSpawn >= 0
			SpawnUnitAtLocationWithDefaultFollowRank(indexToSpawn, spawnPoint, targetLocation, true)
		endif
		
	endif

EndFunction

; Override this if your default follow rank shouldn't be -1 (-1 means the unit should sandbox. Other indexes should follow the respective cmders)
ReferenceAlias Function SpawnUnitAtLocationWithDefaultFollowRank(int unitIndex, ObjectReference spawnPoint, ObjectReference targetLocation, bool moveNow)
	return SpawnUnitAtLocation(unitIndex, spawnPoint, targetLocation, -1, IsOnAlert(), moveNow)
EndFunction

ReferenceAlias Function SpawnUnitAtLocation(int unitIndex, ObjectReference spawnPoint, ObjectReference targetLocation, int followRank, bool spawnAlerted, bool moveNow)
	ReferenceAlias spawnedUnit = factionScript.SpawnUnitForTroopContainer(self, unitIndex, spawnPoint, targetLocation, gameTimeOfLastSetup, followRank, moveNow)

	if spawnedUnit != None
		; add spawned unit index to spawneds list
		int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
		jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount + 1)

		; decrement spawnables amount
		int currentSpawnableAmount = jIntMap.getInt(jSpawnOptionsMap, unitIndex)
		jIntMap.setInt(jSpawnOptionsMap, unitIndex, currentSpawnableAmount - 1)

		if currentSpawnableAmount - 1 <= 0
			jIntMap.removeKey(jSpawnOptionsMap, unitIndex)
		endif

		spawnedUnitsAmount += 1

		; debug.Trace("unit of index " + unitIndex + " has spawned...")
		; debug.Trace("curspawnedamount of " + unitIndex + " is now " + (currentSpawnedAmount + 1))
		; debug.Trace("spawnedUnitsAmount is now " + spawnedUnitsAmount)

		; set unit to be alerted if container is on alert
		if (spawnAlerted)
			Actor unitActor = spawnedUnit.GetReference() as Actor
			unitActor.SetAlert(true)
		endif

		return spawnedUnit
	endif

	return None
EndFunction

Function CullUnitsIfAboveSpawnLimit()
	if spawnedUnitsAmount > GetMaxSpawnedUnitsAmount()
		; despawn one unit. run this more times to keep culling
		SAB_UnitScript ourUnit = factionScript.GetASpawnedUnitFromContainer(self)
		if ourUnit != None
			ourUnit.Despawn()
		endif
	endif
EndFunction


; removes the despawned unit from the spawnedUnits list and adds it back to the spawnables, so that it can spawn again later
Function OwnedUnitHasDespawned(int unitIndex, float timeOwnerWasSetup)

	; debug.Trace("unit of index " + unitIndex + " has despawned...")

	if gameTimeOfLastSetup != timeOwnerWasSetup
		; debug.Trace("unit owner setup time (" + timeOwnerWasSetup + ") does not match container's ("+ gameTimeOfLastSetup +")")
		return
	endif

	int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex) - 1
	jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount)

	; debug.Trace("curspawnedamount of " + unitIndex + " is now " + (currentSpawnedAmount))

	if currentSpawnedAmount <= 0
		jIntMap.removeKey(jSpawnedUnitsMap, unitIndex)
	endif

	; increment spawnables amount
	int currentSpawnableAmount = jIntMap.getInt(jSpawnOptionsMap, unitIndex)
	jIntMap.setInt(jSpawnOptionsMap, unitIndex, currentSpawnableAmount + 1)

	spawnedUnitsAmount -= 1

	; debug.Trace("spawnedUnitsAmount is now " + spawnedUnitsAmount)

EndFunction



; removes the dead unit from the ownedUnits and spawnedUnits lists
Function OwnedUnitHasDied(int unitIndex, float timeOwnerWasSetup)

	; debug.Trace("unit of index " + unitIndex + " has died...")

	if gameTimeOfLastSetup != timeOwnerWasSetup
		; debug.Trace("unit owner setup time (" + timeOwnerWasSetup + ") does not match container's ("+ gameTimeOfLastSetup +")")
		return
	endif

	int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex) - 1
	jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount)

	; debug.Trace("curspawnedamount of " + unitIndex + " is now " + currentSpawnedAmount)

	if currentSpawnedAmount <= 0
		jIntMap.removeKey(jSpawnedUnitsMap, unitIndex)
	endif

	spawnedUnitsAmount -= 1
	totalOwnedUnitsAmount -= 1

	int jUnitMap = jArray.getObj(GetUnitDataHandler().jSABUnitDatasArray, unitIndex)
	float unitPower = jMap.getFlt(jUnitMap, "AutocalcStrength", 1.0)

	currentAutocalcPower -= unitPower

	int currentStoredAmount = jIntMap.getInt(jOwnedUnitsMap, unitIndex)
	jIntMap.setInt(jOwnedUnitsMap, unitIndex, currentStoredAmount - 1)

	; debug.Trace("currentStoredAmount of " + unitIndex + " is now " + (currentStoredAmount - 1))

	if currentStoredAmount - 1 <= 0
		jIntMap.removeKey(jOwnedUnitsMap, unitIndex)
	endif

	; debug.Trace("spawnedUnitsAmount is now " + spawnedUnitsAmount)
	; debug.Trace("totalOwnedUnitsAmount is now " + totalOwnedUnitsAmount)
EndFunction



; makes our units "fight" the enemyContainer's units, and calculates the diplomatic effect as well.
; the result is decided based on the units' autocalcpower values
Function DoAutocalcBattle(SAB_TroopContainerScript enemyContainer)

	; debug.Trace("autocalc fight start!")
	SAB_UnitDataHandler unitDataHandler = GetUnitDataHandler()

	; we want there to be a high chance of the fight not being instantly resolved
	; float ourPower = unitDataHandler.GetTotalAutocalcPowerFromArmy(jOwnedUnitsMap) * Utility.RandomFloat(0.125, 0.5)
	; float theirPower = unitDataHandler.GetTotalAutocalcPowerFromArmy(enemyContainer.jOwnedUnitsMap) * Utility.RandomFloat(0.125, 0.5)

	if enemyContainer.factionScript
		factionScript.DiplomacyDataHandler.GlobalReactToAutocalcBattle(factionScript.GetFactionIndex(), enemyContainer.factionScript.GetFactionIndex())
	endif

	float ourPower = currentAutocalcPower * Utility.RandomFloat(0.125, 0.5)
	float theirPower = enemyContainer.currentAutocalcPower * Utility.RandomFloat(0.125, 0.5)

	TakeAutocalcDamage(theirPower)
	enemyContainer.TakeAutocalcDamage(ourPower)

	if enemyContainer.totalOwnedUnitsAmount <= 0
		enemyContainer.HandleAutocalcDefeat()
	endif

	if totalOwnedUnitsAmount <= 0
		HandleAutocalcDefeat()
	endif
	; debug.Trace("autocalc fight end!")

EndFunction


; removes some of our units based on the power of the enemy
Function TakeAutocalcDamage(float enemyPower, int jSABUnitDatasArrayCached = -1)
	
	if factionScript == None
		return
	endif

	int i = jIntMap.count(jOwnedUnitsMap)

	if jSABUnitDatasArrayCached == -1
		jSABUnitDatasArrayCached = GetUnitDataHandler().jSABUnitDatasArray
	endif

	while enemyPower > 0.0 && totalOwnedUnitsAmount > 0
		i -= 1
		int unitIndex = jIntMap.getNthKey(jOwnedUnitsMap, i)
		int ownedUnitCount = jIntMap.getInt(jOwnedUnitsMap, unitIndex)
		int jUnitMap = jArray.getObj(jSABUnitDatasArrayCached, unitIndex)
		float unitPower = jMap.getFlt(jUnitMap, "AutocalcStrength", 1.0)
		; get the amount of units we'd have to lose to compensate the enemy power...
		; then clamp the units lost to the amount we actually have, and find out how much power that takes care of
		int unitsLost = Math.Ceiling(enemyPower / unitPower)

		if unitsLost > ownedUnitCount
			unitsLost = ownedUnitCount
		endif

		; lose the units!
		jIntMap.setInt(jOwnedUnitsMap, unitIndex, ownedUnitCount - unitsLost)
		if ownedUnitCount - unitsLost <= 0
			jIntMap.removeKey(jOwnedUnitsMap, unitIndex)
		endif

		int curSpawnableAmount = jIntMap.getInt(jSpawnOptionsMap, unitIndex)
		JIntMap.setInt(jSpawnOptionsMap, unitIndex, curSpawnableAmount - unitsLost)
		if curSpawnableAmount - unitsLost <= 0
			jIntMap.removeKey(jSpawnOptionsMap, unitIndex)
		endif

		currentAutocalcPower -= unitsLost * unitPower
		totalOwnedUnitsAmount -= unitsLost

		enemyPower -= (unitsLost * unitPower)

	endwhile

EndFunction



; this container has been completely defeated in an autocalc battle and has no units left!
; this function should do whatever happens in that case
Function HandleAutocalcDefeat()
	Debug.Trace("[SAB] HandleAutocalcDefeat: Override me!")
EndFunction

; override this!
; if true, units spawning from this container should spawn ready for combat
bool Function IsOnAlert()
	return false
endfunction

; true if player belongs to same faction, or a faction that's friendly/allied to the player.
; false if enemy or neutral
bool Function IsAllyOfPlayer()
	if factionScript != None
		if factionScript.IsPlayerPartOfThisFaction() || factionScript.DiplomacyDataHandler.IsFactionAllyOfPlayer(factionScript.GetFactionIndex())
			return true
		endif
	endif

	return false
endfunction

; returns the maximum amount of units this container should be able to own
int Function GetMaxOwnedUnitsAmount()
	return 1
endfunction

; returns the maximum amount of units this container can have spawned in the world at the same time
int Function GetMaxSpawnedUnitsAmount()
	return 1
EndFunction

; returns -1 if neutral/no fac
int Function GetOwnerFactionIndex()
	if factionScript != None
		return factionScript.GetFactionIndex()
	endif

	return -1
EndFunction

; returns the owner faction's name, or "neutral"
string Function GetOwnerFactionName()
	string ownerFacName = "$sab_mcm_locationedit_ownership_option_neutral"
	if factionScript != None
		ownerFacName = factionScript.GetFactionName()
	endif

	return ownerFacName
EndFunction
