Scriptname SAB_CombatOrdersScript extends Quest  
{Script that handles most combat orders-related stuff}

ReferenceAlias Property ArcherMarker  Auto  
{"hold position" marker for archer units}

ReferenceAlias Property MeleeMarker  Auto  
{"hold position" marker for melee units}

ReferenceAlias Property ExtraTypeMarker  Auto  
{"hold position" marker for extraType units}

Faction Property UnitOrdersFaction  Auto  
{"the units' faction, which is divided by ranks that indicate their types and orders"}

Message Property SetOrdersTargetBox  Auto  
{"issue orders to which group? x, y, z or all of them?"}

Message Property SetDesiredOrderBox  Auto  
{"what do you want the selected group to do during combat?"}

GlobalVariable Property DefaultArcherOrder Auto
{"the last order type given to archers; it will also be given to newly spawned ones"}

GlobalVariable Property DefaultMeleeOrder Auto
{"the last order type given to melee fighters; it will also be given to newly spawned ones"}

GlobalVariable Property DefaultExtraTypeOrder Auto
{"the last order type given to extraTypes; it will also be given to newly spawned ones"}


;Groups are usually the following:
; 0 = everyone
; 1 = archers
; 2 = melee
; 3 = extraType
;
;Orders are the following:
; 0 = charge
; 1 = stay close to player
; 2 = hold target position
; 3 = stick to player, hold fire
; 4 = stick to target position, hold fire

;so, in the unit faction, ranks 1 to 4 are archers, 5 to 8 are melee, 9 to 13 are extraType

Function StartOrderProcedure(ObjectReference hitSpot)
	int setOrderedGroupBoxChoice = -1
	int setDesiredOrderBoxChoice = -1
	
	while setOrderedGroupBoxChoice != 4
		;"who are we giving orders to?"
		setOrderedGroupBoxChoice = SetOrdersTargetBox.Show()
		if setOrderedGroupBoxChoice != 4
			setDesiredOrderBoxChoice = SetDesiredOrderBox.Show()
			if setDesiredOrderBoxChoice != 5
				;move markers if this is a "hold target pos" order
				if(setDesiredOrderBoxChoice == 2 || setDesiredOrderBoxChoice == 4)
					MoveHoldPosMarker(setOrderedGroupBoxChoice, hitSpot)
				endif
				;order given, all windows should close now
				GiveOrderToGroup(setOrderedGroupBoxChoice, setDesiredOrderBoxChoice)
				SetDefaultOrder(setOrderedGroupBoxChoice, setDesiredOrderBoxChoice)
				setOrderedGroupBoxChoice = 4 
			endif
		endif
	endwhile
endfunction


Function GiveOrderToGroup(int targetGroup, int orderType)
	; TODO change the alias picking system to the SAB system
	Int i = 72
	ReferenceAlias curMercAlias = none
	ObjectReference mercRef = none
	Actor mercActor = none
	int mercType = 0
	While(i > 11)
		i -= 1
		curMercAlias = GetAlias(i) as ReferenceAlias
		mercRef = curMercAlias.GetReference()
		
		if(mercRef != none)
			mercActor = mercRef as Actor
			;this crazy calc gets the unit type as 1,2 or 3 based on their current rank
			mercType = ((((mercActor.GetFactionRank(UnitOrdersFaction) - 1) as float) / 5.0) as int) + 1
			if(mercType < 1)
				;if, for some reason, we're not of any type, we're considered melee
				mercType = 2
			endif
			
			if (targetGroup == 0 || targetGroup == mercType)
				mercActor.SetFactionRank(UnitOrdersFaction, ((mercType - 1) * 5) + orderType + 1)
				mercActor.EvaluatePackage()
			endif
		endif
	EndWhile
endfunction


Function MoveHoldPosMarker(int targetGroup, ObjectReference newPos)
	if(newPos == none)
		Debug.Notification("unit orders: holding at playerpos instead")
		;eh, the reference's no longer there... let's pretend the order was to hold at the player's pos hahaha
		newPos = Game.GetPlayer()
	endif
	
	if(targetGroup == 0)
		ArcherMarker.GetReference().MoveTo(newPos)
		MeleeMarker.GetReference().MoveTo(newPos)
	elseif(targetGroup == 1)
		ArcherMarker.GetReference().MoveTo(newPos)
	elseif(targetGroup == 2)
		MeleeMarker.GetReference().MoveTo(newPos)
	elseif(targetGroup == 3)
		ExtraTypeMarker.GetReference().MoveTo(newPos)
	endif
	
	
endfunction


Function SetDefaultOrder(int targetGroup, int orderType)
	
	float orderFloat = orderType as float
	if(targetGroup == 0)
		DefaultArcherOrder.SetValue(orderFloat)
		DefaultMeleeOrder.SetValue(orderFloat)
		DefaultExtraTypeOrder.SetValue(orderFloat)
	elseif(targetGroup == 1)
		DefaultArcherOrder.SetValue(orderFloat)
	elseif(targetGroup == 2)
		DefaultMeleeOrder.SetValue(orderFloat)
	else
		DefaultExtraTypeOrder.SetValue(orderFloat)
	endif
	
	
endfunction

Function SetActorMercRank(Actor theActor, int orderType)
	;this sets the actor's rank in the UnitOrdersFaction.
	;it's used for setting Emissi's rank.
	;acceptable ranks for emissi are:
	;6 (melee merc charge)
	;9 (melee merc HF and Stick to Player)
	;99 (flee from enemies)
	;100 (stand still)
	theActor.SetFactionRank(UnitOrdersFaction, orderType)
endfunction
