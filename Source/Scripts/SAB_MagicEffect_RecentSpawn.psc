scriptname SAB_MagicEffect_RecentSpawn extends ActiveMagicEffect

; a modified copy from tonycubed's CHIM Aware NPC Repair mod procedure

Event OnEffectStart(Actor akTarget, Actor akCaster)
    if akTarget == None
        return
    endif

    if akTarget.IsDead()
        return
    endif
    
    RepairAIState(akTarget)
    
EndEvent

Function RepairAIState(Actor a)

    a.SetRestrained(False)
    a.SetDontMove(False)

    a.EvaluatePackage()
EndFunction