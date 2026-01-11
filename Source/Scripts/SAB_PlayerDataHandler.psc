scriptname SAB_PlayerDataHandler extends Quest
{script for setting up and getting data for mod features involving the player.}

SAB_PlayerCommanderScript Property PlayerCommanderScript Auto

SAB_FactionScript Property PlayerFaction Auto Hidden
{The SAB faction the player belongs to. Can be None}

Faction Property VanillaPlayerFaction Auto

SAB_SpawnerScript Property SpawnerScript Auto
SAB_UnitsUpdater Property UnitsUpdater Auto
SAB_FactionDataHandler Property FactionDataHandler Auto

Message Property HowManyUnitsMsg Auto
Form Property Gold001 Auto

SAB_LocationScript Property NearbyLocation Auto Hidden

int lastCheckedUnitAliasIndex = -1

; a jArray of forms, containing known recruiters from which we recruited recently
int jRecentRecruitersArray

Faction Property SAB_RecentRecruitersFaction Auto

Function Initialize()
	PlayerCommanderScript.Setup(None)
	jRecentRecruitersArray = jArray.object()
	JValue.retain(jRecentRecruitersArray, "ShoutAndBlade")
EndFunction

Function OpenPurchaseMyFactionRecruitsMenu(Actor recruiter)
	; cancel procedure if we're not in any faction
	if PlayerFaction == None
		return
	endif

	int recruitIndex = jMap.getInt(PlayerFaction.jFactionData, "RecruitUnitIndex")

	OpenPurchaseUnitsMenu(recruitIndex, recruiter, 1.0)
EndFunction

Function OpenPurchaseMercRecruitsMenu(Actor recruiter)
	; find out which faction the recruiter is part of
	SAB_FactionScript recruiterFac = FactionDataHandler.GetActorSabFaction(recruiter)

	if recruiterFac == None
		return
	endif

	int recruitIndex = jMap.getInt(recruiterFac.jFactionData, "RecruitUnitIndex")

	int spentGold = OpenPurchaseUnitsMenu(recruitIndex, recruiter, JDB.solveFlt(".ShoutAndBlade.playerOptions.mercPriceMultiplier", 3.5))
	recruiterFac.AddGold(spentGold)
EndFunction

