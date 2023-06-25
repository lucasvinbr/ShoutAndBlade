Scriptname SAB_CommanderScript extends SAB_TroopContainerScript  

; cached refs for not fetching all the time
Actor meActor

int Property CmderFollowFactionRank Auto
{ the rank in the "cmderFollowerFaction" referring to this commander. Units in this rank should follow this cmder }

string Property CmderDestinationType Auto
{ can be "A", "B" or "C". Defines which of the 3 faction destinations this cmder will always go to }

Faction Property SAB_CmderConfidenceFaction Auto
{ used to help the commander know when it's best to flee instead of fight }

; reference to the location we're fighting against or trying to take over.
; this should only have a real value if we're close enough to this location
SAB_LocationScript Property TargetLocationScript Auto Hidden

SAB_CrowdReducer Property CrowdReducer Auto

float gameTimeOfLastDestCheck = 0.0

int indexInLocNearbiesArray = -1

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	meActor = GetReference() as Actor

	if TargetLocationScript != None
		; clear previous cmder's linked loc data
		if indexInLocNearbiesArray != -1 && TargetLocationScript.NearbyCommanders[indexInLocNearbiesArray] == self
			TargetLocationScript.UnregisterCommanderFromNearbyList(indexInLocNearbiesArray)
		endif
	endif

	TargetLocationScript = None
	indexInLocNearbiesArray = -1
	parent.Setup(factionScriptRef, curGameTime)
	availableExpPoints = JDB.solveFlt(".ShoutAndBlade.cmderOptions.initialExpPoints", 600.0)
	UpdateConfidenceLevel()
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
			; if indexInCloseByUpdater > -1
			; 	CrowdReducer.NearbyCmdersList.AddForm(GetReference())
			; endif
			; debug.Trace("commander: began closebyupdating!")
			; debug.Trace("commander: nearby cmders: " + CrowdReducer.NumNearbyCmders)
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater > -1
			int indexToUnregister = indexInCloseByUpdater
			indexInCloseByUpdater = -1
			CloseByUpdater.CmderUpdater.UnregisterAliasFromUpdates(indexToUnregister)
			; CrowdReducer.RemoveCmderFromNearbyList(GetReference(), playerActor)
			; debug.Trace("commander: stopped closebyupdating!")
		endif
	endif

EndFunction


bool function RunCloseByUpdate()
	parent.RunCloseByUpdate()

	; some cmders seem to slip by our nearby checks, so here's another one
	if !isNearby
		;debug.Trace("nearby updating a cmder with isNearby set to false!")
		; if meActor
		; 	float playerDistance = playerActor.GetDistance(meActor)
		; 	if playerDistance && playerDistance > 10000
		; 		debug.Trace("nearby updating a cmder with isNearby set to false AND that is far away!")
		; 	endif
		; endif
		ToggleNearbyUpdates(false)
	endif
	return true	
endfunction


bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)

	if updateIndex == 1
		; testing running the big update on nearby updates as well
		RunCloseByUpdate()
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
	
	if !meActor
		debug.Trace("WARNING: attempted to update commander which had an invalid (maybe None?) reference!")
		ClearCmderData()
		return true
	endif

	float playerDistance = playerActor.GetDistance(meActor)

	if playerDistance
		if playerDistance > GetIsNearbyDistance()
			ToggleNearbyUpdates(false)
		else
			ToggleNearbyUpdates(true)
		endif
	endif

	if !meActor.IsDead()
		if !meActor.IsInCombat()
			;debug.Trace("game time updating commander!")

			if curGameTime - gameTimeOfLastUnitUpgrade >= JDB.solveFlt(".ShoutAndBlade.cmderOptions.unitMaintenanceInterval", 0.06)
				gameTimeOfLastUnitUpgrade = curGameTime

				; if we have enough units, upgrade. If we don't, recruit some more
				if totalOwnedUnitsAmount >= GetMaxOwnedUnitsAmount() * 0.7
					TryUpgradeUnits()
				else 
					TryRecruitUnits()
				endif
			endif
			
		endif
	else 
		if ClearAliasIfOutOfTroops()
			CrowdReducer.AddDeadBody(meActor)
			meActor = None
			return true
		else
			; we check against the current "nearby" distance here,
			; to be able to despawn less relevant dead cmders
			if playerDistance && playerDistance > GetIsNearbyDistance()
				; we're dead and despawning but still had troops!
				; give the faction some gold to compensate a little
				factionScript.GetGoldFromDespawningCommander(jOwnedUnitsMap)
				ClearCmderData()
				meActor.Disable()
				meActor.Delete()
				meActor = None
				return true
			endif
		endif
	endif


	UpdateConfidenceLevel()
	meActor.EvaluatePackage()
	; both living and dead cmders can fight for locations

	if TargetLocationScript != None
		bool cmderCanAutocalc = TargetLocationScript.IsReferenceCloseEnoughForAutocalc(meActor)

		if !cmderCanAutocalc
			; we're too far away from the target loc, disengage
			UnregisterAsNearLocation(TargetLocationScript)
			TargetLocationScript = None
		else
			if indexInLocNearbiesArray == -1
				RegisterAsNearLocation(TargetLocationScript)
			endif

			if TargetLocationScript.factionScript == factionScript
				; attempt to reinforce the location if it's undermanned
				if TargetLocationScript.totalOwnedUnitsAmount < TargetLocationScript.GetMaxOwnedUnitsAmount()
					; mark ourselves as interacting so that we can be attacked instead of the location
					TryTransferUnitsToAnotherContainer(TargetLocationScript)
				endif
			else
				SAB_FactionScript locFaction = TargetLocationScript.factionScript
				SAB_DiplomacyDataHandler diploHandler = factionScript.DiplomacyDataHandler
				int ourFacIndex = factionScript.GetFactionIndex()
				bool locIsHostileToUs = !diploHandler.AreFactionsInGoodStanding(factionScript, locFaction)

				if locIsHostileToUs
					TargetLocationScript.BeNotifiedOfNearbyHostileCmder()

					if locFaction != None && diploHandler.AreFactionsNeutral(ourFacIndex, locFaction.GetFactionIndex())
						; don't just stand there, kill them!
						diploHandler.GlobalReactToWarDeclaration \
							(ourFacIndex, locFaction.GetFactionIndex())

						Debug.Trace(factionScript.GetFactionName() + " has declared war against the " + locFaction.GetFactionName())
						Debug.Notification(factionScript.GetFactionName() + " has declared war against the " + locFaction.GetFactionName())
					endif
				endif

				if !isNearby
					; if the player is far away, do autocalc fights!
					; pick fights with the other nearby cmders!
					int i = TargetLocationScript.GetTopNearbyCmderIndex()
					While (i >= 0)
						SAB_CommanderScript otherCmder = TargetLocationScript.NearbyCommanders[i]
						If otherCmder != None && otherCmder != self
							if !diploHandler.AreFactionsInGoodStanding(factionScript, otherCmder.factionScript)
								DoAutocalcBattle(otherCmder)
								return true
							endif
						EndIf

						i -= 1
					EndWhile

					; we couldn't find an enemy cmder to fight. Maybe the loc's garrison then?
					if locFaction != None
						; do an autocalc fight against the location's units!
						if TargetLocationScript.CanAutocalcNow() && locIsHostileToUs
							diploHandler.GlobalReactToLocationAttacked(ourFacIndex, locFaction.GetFactionIndex())
							DoAutocalcBattle(TargetLocationScript)
							return true
						endif
					else
						; the location is neutral! Let's take it
						TargetLocationScript.BeTakenByFaction(factionScript, true)
						TryTransferUnitsToAnotherContainer(TargetLocationScript)
					endif
				else
					; if the player is nearby but the location is empty, take it
					if locFaction == None || \
						(locIsHostileToUs && TargetLocationScript.totalOwnedUnitsAmount <= 0)

						; TargetLocationScript.InteractingCommander = self
						TargetLocationScript.BeTakenByFaction(factionScript, true)
						TryTransferUnitsToAnotherContainer(TargetLocationScript)
					else
						; if the player is nearby, the location is occupied and we are neutral to the owners... it's time to stop being neutral
						if locFaction != None && \
							diploHandler.AreFactionsNeutral(ourFacIndex, locFaction.GetFactionIndex())
							
							diploHandler.GlobalReactToWarDeclaration \
								(ourFacIndex, locFaction.GetFactionIndex())

							Debug.Trace(factionScript.GetFactionName() + " has declared war against the " + locFaction.GetFactionName())
							Debug.Notification(factionScript.GetFactionName() + " has declared war against the " + locFaction.GetFactionName())
						endif
					endif
				endif
			endif
		endif
	else
		if curGameTime - gameTimeOfLastDestCheck > JDB.solveFlt(".ShoutAndBlade.cmderOptions.destCheckInterval", 0.01)
			gameTimeOfLastDestCheck = curGameTime
			if !factionScript.ValidateCmderReachedDestination(self, CmderDestinationType)
				if isNearby
					; the cmder is near the player.
					; we should handle the case where the cmder's faction has just changed targets, 
					; but the cmder had visibly arrived at the previous one
					SAB_LocationScript nearbyLocScript = factionScript.DiplomacyDataHandler.PlayerDataHandler.NearbyLocation

					if nearbyLocScript
						if nearbyLocScript.IsReferenceCloseEnoughForAutocalc(meActor)
							RegisterAsNearLocation(nearbyLocScript)
						endif
					endif
				endif
			endif
		endif
	endif

	return true
