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

SAB_LocationDataHandler Property LocationDataHandler Auto

SAB_LocationScript destinationScript_A
SAB_LocationScript destinationScript_B
SAB_LocationScript destinationScript_C

float gameTimeOfLastDestinationChange_A = 0.0
float gameTimeOfLastDestinationChange_B = 0.0
float gameTimeOfLastDestinationChange_C = 0.0

FormList Property DefaultCmderSpawnPointsList Auto

Faction Property OurFaction Auto
{ This faction's... faction }

SAB_UnitsUpdater Property UnitUpdater Auto

int Property jFactionData Auto
{ This faction's data jMap }

int Property jOwnedLocationIndexesArray Auto
{ indexes of the LocationDataHandler array that contain locations owned by this faction }

bool cmderSpawnIsSet = false

; measured in days (1.0 is a day)
float gameTimeOfLastRealUpdate = 0.0
float gameTimeOfLastDestinationUpdate = 0.0
float gameTimeOfLastGoldAward = 0.0

; prepares this faction's data and registers it for updating
function EnableFaction(int jEnabledFactionData)
	jFactionData = jEnabledFactionData
	CmderDestination_A.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
	CmderDestination_B.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
	CmderDestination_C.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
	destinationScript_A = None
	destinationScript_B = None
	destinationScript_C = None
	jOwnedLocationIndexesArray = jValue.releaseAndRetain(jOwnedLocationIndexesArray, LocationDataHandler.GetLocationIndexesOwnedByFaction(self), "ShoutAndBlade")
endfunction


; returns true if the faction was updated, false if the faction can't be updated (because it's disabled, for example)
bool Function RunUpdate(float daysPassed)
	if jFactionData == 0
		return false
	endif

	if jMap.hasKey(jFactionData, "enabled")
		if daysPassed - gameTimeOfLastRealUpdate >= JDB.solveFlt(".ShoutAndBlade.factionOptions.updateInterval", 0.025)
			gameTimeOfLastRealUpdate = daysPassed
			Debug.Trace("updating faction " + jMap.getStr(jFactionData, "name", "Faction"))

			float goldInterval = JDB.solveFlt(".ShoutAndBlade.factionOptions.goldInterval", 0.12)
			if daysPassed - gameTimeOfLastGoldAward >= goldInterval
				int numAwardsObtained = ((daysPassed - gameTimeOfLastGoldAward) / goldInterval) as int
				int goldPerAward = CalculateTotalGoldAward()
				int currentGold = jMap.getInt(jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))
				jMap.setInt(jFactionData, "AvailableGold", currentGold + (goldPerAward * numAwardsObtained))
				gameTimeOfLastGoldAward = daysPassed
			endif

			if daysPassed - gameTimeOfLastDestinationUpdate >= JDB.solveFlt(".ShoutAndBlade.factionOptions.destCheckInterval", 0.15)
				gameTimeOfLastDestinationUpdate = daysPassed
				RunDestinationsUpdate(daysPassed)
			endif
			
			TrySpawnCommander(daysPassed, true)
		endif
		
	else 
		return false
	endif
	
	return true
	;Debug.Trace("done updating faction " + jMap.getStr(jFactionData, "name", "Faction"))
EndFunction


