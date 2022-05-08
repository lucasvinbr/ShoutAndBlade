Scriptname SAB_LocationScript extends SAB_TroopContainerScript
{ script for a location that can be captured by SAB factions.
 This script should be added to an xmarker in the exterior world, where distance checks should work.}

Cell[] Property InteriorCells Auto
{ The cells this location contains. These cells will have their owner set to the current controlling faction }

ObjectReference[] Property ExternalSpawnPoints Auto
{ Array of objects that should be used as spawn points when outside, but close to, the location. SAB_ObjectsToUseAsSpawnsList will be used instead if not set }

ObjectReference[] Property InternalSpawnPoints Auto
{ Array of objects that should be used as spawn points when inside any of the location's interiorCells. SAB_ObjectsToUseAsSpawnsList will be used instead if not set }

FormList Property SAB_ObjectsToUseAsSpawnsList Auto
{ (Auto-fill) Formlist with objects like xmarkers, that should generally serve as "good enough" spawn points }

ObjectReference Property DefaultLocationsContentParent Auto
{ (Optional) The xmarker that should be the enable parent of all content that should be disabled when this location is taken by one of the SAB factions }

int Property jNearbyLocationsArray Auto Hidden
{ a jArray filled with the locationDataHandler indexes of locations near this one }

ObjectReference Property MoveDestination Auto
{ this is the destination commanders will head to. It can be inside the location itself }

Location Property ThisLocation Auto

float Property GoldRewardMultiplier = 1.0 Auto Hidden
{ a multiplier applied on this location's gold award to the owner. Can make locations more or less valuable to control }

float Property GarrisonSizeMultiplier = 1.0 Auto Hidden
{ a multiplier applied on this location's maximum stored troop amount. Can make locations more or less difficult to defend }

bool Property isEnabled = true Auto Hidden

bool playerIsInside = false

float timeOfLastUnitLoss = -1.0

; used for knowing whether this location is under attack or not
float timeSinceLastUnitLoss = 1.0

SAB_CommanderScript Property InteractingCommander Auto Hidden
{ a reference to the commander currently either attacking or reinforcing this location }

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	parent.Setup(factionScriptRef, curGameTime)
	isEnabled = true

	if factionScriptRef != None
		BeTakenByFaction(factionScriptRef, false)
	endif
EndFunction

; makes this location neutral and removes it from all update queues
Function DisableLocation()
	isEnabled = false
	BecomeNeutral(false)
	ToggleNearbyUpdates(false)
	AliasUpdater.UnregisterAliasFromUpdates(indexInUpdater)

	if DefaultLocationsContentParent != None
		DefaultLocationsContentParent.Enable()
	endif
	
EndFunction

Function BeTakenByFaction(SAB_FactionScript factionScriptRef, bool notify = true)
	jOwnedUnitsMap = jValue.releaseAndRetain(jOwnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnedUnitsMap = jValue.releaseAndRetain(jSpawnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnOptionsMap = jValue.releaseAndRetain(jSpawnOptionsMap, jIntMap.object(), "ShoutAndBlade")
	availableExpPoints = 0.0
	totalOwnedUnitsAmount = 0
	spawnedUnitsAmount = 0
	factionScript = factionScriptRef
	factionScript.AddLocationToOwnedList(self)
	gameTimeOfLastExpAward = 0.0
	gameTimeOfLastUnitUpgrade = 0.0
	gameTimeOfLastSetup = 0.0

	int i = 0
	while i < InteriorCells.Length
		InteriorCells[i].SetFactionOwner(factionScriptRef.OurFaction)
		InteriorCells[i].SetPublic(false)

		i += 1
	endwhile

	if notify
		Debug.Trace(ThisLocation.GetName() + " has been taken by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
		Debug.Notification(ThisLocation.GetName() + " has been taken by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
	endif
EndFunction

; sets this location as not owned by any of the mod's factions. 
; If left at this state for too long, the default content should be enabled again
Function BecomeNeutral(bool notify = true)
	if factionScript != None
		factionScript.RemoveLocationFromOwnedList(self)

		if notify
			Debug.Trace(ThisLocation.GetName() + " is no longer controlled by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
			Debug.Notification(ThisLocation.GetName() + " is no longer controlled by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
		endif
		
	endif
	factionScript = None

	int i = 0
	while i < InteriorCells.Length
		InteriorCells[i].SetFactionOwner(None)
		InteriorCells[i].SetPublic(true)

		i += 1
	endwhile
EndFunction

; sets isNearby and enables or disables closeBy updates
Function ToggleNearbyUpdates(bool updatesEnabled)
	
	; debug.Trace("location: toggleNearbyUpdates " + updatesEnabled)
	; debug.Trace("location: indexInCloseByUpdater " + indexInCloseByUpdater)
	if updatesEnabled && isEnabled
		isNearby = true
		if indexInCloseByUpdater == -1
			indexInCloseByUpdater = CloseByUpdater.LocationUpdater.RegisterAliasForUpdates(self)
			; debug.Trace("location: began closebyupdating!")
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater != -1
			CloseByUpdater.LocationUpdater.UnregisterAliasFromUpdates(indexInCloseByUpdater)
			indexInCloseByUpdater = -1
			; debug.Trace("location: stopped closebyupdating!")
		endif
	endif

EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)

	if !isEnabled
		return false
	endif

	if updateIndex == 1 && gameTimeOfLastSetup != 0.0
		return RunCloseByUpdate()
	endif

	if curGameTime != 0.0
		if gameTimeOfLastExpAward == 0.0
			; set initial values for "gameTime" variables, to avoid them from getting huge accumulated awards
			gameTimeOfLastExpAward = curGameTime
			gameTimeOfLastUnitUpgrade = curGameTime
			gameTimeOfLastSetup = curGameTime
			; debug.Trace(ThisLocation.GetName() + " now has time of last setup: " + gameTimeOfLastSetup)
		endif

		; a timeOfLastUnitLoss equal to 0.0 means a unit has been lost recently
		if timeOfLastUnitLoss == 0.0
			timeOfLastUnitLoss = curGameTime
			timeSinceLastUnitLoss = 0.0

			; notify our owners about the attack
			if factionScript
				factionScript.ReactToLocationUnderAttack(self, curGameTime)
			endif
		else 
			timeSinceLastUnitLoss = curGameTime - timeOfLastUnitLoss
		endif
	endif

	;debug.Trace("game time updating commander (pre check)!")
	float expAwardInterval = JDB.solveFlt(".ShoutAndBlade.locationOptions.expAwardInterval", 0.08)
	if curGameTime - gameTimeOfLastExpAward >= expAwardInterval
		int numAwardsObtained = ((curGameTime - gameTimeOfLastExpAward) / expAwardInterval) as int
		availableExpPoints += JDB.solveFlt(".ShoutAndBlade.locationOptions.awardedXpPerInterval", 250.0) * numAwardsObtained
		gameTimeOfLastExpAward = curGameTime
	endif
	

	float distToPlayer = playerActor.GetDistance(GetReference())
	; debug.Trace("dist to player from location of faction " + jMap.getStr(factionScript.jFactionData, "name", "NEUTRAL") + ": " + distToPlayer)

	; is player in this location's interior or exterior? Does this location have an interior?
	playerIsInside = IsRefInsideThisLocation(playerActor)

	if playerIsInside
		if InteriorCells.Length > 0
			Cell curPlayerCell = playerActor.GetParentCell()
			if curPlayerCell == None || !curPlayerCell.IsInterior()
				playerIsInside = false
			endif
		else
			playerIsInside = false
		endif
	endif

	ToggleNearbyUpdates(distToPlayer <= 8100.0 || playerIsInside) ; TODO make this configurable
	; debug.Trace(ThisLocation.GetName() + ": player is inside? " + playerIsInside)

	if !isNearby && !playerIsInside

		; if a faction controls this location, disable default content if it's still enabled.
		; if it's neutral, enable it back!
		if DefaultLocationsContentParent != None
			if factionScript != None && !DefaultLocationsContentParent.IsDisabled()
				DefaultLocationsContentParent.Disable()
			elseif factionScript == None && DefaultLocationsContentParent.IsDisabled()
				DefaultLocationsContentParent.Enable()
			endif
		endif
			
	endif

	if !IsBeingContested() && curGameTime - gameTimeOfLastUnitUpgrade >= JDB.solveFlt(".ShoutAndBlade.locationOptions.unitMaintenanceInterval", 0.1)
		gameTimeOfLastUnitUpgrade = curGameTime

		; if we have enough units, upgrade. If we don't, recruit some more
		if totalOwnedUnitsAmount >= GetMaxOwnedUnitsAmount() * 0.7
			TryUpgradeUnits()
		else 
			TryRecruitUnits()
		endif
	endif
	
	; Utility.Wait(0.01)

	return true
endfunction


bool function RunCloseByUpdate()

	if !isEnabled
		return false
	endif

	;debug.Trace("real time updating commander!")
	if factionScript != None && spawnedUnitsAmount < GetMaxSpawnedUnitsAmount()
		; spawn random units from "storage"
		int unitIndex = GetUnitIndexToSpawn()
		if unitIndex >= 0
			ReferenceAlias spawnedUnitAlias = SpawnUnitAtLocation(unitIndex, GetSpawnLocationForUnit())

			; go fight the attacking cmder if we're under attack!
			if spawnedUnitAlias != None
				if InteractingCommander != None && InteractingCommander.factionScript != factionScript
					(spawnedUnitAlias.GetReference() as Actor).SendTrespassAlarm(InteractingCommander.GetReference() as Actor)
				endif
			endif
		endif
	endif

	; if we're being attacked by another faction, spawn their units around this location, to make the attack "visible"
	if InteractingCommander != None && InteractingCommander.factionScript != factionScript
		
		InteractingCommander.SpawnBesiegingUnitAtPos(GetSpawnLocationForUnit())
		
	endif

	return true
	
endfunction


bool Function IsRefInsideThisLocation(ObjectReference ref)
	return ThisLocation.IsSameLocation(ref.GetCurrentLocation())
EndFunction

; returns true if this location has recently lost a unit
bool Function IsBeingContested()
	return timeOfLastUnitLoss == 0.0 || timeSinceLastUnitLoss < 0.1
endfunction

; the location can only get involved in autocalc battles if the player isn't nearby.
; if the player's nearby, the battle should resolve with real units
bool Function CanAutocalcNow()
	return !isNearby
EndFunction

bool Function IsReferenceCloseEnoughForAutocalc(ObjectReference targetRef)
	float distToLoc = GetReference().GetDistance(targetRef)
	; debug.Trace("dist to loc from actor: " + distToLoc)
	if distToLoc <= 800.0
		return true
	endif

	distToLoc = MoveDestination.GetDistance(targetRef)
	; debug.Trace("dist to loc movedest from actor: " + distToLoc)
	if distToLoc <= 800.0
		return true
	endif

	return false
EndFunction



Function OwnedUnitHasDied(int unitIndex, float timeOwnerWasSetup)
	parent.OwnedUnitHasDied(unitIndex, timeOwnerWasSetup)
	timeOfLastUnitLoss = 0.0 ; will refresh the time of/since last loss in the next update
	BecomeNeutralIfOutOfTroops()
EndFunction


; returns one of the internal spawn points if this location has one.
; if it doesn't, falls back to getSpawnLocationForUnit
ObjectReference Function GetInteriorSpawnPointIfPossible()
	if InternalSpawnPoints.Length > 0
		return InternalSpawnPoints[Utility.RandomInt(0, InternalSpawnPoints.Length - 1)]
	else 
		return GetSpawnLocationForUnit()
	endif
EndFunction


ObjectReference Function GetSpawnLocationForUnit()
	if playerIsInside
		if InternalSpawnPoints.Length > 0
			return InternalSpawnPoints[Utility.RandomInt(0, InternalSpawnPoints.Length - 1)]
		else
			return Game.FindRandomReferenceOfAnyTypeInListFromRef(SAB_ObjectsToUseAsSpawnsList, playerActor, 4000)
		endif
	else
		if ExternalSpawnPoints.Length > 0
			return ExternalSpawnPoints[Utility.RandomInt(0, ExternalSpawnPoints.Length - 1)]
		else 
			return Game.FindRandomReferenceOfAnyTypeInListFromRef(SAB_ObjectsToUseAsSpawnsList, GetReference(), 4000)
		endif
	endif
EndFunction



; returns true if out of troops and "neutralized"
bool Function BecomeNeutralIfOutOfTroops()
	if factionScript != None
		; debug.Trace("location (" + jMap.getStr(factionScript.jFactionData, "name", "Faction") + "): become neutral if out of troops!")
		; debug.Trace("location: spawnedUnitsAmount: " + spawnedUnitsAmount)
		; debug.Trace("location: troops left (totalOwnedUnitsAmount): " + totalOwnedUnitsAmount)
		; debug.Trace("location: actual spawnable units count: " + GetActualSpawnableUnitsCount())
		; debug.Trace("location: actual spawned units count: " + GetActualSpawnedUnitsCount())
		; debug.Trace("location: actual total units count: " + GetActualTotalUnitsCount())
		if totalOwnedUnitsAmount <= 0
			BecomeNeutral(true)
			return true
		endif
	endif

	return false
EndFunction

Function TakeAutocalcDamage(float enemyPower, int jSABUnitDatasArrayCached = -1)
	parent.TakeAutocalcDamage(enemyPower, jSABUnitDatasArrayCached)
	timeOfLastUnitLoss = 0.0 ; will refresh the time of/since last loss in the next update
EndFunction

Function HandleAutocalcDefeat()
	BecomeNeutralIfOutOfTroops()
EndFunction

int Function GetMaxOwnedUnitsAmount()
	int calculatedMax = (JDB.solveInt(".ShoutAndBlade.locationOptions.maxOwnedUnits", 45) * GarrisonSizeMultiplier) as int

	if calculatedMax < 0
		calculatedMax = 0
	endif

	return calculatedMax
EndFunction

; returns the maximum amount of units this container can have spawned in the world at the same time
int Function GetMaxSpawnedUnitsAmount()
	return JDB.solveInt(".ShoutAndBlade.locationOptions.maxSpawnedUnits", 8)
EndFunction