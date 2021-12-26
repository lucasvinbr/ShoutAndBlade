Scriptname SAB_UnitScript extends ReferenceAlias  

; the unit type index of this unit
int unitIndex

; reference to the commander that spawned us. If we die/despawn, we should tell them
SAB_CommanderScript ownerCommander

Function Setup(int thisUnitIndex, SAB_CommanderScript cmderRef)
	ownerCommander = cmderRef
	unitIndex = thisUnitIndex
EndFunction

Event OnCellDetach()
	debug.Trace("unit: on cell detach!")
	; if we're not dead, despawn (onDeath handles our "dead" situation)
	; TODO check if we're units spawned by the player; in that case, don't despawn
	Actor meActor = GetReference() as Actor

	if !meActor
		ownerCommander.OwnedUnitHasDespawned(unitIndex)
		Clear()
	elseif !meActor.IsDead()
		ownerCommander.OwnedUnitHasDespawned(unitIndex)
		Clear()
		meActor.Disable(true)
		meActor.Delete()
	endif
EndEvent

Event OnDetachedFromCell()
	debug.Trace("unit: on detached from cell!")
	; if we're not dead, despawn (onDeath handles our "dead" situation)
	Actor meActor = GetReference() as Actor
	if !meActor
		ownerCommander.OwnedUnitHasDespawned(unitIndex)
		Clear()
	elseif !meActor.IsDead()
		ownerCommander.OwnedUnitHasDespawned(unitIndex)
		Clear()
		meActor.Disable(true)
		meActor.Delete()
	endif
EndEvent


event OnDeath(Actor akKiller)	
	debug.Trace("unit: dead!")
	ownerCommander.OwnedUnitHasDied(unitIndex)
	Clear()
endEvent