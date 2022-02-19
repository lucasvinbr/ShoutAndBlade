Scriptname SAB_UnitScript extends SAB_UpdatedReferenceAlias  

; the unit type index of this unit
int unitIndex = -1

; reference to the troop container that spawned us. If we die/despawn, we should tell them
SAB_TroopContainerScript ownerTroopContainer

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
	unitIndex = thisUnitIndex
	meActor = GetReference() as Actor
	indexInUpdater = indexInUnitUpdater
	gameTimeOwnerContainerWasSetup = gameTimeSetupOfParentContainer
	; ToggleUpdates(true)
	debug.Trace("unit: setup end!")
EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)
	if !meActor
		; the unit went poof!
		; if we get to the update before knowing what happened here,
		; give the commander another chance to spawn this same unit type
		if unitIndex == -1 || gameTimeOwnerContainerWasSetup == 0.0
			; since all units should have a valid unit index,
			; this means this unit is probably being cleared
			debug.Trace("unit: updated while being set up or cleared!")
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


	if meActor.IsDead()
		if !deathHasBeenHandled
			debug.Trace("unit: death being handled on update!")
			HandleDeath()
		endif
		
		return true
	endif

	float distToPlayer = meActor.GetDistance(playerActor)

	if distToPlayer > GetIsNearbyDistance()
		debug.Trace("unit: too far, despawn!")
		ownerTroopContainer.OwnedUnitHasDespawned(unitIndex, gameTimeOwnerContainerWasSetup)
		meActor.Disable(true)
		meActor.Delete()
		ClearAliasData()
	endif

	return true
EndFunction


float Function GetIsNearbyDistance()
	int nearbyCmders = CrowdReducer.NumNearbyCmders

	if nearbyCmders >= JDB.solveInt(".ShoutAndBlade.cmderOptions.nearbyCmdersLimit", 5)
		return JDB.solveFlt(".ShoutAndBlade.cmderOptions.nearbyDistanceDividend", 16384.0) / nearbyCmders
	endif

	return JDB.solveFlt(".ShoutAndBlade.cmderOptions.isNearbyDistance", 4096.0)
EndFunction


event OnDeath(Actor akKiller)	
	debug.Trace("unit: ondeath!")

	if unitIndex == -1
		debug.Trace("unit: ondeath before being fully set up!")
		return
	endif

	if !deathHasBeenHandled
		debug.Trace("unit: ondeath handle death!")
		HandleDeath()
	endif
	
endEvent

Function HandleDeath()
	deathHasBeenHandled = true
	ownerTroopContainer.OwnedUnitHasDied(unitIndex, gameTimeOwnerContainerWasSetup)
	CrowdReducer.AddDeadBody(meActor)
	ClearAliasData()
EndFunction

Function ClearAliasData()
	debug.Trace("unit: clear alias data!")
	unitIndex = -1
	gameTimeOwnerContainerWasSetup = 0.0
	parent.ClearAliasData()
	meActor = None
EndFunction