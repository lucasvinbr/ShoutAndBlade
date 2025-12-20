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

int Property jUnitsPendingDeploy Auto Hidden
{ array of actors, spawned units still in the hidden cell, waiting to be moved to a spawn destination }

bool Property playerIsControllingDestinations Auto Hidden
{ if true and the player is part of this faction, destinations won't be automatically changed for this faction }

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

bool function IsFactionEnabled()
	return jMap.hasKey(jFactionData, "enabled")
endfunction

bool function IsFactionMercenary()
	return jMap.hasKey(jFactionData, "IsMercenary")
endfunction

bool function CanFactionTakeLocations()
	return !jMap.hasKey(jFactionData, "CannotTakeLocations")
endfunction

; sets mutual faction relations. Doesn't edit json files, only alters the current game's relations
; 0 - Neutral
; 1 - Enemy
; 2 - Ally
; 3 - Friend
Function SetIngameRelationsWithFaction(Faction targetFaction, int relationType)
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

Function UpdatePlayerAccessToOurLocs()
	int i = jArray.count(jOwnedLocationIndexesArray)

	while i > 0
		i -= 1
		int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)
		SAB_LocationScript locScript = LocationDataHandler.GetLocationByIndex(locIndex)

		if locScript != None
			locScript.UpdateInteriorsTrespassingStatus()
		endif

	endwhile
EndFunction

; true if the plyr belongs to this fac and has set to control its destinations
bool Function IsPlayerInControlOfThisFaction()
	return playerIsControllingDestinations && playerHandler != None
endfunction

bool Function IsPlayerPartOfThisFaction()
	return playerHandler != None
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

	if IsFactionEnabled()
		if daysPassed - gameTimeOfLastRealUpdate >= JDB.solveFlt(".ShoutAndBlade.factionOptions.updateInterval", 0.025)
			gameTimeOfLastRealUpdate = daysPassed
			; Debug.Trace("updating faction " + jMap.getStr(jFactionData, "name", "Faction"))

			float goldInterval = JDB.solveFlt(".ShoutAndBlade.factionOptions.goldInterval", 0.12)
			if daysPassed - gameTimeOfLastGoldAward >= goldInterval
				int numAwardsObtained = ((daysPassed - gameTimeOfLastGoldAward) / goldInterval) as int
				int goldPerAward = CalculateTotalGoldAward()
				AddGold(goldPerAward * numAwardsObtained)
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

	if IsPlayerInControlOfThisFaction()
		; don't change destinations, player is in control!
		return
	endif

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
	if curGameTime - gameTimeOfLastDestinationChange_A > gameTimeBeforeChangeDestination || destinationScript_A == None || DiplomacyDataHandler.AreFactionsInGoodStanding(self, destinationScript_A.factionScript) || destinationScript_A.isEnabled == false

		targetLocIndex = jArray.getInt(jAttackTargetsArray, Utility.RandomInt(0, attackTargetsCount - 1), -1)

		if targetLocIndex == -1
			destinationScript_A = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_A = LocationDataHandler.GetLocationByIndex(targetLocIndex)
		endif

		if destinationScript_A != None
			CmderDestination_A.GetReference().MoveTo(destinationScript_A.MoveDestination)
		endif

		gameTimeOfLastDestinationChange_A = curGameTime

		; show quest update to tell plyr the faction has changed priorities
		if playerHandler
			SetObjectiveDisplayed(0, true, true)
		endif
	endif

	; B can be an attack or defend destination. If no "good" targets are available, fall back to a random loc, like A
	if curGameTime - gameTimeOfLastDestinationChange_B > gameTimeBeforeChangeDestination || destinationScript_B == None || destinationScript_B == destinationScript_A || !destinationScript_B.IsBeingContested() || destinationScript_B.isEnabled == false

		targetLocIndex = jArray.getInt(jDefenseTargetsArray, Utility.RandomInt(0, jArray.count(jDefenseTargetsArray) - 1), -1)

		if targetLocIndex == -1
			targetLocIndex = jArray.getInt(jAttackTargetsArray, Utility.RandomInt(0, attackTargetsCount - 1), -1)
		endif

		if targetLocIndex == -1
			destinationScript_B = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_B = LocationDataHandler.GetLocationByIndex(targetLocIndex)
		endif

		if destinationScript_B != None
			CmderDestination_B.GetReference().MoveTo(destinationScript_B.MoveDestination)
		endif
		
		gameTimeOfLastDestinationChange_B = curGameTime

		; show quest update to tell plyr the faction has changed priorities
		if playerHandler
			SetObjectiveDisplayed(1, true, true)
		endif
	endif

	; C is like B, but flipped: attack if any target is available, defend if not
	if curGameTime - gameTimeOfLastDestinationChange_C > gameTimeBeforeChangeDestination || destinationScript_C == None || destinationScript_C.isEnabled == false || !destinationScript_C.IsBeingContested() || destinationScript_C == destinationScript_B

		targetLocIndex = jArray.getInt(jAttackTargetsArray, Utility.RandomInt(0, attackTargetsCount - 1), -1)
		
		if targetLocIndex == -1
			targetLocIndex = jArray.getInt(jDefenseTargetsArray, Utility.RandomInt(0, jArray.count(jDefenseTargetsArray) - 1), -1)
		endif

		if targetLocIndex == -1
			destinationScript_C = LocationDataHandler.GetRandomLocation()
		else
			destinationScript_C = LocationDataHandler.GetLocationByIndex(targetLocIndex)
		endif

		if destinationScript_C != None
			CmderDestination_C.GetReference().MoveTo(destinationScript_C.MoveDestination)
		endif
		
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


