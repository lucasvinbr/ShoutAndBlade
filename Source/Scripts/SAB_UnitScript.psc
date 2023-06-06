Scriptname SAB_UnitScript extends SAB_UpdatedReferenceAlias  

; the unit type index of this unit
int Property unitIndex = -1 auto hidden

; reference to the troop container that spawned us. If we die/despawn, we should tell them
SAB_TroopContainerScript ownerTroopContainer

; ownerTroopContainer, cast to Location
SAB_LocationScript ownerContainerLocation

Actor meActor
Actor Property playerActor Auto
SAB_CrowdReducer Property CrowdReducer Auto

bool deathHasBeenHandled = false

; since there are times when units outlive their owners,
; this is used to know whether the owner container is still the same as when this unit was created
float gameTimeOwnerContainerWasSetup = 0.0

Function Setup(int thisUnitIndex, SAB_TroopContainerScript containerRef, int indexInUnitUpdater, float gameTimeSetupOfParentContainer)
	deathHasBeenHandled = false
	ownerTroopContainer = containerRef
	ownerContainerLocation = containerRef as SAB_LocationScript
	unitIndex = thisUnitIndex
	meActor = GetReference() as Actor
	indexInUpdater = indexInUnitUpdater
	gameTimeOwnerContainerWasSetup = gameTimeSetupOfParentContainer
	; ToggleUpdates(true)
	; debug.Trace("unit: setup end!")
EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)
	if !meActor
		; the unit went poof!
		; if we get to the update before knowing what happened here,
		; give the commander another chance to spawn this same unit type
		if unitIndex == -1 || gameTimeOwnerContainerWasSetup == 0.0
			; since all units should have a valid unit index,
			; this means this unit is probably being cleared
			; debug.Trace("unit: updated while being set up or cleared!")
		else 
			debug.Trace("unit: went poof!")
			debug.Trace("poof unit index: " + unitIndex)
			debug.Trace("poof unit setup time: " + gameTimeOwnerContainerWasSetup)
			debug.Trace("poof unit: " + GetReference())
			ownerTroopContainer.OwnedUnitHasDespawned(unitIndex, gameTimeOwnerContainerWasSetup)
			ClearAliasData()
		endif
		
		return true
	endif

	if meActor == None
		return false
	endif

	if meActor.IsDead()
		if !deathHasBeenHandled
			; debug.Trace("unit: death being handled on update!")
			HandleDeath()
		endif
		
		return true
	endif

	float distToPlayer = meActor.GetDistance(playerActor)

	if distToPlayer > GetIsNearbyDistance()
		; debug.Trace("unit: too far, despawn!")
		Despawn()
		return true
	endif

	; if ownerContainerLocation != None
	; 	; if we're guarding a location and it is under attack, keep trying to find the enemy
	; 	if meActor && !meActor.IsDead() && !meActor.IsInCombat()
	; 		SAB_CommanderScript cmderInOurLocation = ownerContainerLocation.InteractingCommander
	; 		if cmderInOurLocation != None && cmderInOurLocation.factionScript != ownerContainerLocation.factionScript
	; 			Actor attackingCmderActor = cmderInOurLocation.GetReference() as Actor
	; 			if attackingCmderActor && !attackingCmderActor.IsDead()
	; 				meActor.StartCombat(cmderInOurLocation.GetReference() as Actor)
	; 			endif
	; 		endif
	; 	endif
	; endif

	return true
EndFunction


float Function GetIsNearbyDistance()
	; int nearbyCmders = CrowdReducer.NumNearbyCmders

	; if nearbyCmders >= JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5)
	; 	return JDB.solveFlt(".ShoutAndBlade.cmderOptions.nearbyDistanceDividend", 16384.0) / nearbyCmders
	; endif

	; testing separate fixed value here
	return 8192.0
	;return JDB.solveFlt(".ShoutAndBlade.cmderOptions.isNearbyDistance", 4096.0)
EndFunction


event OnDeath(Actor akKiller)	
	; debug.Trace("unit: ondeath!")

	if unitIndex == -1
		; debug.Trace("unit: ondeath before being fully set up!")
		return
	endif

	if akKiller == playerActor
		debug.Trace("player killed a unit!")
		if ownerTroopContainer.factionScript
			ownerTroopContainer.factionScript.DiplomacyDataHandler.QueueGlobalReactToPlayerKillingUnit(ownerTroopContainer.factionScript.GetFactionIndex())
		endif
		 
	endif

	if !deathHasBeenHandled
		; debug.Trace("unit: ondeath handle death!")
		HandleDeath()
	endif
	
endEvent

Function HandleDeath()
	deathHasBeenHandled = true
	ownerTroopContainer.OwnedUnitHasDied(unitIndex, gameTimeOwnerContainerWasSetup)
	CrowdReducer.AddDeadBody(meActor)
	ClearAliasData()
EndFunction

Function Despawn()
	ownerTroopContainer.OwnedUnitHasDespawned(unitIndex, gameTimeOwnerContainerWasSetup)
	meActor.Disable()
	meActor.Delete()
	ClearAliasData()
EndFunction

; despawn, but removes the unit from the container's list instead of adding it back as spawnable
Function DespawnAndDontReturnToContainer()
	deathHasBeenHandled = true
	ownerTroopContainer.OwnedUnitHasDied(unitIndex, gameTimeOwnerContainerWasSetup)
	meActor.Disable()
	meActor.Delete()
	ClearAliasData()
EndFunction

Function ClearAliasData()
	; debug.Trace("unit: clear alias data!")
	unitIndex = -1
	gameTimeOwnerContainerWasSetup = 0.0
	parent.ClearAliasData()
	meActor = None
EndFunction