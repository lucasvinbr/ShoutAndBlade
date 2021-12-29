scriptname SAB_BackgroundUpdater extends Quest
{ updater for things the player can't see right away, like factions and distant commanders }

SAB_FactionScript[] SAB_FactionScripts

SAB_AliasUpdater Property BackgroundCmderUpdater Auto
SAB_AliasUpdater Property BackgroundLocationUpdater Auto

GlobalVariable Property GameDaysPassed Auto

int updatedFactionIndex = -1

bool hasUpdatedFaction = false

function Initialize(SAB_FactionScript[] factionScriptsArray)
	debug.Trace("background updater: initialize!")
	SAB_FactionScripts = factionScriptsArray
	BackgroundCmderUpdater.Initialize()
	RegisterForSingleUpdate(1.0)
endfunction


Event OnUpdate()
	 debug.Trace("background updater: start loop!")

	while true
		; debug.Trace("background updater loop begin")

		UpdateCurrentInstanceGlobal(GameDaysPassed)
		float daysPassed = GameDaysPassed.GetValue()

		hasUpdatedFaction = false

		while !hasUpdatedFaction && updatedFactionIndex >= 0
			hasUpdatedFaction = SAB_FactionScripts[updatedFactionIndex].RunUpdate(daysPassed)
			updatedFactionIndex -= 1
		endwhile

		if updatedFactionIndex < 0
			updatedFactionIndex = SAB_FactionScripts.Length - 1
		endif
		
		Utility.Wait(0.08)

		BackgroundCmderUpdater.RunUpdate(daysPassed, 0)

		Utility.Wait(0.08)

		BackgroundLocationUpdater.RunUpdate(daysPassed, 0)

		Utility.Wait(0.08)
		; debug.Trace("background updater loop end")
	endwhile
EndEvent