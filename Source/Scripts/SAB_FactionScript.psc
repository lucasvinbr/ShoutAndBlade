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

FormList Property DefaultCmderSpawnPointsList Auto

Faction Property OurFaction Auto
{ This faction's... faction }

int Property jFactionData Auto
{ This faction's data jMap }

; cached index for looping over aliases. we store it to start from it instead of from 0 in the next search
int checkedAliasIndex = 0

bool cmderSpawnIsSet = false

; prepares this faction's data and registers it for updating
function EnableFaction(int jEnabledFactionData)
	jFactionData = jEnabledFactionData
	CmderDestination_A.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
	CmderDestination_B.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
	CmderDestination_C.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
endfunction


; returns true if the faction was updated, false if the faction can't be updated (because it's disabled, for example)
bool Function RunUpdate()
	if jFactionData == 0
		return false
	endif

	if jMap.hasKey(jFactionData, "enabled")
		Debug.Trace("updating faction " + jMap.getStr(jFactionData, "name", "Faction"))
		int baseAwardedGold = 500 ; TODO make this configurable

		int currentGold = jMap.getInt(jFactionData, "AvailableGold")
		jMap.setInt(jFactionData, "AvailableGold", currentGold + baseAwardedGold)

		if Utility.RandomInt(1, 10) > 8
			; TODO make the faction get real move targets for the cmders
			CmderDestination_A.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
			CmderDestination_B.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
			CmderDestination_C.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())	
		endif
		

		TrySpawnCommander()
	else 
		return false
	endif
	
	Debug.Trace("done updating faction " + jMap.getStr(jFactionData, "name", "Faction"))
EndFunction

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


