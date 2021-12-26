scriptname SAB_CloseByUpdater extends Quest
{ updater for things the player can see, like nearby commanders }

; we need two arrays because of the 128 elements limit
SAB_CommanderScript[] SAB_ActiveCommandersOne
SAB_CommanderScript[] SAB_ActiveCommandersTwo

int updatedCmderIndex = -1

; the "maximum" currently used cmder index
int topCmderIndex = -1

; a jArray of ints, containing known "hole" indexes in the active cmders array that aren't being used
int jKnownVacantCmderSlots

bool hasUpdatedCmder = false

function Initialize()
	SAB_ActiveCommandersOne = new SAB_CommanderScript[128]
	SAB_ActiveCommandersTwo = new SAB_CommanderScript[128]
	jKnownVacantCmderSlots = jArray.object()
	JValue.retain(jKnownVacantCmderSlots, "ShoutAndBlade")
	RegisterForSingleUpdate(1.0)
endfunction


Event OnUpdate()

	hasUpdatedCmder = false

	while !hasUpdatedCmder && updatedCmderIndex >= 0
		int indexInArray = updatedCmderIndex % 128
		if updatedCmderIndex > 127
			if SAB_ActiveCommandersOne[indexInArray] != None
				hasUpdatedCmder = SAB_ActiveCommandersOne[indexInArray].RunCloseByUpdate()
			endif
		else
			if SAB_ActiveCommandersTwo[indexInArray] != None
				hasUpdatedCmder = SAB_ActiveCommandersTwo[indexInArray].RunCloseByUpdate()
			endif
		endif

		updatedCmderIndex -= 1
	endwhile

	if updatedCmderIndex < 0
		updatedCmderIndex = topCmderIndex
	endif

	RegisterForSingleUpdate(0.4)

EndEvent


; returns the cmder's index in the active cmders array
int Function RegisterCmderForUpdates(SAB_CommanderScript cmderScript)

	int vacantIndex = topCmderIndex + 1

	if !jValue.empty(jKnownVacantCmderSlots)
		; we know of a hole in the array, let's fill it
		vacantIndex = jArray.getInt(jKnownVacantCmderSlots, 0)
		jArray.eraseIndex(jKnownVacantCmderSlots, 0)
	else 
		; increment top cmder index since there are no holes in the array
		topCmderIndex = vacantIndex
		debug.Trace("closeby: topcmderIndex is now " + topCmderIndex)
	endif

	int indexInArray = vacantIndex % 128

	if vacantIndex > 127
		SAB_ActiveCommandersOne[indexInArray] = cmderScript
	else
		SAB_ActiveCommandersTwo[indexInArray] = cmderScript
	endif

	return vacantIndex
EndFunction

; nullifies the cmder's index in the arrays and add the index to the "holes" jArray
Function UnregisterCmderFromUpdates(int cmderIndex)
	int indexInArray = cmderIndex % 128

	if cmderIndex > 127
		SAB_ActiveCommandersOne[indexInArray] = None
	else
		SAB_ActiveCommandersTwo[indexInArray] = None
	endif

	JArray.addInt(jKnownVacantCmderSlots, cmderIndex)
EndFunction