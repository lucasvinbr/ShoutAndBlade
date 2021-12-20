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
	; if we're not dead, despawn (onDeath handles our "dead" situation)
	Actor meActor = GetReference() as Actor
	if !meActor.IsDead()
		ownerCommander.OwnedUnitHasDespawned(unitIndex)
		Clear()
		meActor.Disable(true)
		meActor.Delete()
	endif
EndEvent

event OnDeath(Actor akKiller)	
	ownerCommander.OwnedUnitHasDied(unitIndex)
	Clear()
endEvent