endfunction

; returns the cmder's index in the loc's nearby cmders list. Also sets targetLocation and index in loc nearbies if we successfully register
int Function RegisterAsNearLocation(SAB_LocationScript loc)
	if TargetLocationScript == None
		if indexInLocNearbiesArray != -1
			indexInLocNearbiesArray = -1
		endif
	Else
		if TargetLocationScript != loc
			UnregisterAsNearLocation(TargetLocationScript)
			TargetLocationScript = None
		endif
	endif

	int myIndexInLoc = loc.RegisterCommanderInNearbyList(self, indexInLocNearbiesArray)

	if myIndexInLoc != -1
		TargetLocationScript = loc
		indexInLocNearbiesArray = myIndexInLoc
	else
		; try again later! The loc is full
	endif

	return myIndexInLoc
EndFunction

; sets our index in loc nearbies back to -1
Function UnregisterAsNearLocation(SAB_LocationScript loc)
	if TargetLocationScript == None
		return
	endif

	if loc.NearbyCommanders[indexInLocNearbiesArray] == self
		loc.UnregisterCommanderFromNearbyList(indexInLocNearbiesArray)
	endif
	
	indexInLocNearbiesArray = -1
EndFunction


ObjectReference Function GetSpawnLocationForUnit()
	ObjectReference spawnLocation = meActor

	if meActor.IsInCombat()
		spawnLocation = Game.FindRandomReferenceOfAnyTypeInListFromRef\
			(factionScript.LocationDataHandler.Locations[0].SAB_ObjectsToUseAsSpawnsList, meActor, 1500)

		if spawnLocation == None
			spawnLocation = factionScript.UnitSpawnPoint.GetReference()
		endif
	endif
	
	return spawnLocation
