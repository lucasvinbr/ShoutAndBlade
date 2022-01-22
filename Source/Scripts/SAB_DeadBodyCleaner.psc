Scriptname SAB_DeadBodyCleaner extends Quest  

Actor[] BodiesArray

; if the dead body count from this mod gets above this limit, the oldest body is deleted
int Property MaxCoexistingDeadBodies Auto

int numExistingBodies = 0
int nextBodyIndexToFill = 0
int nextBodyIndexToErase = 0

Function Initialize()
	BodiesArray = new Actor[128]
	MaxCoexistingDeadBodies = 8
EndFunction

; stores the dead body in the bodies array and, if the body limit is reached, deletes the oldest body
Function AddDeadBody(Actor body)
	BodiesArray[nextBodyIndexToFill] = body
	numExistingBodies += 1
	nextBodyIndexToFill += 1

	if nextBodyIndexToFill >= 128
		nextBodyIndexToFill = 0
	endif

	if numExistingBodies > MaxCoexistingDeadBodies
		if BodiesArray[nextBodyIndexToErase]
			BodiesArray[nextBodyIndexToErase].Delete()
		endif
		
		BodiesArray[nextBodyIndexToErase] = None

		numExistingBodies -= 1
		nextBodyIndexToErase += 1

		if nextBodyIndexToErase >= 128
			nextBodyIndexToErase = 0
		endif
	endif
EndFunction