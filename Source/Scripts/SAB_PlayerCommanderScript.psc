Scriptname SAB_PlayerCommanderScript extends SAB_TroopContainerScript  

; reference to the location we're fighting against or trying to take over.
; this should only have a real value if we're close enough to this location
SAB_LocationScript Property TargetLocationScript Auto Hidden

SAB_PlayerDataHandler Property PlayerDataHandler Auto

SAB_CrowdReducer Property CrowdReducer Auto

ObjectReference Property TroopSpawnPoint Auto

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	TargetLocationScript = None
	parent.Setup(factionScriptRef, curGameTime)
	availableExpPoints = JDB.solveFlt(".ShoutAndBlade.cmderOptions.initialExpPoints", 600.0)
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
	float expAwardInterval = JDB.solveFlt(".ShoutAndBlade.cmderOptions.expAwardInterval", 0.08)
	if curGameTime - gameTimeOfLastExpAward >= expAwardInterval
		int numAwardsObtained = ((curGameTime - gameTimeOfLastExpAward) / expAwardInterval) as int
		availableExpPoints += JDB.solveFlt(".ShoutAndBlade.cmderOptions.awardedXpPerInterval", 500.0) * numAwardsObtained
		gameTimeOfLastExpAward = curGameTime
	endif
	
	; TODO auto-upgrade check

	return true
endfunction




ObjectReference Function GetSpawnLocationForUnit()
	ObjectReference spawnLocation = playerActor

	; TODO let player set a spawn elsewhere

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
		debug.Trace("player: started combat!")

		; if the current spawn is too far away,
		; update the spawn point to where the combat started
		
		if TroopSpawnPoint.GetDistance(playerActor) > 4000.0
			TroopSpawnPoint.MoveTo(playerActor)
		endif

	endif
EndEvent


int Function GetMaxOwnedUnitsAmount()
	return JDB.solveInt(".ShoutAndBlade.cmderOptions.maxOwnedUnits", 30)
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