EndFunction


ReferenceAlias Function SpawnUnitAtLocationWithDefaultFollowRank(int unitIndex, ObjectReference targetLocation)
	return SpawnUnitAtLocation(unitIndex, targetLocation, CmderFollowFactionRank)
EndFunction

ReferenceAlias Function SpawnUnitAtLocation(int unitIndex, ObjectReference targetLocation, int followRank)
	ReferenceAlias spawnedUnit = factionScript.SpawnUnitForTroopContainer(self, unitIndex, targetLocation, gameTimeOfLastSetup, followRank)

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
Function SpawnBesiegingUnitAtPos(ObjectReference targetLocation, int followRank)

	if spawnedUnitsAmount < GetMaxBesiegingUnitsAmount()
		int indexToSpawn = GetUnitIndexToSpawn()

		if indexToSpawn >= 0
			SpawnUnitAtLocation(indexToSpawn, targetLocation, followRank)
		endif
		
	endif

EndFunction

; like SpawnUnitBatchAtLocation, but spawns are limited by the max besieging units instead, and may not follow the cmder
Function SpawnBesiegingUnitBatchAtLocation(ObjectReference spawnLocation, int followRank)
	int maxBatchSize = 8
	int spawnedCount = 0

	int spawnedsLimit = GetMaxBesiegingUnitsAmount()

	while spawnedCount < maxBatchSize && spawnedUnitsAmount < spawnedsLimit 
		int unitIndexToSpawn = GetUnitIndexToSpawn()

		if unitIndexToSpawn >= 0
			SpawnUnitAtLocation(unitIndexToSpawn, spawnLocation, followRank)
			spawnedCount += 1
		else 
			; stop spawning, we're out of spawnable units
			spawnedCount = maxBatchSize 
		endif

		; update the max spawneds amount, in case it has changed due to stuff like cmders entering combat
		spawnedsLimit = GetMaxBesiegingUnitsAmount()
		
	endwhile
