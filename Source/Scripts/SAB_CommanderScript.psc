Scriptname SAB_CommanderScript extends SAB_TroopContainerScript  

; cached refs for not fetching all the time
Actor meActor

int Property CmderFollowFactionRank Auto
{ the rank in the "cmderFollowerFaction" referring to this commander. Units in this rank should follow this cmder }

string Property CmderDestinationType Auto
{ can be "A", "B" or "C". Defines which of the 3 faction destinations this cmder will always go to }

; reference to the location we're fighting against or trying to take over.
; this should only have a real value if we're close enough to this location
SAB_LocationScript Property TargetLocationScript Auto

Function Setup(SAB_FactionScript factionScriptRef, float curGameTime = 0.0)
	meActor = GetReference() as Actor
	TargetLocationScript = None
	parent.Setup(factionScriptRef, curGameTime)
EndFunction

; sets isNearby and enables or disables closeBy updates
Function ToggleNearbyUpdates(bool updatesEnabled)
	
	; debug.Trace("commander: toggleNearbyUpdates " + updatesEnabled)
	; debug.Trace("commander: indexInCloseByUpdater " + indexInCloseByUpdater)
	if updatesEnabled
		isNearby = true
		if indexInCloseByUpdater == -1
			indexInCloseByUpdater = CloseByUpdater.CmderUpdater.RegisterAliasForUpdates(self)
			debug.Trace("commander: began closebyupdating!")
		endif
	elseif !updatesEnabled
		isNearby = false
		if indexInCloseByUpdater != -1
			CloseByUpdater.CmderUpdater.UnregisterAliasFromUpdates(indexInCloseByUpdater)
			indexInCloseByUpdater = -1
			debug.Trace("commander: stopped closebyupdating!")
		endif
	endif

EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)

	if updateIndex == 1
		return RunCloseByUpdate()
	endif

	if curGameTime != 0.0 && gameTimeOfLastExpAward == 0.0
		; set initial values for "gameTime" variables, to avoid them from getting huge accumulated awards
		gameTimeOfLastExpAward = curGameTime
	endif

	;debug.Trace("game time updating commander (pre check)!")
	if curGameTime - gameTimeOfLastExpAward >= 0.1 ; TODO make this configurable
		int numAwardsObtained = ((curGameTime - gameTimeOfLastExpAward) / 0.1) as int
		availableExpPoints += 500.0 * numAwardsObtained ; TODO make this configurable
		gameTimeOfLastExpAward = curGameTime
	endif
	
	if !meActor
		debug.Trace("WARNING: attempted to update commander which had an invalid (maybe None?) reference!")
		ClearCmderData()
		return true
	endif

	float distToPlayer = playerActor.GetDistance(meActor)
	; debug.Trace("dist to player from cmder of faction " + jMap.getStr(factionScript.jFactionData, "name", "Faction") + ": " + distToPlayer)

	ToggleNearbyUpdates(distToPlayer <= 8000.0)

	if !meActor.IsDead()
		if !meActor.IsInCombat()
			;debug.Trace("game time updating commander!")

			if curGameTime - gameTimeOfLastUnitUpgrade >= 0.06 ; TODO make this configurable
				gameTimeOfLastUnitUpgrade = curGameTime

				; if we have enough units, upgrade. If we don't, recruit some more
				if totalOwnedUnitsAmount >= GetMaxOwnedUnitsAmount() * 0.7
					TryUpgradeUnits()
				else 
					TryRecruitUnits()
				endif
			endif

			if TargetLocationScript != None
				bool cmderCanAutocalc = TargetLocationScript.IsActorCloseEnoughForAutocalc(meActor)

				if !cmderCanAutocalc
					; we're too far away from the target loc, disengage
					if TargetLocationScript.InteractingCommander == self
						TargetLocationScript.InteractingCommander = None
					endif
					TargetLocationScript = None
				else
					if TargetLocationScript.factionScript == factionScript
						; attempt to reinforce the location if it's undermanned
						if TargetLocationScript.totalOwnedUnitsAmount < TargetLocationScript.GetMaxOwnedUnitsAmount()
							; mark ourselves as interacting so that we can be attacked instead of the location
							TargetLocationScript.InteractingCommander = self
							TryTransferUnitsToAnotherContainer(TargetLocationScript)
						endif
					else 
						if !isNearby
							; if the player is far away, do autocalc fights!
							; if any cmder is currently interacting with the location, we fight them first
							if TargetLocationScript.InteractingCommander != None && TargetLocationScript.InteractingCommander != self
								if TargetLocationScript.InteractingCommander.factionScript != factionScript

									DoAutocalcBattle(TargetLocationScript.InteractingCommander)
									; if the interacting cmder has just been defeated and we're still standing,
									; mark ourselves as the currently interacting ones
									if totalOwnedUnitsAmount > 0 && TargetLocationScript.InteractingCommander == None
										TargetLocationScript.InteractingCommander = self
									endif
									return true
								endif
							elseif TargetLocationScript.factionScript != None
								; do an autocalc fight against the location's units!
								TargetLocationScript.InteractingCommander = self
								DoAutocalcBattle(TargetLocationScript)
								return true
							else
								; the location is neutral! Let's take it
								TargetLocationScript.InteractingCommander = self
								TargetLocationScript.BeTakenByFaction(factionScript)
							endif
						endif
					endif
				endif
			endif
			
			; Utility.Wait(0.01)
			meActor.EvaluatePackage()
			
		endif
	else 
		if ClearAliasIfOutOfTroops()
			return true
		else
			if !isNearby
				ClearCmderData()
			endif
		endif
	endif

	return true
