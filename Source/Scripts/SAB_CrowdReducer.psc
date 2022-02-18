Scriptname SAB_CrowdReducer extends Quest  
{ does things like cleaning up bodies and counting nearby cmders, 
 so that the game doesn't break due to too many people around }

Actor[] BodiesArray

; if the dead body count from this mod gets above this limit, the oldest body is deleted
int Property MaxCoexistingDeadBodies Auto

int Property NumNearbyCmders Auto

int numExistingBodies = 0
int nextBodyIndexToFill = 0
int nextBodyIndexToErase = 0

bool isEditingArray = false

Function Initialize()
	BodiesArray = new Actor[128]
	MaxCoexistingDeadBodies = 12
EndFunction

; stores the dead body in the bodies array and, if the body limit is reached, deletes the oldest body
Function AddDeadBody(Actor body)

	while isEditingArray
		Utility.Wait(Utility.RandomFloat(0.05, 0.15))
		debug.Trace("deadBodyCleaner: attempted to edit array while it was already being edited")
	endwhile

	isEditingArray = true
	
	BodiesArray[nextBodyIndexToFill] = body
	numExistingBodies += 1
	nextBodyIndexToFill += 1

	debug.Trace("deadBodyCleaner: added body to index " + nextBodyIndexToFill)

	if nextBodyIndexToFill >= 128
		nextBodyIndexToFill = 0
	endif

	if numExistingBodies > MaxCoexistingDeadBodies
		if BodiesArray[nextBodyIndexToErase]
			;BodiesArray[nextBodyIndexToErase].SetCriticalStage(BodiesArray[nextBodyIndexToErase].CritStage_DisintegrateEnd)
			; BodiesArray[nextBodyIndexToErase].Disable(true)
			BodiesArray[nextBodyIndexToErase].Delete()
		endif
		
		BodiesArray[nextBodyIndexToErase] = None

		debug.Trace("deadBodyCleaner: deleted body at index " + nextBodyIndexToErase)

		numExistingBodies -= 1
		nextBodyIndexToErase += 1

		if nextBodyIndexToErase >= 128
			nextBodyIndexToErase = 0
		endif
	endif

	isEditingArray = false
EndFunction