; returns a jArray with zones this faction could attack. A location may be added more than once to the list!
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
				SAB_LocationScript locScript = LocationDataHandler.GetLocationByIndex(locIndex)

				if locScript != None
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
							SAB_LocationScript nearbyLocScript = LocationDataHandler.GetLocationByIndex(locIndex)

							if locIndex != -1 && nearbyLocScript != None && nearbyLocScript.isEnabled
								; if we don't own the location with index locIndex, add it as a candidate for attacking
								if jArray.findInt(jOwnedLocationIndexesArray, locIndex) == -1 && !DiplomacyDataHandler.AreFactionsInGoodStanding(self, nearbyLocScript.factionScript)

									JArray.addInt(jPossibleAttackTargets, locIndex)
								endif
							endif
						endwhile

					endif
				endif
				
			endif
		endwhile	
	else 
		; we don't have any location!
		; look for neutral ones for an easier target

		if CanFactionTakeLocations()
			i = LocationDataHandler.NextLocationIndex
			while i > 0
				i -= 1
				
				SAB_LocationScript locScript = LocationDataHandler.GetLocationByIndex(i) 

				if locScript != None && locScript.isEnabled == true && locScript.factionScript == None
					JArray.addInt(jPossibleAttackTargets, i)
				endif
			endwhile
		endif
	endif


	if jArray.count(jPossibleAttackTargets) <= 0
		; no "really good" targets found!
		; we're probably in a good situation, like with more than one location, or surrounded by allies.
		; it's time to take the fight to any enemies left

		i = LocationDataHandler.NextLocationIndex

		while i > 0
			i -= 1

			SAB_LocationScript locScript = LocationDataHandler.GetLocationByIndex(i)
			; check if this location is still owned by us and is enabled.
			; if not, remove it from the owneds list
			if locScript != None && locScript.isEnabled && !DiplomacyDataHandler.AreFactionsInGoodStanding(self, locScript.factionScript)
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
			SAB_LocationScript locScript = LocationDataHandler.GetLocationByIndex(locIndex)
			; check if this location is still valid and owned by us
			if locScript == None || locScript.factionScript != self || !locScript.isEnabled
				JArray.eraseIndex(jOwnedLocationIndexesArray, i)
			else

				if locScript.IsBeingContested()
					JArray.addInt(jPossibleDefenseTargets, locIndex)
				else
					;float locationPower = SpawnerScript.UnitDataHandler.GetTotalAutocalcPowerFromArmy(locScript.jOwnedUnitsMap)
					float locationPower = locScript.currentAutocalcPower

					if locationPower < JDB.solveFlt(".ShoutAndBlade.factionOptions.safeLocationPower", 32.0)
						JArray.addInt(jPossibleDefenseTargets, locIndex)
					endif
					
					; debug.Trace("location " + locScript.GetLocName() + " autocalc power = " + locationPower)
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
		commander.RegisterAsNearLocation(targetLocScript)

		if targetLocScript.factionScript != self && !CanFactionTakeLocations()
			; if we can't take locs,
			; go away from this loc if it's being contested
			if targetLocScript.IsBeingContested()
				if cmderDestType == "a" || cmderDestType == "A"
					gameTimeOfLastDestinationChange_A = 0.0
				elseif cmderDestType == "b" || cmderDestType == "B"
					gameTimeOfLastDestinationChange_B = 0.0
				elseif cmderDestType == "c" || cmderDestType == "C"
					gameTimeOfLastDestinationChange_C = 0.0
				endif
			endif
		endif
		return true
	endif

	return false
