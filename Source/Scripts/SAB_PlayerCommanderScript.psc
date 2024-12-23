Scriptname SAB_PlayerCommanderScript extends SAB_TroopContainerScript  

; reference to the location we're fighting against or trying to take over.
; this should only have a real value if we're close enough to this location
SAB_LocationScript Property TargetLocationScript Auto Hidden

SAB_PlayerDataHandler Property PlayerDataHandler Auto

SAB_CrowdReducer Property CrowdReducer Auto

ObjectReference Property TroopSpawnPoint Auto

float Property gameTimeOfLastRecruiterRefresh Auto Hidden

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	TargetLocationScript = None
	if jOwnedUnitsMap == 0
		parent.Setup(factionScriptRef, curGameTime)
	else 
		; just update player's faction if this script was already set up before
		factionScript = factionScriptRef
	endif
	gameTimeOfLastRecruiterRefresh = 0.0
EndFunction

SAB_UnitDataHandler Function GetUnitDataHandler()
	return PlayerDataHandler.SpawnerScript.UnitDataHandler
EndFunction

; sets isNearby and enables or disables closeBy updates
Function ToggleNearbyUpdates(bool updatesEnabled)
	
	; debug.Trace("commander: toggleNearbyUpdates " + updatesEnabled)
	; debug.Trace("commander: indexInCloseByUpdater " + indexInCloseByUpdater)
	if updatesEnabled
		isNearby = true
		if indexInCloseByUpdater == -1
			indexInCloseByUpdater = -2 ; an attempt to prevent this from running more than once
			indexInCloseByUpdater = CloseByUpdater.CmderUpdater.RegisterAliasForUpdates(self, indexInCloseByUpdater)
			if indexInCloseByUpdater > -1
				; CrowdReducer.NearbyCmdersList.AddForm(GetReference())
				debug.Trace("player: began closebyupdating!")
				; debug.Trace("player: nearby cmders: " + CrowdReducer.NumNearbyCmders)
			endif
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater > -1
			int indexToUnregister = indexInCloseByUpdater
			indexInCloseByUpdater = -1
			CloseByUpdater.CmderUpdater.UnregisterAliasFromUpdates(indexToUnregister)
			; CrowdReducer.RemoveCmderFromNearbyList(GetReference(), playerActor)
			debug.Trace("player: stopped closebyupdating!")
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
	endif

	float recruiterInterval = JDB.solveFlt(".ShoutAndBlade.playerOptions.recruiterInterval", 0.25)

	if recruiterInterval > 0 && curGameTime - gameTimeOfLastRecruiterRefresh >= recruiterInterval
		int numRefreshes = ((curGameTime - gameTimeOfLastRecruiterRefresh) / recruiterInterval) as int

		while numRefreshes > 0
			numRefreshes -= 1
			PlayerDataHandler.RemoveOldestRecruiterFromRecentList()
		endwhile

		gameTimeOfLastRecruiterRefresh = curGameTime
	endif

	;debug.Trace("game time updating commander (pre check)!")
	float expAwardInterval = JDB.solveFlt(".ShoutAndBlade.playerOptions.expAwardInterval", 0.08)
	if expAwardInterval > 0 && curGameTime - gameTimeOfLastExpAward >= expAwardInterval
		; only award xp if player has at least one unit
		if totalOwnedUnitsAmount > 0
			int numAwardsObtained = ((curGameTime - gameTimeOfLastExpAward) / expAwardInterval) as int
			availableExpPoints += playerActor.GetLevel() * JDB.solveFlt(".ShoutAndBlade.playerOptions.expAwardPerPlayerLevel", 25.0) * numAwardsObtained
		endif
		gameTimeOfLastExpAward = curGameTime
	endif
	
	; TODO auto-upgrade check

	isUpdating = false
	return true
endfunction




ObjectReference Function GetSpawnLocationForUnit()
	ObjectReference spawnLocation = TroopSpawnPoint

	if TroopSpawnPoint.GetDistance(playerActor) > 1500.0
		spawnLocation = playerActor
	endif

	return spawnLocation
EndFunction

ReferenceAlias Function SpawnUnitAtLocationWithDefaultFollowRank(int unitIndex, ObjectReference targetLocation)
	return SpawnUnitAtLocation(unitIndex, targetLocation, 0, IsOnAlert())
EndFunction

