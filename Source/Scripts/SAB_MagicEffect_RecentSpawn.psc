scriptname SAB_MagicEffect_RecentSpawn extends ActiveMagicEffect

; basically a copy from tonycubed's CHIM Aware NPC Repair mod procedure
Float Property AIToggleWait = 0.25 Auto

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
    a.EnableAI(False)
    Utility.Wait(AIToggleWait)
    a.EnableAI(True)

    a.StopCombat()
    a.StopCombatAlarm()

    a.SetRestrained(False)
    a.SetDontMove(False)

    a.EvaluatePackage()
EndFunction