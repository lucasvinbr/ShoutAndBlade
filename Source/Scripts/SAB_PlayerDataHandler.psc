scriptname SAB_PlayerDataHandler extends Quest
{script for setting up and getting data for mod features involving the player.}

SAB_PlayerCommanderScript Property PlayerCommanderScript Auto

SAB_FactionScript Property PlayerFaction Auto Hidden


Function Initialize()
	; code
EndFunction


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
	if PlayerFaction != targetFaction
		PlayerFaction.RemovePlayerFromOurFaction(playerActor)
	endif

	PlayerFaction = targetFaction
	; if faction isn't none, set up cmder markers
	if PlayerFaction != None
		PlayerFaction.AddPlayerToOurFaction(playerActor, self)
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