; makes the faction "think" about where its commanders should go to.
; the faction should try to both attack other locations and defend their own
Function RunDestinationsUpdate(float curGameTime)

	int jAttackTargetsArray = FindAttackTargets()
	int jDefenseTargetsArray = FindDefenseTargets()
	int targetLocIndex = -1
	float gameTimeBeforeChangeDestination = JDB.solveFlt(".ShoutAndBlade.factionOptions.destChangeInterval", 1.05)

	; A should be an attack destination!
	if curGameTime - gameTimeOfLastDestinationChange_A > gameTimeBeforeChangeDestination || \
		destinationScript_A == None || destinationScript_A.factionScript == self

		targetLocIndex = jArray.getInt(jAttackTargetsArray, Utility.RandomInt(0, jArray.count(jAttackTargetsArray) - 1), -1)

		if targetLocIndex == -1
			destinationScript_A = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_A = LocationDataHandler.Locations[targetLocIndex]
		endif

		CmderDestination_A.GetReference().MoveTo(destinationScript_A.MoveDestination)
		gameTimeOfLastDestinationChange_A = curGameTime
	endif

	; B can be an attack or defend destination. If no "good" targets are available, fall back to a random loc, like A
	if curGameTime - gameTimeOfLastDestinationChange_B > gameTimeBeforeChangeDestination || \
		 destinationScript_B == None || destinationScript_B == destinationScript_A || destinationScript_B.factionScript == self

		targetLocIndex = jArray.getInt(jDefenseTargetsArray, Utility.RandomInt(0, jArray.count(jDefenseTargetsArray) - 1), -1)

		if targetLocIndex == -1
			targetLocIndex = jArray.getInt(jAttackTargetsArray, Utility.RandomInt(0, jArray.count(jAttackTargetsArray) - 1), -1)
		endif

		if targetLocIndex == -1
			destinationScript_B = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_B = LocationDataHandler.Locations[targetLocIndex]
		endif

		CmderDestination_B.GetReference().MoveTo(destinationScript_B.MoveDestination)
		gameTimeOfLastDestinationChange_B = curGameTime
	endif

	; destination C should be defensive. Look for locations we control that are currently contested and go there, 
	; or just randomly patrol our locations
	if curGameTime - gameTimeOfLastDestinationChange_C > gameTimeBeforeChangeDestination || \
		destinationScript_C == None || destinationScript_C.factionScript != self

		targetLocIndex = jArray.getInt(jDefenseTargetsArray, Utility.RandomInt(0, jArray.count(jDefenseTargetsArray) - 1), -1)

		if targetLocIndex == -1
			destinationScript_C = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_C = LocationDataHandler.Locations[targetLocIndex]
		endif

		CmderDestination_C.GetReference().MoveTo(destinationScript_C.MoveDestination)
		gameTimeOfLastDestinationChange_C = curGameTime
	endif


	JValue.release(jAttackTargetsArray)
	JValue.zeroLifetime(jAttackTargetsArray)
EndFunction


; returns a jArray with zones this faction could attack
int Function FindAttackTargets()
	int i = jArray.count(jOwnedLocationIndexesArray)
	int j = 0

	
	int jPossibleAttackTargets = jArray.object()
	JValue.retain(jPossibleAttackTargets, "ShoutAndBlade")

	if i > 0
		; look at the locations near our own and add them to the "candidates" list
		while i > 0
			i -= 1
			int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

			if locIndex != -1
				SAB_LocationScript locScript = LocationDataHandler.Locations[locIndex]
				; check if this location is still owned by us
				if locScript.factionScript != self
					JArray.eraseIndex(jOwnedLocationIndexesArray, i)
				else
					int jNearbyLocsArray = locScript.jNearbyLocationsArray	
					j = jArray.count(jNearbyLocsArray)

					while j > 0
						locIndex = jArray.getInt(jNearbyLocsArray, j, -1)

						if locIndex != -1
							; if we don't own the location with index locIndex, add it as a candidate for attacking
							if jArray.findInt(jOwnedLocationIndexesArray, locIndex) == -1
								JArray.addInt(jPossibleAttackTargets, locIndex)
							endif
						endif
					endwhile

				endif
			endif
		endwhile	
	else 
		; we don't have any location!
		; look for neutral ones for an easier target
		SAB_LocationScript[] locScripts = LocationDataHandler.Locations
		i = locScripts.Length

		while i > 0
			i -= 1
			
			SAB_LocationScript locScript = LocationDataHandler.Locations[i]

			if locScript.factionScript == None
				JArray.addInt(jPossibleAttackTargets, i)
			endif
		endwhile
	endif

	return jPossibleAttackTargets

EndFunction


