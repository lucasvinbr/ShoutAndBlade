Scriptname SAB_CrowdReducer extends Quest  
{ does things like cleaning up bodies and counting nearby cmders, 
 so that the game doesn't break due to too many people around }

Actor[] BodiesArray


; int Property NumNearbyCmders Auto Hidden

; int topFilledNearbyCmderIndex = -1
; bool editingNearbyCmderIndexes = false
; int jKnownVacantNearbyCmderSlots = -1

; SAB_CommanderScript[] Property NearbyCommanders Auto Hidden
;{ references to the commanders currently considered to be nearby }


ObjectReference Property BodyDumpReference Auto
{ reference to which bodies that will be deleted are moved }

int numExistingBodies = 0
int nextBodyIndexToFill = 0
int nextBodyIndexToErase = 0


Function Initialize()
	BodiesArray = new Actor[128]

	; if jKnownVacantNearbyCmderSlots == -1 || jKnownVacantNearbyCmderSlots == 0
	; 	NearbyCommanders = new SAB_CommanderScript[128]
	; 	jKnownVacantNearbyCmderSlots = jArray.object()
	; 	JValue.retain(jKnownVacantNearbyCmderSlots, "ShoutAndBlade")
	; endif
EndFunction

; stores the dead body in the bodies array and, if the body limit is reached, deletes the oldest body
Function AddDeadBody(Actor body)
	BodiesArray[nextBodyIndexToFill] = body
	numExistingBodies += 1
	nextBodyIndexToFill += 1

	; debug.Trace("deadBodyCleaner: added body to index " + nextBodyIndexToFill)

	if nextBodyIndexToFill >= 128
		nextBodyIndexToFill = 0
	endif

	if numExistingBodies > JDB.solveInt(".ShoutAndBlade.generalOptions.maxDeadBodies", 12)

		RegisterForSingleUpdate(0.01)
		
	endif

EndFunction

Event OnUpdate()
	
	int bodiesErased = 0

	while bodiesErased < 5 && numExistingBodies > JDB.solveInt(".ShoutAndBlade.generalOptions.maxDeadBodies", 12)

		; since something else referencing the body can keep holding us up here forever,
		; we should increment the next body to erase before deleting
		int bodyIndexToEraseNow = nextBodyIndexToErase

		nextBodyIndexToErase += 1

		if nextBodyIndexToErase >= 128
			nextBodyIndexToErase = 0
		endif

		Actor bodyToDelete = BodiesArray[bodyIndexToEraseNow]
		BodiesArray[bodyIndexToEraseNow] = None

		if bodyToDelete

			bodyToDelete.MoveTo(BodyDumpReference)
			bodyToDelete.DisableNoWait()
			bodyToDelete.Delete()
			
		endif

		numExistingBodies -= 1
		bodiesErased += 1
		
		;debug.Trace("deadBodyCleaner: deleted body at index " + bodyIndexToEraseNow)
		;debug.Trace("deadBodyCleaner: bodycount is now " + numExistingBodies)

	endwhile
EndEvent

; returns the cmder's index in the nearbies array, or -1 if we failed to find a vacant index
; int Function RegisterCommanderInNearbyList(SAB_CommanderScript cmderScript, int currentIndex = -1)

; 	if currentIndex > -1
; 		; debug.Trace(GetLocName() + " wanted to register " + cmderScript + ", but it already had an index")
; 		return -1
; 	endif

; 	while editingNearbyCmderIndexes
; 		debug.Trace("(register) hold on, crowdReducer is editing nearby cmder indexes")
; 		Utility.Wait(0.05)
; 	endwhile

; 	editingNearbyCmderIndexes = true
; 	int vacantIndex = topFilledNearbyCmderIndex + 1

; 	if !jValue.empty(jKnownVacantNearbyCmderSlots)
; 		if vacantIndex == 0
; 			; topFilledNearbyCmderIndex is -1!
; 			; in this case, we aren't expecting any vacant slots,
; 			; so we empty the vacants list
; 			debug.Trace("crowdReducer is clearing invalid vacant nearby cmder slots")
; 			jArray.clear(jKnownVacantNearbyCmderSlots)
; 			; numActives = 0
; 			topFilledNearbyCmderIndex = vacantIndex
; 		else
; 			; we know of a hole in the array, let's fill it
; 			vacantIndex = jArray.getInt(jKnownVacantNearbyCmderSlots, 0)
; 			; debug.Trace("got vacant alias index from hole: " + vacantIndex)
; 			jArray.eraseInteger(jKnownVacantNearbyCmderSlots, vacantIndex)
; 		endif
; 	else 
; 		if vacantIndex >= 32
; 			; there are no holes and all entries are filled!
; 			; abort
; 			debug.Trace("crowdReducer is full of nearby cmders!")
; 			editingNearbyCmderIndexes = false
; 			return -1
; 		endif
; 		; increment top index since there are no holes in the array
; 		topFilledNearbyCmderIndex = vacantIndex
; 		; debug.Trace("aliasUpdater: topFilledNearbyCmderIndex is now " + topFilledNearbyCmderIndex)
; 	endif

; 	NearbyCommanders[vacantIndex] = cmderScript

; 	; numActives += 1

; 	editingNearbyCmderIndexes = false
; 	return vacantIndex
; EndFunction

; ; nullifies the alias's index in the arrays and add the index to the "holes" jArray
; Function UnregisterCommanderFromNearbyList(int cmderIndexInNearbies)
; 	; debug.Trace("unregister alias " + aliasIndex)

; 	if cmderIndexInNearbies < 0
; 		return
; 	endif

; 	while editingNearbyCmderIndexes
; 		debug.Trace("(unregister) hold on, crowdReducer is editing nearby cmder indexes")
; 		Utility.Wait(0.05)
; 	endwhile

; 	editingNearbyCmderIndexes = true

; 	NearbyCommanders[cmderIndexInNearbies] = None

; 	; handle this new "hole" in the filled array:
; 	; if it's a hole in the top, we can just decrement the top
; 	if cmderIndexInNearbies == topFilledNearbyCmderIndex
; 		topFilledNearbyCmderIndex -= 1
; 	else
; 		JArray.addInt(jKnownVacantNearbyCmderSlots, cmderIndexInNearbies)

; 		if topFilledNearbyCmderIndex > -1
; 			; try and decrement topFilledNearbyCmderIndex by finding holes at the top
; 			int topHoleIndex = JArray.findInt(jKnownVacantNearbyCmderSlots, topFilledNearbyCmderIndex)

; 			SAB_CommanderScript topRef = NearbyCommanders[topFilledNearbyCmderIndex]

; 			While topHoleIndex != -1 || (topFilledNearbyCmderIndex >= 0 && !topRef)
; 				debug.Trace("found hole at the top crowdReducer nearby cmders! decrementing topFilledNearbyCmderIndex")
; 				jArray.eraseInteger(jKnownVacantNearbyCmderSlots, topFilledNearbyCmderIndex)
; 				topFilledNearbyCmderIndex -= 1

; 				topHoleIndex = JArray.findInt(jKnownVacantNearbyCmderSlots, topFilledNearbyCmderIndex)

; 				if topFilledNearbyCmderIndex >= 0
; 					topRef = NearbyCommanders[topFilledNearbyCmderIndex]
; 				endif
; 			EndWhile

; 			if topFilledNearbyCmderIndex == -1 && jArray.count(jKnownVacantNearbyCmderSlots) > 0
; 				; there's an invalid hole in the vacant slots array! It should be empty if topFilled is -1
; 				jArray.clear(jKnownVacantNearbyCmderSlots)
; 			endif

			
; 		endif
; 	endif
	
; 	editingNearbyCmderIndexes = false
; 	; numActives -= 1
; EndFunction

; bool function IsCommanderInNearbyList(SAB_CommanderScript cmderScript)
; 	int i = topFilledNearbyCmderIndex
; 	While (i >= 0)
; 		if NearbyCommanders[i] == cmderScript
; 			return true
; 		endif

; 		i -= 1
; 	EndWhile

; 	return false
; endfunction

; int Function GetTopNearbyCmderIndex()
; 	return topFilledNearbyCmderIndex
; EndFunction