EndFunction

; sets the "confidence faction" rank for this cmder. The higher the more confidence
Function UpdateConfidenceLevel()
	if !meActor
		return
	endif

	
	if currentAutocalcPower > JDB.solveFlt(".ShoutAndBlade.cmderOptions.confidentPower", 45.0)
		meActor.SetFactionRank(SAB_CmderConfidenceFaction, 1)
	else
		meActor.SetFactionRank(SAB_CmderConfidenceFaction, 0)
	endif

EndFunction


Event OnAttachedToCell()
	if meActor && !isNearby
		ToggleNearbyUpdates(true)
	endif
EndEvent

Event OnCellAttach()
	if meActor && !isNearby
		ToggleNearbyUpdates(true)
	endif
EndEvent

Event OnCellDetach()
	if isNearby
		ToggleNearbyUpdates(false)
	endif
EndEvent

Event OnDetachedFromCell()
	if isNearby
		ToggleNearbyUpdates(false)
	endif
EndEvent

Event OnPackageEnd(Package akOldPackage)
	; this is kind of reliable, but the cmder has to ge to the exact point, so we should probably run other, more "relaxed", checks
	factionScript.ValidateCmderReachedDestination(self, CmderDestinationType)
EndEvent

Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	if aeCombatState == 1 || aeCombatState == 2 ; engaging or searching
		; debug.Trace("commander: started combat!")

		; if the current spawn is too far away,
		; update the faction's unit spawn point to where this cmder started combat
		ObjectReference unitSpawn = factionScript.UnitSpawnPoint.GetReference()
		if unitSpawn.GetDistance(meActor) > 800.0
			unitSpawn.MoveTo(meActor)
		endif

		float playerDistance = playerActor.GetDistance(meActor)
		if playerDistance && playerDistance <= GetIsNearbyDistance()
			ToggleNearbyUpdates(true)
		endif
	endif
EndEvent

event OnDeath(Actor akKiller)	
	; debug.Trace("commander: dead!")

	if akKiller == playerActor
		debug.Trace("player killed a cmder!")
		factionScript.DiplomacyDataHandler.GlobalReactToPlayerKillingCmder(factionScript.GetFactionIndex())
	endif

	if ClearAliasIfOutOfTroops()
		CrowdReducer.AddDeadBody(meActor)
		meActor = None
	endif
endEvent

Function OwnedUnitHasDied(int unitIndex, float timeOwnerWasSetup)
	parent.OwnedUnitHasDied(unitIndex, timeOwnerWasSetup)
	UpdateConfidenceLevel()
EndFunction