ReferenceAlias Function SpawnUnitAtLocation(int unitIndex, ObjectReference targetLocation, int followRank, bool spawnAlerted)
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

		(spawnedUnit.GetReference() as Actor).SetPlayerTeammate(true, true)

		spawnedUnitsAmount += 1

		; set unit to be alerted if cmder is dead or in combat
		if (spawnAlerted)
			Actor unitActor = spawnedUnit.GetReference() as Actor
			unitActor.SetAlert(true)
		endif

		return spawnedUnit
	endif

	return None
EndFunction


; like spawnRandomUnitAtPos, but spawns are limited by the max besieging units instead
Function SpawnBesiegingUnitAtPos(ObjectReference targetLocation)

	if spawnedUnitsAmount < GetMaxBesiegingUnitsAmount()
		int indexToSpawn = GetUnitIndexToSpawn()

		if indexToSpawn >= 0
			SpawnUnitAtLocationWithDefaultFollowRank(indexToSpawn, targetLocation)
		endif
		
	endif

EndFunction

Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	; if aeCombatState == 1 || aeCombatState == 2 ; engaging or searching
	; 	; debug.Trace("player: started combat!")

	; 	; if the current spawn is too far away,
	; 	; update the spawn point to where the combat started
		
	; 	; if TroopSpawnPoint.GetDistance(playerActor) > 4000.0
	; 	; 	TroopSpawnPoint.MoveTo(playerActor)
	; 	; endif
	; 	ToggleNearbyUpdates(true)

	; ; else
	; ; 	ToggleNearbyUpdates(false)
	; endif
EndEvent

; all units currently deployed should disappear, going back to "storage"
Function DespawnAllUnits()

	; keep despawning the first entry of the spawneds map, until there are no more entries in it... 
	; or until we change our mind about despawning
	int spawnedUnitTypesCount = jIntMap.count(jSpawnedUnitsMap)
	int unitTypeIndexToDespawn = -1

	while spawnedUnitTypesCount > 0 && !isNearby
		unitTypeIndexToDespawn = JIntMap.nextKey(jSpawnedUnitsMap, -1, -1)
		
		int spawnedsCount = JIntMap.getInt(jSpawnedUnitsMap, unitTypeIndexToDespawn)

		; search for them in the spawned units list and despawn them
		while spawnedsCount > 0
			SAB_UnitScript unitToRemove = PlayerDataHandler.GetSpawnedUnitOfType(unitTypeIndexToDespawn)

			if unitToRemove != None
				unitToRemove.Despawn()
			endif

			spawnedsCount -= 1 ; assume we removed successfully, or else we may keep checking forever
		endwhile

		spawnedUnitTypesCount -= 1 ; we're assuming all units of this type have been removed, just to not check too much
	endwhile

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

		int jUnitMap = jArray.getObj(PlayerDataHandler.SpawnerScript.UnitDataHandler.jSABUnitDatasArray, unitTypeIndex)
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
		SAB_UnitScript unitToRemove = PlayerDataHandler.GetSpawnedUnitOfType(unitTypeIndex)

		if unitToRemove != None
			unitToRemove.DespawnAndDontReturnToContainer()
		endif

		amountToRemove -= 1 ; assume we removed successfully, or else we may keep checking forever
	endwhile
EndFunction

int Function GetMaxOwnedUnitsAmount()
	return Math.Floor(JDB.solveInt(".ShoutAndBlade.playerOptions.baseMaxOwnedUnits", 50) + \
		JDB.solveFlt(".ShoutAndBlade.playerOptions.bonusMaxOwnedUnitsPerLevel", 5) * playerActor.GetLevel())
EndFunction

int Function GetMaxSpawnedUnitsAmount()
	int nearbyCmders = CloseByUpdater.CmderUpdater.numActives

	int baseCombatMax = JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsInCombat", 8)

	if nearbyCmders >= JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5)
		
		int limitedMax = JDB.solveInt(".ShoutAndBlade.cmderOptions.combatSpawnsDividend", 20) / nearbyCmders

		if limitedMax < baseCombatMax
			return limitedMax
		endif
	endif

	return baseCombatMax
EndFunction

int Function GetMaxBesiegingUnitsAmount()
	return GetMaxSpawnedUnitsAmount()
EndFunction

; if true, units spawning from this container should spawn ready for combat
bool Function IsOnAlert()
	return playerActor.IsInCombat()
endfunction