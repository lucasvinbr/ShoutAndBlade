Scriptname SAB_PlayerCommanderScript extends SAB_TroopContainerScript  

; reference to the location we're fighting against or trying to take over.
; this should only have a real value if we're close enough to this location
SAB_LocationScript Property TargetLocationScript Auto Hidden

SAB_PlayerDataHandler Property PlayerDataHandler Auto

SAB_CrowdReducer Property CrowdReducer Auto

ObjectReference Property TroopSpawnPoint Auto

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	TargetLocationScript = None
	if jOwnedUnitsMap == 0
		parent.Setup(factionScriptRef, curGameTime)
	else 
		; just update player's faction if this script was already set up before
		factionScript = factionScriptRef
	endif
	
EndFunction

; sets isNearby and enables or disables closeBy updates
Function ToggleNearbyUpdates(bool updatesEnabled)
	
	; debug.Trace("commander: toggleNearbyUpdates " + updatesEnabled)
	; debug.Trace("commander: indexInCloseByUpdater " + indexInCloseByUpdater)
	if updatesEnabled
		isNearby = true
		if indexInCloseByUpdater == -1
			indexInCloseByUpdater = CloseByUpdater.CmderUpdater.RegisterAliasForUpdates(self)
			CrowdReducer.NumNearbyCmders += 1
			debug.Trace("player: began closebyupdating!")
			debug.Trace("player: nearby cmders: " + CrowdReducer.NumNearbyCmders)
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater != -1
			CloseByUpdater.CmderUpdater.UnregisterAliasFromUpdates(indexInCloseByUpdater)
			indexInCloseByUpdater = -1
			CrowdReducer.NumNearbyCmders -= 1
			debug.Trace("player: stopped closebyupdating!")
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
	endif

	;debug.Trace("game time updating commander (pre check)!")
	float expAwardInterval = JDB.solveFlt(".ShoutAndBlade.playerOptions.expAwardInterval", 0.08)
	if curGameTime - gameTimeOfLastExpAward >= expAwardInterval
		int numAwardsObtained = ((curGameTime - gameTimeOfLastExpAward) / expAwardInterval) as int
		availableExpPoints += playerActor.GetLevel() * JDB.solveFlt(".ShoutAndBlade.playerOptions.expAwardPerPlayerLevel", 25.0) * numAwardsObtained
		gameTimeOfLastExpAward = curGameTime
	endif
	
	; TODO auto-upgrade check

	return true
endfunction




ObjectReference Function GetSpawnLocationForUnit()
	ObjectReference spawnLocation = TroopSpawnPoint

	if TroopSpawnPoint.GetDistance(playerActor) > 1500.0
		spawnLocation = playerActor
	endif

	return spawnLocation
EndFunction


ReferenceAlias Function SpawnUnitAtLocation(int unitIndex, ObjectReference targetLocation)
	ReferenceAlias spawnedUnit = PlayerDataHandler.SpawnPlayerUnit(unitIndex, targetLocation, gameTimeOfLastSetup)

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

		return spawnedUnit
	endif

	return None
EndFunction


; like spawnRandomUnitAtPos, but spawns are limited by the max besieging units instead
Function SpawnBesiegingUnitAtPos(ObjectReference targetLocation)

	if spawnedUnitsAmount < GetMaxBesiegingUnitsAmount()
		int indexToSpawn = GetUnitIndexToSpawn()

		if indexToSpawn >= 0
			SpawnUnitAtLocation(indexToSpawn, targetLocation)
		endif
		
	endif

EndFunction

Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	if aeCombatState == 1 || aeCombatState == 2 ; engaging or searching
		; debug.Trace("player: started combat!")

		; if the current spawn is too far away,
		; update the spawn point to where the combat started
		
		; if TroopSpawnPoint.GetDistance(playerActor) > 4000.0
		; 	TroopSpawnPoint.MoveTo(playerActor)
		; endif
		ToggleNearbyUpdates(true)

	else
		ToggleNearbyUpdates(false)
	endif
EndEvent

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
		SAB_UnitScript unitToRemove = PlayerDataHandler.GetSpawnedUnitOfType(unitTypeIndex)

		if unitToRemove != None
			unitToRemove.DespawnAndDontReturnToContainer()
		endif

		amountToRemove -= 1 ; assume we removed successfully, or else we may keep checking forever
	endwhile
EndFunction

int Function GetMaxOwnedUnitsAmount()
	return JDB.solveInt(".ShoutAndBlade.playerOptions.maxOwnedUnits", 30)
EndFunction

int Function GetMaxSpawnedUnitsAmount()
	int nearbyCmders = CrowdReducer.NumNearbyCmders

	if nearbyCmders >= JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5)
		return JDB.solveInt(".ShoutAndBlade.cmderOptions.combatSpawnsDividend", 20) / nearbyCmders
	endif

	return JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsInCombat", 8)
EndFunction

int Function GetMaxBesiegingUnitsAmount()
	int nearbyCmders = CrowdReducer.NumNearbyCmders

	if nearbyCmders >= JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5)
		return JDB.solveInt(".ShoutAndBlade.cmderOptions.combatSpawnsDividend", 20) / nearbyCmders
	endif

	return JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsWhenBesieging", 8)
EndFunction