EndFunction

; true if at least one of dests a,b,c are set to this loc
bool Function IsLocationOneOfThisFacsDestinations(SAB_LocationScript locScript)
	return destinationScript_A == locScript || destinationScript_B == locScript || destinationScript_C == locScript
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
		SAB_LocationScript locScript = LocationDataHandler.GetLocationByIndex(locIndex)

		if locIndex != -1 && locScript != None
			totalAward += (baseGoldPerLoc * locScript.GoldRewardMultiplier) as int
		endif

	endwhile

	return totalAward
EndFunction


Function AddLocationToOwnedList(SAB_LocationScript locationScript)
	If locationScript == None
		return
	EndIf

	int locIndex = LocationDataHandler.GetLocationIndexById(locationScript.GetLocId())

	if locIndex == -1
		debug.Trace("AddLocationToOwnedList: invalid location! " + locationScript.GetLocName() + " not found in locations array")
		return
	endif

	int locIndexInOwnedsArray = JArray.findInt(jOwnedLocationIndexesArray, locIndex)

	if locIndexInOwnedsArray == -1
		jArray.addInt(jOwnedLocationIndexesArray, locIndex)
	endif

EndFunction

Function RemoveLocationFromOwnedList(SAB_LocationScript locationScript)
	If locationScript == None
		return
	EndIf

	int locIndex = LocationDataHandler.GetLocationIndexById(locationScript.GetLocId())

	if locIndex == -1
		debug.Trace("AddLocationToOwnedList: invalid location! " + locationScript.GetLocName() + " not found in locations array")
		return
	endif

	JArray.eraseInteger(jOwnedLocationIndexesArray, locIndex)
	
EndFunction

Function PlayerSetFacDestination(string cmderDestType = "a", SAB_LocationScript newDestination)
	if newDestination == None
		return
	endif
	
	ObjectReference cmderDest = CmderDestination_A.GetReference()

	if cmderDestType == "a" || cmderDestType == "A"
		cmderDest = CmderDestination_A.GetReference()
		destinationScript_A = newDestination
		SetObjectiveDisplayed(0, true, true)
	elseif cmderDestType == "b" || cmderDestType == "B"
		cmderDest = CmderDestination_B.GetReference()
		destinationScript_B = newDestination
		SetObjectiveDisplayed(1, true, true)
	elseif cmderDestType == "c" || cmderDestType == "C"
		cmderDest = CmderDestination_C.GetReference()
		destinationScript_C = newDestination
		SetObjectiveDisplayed(2, true, true)
	endif

	cmderDest.MoveTo(newDestination.MoveDestination)
	
EndFunction

; if we're still owners of the attacked loc and aren't busy defending some other loc that's also being attacked,
; change one of our defensive objectives to the attacked loc
Function ReactToLocationUnderAttack(SAB_LocationScript attackedLoc, float curGameTime)

	if attackedLoc.factionScript == self
		if IsPlayerInControlOfThisFaction()
			; don't change dests, just notify player about the attack if the loc isn't marked as dest already
			if destinationScript_A != attackedLoc && destinationScript_B != attackedLoc && destinationScript_C != attackedLoc
				Debug.Notification(attackedLoc.GetLocName() + " is under attack!")
			endif

			return
		endif

		if destinationScript_B == None || destinationScript_B.factionScript != self || (destinationScript_B.factionScript == self && !destinationScript_B.IsBeingContested()) || destinationScript_B.isEnabled == false

			destinationScript_B = attackedLoc
			CmderDestination_B.GetReference().MoveTo(destinationScript_B.MoveDestination)
			gameTimeOfLastDestinationChange_B = curGameTime
		
		elseif destinationScript_B != attackedLoc && (destinationScript_C == None || destinationScript_C.isEnabled == false || destinationScript_C.factionScript != self || (destinationScript_C.factionScript == self && !destinationScript_C.IsBeingContested()) || destinationScript_C == destinationScript_B)
		
			destinationScript_C = attackedLoc
			CmderDestination_C.GetReference().MoveTo(destinationScript_C.MoveDestination)
			gameTimeOfLastDestinationChange_C = curGameTime

		endif
	endif
