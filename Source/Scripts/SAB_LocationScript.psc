Scriptname SAB_LocationScript extends SAB_TroopContainerScript
{ script for a location that can be captured by SAB factions.
 This script should be added to an xmarker in the exterior world, where distance checks should work.}

Cell[] Property InteriorCells Auto
{ The cells this location contains. These cells will have their owner set to the current controlling faction }

ObjectReference[] Property ExternalSpawnPoints Auto
{ (Optional) Array of objects that should be used as spawn points when outside, but close to, the location. SAB_ObjectsToUseAsSpawnsList will be used instead if not set }

ObjectReference[] Property InternalSpawnPoints Auto
{ (Optional) Array of objects that should be used as spawn points when inside any of the location's interiorCells. SAB_ObjectsToUseAsSpawnsList will be used instead if not set }

ObjectReference[] Property ExtraIsNearbyOutsideMarkers Auto
{ (Optional) usually, we only check against the object reference filling this alias to see if the player is nearby but not inside the loc, but this might not be enough if the location is too big.
  You can add additional markers for the "is nearby but not inside" checking here}

FormList Property SAB_ObjectsToUseAsSpawnsList Auto
{ (Auto-fill) Formlist with objects like xmarkers, that should generally serve as "good enough" spawn points }

ObjectReference Property DefaultLocationsContentParent Auto
{ (Optional) The xmarker that should be the enable parent of all content that should be disabled when this location is taken by one of the SAB factions }

; a map of "unit index - amount" ints describing the starting garrison of this location, the one that will be added when location data is loaded
int property jStartingUnitsMap auto Hidden

int Property jNearbyLocationsArray Auto Hidden
{ a jArray filled with the locationDataHandler indexes of locations near this one }

ObjectReference Property MoveDestination Auto
{ this is the destination commanders will head to. It can be inside the location itself }

Location Property ThisLocation Auto
{ this should be set to the interior location, where moveDestination probably is }

string Property OverrideDisplayName = "" Auto
{ overrides the name of the location when displayed in the mod's menus and notifications. This is also editable by the users via the menus }

float Property GoldRewardMultiplier = 1.0 Auto Hidden
{ a multiplier applied on this location's gold award to the owner. Can make locations more or less valuable to control }

float Property GarrisonSizeMultiplier = 1.0 Auto Hidden
{ a multiplier applied on this location's maximum stored troop amount. Can make locations more or less difficult to defend }

ObjectReference Property DistCalculationReference Auto
{ (Optional) if not None, this object will be used as reference when calculating distances between locations. if not set, the base alias reference will be used }

bool Property isEnabled = true Auto Hidden

bool playerIsInside = false

float timeOfLastUnitLoss = -1.0

; used for knowing whether this location is under attack or not
float timeSinceLastUnitLoss = 1.0

; game time of the last moment when a hostile cmder has notified this location that they're nearby
float timeOfLastHostileCmderUpdate = -1.0

; used for knowing whether this location is under attack or not
float timeSinceLastHostileCmderUpdate = 1.0

SAB_CommanderScript[] Property NearbyCommanders Auto Hidden
{ references to the commanders currently either attacking or reinforcing this location }

int topFilledNearbyCmderIndex = -1
bool editingNearbyCmderIndexes = false
int jKnownVacantNearbyCmderSlots = -1


Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	parent.Setup(factionScriptRef, curGameTime)

	if jKnownVacantNearbyCmderSlots == -1 || jKnownVacantNearbyCmderSlots == 0
		NearbyCommanders = new SAB_CommanderScript[128]
		jKnownVacantNearbyCmderSlots = jArray.object()
		JValue.retain(jKnownVacantNearbyCmderSlots, "ShoutAndBlade")
	endif

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

	ToggleLocationDefaultContent(true)
	
EndFunction

Function BeTakenByFaction(SAB_FactionScript factionScriptRef, bool notify = true)
	if !factionScriptRef
		BecomeNeutral(notify)
		return
	endif

	jOwnedUnitsMap = jValue.releaseAndRetain(jOwnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnedUnitsMap = jValue.releaseAndRetain(jSpawnedUnitsMap, jIntMap.object(), "ShoutAndBlade")
	jSpawnOptionsMap = jValue.releaseAndRetain(jSpawnOptionsMap, jIntMap.object(), "ShoutAndBlade")
	availableExpPoints = 0.0
	totalOwnedUnitsAmount = 0
	currentAutocalcPower = 0.0
	spawnedUnitsAmount = 0
	factionScript = factionScriptRef
	factionScript.AddLocationToOwnedList(self)
	gameTimeOfLastExpAward = 0.0
	gameTimeOfLastUnitUpgrade = 0.0
	gameTimeOfLastSetup = 0.0

	UpdateInteriorsTrespassingStatus()

	if notify
		Debug.Trace(GetLocName() + " has been taken by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
		Debug.Notification(GetLocName() + " has been taken by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
	endif
EndFunction

; sets this location as not owned by any of the mod's factions. 
; If left at this state for too long, the default content should be enabled again
Function BecomeNeutral(bool notify = true)
	if factionScript != None
		factionScript.RemoveLocationFromOwnedList(self)

		if notify
			Debug.Trace(GetLocName() + " is no longer controlled by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
			Debug.Notification(GetLocName() + " is no longer controlled by the " + jMap.getStr(factionScript.jFactionData, "name", "Faction"))
		endif
		
	endif
	factionScript = None

	UpdateInteriorsTrespassingStatus()
EndFunction

; sets interior cells' faction owner and whether they're public or not 
; (public if friend of player, or no faction here)
Function UpdateInteriorsTrespassingStatus()
	bool hasOwner = factionScript != None
	Faction ownerFac = None

	If hasOwner
		ownerFac = factionScript.OurFaction
	EndIf

	int i = 0
	while i < InteriorCells.Length
		InteriorCells[i].SetFactionOwner(ownerFac)

		If hasOwner
			; make neutral/hostile owned locations private, 
			; to make the units attack the player if they don't leave
			InteriorCells[i].SetPublic(factionScript.DiplomacyDataHandler.IsFactionAllyOfPlayer(factionScript.GetFactionIndex()))	
		else
			InteriorCells[i].SetPublic(true)
		endif

		i += 1
	endwhile
EndFunction

; enables/disables the default content parent
Function ToggleLocationDefaultContent(bool enableContent)
	if DefaultLocationsContentParent != None
		if enableContent && DefaultLocationsContentParent.IsDisabled()
			DefaultLocationsContentParent.Enable()
		elseif !enableContent && DefaultLocationsContentParent.IsEnabled()
			DefaultLocationsContentParent.Disable()
		endif
	endif
EndFunction

; sets isNearby and enables or disables closeBy updates
Function ToggleNearbyUpdates(bool updatesEnabled)
	
	; debug.Trace("location: toggleNearbyUpdates " + updatesEnabled)
	; debug.Trace("location: indexInCloseByUpdater " + indexInCloseByUpdater)
	if updatesEnabled && isEnabled
		isNearby = true
		if indexInCloseByUpdater == -1
			indexInCloseByUpdater = -2
			indexInCloseByUpdater = CloseByUpdater.LocationUpdater.RegisterAliasForUpdates(self, indexInCloseByUpdater)
			; debug.Trace("location: began closebyupdating!")
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater > -1
			int indexToUnregister = indexInCloseByUpdater
			indexInCloseByUpdater = -1
			CloseByUpdater.LocationUpdater.UnregisterAliasFromUpdates(indexToUnregister)
			; debug.Trace("location: stopped closebyupdating!")
		endif
	endif

	if factionScript
		if isNearby
			factionScript.DiplomacyDataHandler.PlayerDataHandler.NearbyLocation = self
		elseif factionScript.DiplomacyDataHandler.PlayerDataHandler.NearbyLocation == self
			factionScript.DiplomacyDataHandler.PlayerDataHandler.NearbyLocation = None
		endif
	endif

EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)

	if !isEnabled
		return false
	endif

	If isUpdating
		return false
	EndIf

	isUpdating = true

	if updateIndex == 1 && gameTimeOfLastSetup != 0.0
		bool hasUpdated = RunCloseByUpdate()

		isUpdating = false
		
		return hasUpdated
	endif

	if curGameTime != 0.0
		if gameTimeOfLastExpAward == 0.0
			; set initial values for "gameTime" variables, to avoid them from getting huge accumulated awards
			gameTimeOfLastExpAward = curGameTime
			gameTimeOfLastUnitUpgrade = curGameTime
			gameTimeOfLastSetup = curGameTime
			; debug.Trace(GetLocName() + " now has time of last setup: " + gameTimeOfLastSetup)
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

		; a timeOfLastHostileCmderUpdate equal to 0.0 means a hostile cmder has just been updated
		if timeOfLastHostileCmderUpdate == 0.0
			timeOfLastHostileCmderUpdate = curGameTime
			timeSinceLastHostileCmderUpdate = 0.0

			; notify our owners about the attack
			if factionScript
				factionScript.ReactToLocationUnderAttack(self, curGameTime)
			endif
		else 
			timeSinceLastHostileCmderUpdate = curGameTime - timeOfLastHostileCmderUpdate
		endif
	endif

	;debug.Trace("game time updating commander (pre check)!")
	float expAwardInterval = JDB.solveFlt(".ShoutAndBlade.locationOptions.expAwardInterval", 0.08)
	if curGameTime - gameTimeOfLastExpAward >= expAwardInterval
		int numAwardsObtained = ((curGameTime - gameTimeOfLastExpAward) / expAwardInterval) as int
		availableExpPoints += JDB.solveFlt(".ShoutAndBlade.locationOptions.awardedXpPerInterval", 250.0) * numAwardsObtained
		gameTimeOfLastExpAward = curGameTime
	endif
	

	; is player in this location's interior or exterior? Does this location have an interior?
	playerIsInside = IsRefInThisLocationsInteriors(playerActor)

	ToggleNearbyUpdates(playerIsInside || IsRefNearbyOutside(playerActor)) 
	; debug.Trace(GetLocName() + ": player is inside? " + playerIsInside)

	if !isNearby && !playerIsInside

		; if a faction controls this location, disable default content if it's still enabled.
		; if it's neutral, enable it back!
		; do it only if the player is far away, to make it less noticeable
		ToggleLocationDefaultContent(factionScript == None)
			
	endif

	; if we're not under attack, run the unit maintenance checks
	if !IsBeingContested() && curGameTime - gameTimeOfLastUnitUpgrade >= JDB.solveFlt(".ShoutAndBlade.locationOptions.unitMaintenanceInterval", 0.1)
		gameTimeOfLastUnitUpgrade = curGameTime

		; if we have enough units, upgrade. If we don't, recruit some more
		if totalOwnedUnitsAmount >= GetMaxOwnedUnitsAmount() * 0.7
			TryUpgradeUnits(false)
		else 
			TryRecruitUnits()
		endif
	endif
	
	; Utility.Wait(0.01)

	isUpdating = false
	return true
endfunction


bool function RunCloseByUpdate()

	if !isEnabled
		return false
	endif

	; spawn random units from "storage". If we're under attack, spawn groups of units instead of one at a time
	if factionScript != None
		if IsBeingContested()
			SpawnUnitBatch()
		else
			SpawnRandomUnitAtPos(GetSpawnLocationForUnit())
		endif
	endif

	; if commanders are nearby, spawn their units around the loc, to try and make it as populated as it actually is,
	; both inside and outside
	if topFilledNearbyCmderIndex >= 0 
		int i = topFilledNearbyCmderIndex
		While (i >= 0)
			SAB_CommanderScript InteractingCommander = NearbyCommanders[i]

			if InteractingCommander != None && InteractingCommander.IsValid()
				if IsBeingContested()
					InteractingCommander.SpawnBesiegingUnitBatchAtLocation(GetSpawnLocationForUnit(), -1, true)
				else
					; "ambient units", just to populate the location
					InteractingCommander.SpawnBesiegingUnitAtPos(GetSpawnLocationForUnit(), -1, false)
				endif
			endif

			i -= 1
		EndWhile
		
	endif

	return true
	
endfunction


; returns the cmder's index in the nearbies array, or -1 if we failed to find a vacant index
int Function RegisterCommanderInNearbyList(SAB_CommanderScript cmderScript, int currentIndex = -1)

	if currentIndex > -1
		; debug.Trace(GetLocName() + " wanted to register " + cmderScript + ", but it already had an index")
		return -1
	endif

	while editingNearbyCmderIndexes
		debug.Trace("(register) hold on, " + GetLocName() + " is editing nearby cmder indexes")
		Utility.Wait(0.05)
	endwhile

	editingNearbyCmderIndexes = true
	int vacantIndex = topFilledNearbyCmderIndex + 1

	if !jValue.empty(jKnownVacantNearbyCmderSlots)
		if vacantIndex == 0
			; topFilledNearbyCmderIndex is -1!
			; in this case, we aren't expecting any vacant slots,
			; so we empty the vacants list
			debug.Trace("loc " + GetLocName() + " is clearing invalid vacant nearby cmder slots")
			jArray.clear(jKnownVacantNearbyCmderSlots)
			; numActives = 0
			topFilledNearbyCmderIndex = vacantIndex
		else
			; we know of a hole in the array, let's fill it
			vacantIndex = jArray.getInt(jKnownVacantNearbyCmderSlots, 0)
			; debug.Trace("got vacant alias index from hole: " + vacantIndex)
			jArray.eraseInteger(jKnownVacantNearbyCmderSlots, vacantIndex)
		endif
	else 
		if vacantIndex >= 128
			; there are no holes and all entries are filled!
			; abort
			debug.Trace("loc " + GetLocName() + " is full of nearby cmders!")
			editingNearbyCmderIndexes = false
			return -1
		endif
		; increment top index since there are no holes in the array
		topFilledNearbyCmderIndex = vacantIndex
		; debug.Trace("aliasUpdater: topFilledNearbyCmderIndex is now " + topFilledNearbyCmderIndex)
	endif

	NearbyCommanders[vacantIndex] = cmderScript

	; numActives += 1

	editingNearbyCmderIndexes = false
	return vacantIndex
EndFunction

; nullifies the alias's index in the arrays and add the index to the "holes" jArray
Function UnregisterCommanderFromNearbyList(int cmderIndexInNearbies)
	; debug.Trace("unregister alias " + aliasIndex)

	if cmderIndexInNearbies < 0
		return
	endif

	while editingNearbyCmderIndexes
		debug.Trace("(unregister) hold on, " + GetLocName() + " is editing nearby cmder indexes")
		Utility.Wait(0.05)
	endwhile

	editingNearbyCmderIndexes = true

	NearbyCommanders[cmderIndexInNearbies] = None

	; handle this new "hole" in the filled array:
	; if it's a hole in the top, we can just decrement the top
	if cmderIndexInNearbies == topFilledNearbyCmderIndex
		topFilledNearbyCmderIndex -= 1
	else
		JArray.addInt(jKnownVacantNearbyCmderSlots, cmderIndexInNearbies)

		if topFilledNearbyCmderIndex > -1
			; try and decrement topFilledNearbyCmderIndex by finding holes at the top
			int topHoleIndex = JArray.findInt(jKnownVacantNearbyCmderSlots, topFilledNearbyCmderIndex)

			SAB_CommanderScript topRef = NearbyCommanders[topFilledNearbyCmderIndex]

			While topHoleIndex != -1 || (topFilledNearbyCmderIndex >= 0 && !topRef)
				; debug.Trace("found hole at the top of a loc's nearby cmders! decrementing topFilledNearbyCmderIndex")
				jArray.eraseInteger(jKnownVacantNearbyCmderSlots, topFilledNearbyCmderIndex)
				topFilledNearbyCmderIndex -= 1

				topHoleIndex = JArray.findInt(jKnownVacantNearbyCmderSlots, topFilledNearbyCmderIndex)

				if topFilledNearbyCmderIndex >= 0
					topRef = NearbyCommanders[topFilledNearbyCmderIndex]
				endif
			EndWhile

			if topFilledNearbyCmderIndex == -1 && jArray.count(jKnownVacantNearbyCmderSlots) > 0
				; there's an invalid hole in the vacant slots array! It should be empty if topFilled is -1
				jArray.clear(jKnownVacantNearbyCmderSlots)
			endif

			
		endif
	endif
	
	editingNearbyCmderIndexes = false
	; numActives -= 1
EndFunction

bool function IsCommanderInNearbyList(SAB_CommanderScript cmderScript)
	return GetCommanderIndexInNearbyList(cmderScript) != -1
endfunction

; returns -1 if not found
int function GetCommanderIndexInNearbyList(SAB_CommanderScript cmderScript)
	if cmderScript == None
		return -1
	endif

	int i = topFilledNearbyCmderIndex
	While (i >= 0)
		if NearbyCommanders[i] == cmderScript
			return i
		endif

		i -= 1
	EndWhile

	return -1
endfunction


int Function GetTopNearbyCmderIndex()
	return topFilledNearbyCmderIndex
EndFunction

; refreshes the time of last hostile cmder detection, to mark the loc as contested
Function BeNotifiedOfNearbyHostileCmder()
	timeOfLastHostileCmderUpdate = 0.0
EndFunction

; does a ThisLocation.IsSameLocation check. This can be true even if we're outside the loc but close by,
; like at the gates of the fort or something like that
bool Function IsRefInsideThisLocation(ObjectReference ref)
	;debug.Trace(ThisLocation + ": is same location as " + ref.GetCurrentLocation() + "?")
	return ThisLocation.IsSameLocation(ref.GetCurrentLocation())
EndFunction

; checks the interiorCells list. if there is no interior, always returns false
bool Function IsRefInThisLocationsInteriors(ObjectReference ref)
	if InteriorCells.Length == 0
		return false
	endif

	Cell refCell = ref.GetParentCell()

	if refCell == None
		return false
	endif

	int i = InteriorCells.Length

	While (i > 0)
		i -= 1
		Cell testedCell = InteriorCells[i]

		if refCell == testedCell
			return true
		endif
	EndWhile

	return false
EndFunction

; returns true if this location has recently lost a unit or a hostile commander is nearby
bool Function IsBeingContested()
	return timeOfLastUnitLoss == 0.0 || timeSinceLastUnitLoss < 0.1 || timeSinceLastHostileCmderUpdate < 0.1
endfunction

; the location can only get involved in autocalc battles if the player isn't nearby.
; if the player's nearby, the battle should resolve with real units
bool Function CanAutocalcNow()
	return !isNearby
EndFunction

; checks if the target reference is outisde but close enough.
; Does the actual checks! no caching
bool Function IsRefNearbyOutside(ObjectReference targetRef, float nearbyDistance = 8100.0)
	float distToRef = targetRef.GetDistance(GetReference())

	If (distToRef < nearbyDistance)
		return true
	EndIf

	int i = ExtraIsNearbyOutsideMarkers.Length

	While i > 0
		i -= 1

		distToRef = targetRef.GetDistance(ExtraIsNearbyOutsideMarkers[i])
		If (distToRef < nearbyDistance)
			return true
		EndIf
	EndWhile

	return false
EndFunction

ObjectReference Function GetClosestOutsideSpawnMarkerFromRef(ObjectReference targetRef)
	float smallestDist = targetRef.GetDistance(GetReference())
	ObjectReference closestMarker = GetReference()

	int i = ExtraIsNearbyOutsideMarkers.Length

	While i > 0
		i -= 1

		float distToNewRef = targetRef.GetDistance(ExtraIsNearbyOutsideMarkers[i])
		If (distToNewRef < smallestDist)
			smallestDist = distToNewRef
			closestMarker = ExtraIsNearbyOutsideMarkers[i]
		EndIf
	EndWhile

	return closestMarker
EndFunction

bool Function IsReferenceCloseEnoughForAutocalc(ObjectReference targetRef)

	if IsRefInThisLocationsInteriors(targetRef)
		if playerIsInside
			float distToLoc = MoveDestination.GetDistance(targetRef)
			; debug.Trace("dist to loc movedest from actor: " + distToLoc)
			if distToLoc <= 1800.0
				return true
			endif
		else
			return true
		endif
	else
		if IsRefNearbyOutside(targetRef, 1800.0)
			return true
		else
			float distToLoc = MoveDestination.GetDistance(targetRef)
			; debug.Trace("dist to loc movedest from actor: " + distToLoc)
			if distToLoc <= 1800.0
				return true
			endif
		endif
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
	if playerIsInside || isNearby
		if InternalSpawnPoints.Length > 0
			return InternalSpawnPoints[Utility.RandomInt(0, InternalSpawnPoints.Length - 1)]
		else 
			return GetSpawnLocationForUnit()
		endif
	else
		return MoveDestination
	endif
EndFunction


ObjectReference Function GetSpawnLocationForUnit()
	if playerIsInside
		; debug.Trace("player is inside " + GetLocName())
		if InternalSpawnPoints.Length > 0
			return InternalSpawnPoints[Utility.RandomInt(0, InternalSpawnPoints.Length - 1)]
		else
			return Game.FindRandomReferenceOfAnyTypeInListFromRef(SAB_ObjectsToUseAsSpawnsList, playerActor, 1500)
		endif
	else
		if ExternalSpawnPoints.Length > 0
			return ExternalSpawnPoints[Utility.RandomInt(0, ExternalSpawnPoints.Length - 1)]
		else 
			return Game.FindRandomReferenceOfAnyTypeInListFromRef(SAB_ObjectsToUseAsSpawnsList, GetClosestOutsideSpawnMarkerFromRef(playerActor), 4000)
		endif
	endif
EndFunction

; returns DistCalculationReference if it's set, GetReference() otherwise. 
; Used for caching of a location's closest locs
ObjectReference Function GetDistanceCheckReference()
	if DistCalculationReference
		return DistCalculationReference
	else
		return GetReference()
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

string Function GetLocId()
	return JString.encodeFormToString(ThisLocation)
EndFunction

string Function GetLocName()
	if OverrideDisplayName != ""
		return OverrideDisplayName
	else
		return ThisLocation.GetName()
	endif
EndFunction

; if true, units spawning from this container should spawn ready for combat
bool Function IsOnAlert()
	return IsBeingContested()
endfunction

bool Function IsInitialized()
	return jKnownVacantNearbyCmderSlots != -1
EndFunction