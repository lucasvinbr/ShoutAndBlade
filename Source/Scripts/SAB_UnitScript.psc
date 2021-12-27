Scriptname SAB_UnitScript extends SAB_UpdatedReferenceAlias  

; the unit type index of this unit
int unitIndex

; reference to the commander that spawned us. If we die/despawn, we should tell them
SAB_CommanderScript ownerCommander

Actor meActor
Actor Property playerActor Auto

Function Setup(int thisUnitIndex, SAB_CommanderScript cmderRef, int indexInUnitUpdater)
	ownerCommander = cmderRef
	unitIndex = thisUnitIndex
	meActor = GetReference() as Actor
	indexInUpdater = indexInUnitUpdater
	ToggleUpdates(true)
EndFunction

bool Function RunUpdate(float curGameTime = 0.0, int updateIndex = 0)
	if !meActor
		; the unit went poof!
		; if we get to the update before knowing what happened here,
		; give the commander another chance to spawn this same unit type
		ownerCommander.OwnedUnitHasDespawned(unitIndex)
		ClearAliasData()
		return true
	endif

	float distToPlayer = meActor.GetDistance(playerActor)

	if distToPlayer > 4100.0
		debug.Trace("unit: too far, despawn!")
		ClearAliasData()
		meActor.Disable(true)
		meActor.Delete()
	endif

	return true
EndFunction

event OnDeath(Actor akKiller)	
	debug.Trace("unit: dead!")
	ownerCommander.OwnedUnitHasDied(unitIndex)
	ClearAliasData()
endEvent