EndFunction


; spends gold and returns a number of recruits "purchased".
; the caller should do something with this number
int function PurchaseRecruits(int maxAmountPurchased = 100)

	if !IsFactionEnabled()
		return 0
	endif

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

	int jBaseUnitData = jArray.getObj(SpawnerScript.UnitDataHandler.jSABUnitDatasArray, unitIndex)

	if jBaseUnitData == 0
		; bad base unit
		return 0
	endif

	int jUpgradeOptions = jMap.getObj(jBaseUnitData, "jUpgradeOptionsArray")

	; try to spread out our upgrades if there is more than 1 upgrade option
	int i = jValue.count(jUpgradeOptions)

	if i == 0
		; no upgrades for the picked unit! abort
		return 0
	endif

	int jUpgradeResultMap = jMap.object()
	int jUpgradedUnitsArray = jArray.object()
	jMap.setObj(jUpgradeResultMap, "UpgradedUnits", jUpgradedUnitsArray)
	JValue.retain(jUpgradeResultMap, "ShoutAndBlade")

	while i > 0 && unitAmount > 0
		i -= 1

		int upgradedUnitIndex = jArray.getInt(jUpgradeOptions, i, -1)
		int jUpgradedUnitData = jArray.getObj(SpawnerScript.UnitDataHandler.jSABUnitDatasArray, upgradedUnitIndex)

		if jUpgradedUnitData == 0
			; bad data! abort
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
	; find a spawn for the cmder.
	; prioritize mod locations
	SAB_LocationScript spawnLoc = GetLocationForCmderSpawn()
	ObjectReference cmderSpawn = None

	if(spawnLoc != None)
		cmderSpawn = spawnLoc.GetInteriorSpawnPointIfPossible()
	else
		cmderSpawn = GetCmderSpawnPoint()
	endif

	if cmderSpawn == None
		return None
	endif

	int cmderUnitTypeIndex = jMap.getInt(jFactionData, "CmderUnitIndex")

	int cmderAliasID = GetFreeCmderAliasID()

	if cmderAliasID == -1
		return None
	endif

	SAB_CommanderScript cmderAlias = GetAlias(cmderAliasID) as SAB_CommanderScript

	; check if we can afford creating a new cmder
	int cmderCost = JDB.solveInt(".ShoutAndBlade.factionOptions.createCmderCost", 250)

	float extraCmderCostPercent = JDB.solveFlt(".ShoutAndBlade.factionOptions.createCmderCostPercent", 10.0) / 100.0

	int currentGold = jMap.getInt(jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))

	cmderCost += (currentGold * extraCmderCostPercent) as int

	if (!onlySpawnIfHasExtraMoney && currentGold < cmderCost) || (onlySpawnIfHasExtraMoney && currentGold < JDB.solveInt(".ShoutAndBlade.factionOptions.minCmderGold", 600))
		return None
	endif

	Actor cmderUnit = SpawnerScript.SpawnUnit(cmderAlias.CrowdReducer.BodyDumpReference, None, cmderUnitTypeIndex)

	if cmderUnit == None
		debug.Trace("spawn cmder: cmderUnit is null!")
		return None
	endif

	If IsFactionMercenary()
		cmderUnit.AddToFaction(DiplomacyDataHandler.FactionDataHandler.MercDealerFaction)
	EndIf

	cmderAlias.ForceRefTo(cmderUnit)
	cmderAlias.Setup(self, curGameTime)

	cmderUnit.MoveTo(cmderSpawn)
	; debug.Trace("spawned cmder package is " + cmderUnit.GetCurrentPackage())

	jMap.setInt(jFactionData, "AvailableGold", currentGold - cmderCost)

	; draw a map marker for this cmder!
	if playerHandler
		SetObjectiveDisplayed(cmderAliasID, true, false)
	endif

	; if spawned in a location, register cmder as nearby
	if spawnLoc != None
		; don't attack random locs like this if the player is in control!
		; the player should have more control over their diplomacy
		if !playerIsControllingDestinations
			cmderAlias.RegisterAsNearLocation(spawnLoc)
		endif
		
	endif

	return cmderAlias

EndFunction