; returns a jArray with zones this faction should defend (because they're under attack or are poorly defended)
int Function FindDefenseTargets()
	int i = jArray.count(jOwnedLocationIndexesArray)
	int j = 0
	
	int jPossibleDefenseTargets = jArray.object()
	JValue.retain(jPossibleDefenseTargets, "ShoutAndBlade")

	while i > 0
		i -= 1
		int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

		if locIndex != -1
			SAB_LocationScript locScript = LocationDataHandler.Locations[locIndex]
			; check if this location is still owned by us
			if locScript.factionScript != self
				JArray.eraseIndex(jOwnedLocationIndexesArray, i)
			else

				if locScript.IsBeingContested()
					JArray.addInt(jPossibleDefenseTargets, locIndex)
				else
					float locationPower = SpawnerScript.UnitDataHandler.GetTotalAutocalcPowerFromArmy(locScript.jOwnedUnitsMap)

					if locationPower < JDB.solveFlt(".ShoutAndBlade.factionOptions.safeLocationPower", 32.0)
						JArray.addInt(jPossibleDefenseTargets, locIndex)
					endif
					
					debug.Trace("location " + locScript.ThisLocation.GetName() + " autocalc power = " + locationPower)
				endif

			endif
		endif
	endwhile

	return jPossibleDefenseTargets

EndFunction


; destination code can be A, B or C.
; we should check if the cmder really is close to the respective xmarker, and, if it really is the case, do stuff
Function ValidateCmderReachedDestination(SAB_CommanderScript commander, string cmderDestType = "a")
	ObjectReference cmderDest = CmderDestination_A.GetReference()
	ObjectReference cmderRef = commander.GetReference()
	SAB_LocationScript targetLocScript = destinationScript_A

	if cmderDestType == "b" || cmderDestType == "B"
		cmderDest = CmderDestination_B.GetReference()
		targetLocScript = destinationScript_B
	elseif cmderDestType == "c" || cmderDestType == "C"
		cmderDest = CmderDestination_C.GetReference()
		targetLocScript = destinationScript_C
	endif

	if targetLocScript == None
		return
	endif
	
	if targetLocScript.IsReferenceCloseEnoughForAutocalc(cmderRef)
		; the commander has really arrived! Do stuff like autocalc battles now.
		; assign the location to the cmder, and then they'll figure out what to do when updating
		Debug.Trace("commander has arrived and has been assigned the loc script!")
		commander.TargetLocationScript = targetLocScript
	endif

EndFunction


; returns the total gold amount the faction gets in one "gold award cycle"
int Function CalculateTotalGoldAward()
	int baseAwardedGold = JDB.solveInt(".ShoutAndBlade.factionOptions.baseGoldAward", 500)
	int baseGoldPerLoc = JDB.solveInt(".ShoutAndBlade.locationOptions.baseGoldAward", 1500)
	int totalAward = baseAwardedGold

	; add more gold per zone owned
	int i = jArray.count(jOwnedLocationIndexesArray)

	while i > 0
		int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

		if locIndex != -1
			totalAward += (baseGoldPerLoc * LocationDataHandler.Locations[locIndex].GoldRewardMultiplier) as int
		endif

		i -= 1
	endwhile

	return totalAward
EndFunction


; spends gold and returns a number of recruits "purchased".
; the caller should do something with this number
int function PurchaseRecruits(int maxAmountPurchased = 100)

	int recruitIndex = jMap.getInt(jFactionData, "RecruitUnitIndex")
	int currentGold = jMap.getInt(jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))
	int recruitedAmount = 0

	int jRecruitObj = jArray.getObj(SpawnerScript.UnitDataHandler.jSABUnitDatasArray, recruitIndex)
	int goldCostPerRec = jMap.getInt(jRecruitObj, "GoldCost", 10)

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
	int currentGold = jMap.getInt(jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))
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
			; Utility.Wait(0.01)
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

	int goldCostPerUpg = jMap.getInt(jUpgradedUnitData, "GoldCost", 10)
	float expCostPerUpg = jMap.getFlt(jUpgradedUnitData, "ExpCost", 10.0)
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
	JValue.zeroLifetime(jUpgradeOptions)
endfunction


