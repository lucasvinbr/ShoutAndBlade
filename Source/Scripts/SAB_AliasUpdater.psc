scriptname SAB_AliasUpdater extends Quest
{ updater for aliases the player can see, like nearby commanders }

; we need two arrays because of the 128 elements limit
SAB_UpdatedReferenceAlias[] SAB_ActiveElementsOne
SAB_UpdatedReferenceAlias[] SAB_ActiveElementsTwo

int updatedAliasIndex = -1

; the "maximum" currently used index
int topFilledIndex = -1

; a jArray of ints, containing known "hole" indexes in the actives array that aren't being used
int jKnownVacantSlots

bool hasUpdatedAnElement = false

function Initialize()
	debug.Trace("alias updater: initialize!")
	SAB_ActiveElementsOne = new SAB_UpdatedReferenceAlias[128]
	SAB_ActiveElementsTwo = new SAB_UpdatedReferenceAlias[128]
	jKnownVacantSlots = jArray.object()
	JValue.retain(jKnownVacantSlots, "ShoutAndBlade")
endfunction


function RunUpdate(float curGameTime = 0.0, int updateIndexToUse = 0)
	; debug.Trace("alias updater: start loop!")

	hasUpdatedAnElement = false

	while !hasUpdatedAnElement && updatedAliasIndex >= 0
		int indexInArray = updatedAliasIndex % 128
		if updatedAliasIndex > 127
			if SAB_ActiveElementsOne[indexInArray] != None
				hasUpdatedAnElement = SAB_ActiveElementsOne[indexInArray].RunUpdate(curGameTime, updateIndexToUse)
			endif
		else
			if SAB_ActiveElementsTwo[indexInArray] != None
				hasUpdatedAnElement = SAB_ActiveElementsTwo[indexInArray].RunUpdate(curGameTime, updateIndexToUse)
			endif
		endif

		if hasUpdatedAnElement
			; debug.Trace("updated alias with index " + updatedAliasIndex)
		endif

		updatedAliasIndex -= 1
	endwhile

	if updatedAliasIndex < 0
		updatedAliasIndex = topFilledIndex
	endif

	; debug.Trace("alias updater loop end")

endFunction


; returns the alias's index in the active aliases array, or -1 if we failed to find a vacant index
int Function RegisterAliasForUpdates(SAB_UpdatedReferenceAlias updatedScript)

	int vacantIndex = topFilledIndex + 1

	if !jValue.empty(jKnownVacantSlots)
		; we know of a hole in the array, let's fill it
		vacantIndex = jArray.getInt(jKnownVacantSlots, 0)
		jArray.eraseIndex(jKnownVacantSlots, 0)
	else 
		if vacantIndex >= 256
			; there are no holes and all entries are filled!
			; abort
			return -1
		endif
		; increment top index since there are no holes in the array
		topFilledIndex = vacantIndex
		debug.Trace("aliasUpdater: topFilledIndex is now " + topFilledIndex)
	endif

	int indexInArray = vacantIndex % 128

	if vacantIndex > 127
		SAB_ActiveElementsOne[indexInArray] = updatedScript
	else
		SAB_ActiveElementsTwo[indexInArray] = updatedScript
	endif

	return vacantIndex
EndFunction

; nullifies the alias's index in the arrays and add the index to the "holes" jArray
Function UnregisterAliasFromUpdates(int aliasIndex)
	int indexInArray = aliasIndex % 128

	if aliasIndex > 127
		SAB_ActiveElementsOne[indexInArray] = None
	else
		SAB_ActiveElementsTwo[indexInArray] = None
	endif

	JArray.addInt(jKnownVacantSlots, aliasIndex)
EndFunction