; find a free unit slot and spawn a unit of the desired type
ReferenceAlias Function SpawnUnitForTroopContainer(SAB_TroopContainerScript troopContainer, int unitIndex, ObjectReference spawnLocation, ObjectReference moveDestAfterSpawn, float containerSetupTime, int cmderFollowRank = -1, bool moveNow = true)
	
	if moveDestAfterSpawn == None
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

	Actor spawnedUnit = SpawnerScript.SpawnUnit(spawnLocation, None, unitIndex, -1, cmderFollowRank)

	if spawnedUnit == None
		debug.Trace("spawn unit for container: got none as spawnedUnit, aborting!")
		UnitUpdater.UnitUpdater.UnregisterAliasFromUpdates(unitIndexInUnitUpdater)
		return None
	endif

	If IsFactionMercenary()
		spawnedUnit.AddToFaction(DiplomacyDataHandler.FactionDataHandler.MercDealerFaction)
	EndIf

	unitAlias.ForceRefTo(spawnedUnit)
	(unitAlias as SAB_UnitScript).Setup(unitIndex, troopContainer, unitIndexInUnitUpdater, containerSetupTime)

	If moveNow
		spawnedUnit.MoveTo(moveDestAfterSpawn)
	else
		jArray.AddForm(jUnitsPendingDeploy, spawnedUnit)
	endif
	; 

	; debug.Trace("spawned unit package is " + spawnedUnit.GetCurrentPackage())

	return unitAlias

EndFunction

; when a dead commander despawns, but still had some troops,
; the faction gets some gold back, based on the gold costs of the units
Function GetGoldFromDespawningCommander(int jCmderArmyMap)
	int armyGold = SpawnerScript.UnitDataHandler.GetTotalCurrentGoldCostFromArmy(jCmderArmyMap)
	int cmderSpawnCost = JDB.solveInt(".ShoutAndBlade.factionOptions.createCmderCost", 250)

	float extraCmderCostPercent = JDB.solveFlt(".ShoutAndBlade.factionOptions.createCmderCostPercent", 10.0) / 100.0
	int currentGold = jMap.getInt(jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))

	cmderSpawnCost += (currentGold * extraCmderCostPercent) as int

	armyGold += cmderSpawnCost

	debug.Trace("faction got " + armyGold + " gold back from a despawning cmder")
	AddGold(armyGold)
EndFunction

Function AddGold(int goldAmount)
	int currentGold = jMap.getInt(jFactionData, "AvailableGold", JDB.solveInt(".ShoutAndBlade.factionOptions.initialGold", SAB_FactionDataHandler.GetDefaultFactionGold()))
	jMap.setInt(jFactionData, "AvailableGold", currentGold + goldAmount)
EndFunction


Function DeployPendingUnits(ObjectReference spawnPoint, bool setAlert)
	if spawnPoint == None
		return
	endif

	If jUnitsPendingDeploy == 0
		jUnitsPendingDeploy = jArray.object()
		jValue.retain(jUnitsPendingDeploy, "ShoutAndBlade")
	EndIf

	int i = jArray.count(jUnitsPendingDeploy)

	if i <= 0
		return
	endif

	; ; if we're on alert, we should find an enemy to start fighting as soon as we spawn
	Actor targetEnemy = none
	SAB_CrowdReducer crowdReducer = DiplomacyDataHandler.PlayerDataHandler.PlayerCommanderScript.CrowdReducer
	int jUnitsMap = crowdReducer.jLivingUnitsMap
	int j = jIntMap.count(jUnitsMap)
	int count = 0

	; iterate over facs with living units, looking for an enemy fac, then get one of their units
	while j > 0
		j -= 1
		int facIndexWithUnits = jIntMap.getNthKey(jUnitsMap, j)
		int jFacUnitsArr = jIntMap.getObj(jUnitsMap, facIndexWithUnits)
		int unitCount = jArray.count(jFacUnitsArr)
		
		if unitCount > 0
			if DiplomacyDataHandler.AreFactionsEnemies(factionIndex, facIndexWithUnits)
				targetEnemy = jArray.getForm(jFacUnitsArr, Utility.RandomInt(0, unitCount - 1)) as Actor
			endif
		endif
		
		
		If targetEnemy != none && !targetEnemy.IsDead()
			; got good enemy! break loop
			j = -1
		EndIf

	endwhile

	while i > 0
		i -= 1
		Actor pendingUnit = jArray.getForm(jUnitsPendingDeploy, i) as Actor

		pendingUnit.MoveTo(spawnPoint)
		if setAlert
			pendingUnit.SetAlert(true)
			if targetEnemy != none
				; pendingUnit.EnableAI(true)
				; pendingUnit.EvaluatePackage()
				; pendingUnit.StartCombat(targetEnemy)
				; targetEnemy.CreateDetectionEvent(pendingUnit, 100)
				targetEnemy.DoCombatSpellApply(SpawnerScript.NewlySpawnedInCombatSpell, pendingUnit)
			endif
		endif
		jArray.eraseIndex(jUnitsPendingDeploy, i)
		
	endwhile

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

