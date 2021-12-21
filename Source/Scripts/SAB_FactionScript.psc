Scriptname SAB_FactionScript extends Quest  

ReferenceAlias Property CmderSpawnPoint Auto
{ The position for spawning new commanders if we have no zones }

ReferenceAlias Property UnitSpawnPoint Auto
{ Position for spawning new units in combat }

ReferenceAlias Property CmderDestination_A Auto
{ A destination marker, used by the faction commanders to know where to go to }

ReferenceAlias Property CmderDestination_B Auto
{ A destination marker, used by the faction commanders to know where to go to }

ReferenceAlias Property CmderDestination_C Auto
{ A destination marker, used by the faction commanders to know where to go to }

SAB_SpawnerScript Property SpawnerScript Auto

Faction Property OurFaction Auto
{ This faction's... faction }

int Property jFactionData Auto
{ This faction's data jMap }

; cached index for looping over aliases. we store it to start from it instead of from 0 in the next search
int checkedAliasIndex = 0

event OnInit()
	RegisterForSingleUpdateGameTime(0.15)
endEvent

Event OnUpdateGameTime()
	if jFactionData == 0
		return
	endif

	if jMap.hasKey(jFactionData, "enabled")
		Debug.Trace("updating faction " + jMap.getStr(jFactionData, "name", "Faction"))
		int baseAwardedGold = 200 ; TODO make this configurable

		int currentGold = jMap.getInt(jFactionData, "AvailableGold")
		jMap.setInt(jFactionData, "AvailableGold", currentGold + baseAwardedGold)

		; TODO make the faction get real move targets for the cmders
		Actor playerRef = Game.GetPlayer()
		CmderDestination_A.GetReference().MoveTo(playerRef)
		CmderDestination_B.GetReference().MoveTo(playerRef)
		CmderDestination_C.GetReference().MoveTo(playerRef)

		TrySpawnCommander()
	endif
	
	float baseUpdateInterval = 1.0 ; TODO make this configurable
	RegisterForSingleUpdateGameTime(Utility.RandomFloat(baseUpdateInterval - 0.2, baseUpdateInterval + 0.2))
EndEvent

; spends gold and returns a number of recruits "purchased".
; the caller should do something with this number
int function PurchaseRecruits(int maxAmountPurchased = 100)

	int recruitIndex = jMap.getInt(jFactionData, "RecruitUnitIndex")
	int currentGold = jMap.getInt(jFactionData, "AvailableGold")
	int recruitedAmount = 0

	int jRecruitObj = jArray.getObj(SpawnerScript.UnitDataHandler.jSABUnitDatasArray, recruitIndex)
	int goldCostPerRec = jMap.getInt(jRecruitObj, "GoldCost")

	if goldCostPerRec <= 0
		recruitedAmount = maxAmountPurchased
	else
		recruitedAmount = currentGold / goldCostPerRec
		if recruitedAmount > maxAmountPurchased
			recruitedAmount = maxAmountPurchased
		endif

		jMap.setInt(jFactionData, "AvailableGold", currentGold - (recruitedAmount * goldCostPerRec))
	endif

	Debug.Trace("recruited " + recruitedAmount + " recruits for " + (recruitedAmount * goldCostPerRec) + " gold")

	return recruitedAmount

endfunction

; if we can afford it and there's a free cmder slot,
; spawn a new cmder somewhere
ReferenceAlias Function TrySpawnCommander()
	; find a spawn for the cmder
	; TODO consider owned zones
	ObjectReference cmderSpawn = CmderSpawnPoint.GetReference()

	int cmderUnitTypeIndex = jMap.getInt(jFactionData, "CmderUnitIndex")

	; restart the cached alias index check, to help the alias finding to fail less often for commanders
	; (since it's shared with the units' alias finding, there's a high chance the index will be high and fail)
	checkedAliasIndex = 0
	ReferenceAlias cmderAlias = FindEmptyAlias("Commander")

	if cmderAlias == None
		return None
	endif

	Actor cmderUnit = SpawnerScript.SpawnUnit(cmderSpawn, OurFaction, cmderUnitTypeIndex)

	if cmderUnit == None
		return None
	endif

	cmderAlias.ForceRefTo(cmderUnit)
	(cmderAlias as SAB_CommanderScript).Setup(self)

	return cmderAlias

EndFunction

; find a free unit slot and spawn a unit of the desired type
ReferenceAlias Function SpawnUnitForCmder(SAB_CommanderScript commander, int unitIndex, ObjectReference spawnLocation)
	
	ReferenceAlias unitAlias = FindEmptyAlias("Unit")

	if unitAlias == None
		return None
	endif

	Actor spawnedUnit = SpawnerScript.SpawnUnit(spawnLocation, OurFaction, unitIndex, -1, commander.CmderFollowFactionRank)

	if spawnedUnit == None
		return None
	endif

	unitAlias.ForceRefTo(spawnedUnit)
	(unitAlias as SAB_UnitScript).Setup(unitIndex, commander)

	return unitAlias

EndFunction

; destination code can be A, B or C.
; we should check if the cmder really is close to the respective xmarker, and, if it really is the case, do stuff
Function CmderReachedDestination(SAB_CommanderScript commander)
	ObjectReference cmderDest = CmderDestination_A.GetReference()
	ObjectReference cmderRef = commander.GetReference()

	if commander.CmderDestinationType == "B"
		cmderDest = CmderDestination_B.GetReference()
	elseif commander.CmderDestinationType == "C"
		cmderDest = CmderDestination_C.GetReference()
	endif

	if cmderRef.GetCurrentLocation() == cmderDest.GetCurrentLocation()
		if cmderRef.GetDistance(cmderDest) < 25.0
			Debug.Notification("commander has arrived!!! do stuff")
			Debug.Trace("commander has arrived!!! do stuff")
		else
			Debug.Trace("commander is too far away")
		endif
	else
		Debug.Trace("commander is somewhere other than their dest!")
	endif

EndFunction

; Returns an open alias reference with a name starting with aliasPrefix followed by a number.
; returns none if no empty aliases are found
ReferenceAlias function FindEmptyAlias(string aliasPrefix)
	ReferenceAlias ref
 
	while true
		checkedAliasIndex += 1
		ref = getAliasByName(aliasPrefix + checkedAliasIndex) as ReferenceAlias

		if !ref
			; we couldn't find an alias with the provided name!
			; return none and reset our checked index
			checkedAliasIndex = 0
			return ref
		endif

		if !ref.getReference()
			return ref
		endif
	endwhile
endfunction