; if we can afford it and there's a free cmder slot,
; spawn a new cmder somewhere.
; (optionally spawn only if we've got double the cmder spawn cost,
;  to make sure we've got enough money to give the cmder some units)
ReferenceAlias Function TrySpawnCommander(float curGameTime, bool onlySpawnIfHasExtraMoney = false)
	; find a spawn for the cmder
	ObjectReference cmderSpawn = GetCmderSpawnPoint()

	int cmderUnitTypeIndex = jMap.getInt(jFactionData, "CmderUnitIndex")

	ReferenceAlias cmderAlias = FindEmptyAlias("Commander")

	if cmderAlias == None
		return None
	endif

	; check if we can afford creating a new cmder
	int cmderCost = JDB.solveInt(".ShoutAndBlade.factionOptions.createCmderCost", 250)
	int currentGold = jMap.getInt(jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))

	if (!onlySpawnIfHasExtraMoney && currentGold < cmderCost) || (onlySpawnIfHasExtraMoney && currentGold < JDB.solveInt(".ShoutAndBlade.factionOptions.minCmderGold", 600))
		return None
	endif

	Actor cmderUnit = SpawnerScript.SpawnUnit(cmderSpawn, OurFaction, cmderUnitTypeIndex)

	if cmderUnit == None
		return None
	endif

	cmderAlias.ForceRefTo(cmderUnit)
	(cmderAlias as SAB_CommanderScript).Setup(self, curGameTime)

	; debug.Trace("spawned cmder package is " + cmderUnit.GetCurrentPackage())

	jMap.setInt(jFactionData, "AvailableGold", currentGold - cmderCost)

	return cmderAlias

EndFunction

; find a free unit slot and spawn a unit of the desired type
ReferenceAlias Function SpawnUnitForTroopContainer(SAB_TroopContainerScript troopContainer, int unitIndex, ObjectReference spawnLocation, float containerSetupTime, int cmderFollowRank = -1)
	
	if unitIndex < 0
		debug.Trace("spawn unit for cmder: invalid unit index!")
		return None
	endif

	ReferenceAlias unitAlias = GetFreeUnitAliasSlot()

	if unitAlias == None
		debug.Trace("spawn unit for cmder: no free alias slot!")
		return None
	endif

	int unitIndexInUnitUpdater = UnitUpdater.UnitUpdater.RegisterAliasForUpdates(unitAlias as SAB_UnitScript)

	if unitIndexInUnitUpdater == -1
		debug.Trace("spawn unit for cmder: unitIndexInUnitUpdater is -1!")
		return None
	endif

	Actor spawnedUnit = SpawnerScript.SpawnUnit(spawnLocation, OurFaction, unitIndex, -1, cmderFollowRank)

	if spawnedUnit == None
		debug.Trace("spawn unit for cmder: got none as spawnedUnit, aborting!")
		UnitUpdater.UnitUpdater.UnregisterAliasFromUpdates(unitIndexInUnitUpdater)
		return None
	endif

	unitAlias.ForceRefTo(spawnedUnit)
	(unitAlias as SAB_UnitScript).Setup(unitIndex, troopContainer, unitIndexInUnitUpdater, containerSetupTime)

	; debug.Trace("spawned unit package is " + spawnedUnit.GetCurrentPackage())

	return unitAlias

EndFunction


; Returns an open alias reference with a name starting with aliasPrefix followed by a number.
; returns none if no empty aliases are found
ReferenceAlias function FindEmptyAlias(string aliasPrefix)
	ReferenceAlias ref
	int checkedAliasIndex = 0
 
	while true
		checkedAliasIndex += 1
		ref = getAliasByName(aliasPrefix + checkedAliasIndex) as ReferenceAlias

		; Utility.Wait(0.01)

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

; returns a spawn point from one of our locations, or a random preset one if we don't control any location and we haven't set the fallback point
ObjectReference function GetCmderSpawnPoint()
	int i = jArray.count(jOwnedLocationIndexesArray)

	while i > 0
		int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

		if locIndex != -1
			; cmders shouldn't spawn in a contested zone
			if !LocationDataHandler.Locations[locIndex].IsBeingContested()
				return LocationDataHandler.Locations[locIndex].GetSpawnLocationForUnit()
			endif
		endif

		i -= 1
	endwhile

	if !cmderSpawnIsSet
		return GetRandomCmderDefaultSpawnPoint()
	else
		return CmderSpawnPoint.GetReference()
	endif
endfunction

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