; returns the first living unit we find that "belongs" to the troop container
SAB_UnitScript Function GetASpawnedUnitFromContainer(SAB_TroopContainerScript troopcontainer)
	;the alias ids used by units range from 28 to 127

	int checkedAliasesCount = 0

	While checkedAliasesCount < 100
		lastCheckedUnitAliasIndex -= 1

		if lastCheckedUnitAliasIndex < 28
			lastCheckedUnitAliasIndex = 127
		endif

		SAB_UnitScript unitAlias = GetAlias(lastCheckedUnitAliasIndex) as SAB_UnitScript

		if(unitAlias.GetOwnerContainer() == troopcontainer && unitAlias.IsAlive())
			return unitAlias
		endif

		checkedAliasesCount += 1
	EndWhile
	
	return None
endFunction

; returns the first living unit we find that "belongs" to the provided troop container
SAB_UnitScript Function GetSpawnedUnitOfTypeFromContainer(SAB_TroopContainerScript troopcontainer, int unitTypeIndex)
	;the alias ids used by units range from 28 to 127

	int checkedAliasesCount = 0

	While checkedAliasesCount < 100
		lastCheckedUnitAliasIndex -= 1

		if lastCheckedUnitAliasIndex < 28
			lastCheckedUnitAliasIndex = 127
		endif

		SAB_UnitScript unitAlias = GetAlias(lastCheckedUnitAliasIndex) as SAB_UnitScript

		if(unitAlias.GetOwnerContainer() == troopcontainer && unitAlias.IsAlive() && unitAlias.unitIndex == unitTypeIndex)
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

SAB_LocationScript function GetLocationForCmderSpawn()
	int i = jArray.count(jOwnedLocationIndexesArray)

	while i > 0
		i -= 1
		int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

		if locIndex != -1
			; cmders shouldn't spawn in a contested zone
			SAB_LocationScript locScript = LocationDataHandler.GetLocationByIndex(locIndex)
			if locScript != None && !locScript.IsBeingContested()
				return locScript
			endif
		endif

	endwhile

	int numRandomAttempts = 0
	while numRandomAttempts < 10
		SAB_LocationScript pickedLoc = LocationDataHandler.GetRandomLocation()
		if !pickedLoc.isNearby && !pickedLoc.IsBeingContested()
			return pickedLoc
		endif

		numRandomAttempts += 1
	endwhile
endfunction

; returns a spawn point from one of our locations, or a random preset one if we don't control any location and we haven't set the fallback point
ObjectReference function GetCmderSpawnPoint()
	int i = jArray.count(jOwnedLocationIndexesArray)

	while i > 0
		i -= 1
		int locIndex = jArray.getInt(jOwnedLocationIndexesArray, i, -1)

		if locIndex != -1
			; cmders shouldn't spawn in a contested zone
			SAB_LocationScript locScript = LocationDataHandler.GetLocationByIndex(locIndex)
			if locScript != None && !locScript.IsBeingContested()
				return locScript.GetInteriorSpawnPointIfPossible()
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

	; try to spawn them in random uncontested locs away from the player
	while numRandomAttempts < 10
		SAB_LocationScript pickedLoc = LocationDataHandler.GetRandomLocation()
		if !pickedLoc.isNearby && !pickedLoc.IsBeingContested()
			return pickedLoc.GetInteriorSpawnPointIfPossible()
		endif

		numRandomAttempts += 1
	endwhile

	; no good loc? use one of the default ones
	while numRandomAttempts < 20
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
			totalPower += cmderScript.currentAutocalcPower
			;totalPower += unitDataHandler.GetTotalAutocalcPowerFromArmy(cmderScript.jOwnedUnitsMap)
		endif

	EndWhile
	
	return totalPower
EndFunction