; returns true if out of troops and cleared
bool Function ClearAliasIfOutOfTroops()
	; debug.Trace("commander (" + jMap.getStr(factionScript.jFactionData, "name", "Faction") + "): clear alias if out of troops!")
	; debug.Trace("dead commander: troops left (totalOwnedUnitsAmount): " + totalOwnedUnitsAmount)
	; debug.Trace("dead commander: spawnedUnitsAmount: " + spawnedUnitsAmount)
	; debug.Trace("dead commander: actual spawnable units count: " + GetActualSpawnableUnitsCount())
	; debug.Trace("dead commander: actual spawned units count: " + GetActualSpawnedUnitsCount())
	; debug.Trace("dead commander: actual total units count: " + GetActualTotalUnitsCount())
	if totalOwnedUnitsAmount <= 0
		ClearCmderData()
		return true
	endif

	return false
EndFunction

Function HandleAutocalcDefeat()
	; debug.Trace("commander (" + jMap.getStr(factionScript.jFactionData, "name", "Faction") + "): defeated in autocalc!")
	ClearCmderData()
	; meActor.SetCriticalStage(meActor.CritStage_DisintegrateEnd)
	meActor.Disable()
	meActor.Delete()
	meActor = None
EndFunction

; returns true if this cmder has a valid actor reference
bool Function IsValid()
	if meActor
		return true
	endif

	return false
EndFunction

; clears the alias and stops updates
Function ClearCmderData()
	; debug.Trace("commander: clear cmder data!")

	if TargetLocationScript != None
		UnregisterAsNearLocation(TargetLocationScript)
	endif

	ToggleNearbyUpdates(false)
	ToggleUpdates(false)
	Clear()

EndFunction

int Function GetMaxOwnedUnitsAmount()
	return JDB.solveInt(".ShoutAndBlade.cmderOptions.maxOwnedUnits", 30)
EndFunction

float Function GetIsNearbyDistance()
	int nearbyCmders = CloseByUpdater.CmderUpdater.numActives

	if nearbyCmders >= JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5)
		return JDB.solveFlt(".ShoutAndBlade.cmderOptions.nearbyDistanceDividend", 16384.0) / nearbyCmders
	endif

	return JDB.solveFlt(".ShoutAndBlade.cmderOptions.isNearbyDistance", 4096.0)
EndFunction

int Function GetMaxSpawnedUnitsAmount()
	int nearbyCmders = CloseByUpdater.CmderUpdater.numActives
	
	if meActor == None
		return 0
	endif

	if meActor.IsInCombat() || meActor.IsDead()
		if nearbyCmders >= JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5)
			
			; debug.Trace("Cmder GetMaxSpawnedUnitsAmount: in combat and above nearbyCmdersLimit. MaxAmount: " + \
			; 				(JDB.solveInt(".ShoutAndBlade.cmderOptions.combatSpawnsDividend", 20) / nearbyCmders))
			int numSpawns = JDB.solveInt(".ShoutAndBlade.cmderOptions.combatSpawnsDividend", 20) / nearbyCmders
			; if numSpawns < 1
			; 	numSpawns = 1
			; endif
			return numSpawns
		endif

		; debug.Trace("Cmder GetMaxSpawnedUnitsAmount: in combat. MaxAmount: " + \
		; 					(JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsInCombat", 8)))
		return JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsInCombat", 8)
	else
		; debug.Trace("Cmder GetMaxSpawnedUnitsAmount: peaceful. MaxAmount: " + \
		; 					(JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsOutsideCombat", 6)))
		return JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsOutsideCombat", 6)
	endif
EndFunction

; returns max units per cmder that is inside the location
int Function GetMaxBesiegingUnitsAmount()
	int nearbyCmders = CloseByUpdater.CmderUpdater.numActives

	if TargetLocationScript != None
		nearbyCmders += TargetLocationScript.GetTopNearbyCmderIndex()
	endif

	if nearbyCmders >= JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5)
		return JDB.solveInt(".ShoutAndBlade.cmderOptions.combatSpawnsDividend", 20) / nearbyCmders
	endif

	return JDB.solveInt(".ShoutAndBlade.cmderOptions.maxSpawnsWhenBesieging", 8)
EndFunction