; returns gold spent
int Function OpenPurchaseUnitsMenu(int unitIndex = -1, Actor recruiter, float priceMult = 1.0)

	if unitIndex == -1
		return 0
	endif

	int freeUnitSlots = PlayerCommanderScript.GetMaxOwnedUnitsAmount() - PlayerCommanderScript.totalOwnedUnitsAmount

	if freeUnitSlots <= 0
		Debug.Notification("You have reached your unit count limit! Level up to be able to recruit more.")
		return 0
	endif

	int numUnitsAvailable = utility.RandomInt(JDB.solveInt(".ShoutAndBlade.playerOptions.minUnitsAvailablePerRecruiter", 8), JDB.solveInt(".ShoutAndBlade.playerOptions.maxUnitsAvailablePerRecruiter", 25))

	; limit num units available according to number of free unit slots the player has
	if numUnitsAvailable > freeUnitSlots
		numUnitsAvailable = freeUnitSlots
	endif

	; figure out purchased unit's cost
	int jRecruitObj = jArray.getObj(SpawnerScript.UnitDataHandler.jSABUnitDatasArray, unitIndex)
	int goldCostPerRec = (jMap.getInt(jRecruitObj, "GoldCost", 10) * priceMult) as int

	;opens "how many units?" box, with options ranging from none to 5, depending on how much gold player has
	;the last option makes the menu open again, incrementing the desired number by 5 (5 plus the new choice)
	;this can be done indefinitely (5 plus 5 plus 5 plus 5 plus 4: you'll hire 24 units... or less, if your gold or the unit limit ends)
	int numberOfUnitsToPurchase = 0
	
	int chosenMsgBoxIndex = HowManyUnitsMsg.show(numUnitsAvailable, goldCostPerRec, numberOfUnitsToPurchase)
	while chosenMsgBoxIndex == 6 && numberOfUnitsToPurchase < numUnitsAvailable
		numberOfUnitsToPurchase += 5
		chosenMsgBoxIndex = HowManyUnitsMsg.show(numUnitsAvailable, goldCostPerRec,numberOfUnitsToPurchase)
	endwhile

	numberOfUnitsToPurchase += chosenMsgBoxIndex
	
	if chosenMsgBoxIndex == 7 || numberOfUnitsToPurchase > numUnitsAvailable ; "all" option
		numberOfUnitsToPurchase = numUnitsAvailable
	endif
	
	if numberOfUnitsToPurchase > 0
		Actor player = Game.GetPlayer()
		int playerGold = player.GetItemCount(Gold001)
	
		; clamp number of recruited units based on player's gold
		int maxUnitsPlayerCanAfford = Math.Floor(playerGold / goldCostPerRec)
	
		if numberOfUnitsToPurchase > maxUnitsPlayerCanAfford
			numberOfUnitsToPurchase = maxUnitsPlayerCanAfford
		endif
	
		; add units and deduct gold from player
		player.RemoveItem(Gold001, goldCostPerRec * numberOfUnitsToPurchase)
		PlayerCommanderScript.AddUnitsOfType(unitIndex, numberOfUnitsToPurchase)

		if recruiter != None
			; add recruiter to "recently recruited from" list, to prevent the player from just spam recruiting from one person
			recruiter.AddToFaction(SAB_RecentRecruitersFaction)
			jArray.addForm(jRecentRecruitersArray, recruiter)
		endif

		return goldCostPerRec * numberOfUnitsToPurchase
	endif
	
endFunction

Function RemoveOldestRecruiterFromRecentList()
	Form oldRecruiter = jArray.getForm(jRecentRecruitersArray, 0)
	if oldRecruiter
		Actor oldRecruiterActor = oldRecruiter as Actor

		if oldRecruiterActor
			oldRecruiterActor.RemoveFromFaction(SAB_RecentRecruitersFaction)
		endif
	endif

	jArray.eraseIndex(jRecentRecruitersArray, 0)
EndFunction

; makes the player stop deploying units, and hides all deployed ones
Function DespawnAllPlayerUnits()
	PlayerCommanderScript.ToggleNearbyUpdates(false)

	PlayerCommanderScript.DespawnAllUnits()
EndFunction


ReferenceAlias Function SpawnPlayerUnit(int unitIndex, ObjectReference spawnPoint, ObjectReference moveDestAfterSpawn, float containerSetupTime)
	if moveDestAfterSpawn == None
		return None
	endif

	if unitIndex < 0
		debug.Trace("[SAB] spawn unit for player: invalid unit index!")
		return None
	endif

	ReferenceAlias unitAlias = GetFreeUnitAliasSlot()

	if unitAlias == None
		debug.Trace("[SAB] spawn unit for player: no free alias slot!")
		return None
	endif

	int unitIndexInUnitUpdater = UnitsUpdater.UnitUpdater.RegisterAliasForUpdates(unitAlias as SAB_UnitScript, -1)

	if unitIndexInUnitUpdater == -1
		debug.Trace("[SAB] spawn unit for player: unitIndexInUnitUpdater is -1!")
		return None
	endif

	Actor spawnedUnit = SpawnerScript.SpawnUnit(spawnPoint, None, unitIndex, -1, 0)

	if spawnedUnit == None
		debug.Trace("[SAB] spawn unit for player: got none as spawnedUnit, aborting!")
		UnitsUpdater.UnitUpdater.UnregisterAliasFromUpdates(unitIndexInUnitUpdater)
		return None
	endif

	unitAlias.ForceRefTo(spawnedUnit)
	(unitAlias as SAB_UnitScript).Setup(unitIndex, PlayerCommanderScript, unitIndexInUnitUpdater, containerSetupTime)

	spawnedUnit.MoveTo(moveDestAfterSpawn)

	; debug.Trace("spawned unit package is " + spawnedUnit.GetCurrentPackage())

	return unitAlias
EndFunction

; runs procedures needed for leaving previous faction (if any) and joining the new one. 
; Target faction can be None if the player is just leaving
Function JoinFaction(SAB_FactionScript targetFaction)

	if PlayerFaction == targetFaction
		return
	endif

	; leave previous faction if any
	Actor playerActor = Game.GetPlayer()

	; make player leave previous faction, then join the new one
	if PlayerFaction != None && PlayerFaction != targetFaction
		PlayerFaction.RemovePlayerFromOurFaction(playerActor)
	endif

	PlayerFaction = targetFaction
	; if faction isn't none, set up cmder markers and quest stage
	if PlayerFaction != None
		PlayerFaction.AddPlayerToOurFaction(playerActor, self)
		SetStage(10)
	else
		SetStage(0)
	endif
	
	PlayerCommanderScript.Setup(PlayerFaction)

EndFunction


ReferenceAlias Function GetFreeUnitAliasSlot()
	;the alias ids used by units range from 3 to 102

	int checkedAliasesCount = 0

	While checkedAliasesCount < 100
		lastCheckedUnitAliasIndex -= 1

		if lastCheckedUnitAliasIndex < 3
			lastCheckedUnitAliasIndex = 102
		endif

		ReferenceAlias unitAlias = GetAlias(lastCheckedUnitAliasIndex) as ReferenceAlias
		
		if(!unitAlias.GetReference())
			return unitAlias
		endif

		checkedAliasesCount += 1
	EndWhile
	
	return None
endFunction


SAB_UnitScript Function GetSpawnedUnitOfType(int unitTypeIndex)
	;the alias ids used by units range from 3 to 102

	if unitTypeIndex < 0
		return None
	endif

	int nextAliasToCheck = 103

	While nextAliasToCheck > 3
		nextAliasToCheck -= 1

		SAB_UnitScript unitAlias = GetAlias(nextAliasToCheck) as SAB_UnitScript
		
		if(unitAlias.unitIndex == unitTypeIndex)
			return unitAlias
		endif

	EndWhile
	
	return None
endFunction

; playerData jmap entries:

; int FactionIndex - -1 for no faction

; a map of "unit index - amount" ints describing the units owned by the player
; int jPlayerTroopsMap

; it's a key with a value we don't care about! We only check if it exists. If it exists it means "enabled" to us. If it doesn't, it's "disabled".
; int autoUpgradeTroops

; only auto-upgrade if the player has more than this amount of gold
; int autoUpgradeTroopsGoldThreshold