endfunction


Function SpawnUnit(int unitIndex)
	Debug.Trace("cmder: spawn unit begin!")
	ObjectReference spawnLocation = meActor

	if meActor.IsInCombat()
		spawnLocation = factionScript.UnitSpawnPoint.GetReference()
	endif

	ReferenceAlias spawnedUnit = factionScript.SpawnUnitForTroopContainer(self, unitIndex, spawnLocation, gameTimeOfLastSetup, CmderFollowFactionRank)

	if spawnedUnit != None
		; add spawned unit index to spawneds list
		int currentSpawnedAmount = jIntMap.getInt(jSpawnedUnitsMap, unitIndex)
		jIntMap.setInt(jSpawnedUnitsMap, unitIndex, currentSpawnedAmount + 1)

		spawnedUnitsAmount += 1
	endif
EndFunction

Event OnPackageEnd(Package akOldPackage)
	; this is kind of reliable
	factionScript.ValidateCmderReachedDestination(self)
EndEvent

Event OnCombatStateChanged(Actor akTarget, int aeCombatState)
	debug.Trace("commander: combat state changed!")
	if aeCombatState == 1 || aeCombatState == 2 ; engaging or searching
		ToggleNearbyUpdates(true)
		; if the current spawn is too far away,
		; update the faction's unit spawn point to where this cmder started combat
		ObjectReference unitSpawn = factionScript.UnitSpawnPoint.GetReference()
		if unitSpawn.GetDistance(meActor) > 800.0
			unitSpawn.MoveTo(meActor)
		endif
	endif
EndEvent

event OnDeath(Actor akKiller)	
	debug.Trace("commander: dead!")
	ClearAliasIfOutOfTroops()
endEvent

; returns true if out of troops and cleared
bool Function ClearAliasIfOutOfTroops()
	debug.Trace("commander (" + jMap.getStr(factionScript.jFactionData, "name", "Faction") + "): clear alias if out of troops!")
	debug.Trace("dead commander: totalOwnedUnitsAmount: " + totalOwnedUnitsAmount)
	debug.Trace("dead commander: spawnedUnitsAmount: " + spawnedUnitsAmount)
	debug.Trace("dead commander: troops left: " + totalOwnedUnitsAmount)
	if totalOwnedUnitsAmount <= 0
		ClearCmderData()
		return true
	endif

	return false
EndFunction

Function HandleAutocalcDefeat()
	ClearCmderData()
	meActor.Disable(false)
	meActor.Delete()
EndFunction

; clears the alias and stops updates
Function ClearCmderData()
	debug.Trace("commander: clear cmder data!")

	if TargetLocationScript != None
		if TargetLocationScript.InteractingCommander == self
			TargetLocationScript.InteractingCommander = None
		endif
	endif

	Clear()
	ToggleNearbyUpdates(false)
	ToggleUpdates(false)

EndFunction

int Function GetMaxOwnedUnitsAmount()
	return 30 ; TODO make this configurable
EndFunction