; given the amount and index of the provided unit, the available experience points and the available faction gold,
; attempts to upgrade the units to a random option of the upgrades available in the troop lines.
; returns a jMap with new units' index and amount
int function TryUpgradeUnits(int unitIndex, int unitAmount, float availableExp)
	int currentGold = jMap.getInt(jFactionData, "AvailableGold")
	int jUpgradeOptions = jArray.object()
	jValue.retain(jUpgradeOptions, "ShoutAndBlade")

	; iterate through troop lines, looking for the passed unitIndex, and store the indexes of the "next step" units
	int jOurTroopLinesArr = jMap.getObj(jFactionData, "jTroopLinesArray")
	int numTroopLines = jValue.count(jOurTroopLinesArr)
	int relevantTroopLineLength = 0
	int i = 0
	int j = 0

	while i < numTroopLines
		int jCurTroopLineArr = jArray.getObj(jOurTroopLinesArr, i)
		relevantTroopLineLength = jValue.count(jCurTroopLineArr) - 1 ; no need to look at the last index

		j = 0
		while j < relevantTroopLineLength
			if jArray.getInt(jCurTroopLineArr, j, -1) == unitIndex
				JArray.addInt(jUpgradeOptions, jArray.getInt(jCurTroopLineArr, j + 1))
			endif
			Utility.Wait(0.01)
			j += 1
		endwhile

		i += 1
	endwhile

	; pick one of the upgrade options and calculate how many we can upgrade
	; (it's ok to end up with 0 upgraded units)
	int upgradedUnitIndex = jArray.getInt(jUpgradeOptions, Utility.RandomInt(0, jValue.count(jUpgradeOptions) - 1), -1)
	int jUpgradedUnitData = jArray.getObj(SpawnerScript.UnitDataHandler.jSABUnitDatasArray, upgradedUnitIndex)

	if jUpgradedUnitData == 0
		return 0
	endif

	int goldCostPerUpg = jMap.getInt(jUpgradedUnitData, "GoldCost")
	float expCostPerUpg = jMap.getFlt(jUpgradedUnitData, "ExpCost")
	int upgradedAmountConsideringExp = 0
	int upgradedAmount = 0
	
	; first consider gold, then exp
	if goldCostPerUpg <= 0
		upgradedAmount = unitAmount
	else
		upgradedAmount = currentGold / goldCostPerUpg
		if upgradedAmount > unitAmount
			upgradedAmount = unitAmount
		endif	
	endif

	if expCostPerUpg > 0
		upgradedAmountConsideringExp = (availableExp / expCostPerUpg) as int
		if upgradedAmountConsideringExp < upgradedAmount
			upgradedAmount = upgradedAmountConsideringExp
		endif
	endif
	
	if upgradedAmount > 0
		jMap.setInt(jFactionData, "AvailableGold", currentGold - (upgradedAmount * goldCostPerUpg))

		int jUpgradeResultMap = jMap.object()

		jMap.setInt(jUpgradeResultMap, "NewUnitIndex", upgradedUnitIndex)
		jMap.setInt(jUpgradeResultMap, "NewUnitAmount", upgradedAmount)
		jMap.setFlt(jUpgradeResultMap, "RemainingExp", availableExp - (upgradedAmount * expCostPerUpg))

		Debug.Trace("upgraded " + upgradedAmount + " units for " + (upgradedAmount * goldCostPerUpg) + " gold")
		return jUpgradeResultMap
	else 
		return 0
	endif


	jValue.release(jUpgradeOptions)
endfunction


; moves the cmder spawn to the location of the target ref and marks the spawn as set...
; unless the target ref is none; in that case we mark the spawn as "unset"
Function SetCmderSpawnLocation(ObjectReference targetLocationRef)
	if targetLocationRef != None
		CmderSpawnPoint.GetReference().MoveTo(targetLocationRef)
		cmderSpawnIsSet = true
	else
		cmderSpawnIsSet = false
	endif
endFunction

; if we can afford it and there's a free cmder slot,
; spawn a new cmder somewhere
ReferenceAlias Function TrySpawnCommander()
	; find a spawn for the cmder
	; TODO consider owned zones
	ObjectReference cmderSpawn = CmderSpawnPoint.GetReference()

	if !cmderSpawnIsSet
		; the cmder spawn point isn't set!
		; get a good random one from the preset spawns list
		cmderSpawn = GetRandomCmderDefaultSpawnPoint()
	endif

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
	
	ReferenceAlias unitAlias = GetFreeUnitAliasSlot()

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
	string cmderDestType = commander.CmderDestinationType

	if cmderDestType == "b" || cmderDestType == "B"
		cmderDest = CmderDestination_B.GetReference()
	elseif cmderDestType == "c" || cmderDestType == "C"
		cmderDest = CmderDestination_C.GetReference()
	endif

	if cmderRef.GetCurrentLocation() == cmderDest.GetCurrentLocation()
		if cmderRef.GetDistance(cmderDest) < 800.0
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

		Utility.Wait(0.01)

		if ref == None
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

ReferenceAlias Function GetFreeUnitAliasSlot()
	;the alias ids used by units range from 21 to 80
	Int i = 81
	While i > 21
		i -= 1
		;debug.Trace(GetAlias(i))
		ReferenceAlias unitAlias = GetAlias(i) as ReferenceAlias
		
		if(!unitAlias.GetReference())
			return unitAlias
		endif
	EndWhile
	
	return None
endFunction

ObjectReference function GetRandomCmderDefaultSpawnPoint()
	ObjectReference pickedSpawnPoint = DefaultCmderSpawnPointsList.GetAt(0) as ObjectReference
	Actor player = Game.GetPlayer()
	int numRandomAttempts = 0

	while numRandomAttempts < 10
		pickedSpawnPoint = DefaultCmderSpawnPointsList.GetAt(Utility.RandomInt(0, DefaultCmderSpawnPointsList.GetSize() - 1)) as ObjectReference

		if pickedSpawnPoint.GetDistance(player) >= 2500.0
			return pickedSpawnPoint
		endif

		numRandomAttempts += 1

	endwhile

	return pickedSpawnPoint
EndFunction