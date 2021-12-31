Scriptname SAB_LocationScript extends SAB_TroopContainerScript
{ script for a location that can be captured by SAB factions.
 This script should be added to an xmarker in the exterior world, where distance checks should work.}

ObjectReference[] Property ExternalSpawnPoints Auto
ObjectReference[] Property InternalSpawnPoints Auto

ObjectReference Property DefaultLocationsContentParent Auto
{ The xmarker that should be the enable parent of all content that should be disabled when this location is taken by one of the SAB factions }

int Property jNearbyLocationsArray Auto
{ a jArray filled with the locationDataHandler indexes of locations near this one }

ObjectReference Property MoveDestination Auto
{ this is the destination commanders will head to. It can be inside the location itself }

Location Property ThisLocation Auto

float Property GoldRewardMultiplier = 1.0 Auto
{ a multiplier applied on this location's gold award to the owner. Can make locations more or less valuable to control }

bool playerIsInside = false

float timeOfLastUnitLoss = 0.0
; used for knowing whether this location is under attack or not
float timeSinceLastUnitLoss = 0.0

SAB_CommanderScript Property InteractingCommander Auto
{ a reference to the commander currently either attacking or reinforcing this location }

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	parent.Setup(factionScriptRef, curGameTime)
EndFunction

Function BeTakenByFaction(SAB_FactionScript factionScriptRef)
	ToggleNearbyUpdates(false)
	jOwnedUnitsMap = jValue.releaseAndRetain(jOwnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnedUnitsMap = jValue.releaseAndRetain(jSpawnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnOptionsArray = jValue.releaseAndRetain(jSpawnOptionsArray, jArray.object(), "ShoutAndBlade")
	availableExpPoints = 0.0
	totalOwnedUnitsAmount = 0
	spawnedUnitsAmount = 0
	factionScript = factionScriptRef
	gameTimeOfLastExpAward = 0.0
	gameTimeOfLastUnitUpgrade = 0.0
	gameTimeOfLastSetup = 0.0
	Debug.Trace(ThisLocation.GetName() + " has been taken by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
	Debug.Notification(ThisLocation.GetName() + " has been taken by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
EndFunction

; stops nearby updates and sets this location as neutral
Function BecomeNeutral()
	debug.Trace("location: become neutral!")
	ToggleNearbyUpdates(false)
	factionScript = None
EndFunction

; sets isNearby and enables or disables closeBy updates
Function ToggleNearbyUpdates(bool updatesEnabled)
	
	debug.Trace("location: toggleNearbyUpdates " + updatesEnabled)
	debug.Trace("location: indexInCloseByUpdater " + indexInCloseByUpdater)
	if updatesEnabled
		isNearby = true
		if indexInCloseByUpdater == -1
			indexInCloseByUpdater = CloseByUpdater.LocationUpdater.RegisterAliasForUpdates(self)
			debug.Trace("location: began closebyupdating!")
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater != -1
			CloseByUpdater.LocationUpdater.UnregisterAliasFromUpdates(indexInCloseByUpdater)
			indexInCloseByUpdater = -1
			debug.Trace("location: stopped closebyupdating!")
		endif
	endif

EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)

	if updateIndex == 1
		return RunCloseByUpdate()
	endif

	if curGameTime != 0.0
		if gameTimeOfLastExpAward == 0.0
			; set initial values for "gameTime" variables, to avoid them from getting huge accumulated awards
			gameTimeOfLastExpAward = curGameTime
			gameTimeOfLastUnitUpgrade = curGameTime
			gameTimeOfLastSetup = curGameTime
		endif

		; a timeOfLastUnitLoss equal to 0.0 means a unit has been lost recently
		if timeOfLastUnitLoss == 0.0
			timeOfLastUnitLoss = curGameTime
			timeSinceLastUnitLoss = 0.0
		else 
			timeSinceLastUnitLoss = curGameTime - timeOfLastUnitLoss
		endif
	endif

	;debug.Trace("game time updating commander (pre check)!")
	if curGameTime - gameTimeOfLastExpAward >= 0.2 ; TODO make this configurable
		int numAwardsObtained = ((curGameTime - gameTimeOfLastExpAward) / 0.2) as int
		availableExpPoints += 250.0 * numAwardsObtained ; TODO make this configurable
		gameTimeOfLastExpAward = curGameTime
	endif
	

	float distToPlayer = playerActor.GetDistance(GetReference())
	; debug.Trace("dist to player from location of faction " + jMap.getStr(factionScript.jFactionData, "name", "NEUTRAL") + ": " + distToPlayer)

	playerIsInside = ThisLocation.IsSameLocation(playerActor.GetCurrentLocation())

	ToggleNearbyUpdates(factionScript != None && (distToPlayer <= 8000.0 || playerIsInside))

	if !isNearby && !playerIsInside

		; if a faction contorls this location, disable default content if it's still enabled.
		; if it's neutral, enable it back!
		if factionScript != None && !DefaultLocationsContentParent.IsDisabled()
			DefaultLocationsContentParent.Disable()
		elseif factionScript == None && DefaultLocationsContentParent.IsDisabled()
			DefaultLocationsContentParent.Enable()
		endif
			
	endif

	if curGameTime - gameTimeOfLastUnitUpgrade >= 0.1 ; TODO make this configurable
		gameTimeOfLastUnitUpgrade = curGameTime

		; if we have enough units, upgrade. If we don't, recruit some more
		if totalOwnedUnitsAmount >= GetMaxOwnedUnitsAmount() * 0.7
			TryUpgradeUnits()
		else 
			TryRecruitUnits()
		endif
	endif
	
	Utility.Wait(0.01)

	return true
endfunction


bool function RunCloseByUpdate()
	;debug.Trace("real time updating commander!")
	if factionScript != None && spawnedUnitsAmount < 20 ; TODO make this configurable
		; spawn random unit from "storage"
		int indexToSpawn = GetUnitIndexToSpawn()
		if indexToSpawn >= 0
			SpawnUnit(indexToSpawn)
		endif
	endif

	return true
	
endfunction


; returns true if this location has recently lost a unit
bool Function IsBeingContested()
	return timeSinceLastUnitLoss > 0.1
endfunction


bool Function IsActorCloseEnoughForAutocalc(Actor targetActor)
	float distToLoc = GetReference().GetDistance(targetActor)
	debug.Trace("dist to loc from actor: " + distToLoc)
	if distToLoc <= 1000.0
		return true
	endif

	distToLoc = MoveDestination.GetDistance(targetActor)
	debug.Trace("dist to loc movedest from actor: " + distToLoc)
	if distToLoc <= 1000.0
		return true
	endif

	return false
EndFunction


Function OwnedUnitHasDied(int unitIndex, float timeOwnerWasSetup)
	parent.OwnedUnitHasDied(unitIndex, timeOwnerWasSetup)
	timeOfLastUnitLoss = 0.0 ; will refresh the time of/since last loss in the next update
	BecomeNeutralIfOutOfTroops()
EndFunction

ObjectReference Function GetSpawnLocationForUnit()
	if playerIsInside && InternalSpawnPoints.Length > 0
		return InternalSpawnPoints[Utility.RandomInt(0, InternalSpawnPoints.Length - 1)]
	else 
		return ExternalSpawnPoints[Utility.RandomInt(0, ExternalSpawnPoints.Length - 1)]
	endif
EndFunction


Function SpawnUnit(int unitIndex)
	Debug.Trace("location: spawn unit begin!")
	ObjectReference spawnLocation = GetSpawnLocationForUnit()

	ReferenceAlias spawnedUnit = factionScript.SpawnUnitForTroopContainer(self, unitIndex, spawnLocation, gameTimeOfLastSetup)

	if spawnedUnit != None
		; add spawned unit index to spawneds list
		int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
		jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount + 1)

		spawnedUnitsAmount += 1
	endif
EndFunction

; returns true if out of troops and "neutralized"
bool Function BecomeNeutralIfOutOfTroops()
	if factionScript != None
		debug.Trace("location (" + jMap.getStr(factionScript.jFactionData, "name", "Faction") + "): become neutral if out of troops!")
		debug.Trace("location: totalOwnedUnitsAmount: " + totalOwnedUnitsAmount)
		debug.Trace("location: spawnedUnitsAmount: " + spawnedUnitsAmount)
		debug.Trace("location: troops left: " + totalOwnedUnitsAmount)
		if totalOwnedUnitsAmount <= 0
			BecomeNeutral()
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
	return 45 ; TODO make this configurable
EndFunction