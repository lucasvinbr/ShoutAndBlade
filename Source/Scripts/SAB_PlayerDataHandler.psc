scriptname SAB_PlayerDataHandler extends Quest
{script for setting up and getting data for mod features involving the player.}

SAB_PlayerCommanderScript Property PlayerCommanderScript Auto


ReferenceAlias Function SpawnPlayerUnit(int unitIndex, ObjectReference targetLocation, float containerSetupTime)
	; TODO copy factionScript spawn procedure, fetching empty aliases from the player quest instead of faction quest
EndFunction

; playerData jmap entries:

; int FactionIndex - -1 for no faction

; a map of "unit index - amount" ints describing the units owned by the player
; int jPlayerTroopsMap

; it's a key with a value we don't care about! We only check if it exists. If it exists it means "enabled" to us. If it doesn't, it's "disabled".
; int autoUpgradeTroops

; only auto-upgrade if the player has more than this amount of gold
; int autoUpgradeTroopsGoldThreshold
