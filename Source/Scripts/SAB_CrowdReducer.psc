Scriptname SAB_CrowdReducer extends Quest  
{ does things like cleaning up bodies and counting nearby cmders, 
 so that the game doesn't break due to too many people around }

Actor[] BodiesArray


int Property NumNearbyCmders Hidden
	int Function Get()
		return NearbyCmdersList.GetSize()
	EndFunction
EndProperty

FormList Property NearbyCmdersList Auto

ObjectReference Property BodyDumpReference Auto
{ reference to which bodies that will be deleted are moved }

int numExistingBodies = 0
int nextBodyIndexToFill = 0
int nextBodyIndexToErase = 0


Function Initialize()
	BodiesArray = new Actor[128]
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

Function RemoveCmderFromNearbyList(Form cmderForm, Actor playerRef)
	NearbyCmdersList.RemoveAddedForm(cmderForm)

	; entries' validity check
	int i = NearbyCmdersList.GetSize()

	While i > 0
		i -= 1
		ObjectReference testedRef = NearbyCmdersList.GetAt(i) as ObjectReference
		if !testedRef || playerRef.GetDistance(testedRef) > 10000
			NearbyCmdersList.RemoveAddedForm(testedRef)
			debug.Trace("removed invalid cmder from nearby list")
		endif
	EndWhile
EndFunction