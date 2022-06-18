scriptname SAB_PlayerDataHandler extends Quest
{script for setting up and getting data for mod features involving the player.}

SAB_PlayerCommanderScript Property PlayerCommanderScript Auto

SAB_FactionScript Property PlayerFaction Auto Hidden

SAB_SpawnerScript Property SpawnerScript Auto

Message Property HowManyUnitsMsg Auto
Form Property Gold001 Auto

Function Initialize()
	; code
EndFunction

Function OpenPurchaseRecruitsMenu()
	; cancel procedure if we're not in any faction
	if PlayerFaction == None
		return
	endif

	int recruitIndex = jMap.getInt(PlayerFaction.jFactionData, "RecruitUnitIndex")

	OpenPurchaseUnitsMenu(recruitIndex)
EndFunction

Function OpenPurchaseUnitsMenu(int unitIndex = -1)

	if unitIndex == -1
		return
	endif

	int numUnitsAvailable = utility.RandomInt(2, 25) ; TODO make this configurable (max and min units available per recruiter)

	; figure out purchased unit's cost
	int jRecruitObj = jArray.getObj(SpawnerScript.UnitDataHandler.jSABUnitDatasArray, unitIndex)
	int goldCostPerRec = jMap.getInt(jRecruitObj, "GoldCost", 10)

	;opens "how many units?" box, with options ranging from none to 5, depending on how much gold player has
	;the last option makes the menu open again, incrementing the desired number by 5 (5 plus the new choice)
	;this can be done indefinitely (5 plus 5 plus 5 plus 5 plus 4: you'll hire 24 units... or less, if your gold or the unit limit ends)
	int numberOfUnitsToPurchase = 0
	
	int chosenMsgBoxIndex = HowManyUnitsMsg.show(numUnitsAvailable, numUnitsAvailable, numberOfUnitsToPurchase, goldCostPerRec)
	while chosenMsgBoxIndex == 6
		numberOfUnitsToPurchase += 5
		chosenMsgBoxIndex = HowManyUnitsMsg.show(numUnitsAvailable, numUnitsAvailable, numberOfUnitsToPurchase, goldCostPerRec)
	endwhile

	numberOfUnitsToPurchase += chosenMsgBoxIndex
	
	if chosenMsgBoxIndex == 7 ; "all" option
		numberOfUnitsToPurchase = numUnitsAvailable
	endif
	
	
	Actor player = Game.GetPlayer()
	int playerGold = player.GetItemCount(Gold001)

	; clamp number of recruited units based on player's gold
	int maxUnitsPlayerCanAfford = playerGold % goldCostPerRec

	if numberOfUnitsToPurchase > maxUnitsPlayerCanAfford
		numberOfUnitsToPurchase = maxUnitsPlayerCanAfford
	endif

	; add units and deduct gold from player
	player.RemoveItem(Gold001, goldCostPerRec * numberOfUnitsToPurchase)
	PlayerCommanderScript.AddUnitsOfType(unitIndex, numberOfUnitsToPurchase)
	
endFunction



ReferenceAlias Function SpawnPlayerUnit(int unitIndex, ObjectReference targetLocation, float containerSetupTime)
	; TODO copy factionScript spawn procedure, fetching empty aliases from the player quest instead of faction quest
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
	
EndFunction


; playerData jmap entries:

; int FactionIndex - -1 for no faction

; a map of "unit index - amount" ints describing the units owned by the player
; int jPlayerTroopsMap

; it's a key with a value we don't care about! We only check if it exists. If it exists it means "enabled" to us. If it doesn't, it's "disabled".
; int autoUpgradeTroops

; only auto-upgrade if the player has more than this amount of gold
; int autoUpgradeTroopsGoldThreshold
