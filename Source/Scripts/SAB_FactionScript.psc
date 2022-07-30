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
SAB_DiplomacyDataHandler Property DiplomacyDataHandler Auto

SAB_LocationScript Property destinationScript_A Auto Hidden
SAB_LocationScript Property destinationScript_B Auto Hidden
SAB_LocationScript Property destinationScript_C Auto Hidden

float gameTimeOfLastDestinationChange_A = 0.0
float gameTimeOfLastDestinationChange_B = 0.0
float gameTimeOfLastDestinationChange_C = 0.0

FormList Property DefaultCmderSpawnPointsList Auto

Faction Property OurFaction Auto
{ This faction's... faction }

SAB_UnitsUpdater Property UnitUpdater Auto

int Property jFactionData Auto Hidden
{ This faction's data jMap }

int Property jOwnedLocationIndexesArray Auto Hidden
{ indexes of the LocationDataHandler array that contain locations owned by this faction }

; the player-related handler script. if this var has a value assigned, it probably means the player belongs to this faction
SAB_PlayerDataHandler playerHandler

bool cmderSpawnIsSet = false

; measured in days (1.0 is a day)
float gameTimeOfLastRealUpdate = 0.0
float gameTimeOfLastDestinationUpdate = 0.0
float gameTimeOfLastGoldAward = 0.0

int lastCheckedUnitAliasIndex = -1
int lastCheckedCmderAliasIndex = -1

int factionIndex = -1

; prepares this faction's data and registers it for updating
function EnableFaction(int jEnabledFactionData, int thisFactionIndex)
	jFactionData = jEnabledFactionData
	CmderDestination_A.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
	CmderDestination_B.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
	CmderDestination_C.GetReference().MoveTo(GetRandomCmderDefaultSpawnPoint())
	destinationScript_A = None
	destinationScript_B = None
	destinationScript_C = None
	jOwnedLocationIndexesArray = jValue.releaseAndRetain(jOwnedLocationIndexesArray, LocationDataHandler.GetLocationIndexesOwnedByFaction(self), "ShoutAndBlade")
	factionIndex = thisFactionIndex
endfunction


; sets mutual faction relations. Doesn't edit json files, only alters the current game's relations
; 0 - Neutral
; 1 - Enemy
; 2 - Ally
; 3 - Friend
Function SetRelationsWithFaction(Faction targetFaction, int relationType)
	; we use this just to be able to fetch the standing with getReaction
	targetFaction.SetReaction(OurFaction, relationType)
	OurFaction.SetReaction(targetFaction, relationType)

	; this is what actually makes them fight each other
	if relationType == 0
		targetFaction.SetEnemy(OurFaction, true, true)
	elseif relationType == 1
		targetFaction.SetEnemy(OurFaction, false, false)
	elseif relationType == 2
		targetFaction.SetAlly(OurFaction, false, false)
	elseif relationType == 3
		targetFaction.SetAlly(OurFaction, true, true)
	endif

	; this can be used to get the current standing
	; debug.Trace(targetFaction.GetReaction(OurFaction))
EndFunction

; also runs global diplomatic reaction
Function AddPlayerToOurFaction(Actor playerActor, SAB_PlayerDataHandler playerDataHandler)
	playerActor.AddToFaction(OurFaction)
	DiplomacyDataHandler.GlobalReactToPlayerJoiningFaction(GetFactionIndex())
	playerHandler = playerDataHandler
	ToggleObjectiveMarkersDisplay(true)
EndFunction

; also runs global diplomatic reaction
Function RemovePlayerFromOurFaction(Actor playerActor)
	playerActor.RemoveFromFaction(OurFaction)
	DiplomacyDataHandler.GlobalReactToPlayerLeavingFaction(GetFactionIndex())
	ToggleObjectiveMarkersDisplay(false)
	playerHandler = None
EndFunction

; don't use this for the player! use AddPlayerToOurFaction in that case
Function AddActorToOurFaction(Actor targetActor)
	targetActor.AddToFaction(OurFaction)
EndFunction

; don't use this for the player!
Function RemoveActorFromOurFaction(Actor targetActor)
	targetActor.RemoveFromFaction(OurFaction)
EndFunction


; returns true if the faction was updated, false if the faction can't be updated (because it's disabled, for example)
bool Function RunUpdate(float daysPassed)
	if jFactionData == 0
		return false
	endif

	if jMap.hasKey(jFactionData, "enabled")
		if daysPassed - gameTimeOfLastRealUpdate >= JDB.solveFlt(".ShoutAndBlade.factionOptions.updateInterval", 0.025)
			gameTimeOfLastRealUpdate = daysPassed
			; Debug.Trace("updating faction " + jMap.getStr(jFactionData, "name", "Faction"))

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

	int attackTargetsCount = jArray.count(jAttackTargetsArray)

	; if there are no more good attack targets, we should break some alliances to keep the wars going
	if attackTargetsCount == 0
		DiplomacyDataHandler.GlobalAllianceDecayWithFac(GetFactionIndex())
	endif

	; A should be an attack destination!
	if curGameTime - gameTimeOfLastDestinationChange_A > gameTimeBeforeChangeDestination || \
		destinationScript_A == None || \
		DiplomacyDataHandler.AreFactionsInGoodStanding(self, destinationScript_A.factionScript) || \
		destinationScript_A.isEnabled == false

		targetLocIndex = jArray.getInt(jAttackTargetsArray, Utility.RandomInt(0, attackTargetsCount - 1), -1)

		if targetLocIndex == -1
			destinationScript_A = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_A = LocationDataHandler.Locations[targetLocIndex]
		endif

		CmderDestination_A.GetReference().MoveTo(destinationScript_A.MoveDestination)
		gameTimeOfLastDestinationChange_A = curGameTime

		; show quest update to tell plyr the faction has changed priorities
		if playerHandler
			SetObjectiveDisplayed(0, true, true)
		endif
	endif

	; B can be an attack or defend destination. If no "good" targets are available, fall back to a random loc, like A
	if curGameTime - gameTimeOfLastDestinationChange_B > gameTimeBeforeChangeDestination || \
		 destinationScript_B == None || destinationScript_B == destinationScript_A || \
		 !destinationScript_B.IsBeingContested() || \
		 destinationScript_B.isEnabled == false

		targetLocIndex = jArray.getInt(jDefenseTargetsArray, Utility.RandomInt(0, jArray.count(jDefenseTargetsArray) - 1), -1)

		if targetLocIndex == -1
			targetLocIndex = jArray.getInt(jAttackTargetsArray, Utility.RandomInt(0, attackTargetsCount - 1), -1)
		endif

		if targetLocIndex == -1
			destinationScript_B = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_B = LocationDataHandler.Locations[targetLocIndex]
		endif

		CmderDestination_B.GetReference().MoveTo(destinationScript_B.MoveDestination)
		gameTimeOfLastDestinationChange_B = curGameTime

		; show quest update to tell plyr the faction has changed priorities
		if playerHandler
			SetObjectiveDisplayed(1, true, true)
		endif
	endif

	; C is like B, but flipped: attack if any target is available, defend if not
	if curGameTime - gameTimeOfLastDestinationChange_C > gameTimeBeforeChangeDestination || \
		destinationScript_C == None || destinationScript_C.isEnabled == false || \
		!destinationScript_C.IsBeingContested() || \
		destinationScript_C == destinationScript_B

		targetLocIndex = jArray.getInt(jAttackTargetsArray, Utility.RandomInt(0, attackTargetsCount - 1), -1)
		
		if targetLocIndex == -1
			targetLocIndex = jArray.getInt(jDefenseTargetsArray, Utility.RandomInt(0, jArray.count(jDefenseTargetsArray) - 1), -1)
		endif

		if targetLocIndex == -1
			destinationScript_C = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_C = LocationDataHandler.Locations[targetLocIndex]
		endif

		CmderDestination_C.GetReference().MoveTo(destinationScript_C.MoveDestination)
		gameTimeOfLastDestinationChange_C = curGameTime

		; show quest update to tell plyr the faction has changed priorities
		if playerHandler
			SetObjectiveDisplayed(2, true, true)
		endif
	endif


	JValue.release(jAttackTargetsArray)
	JValue.zeroLifetime(jAttackTargetsArray)

	JValue.release(jDefenseTargetsArray)
	JValue.zeroLifetime(jDefenseTargetsArray)
EndFunction


; returns a jArray with zones this faction could attack
int Function FindAttackTargets()
	int i = jArray.count(jOwnedLocationIndexesArray)
	int j = 0

	
	int jPossibleAttackTargets = jArray.object()
	JValue.retain(jPossibleAttackTargets, "ShoutAndBlade")
	SAB_LocationScript[] locScripts = LocationDataHandler.Locations

	if i > 0
		; look at the locations near our own and add them to the "candidates" list
		while i > 0
			i -= 1
			int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

			if locIndex != -1
				SAB_LocationScript locScript = locScripts[locIndex]
				; check if this location is still owned by us and is enabled.
				; if not, remove it from the owneds list
				if locScript.factionScript != self || !locScript.isEnabled
					JArray.eraseIndex(jOwnedLocationIndexesArray, i)
				else
					int jNearbyLocsArray = locScript.jNearbyLocationsArray	
					j = jArray.count(jNearbyLocsArray)

					while j > 0
						j -= 1
						locIndex = jArray.getInt(jNearbyLocsArray, j, -1)
						SAB_LocationScript nearbyLocScript = locScripts[locIndex]

						if locIndex != -1
							; if we don't own the location with index locIndex, add it as a candidate for attacking
							if jArray.findInt(jOwnedLocationIndexesArray, locIndex) == -1 && \
								!DiplomacyDataHandler.AreFactionsInGoodStanding(self, nearbyLocScript.factionScript)

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
		i = LocationDataHandler.NextLocationIndex

		while i > 0
			i -= 1
			
			SAB_LocationScript locScript = locScripts[i]

			if locScript.isEnabled == true && locScript.factionScript == None
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
					
					; debug.Trace("location " + locScript.ThisLocation.GetName() + " autocalc power = " + locationPower)
				endif

			endif
		endif
	endwhile

	return jPossibleDefenseTargets

EndFunction


; destination code can be A, B or C.
; we should check if the cmder really is close to the respective xmarker, and,
; if it really is the case, assign them to the loc script!
; returns true if the cmder was assigned the loc script
bool Function ValidateCmderReachedDestination(SAB_CommanderScript commander, string cmderDestType = "a")
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
		return false
	endif
	
	if targetLocScript.IsReferenceCloseEnoughForAutocalc(cmderRef)
		; the commander has really arrived! Do stuff like autocalc battles now.
		; assign the location to the cmder, and then they'll figure out what to do when updating
		; Debug.Trace("commander has arrived and has been assigned the loc script!")
		commander.TargetLocationScript = targetLocScript
		return true
	endif

	return false
EndFunction


; returns the total gold amount the faction gets in one "gold award cycle"
int Function CalculateTotalGoldAward()
	int baseAwardedGold = JDB.solveInt(".ShoutAndBlade.factionOptions.baseGoldAward", 500)
	int baseGoldPerLoc = JDB.solveInt(".ShoutAndBlade.locationOptions.baseGoldAward", 1500)
	int totalAward = baseAwardedGold

	; add more gold per zone owned
	int i = jArray.count(jOwnedLocationIndexesArray)

	while i > 0
		i -= 1
		int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

		if locIndex != -1
			totalAward += (baseGoldPerLoc * LocationDataHandler.Locations[locIndex].GoldRewardMultiplier) as int
		endif

	endwhile

	return totalAward
EndFunction


Function AddLocationToOwnedList(SAB_LocationScript locationScript)
	int locIndex = LocationDataHandler.Locations.Find(locationScript)

	if locIndex == -1
		debug.Trace("AddLocationToOwnedList: invalid location! " + locationScript.ThisLocation.GetName() + " not found in locations array")
		return
	endif

	int locIndexInOwnedsArray = JArray.findInt(jOwnedLocationIndexesArray, locIndex)

	if locIndexInOwnedsArray == -1
		jArray.addInt(jOwnedLocationIndexesArray, locIndex)
	endif

EndFunction

Function RemoveLocationFromOwnedList(SAB_LocationScript locationScript)
	int locIndex = LocationDataHandler.Locations.Find(locationScript)

	if locIndex == -1
		debug.Trace("AddLocationToOwnedList: invalid location! " + locationScript.ThisLocation.GetName() + " not found in locations array")
		return
	endif

	JArray.eraseInteger(jOwnedLocationIndexesArray, locIndex)
	
EndFunction

; if we're still owners of the attacked loc and aren't busy defending some other loc that's also being attacked,
; change one of our defensive objectives to the attacked loc
Function ReactToLocationUnderAttack(SAB_LocationScript attackedLoc, float curGameTime)
	if attackedLoc.factionScript == self
		if destinationScript_B == None || destinationScript_B.factionScript != self || \
				(destinationScript_B.factionScript == self && !destinationScript_B.IsBeingContested()) || \
				destinationScript_B.isEnabled == false

			destinationScript_B = attackedLoc
			CmderDestination_B.GetReference().MoveTo(destinationScript_B.MoveDestination)
			gameTimeOfLastDestinationChange_B = curGameTime
		
		elseif destinationScript_B != attackedLoc && \
				(destinationScript_C == None || destinationScript_C.isEnabled == false || \
				destinationScript_C.factionScript != self || \
				(destinationScript_C.factionScript == self && !destinationScript_C.IsBeingContested()) || \
				destinationScript_C == destinationScript_B)
		
			destinationScript_C = attackedLoc
			CmderDestination_C.GetReference().MoveTo(destinationScript_C.MoveDestination)
			gameTimeOfLastDestinationChange_C = curGameTime

		endif
	endif
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

	; Debug.Trace("recruited " + recruitedAmount + " recruits for " + (recruitedAmount * goldCostPerRec) + " gold")

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

	; try to spread out our upgrades if there is more than 1 upgrade option
	i = jValue.count(jUpgradeOptions)
	int jUpgradeResultMap = jMap.object()
	int jUpgradedUnitsArray = jArray.object()
	jMap.setObj(jUpgradeResultMap, "UpgradedUnits", jUpgradedUnitsArray)
	JValue.retain(jUpgradeResultMap, "ShoutAndBlade")

	while i > 0 && unitAmount > 0
		i -= 1

		int upgradedUnitIndex = jArray.getInt(jUpgradeOptions, i, -1)
		int jUpgradedUnitData = jArray.getObj(SpawnerScript.UnitDataHandler.jSABUnitDatasArray, upgradedUnitIndex)

		if jUpgradedUnitData == 0
			jValue.release(jUpgradeOptions)
			jValue.zeroLifetime(jUpgradeOptions)
			jValue.release(jUpgradeResultMap)
			jValue.zeroLifetime(jUpgradeResultMap)
			return 0
		endif

		int goldCostPerUpg = jMap.getInt(jUpgradedUnitData, "GoldCost", 10)
		float expCostPerUpg = jMap.getFlt(jUpgradedUnitData, "ExpCost", 10.0)

		if goldCostPerUpg < currentGold && expCostPerUpg < availableExp
			int unitsToUpgrade = Utility.RandomInt(unitAmount / (i + 1), unitAmount)

			if unitsToUpgrade > 0
				int upgradedAmountConsideringExp = 0
				int upgradedAmount = 0

				; upgrade!
				; first consider gold, then exp
				if goldCostPerUpg <= 0
					upgradedAmount = unitsToUpgrade
				else
					upgradedAmount = currentGold / goldCostPerUpg
					if upgradedAmount > unitsToUpgrade
						upgradedAmount = unitsToUpgrade
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
					currentGold -= (upgradedAmount * goldCostPerUpg)
					availableExp -= (upgradedAmount * expCostPerUpg)

					unitAmount -= upgradedAmount

					int jUpgradedUnitsMap = jMap.object()

					jMap.setInt(jUpgradedUnitsMap, "NewUnitIndex", upgradedUnitIndex)
					jMap.setInt(jUpgradedUnitsMap, "NewUnitAmount", upgradedAmount)

					JArray.addObj(jUpgradedUnitsArray, jUpgradedUnitsMap)

					; Debug.Trace("upgraded " + upgradedAmount + " units for " + (upgradedAmount * goldCostPerUpg) + " gold")
				endif
			endif
			
		endif

	endwhile
	
	jMap.setFlt(jUpgradeResultMap, "RemainingExp", availableExp)

	jValue.release(jUpgradeOptions)
	JValue.zeroLifetime(jUpgradeOptions)

	return jUpgradeResultMap

endfunction


; if we can afford it and there's a free cmder slot,
; spawn a new cmder somewhere.
; (optionally spawn only if we've got double the cmder spawn cost,
;  to make sure we've got enough money to give the cmder some units)
ReferenceAlias Function TrySpawnCommander(float curGameTime, bool onlySpawnIfHasExtraMoney = false)
	; find a spawn for the cmder
	ObjectReference cmderSpawn = GetCmderSpawnPoint()

	if cmderSpawn == None
		return None
	endif

	int cmderUnitTypeIndex = jMap.getInt(jFactionData, "CmderUnitIndex")

	int cmderAliasID = GetFreeCmderAliasID()

	if cmderAliasID == -1
		return None
	endif

	ReferenceAlias cmderAlias = GetAlias(cmderAliasID) as ReferenceAlias

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

	; draw a map marker for this cmder!
	if playerHandler
		SetObjectiveDisplayed(cmderAliasID, true, false)
	endif

	return cmderAlias

EndFunction

; find a free unit slot and spawn a unit of the desired type
ReferenceAlias Function SpawnUnitForTroopContainer(SAB_TroopContainerScript troopContainer, int unitIndex, ObjectReference spawnLocation, float containerSetupTime, int cmderFollowRank = -1)
	
	if spawnLocation == None
		return None
	endif

	if unitIndex < 0
		debug.Trace("spawn unit for container: invalid unit index!")
		return None
	endif

	ReferenceAlias unitAlias = GetFreeUnitAliasSlot()

	if unitAlias == None
		debug.Trace("spawn unit for container: no free alias slot!")
		return None
	endif

	int unitIndexInUnitUpdater = UnitUpdater.UnitUpdater.RegisterAliasForUpdates(unitAlias as SAB_UnitScript, -1)

	if unitIndexInUnitUpdater == -1
		debug.Trace("spawn unit for container: unitIndexInUnitUpdater is -1!")
		return None
	endif

	Actor spawnedUnit = SpawnerScript.SpawnUnit(spawnLocation, OurFaction, unitIndex, -1, cmderFollowRank)

	if spawnedUnit == None
		debug.Trace("spawn unit for container: got none as spawnedUnit, aborting!")
		UnitUpdater.UnitUpdater.UnregisterAliasFromUpdates(unitIndexInUnitUpdater)
		return None
	endif

	unitAlias.ForceRefTo(spawnedUnit)
	(unitAlias as SAB_UnitScript).Setup(unitIndex, troopContainer, unitIndexInUnitUpdater, containerSetupTime)

	; debug.Trace("spawned unit package is " + spawnedUnit.GetCurrentPackage())

	return unitAlias

EndFunction

; when a dead commander despawns, but still had some troops,
; the faction gets some gold back, based on the gold costs of the units
Function GetGoldFromDespawningCommander(int jCmderArmyMap)
	int armyGold = SpawnerScript.UnitDataHandler.GetTotalCurrentGoldCostFromArmy(jCmderArmyMap)

	int currentGold = jMap.getInt(jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))

	debug.Trace("faction got " + armyGold + " gold back from a despawning cmder")
	jMap.setInt(jFactionData, "AvailableGold", currentGold + armyGold)
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

; returns -1 if no free ID is found
int Function GetFreeCmderAliasID()
	;the alias ids used by commanders range from 13 to 27

	int checkedAliasesCount = 0

	While checkedAliasesCount < 15
		lastCheckedCmderAliasIndex -= 1

		if lastCheckedCmderAliasIndex < 13
			lastCheckedCmderAliasIndex = 27
		endif

		ReferenceAlias cmderAlias = GetAlias(lastCheckedCmderAliasIndex) as ReferenceAlias
		
		if(!cmderAlias.GetReference())
			return lastCheckedCmderAliasIndex
		endif

		checkedAliasesCount += 1
	EndWhile
	
	return -1
endFunction


ReferenceAlias Function GetFreeUnitAliasSlot()
	;the alias ids used by units range from 28 to 127

	int checkedAliasesCount = 0

	While checkedAliasesCount < 100
		lastCheckedUnitAliasIndex -= 1

		if lastCheckedUnitAliasIndex < 28
			lastCheckedUnitAliasIndex = 127
		endif

		ReferenceAlias unitAlias = GetAlias(lastCheckedUnitAliasIndex) as ReferenceAlias
		
		if(!unitAlias.GetReference())
			return unitAlias
		endif

		checkedAliasesCount += 1
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
		i -= 1
		int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

		if locIndex != -1
			; cmders shouldn't spawn in a contested zone
			if !LocationDataHandler.Locations[locIndex].IsBeingContested()
				return LocationDataHandler.Locations[locIndex].GetInteriorSpawnPointIfPossible()
			endif
		endif

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


; returns this faction's name
string Function GetFactionName()
	return jMap.getStr(jFactionData, "name", "Faction")
endfunction

int Function GetFactionIndex()
	return factionIndex
EndFunction

; returns the amount of currently "active" commanders
; (an active cmder may not necessarily be alive, but still hasn't had their alias cleared)
int Function GetNumActiveCommanders()
	;the alias ids used by commanders range from 13 to 27
	int numActiveCmders = 0
	int i = 28

	While i > 13
		i -= 1

		ReferenceAlias cmderAlias = GetAlias(i) as ReferenceAlias
		
		if(cmderAlias.GetReference())
			numActiveCmders += 1
		endif

	EndWhile
	
	return numActiveCmders
EndFunction


Function ToggleObjectiveMarkersDisplay(bool markersEnabled)
	;the alias ids used by commanders range from 13 to 27
	int i = 28

	While i > 13
		i -= 1

		SetObjectiveDisplayed(i, markersEnabled, false)

	EndWhile

	; show markers for the destinations as well
	SetObjectiveDisplayed(0, markersEnabled, markersEnabled)
	SetObjectiveDisplayed(1, markersEnabled, markersEnabled)
	SetObjectiveDisplayed(2, markersEnabled, markersEnabled)
EndFunction

; returns the combined autocalc power of all currently "active" commanders' armies
; (an active cmder may not necessarily be alive, but still hasn't had their alias cleared)
float Function GetTotalActiveCommandersAutocalcPower()
	;the alias ids used by commanders range from 13 to 27
	float totalPower = 0
	int i = 28

	SAB_UnitDataHandler unitDataHandler = SpawnerScript.UnitDataHandler

	While i > 13
		i -= 1

		ReferenceAlias cmderAlias = GetAlias(i) as ReferenceAlias
		
		if(cmderAlias.GetReference())
			SAB_CommanderScript cmderScript = cmderAlias as SAB_CommanderScript
			totalPower += unitDataHandler.GetTotalAutocalcPowerFromArmy(cmderScript.jOwnedUnitsMap)
		endif

	EndWhile
	
	return totalPower
EndFunction