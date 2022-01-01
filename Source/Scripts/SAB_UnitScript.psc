Scriptname SAB_UnitScript extends SAB_UpdatedReferenceAlias  

; the unit type index of this unit
int unitIndex

; reference to the troop container that spawned us. If we die/despawn, we should tell them
SAB_TroopContainerScript ownerTroopContainer

Actor meActor
Actor Property playerActor Auto

; since there are times when units outlive their owners,
; this is used to know whether the owner container is still the same as when this unit was created
float gameTimeOwnerContainerWasSetup = 0.0

Function Setup(int thisUnitIndex, SAB_TroopContainerScript containerRef, int indexInUnitUpdater, float gameTimeSetupOfParentContainer)
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
		if unitIndex == -1
			; since all units should have a valid unit index,
			; this means this unit is probably being cleared
			debug.Trace("unit: updated while being cleared!")
		else 
			debug.Trace("unit: went poof!")
			ownerTroopContainer.OwnedUnitHasDespawned(unitIndex, gameTimeOwnerContainerWasSetup)
			ClearAliasData()
		endif
		
		return true
	endif

	float distToPlayer = meActor.GetDistance(playerActor)

	if distToPlayer > 8100.0
		debug.Trace("unit: too far, despawn!")
		ownerTroopContainer.OwnedUnitHasDespawned(unitIndex, gameTimeOwnerContainerWasSetup)
		ClearAliasData()
		meActor.Disable(false)
		meActor.Delete()
	endif

	return true
EndFunction

event OnDeath(Actor akKiller)	
	debug.Trace("unit: dead!")
	ownerTroopContainer.OwnedUnitHasDied(unitIndex, gameTimeOwnerContainerWasSetup)
	ClearAliasData()
endEvent

Function ClearAliasData()
	debug.Trace("unit: clear alias data!")
	unitIndex = -1
	parent.ClearAliasData()
EndFunction