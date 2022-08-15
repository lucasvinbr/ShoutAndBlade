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

; we shouldn't register new aliases while this is true, 
; to prevent an index from being registered outside the ones we'll be looping through after the cleanup
bool cleaningIndexes = false

int Property numActives = 0 Auto Hidden

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
int Function RegisterAliasForUpdates(SAB_UpdatedReferenceAlias updatedScript, int currentIndex = -1)

	if currentIndex != -1
		debug.Trace(GetName() + " wanted to register " + updatedScript + ", but it already had an index")
		return -1
	endif

	while cleaningIndexes
		debug.Trace("hold on, " + GetName() + " is cleaning indexes")
		Utility.Wait(0.05)
	endwhile

	int vacantIndex = topFilledIndex + 1

	if !jValue.empty(jKnownVacantSlots)
		; we know of a hole in the array, let's fill it
		vacantIndex = jArray.getInt(jKnownVacantSlots, 0)
		; debug.Trace("got vacant alias index from hole: " + vacantIndex)
		jArray.eraseInteger(jKnownVacantSlots, vacantIndex)
	else 
		if vacantIndex >= 256
			; there are no holes and all entries are filled!
			; abort
			return -1
		endif
		; increment top index since there are no holes in the array
		topFilledIndex = vacantIndex
		; debug.Trace("aliasUpdater: topFilledIndex is now " + topFilledIndex)
	endif

	int indexInArray = vacantIndex % 128

	if vacantIndex > 127
		SAB_ActiveElementsOne[indexInArray] = updatedScript
	else
		SAB_ActiveElementsTwo[indexInArray] = updatedScript
	endif

	numActives += 1

	return vacantIndex
EndFunction

; nullifies the alias's index in the arrays and add the index to the "holes" jArray
Function UnregisterAliasFromUpdates(int aliasIndex)
	; debug.Trace("unregister alias " + aliasIndex)

	if aliasIndex < 0
		return
	endif

	int indexInArray = aliasIndex % 128

	if aliasIndex > 127
		SAB_ActiveElementsOne[indexInArray] = None
	else
		SAB_ActiveElementsTwo[indexInArray] = None
	endif

	; handle this new "hole" in the filled array:
	; if it's a hole in the top, we can just decrement the top
	if aliasIndex == topFilledIndex
		if !cleaningIndexes
			topFilledIndex -= 1
		endif
	else
		JArray.addInt(jKnownVacantSlots, aliasIndex)

		if !cleaningIndexes && topFilledIndex > -1

			cleaningIndexes = true
			; try and decrement topFilledIndex by finding holes at the top
			int topHoleIndex = JArray.findInt(jKnownVacantSlots, topFilledIndex)

			SAB_UpdatedReferenceAlias topRef
			int topFilledInArray = topFilledIndex % 128

			if topFilledIndex > 127
				topRef = SAB_ActiveElementsOne[topFilledInArray]
			else
				topRef = SAB_ActiveElementsTwo[topFilledInArray]
			endif

			While topHoleIndex != -1 || (topFilledIndex >= 0 && !topRef)
				debug.Trace("found hole at the top of an aliasupdater! decrementing topFilledIndex")
				jArray.eraseInteger(jKnownVacantSlots, topFilledIndex)
				topFilledIndex -= 1

				topHoleIndex = JArray.findInt(jKnownVacantSlots, topFilledIndex)

				topFilledInArray = topFilledIndex % 128

				if topFilledIndex > 127
					topRef = SAB_ActiveElementsOne[topFilledInArray]
				elseif topFilledIndex > -1
					topRef = SAB_ActiveElementsTwo[topFilledInArray]
				endif
			EndWhile

			if topFilledIndex == -1 && jArray.count(jKnownVacantSlots) > 0
				; there's an invalid hole in the vacant slots array! It should be empty if topFilled is -1
				jArray.clear(jKnownVacantSlots)
			endif

			cleaningIndexes = false
		endif
	endif
	

	numActives -= 1
EndFunction

int Function GetTopIndex()
	return topFilledIndex
EndFunction

; gets the first or second array of aliases. 0 or anything else for elements two, 1 for elements one (only 2 available currently)
SAB_UpdatedReferenceAlias[] Function GetAliasesArray(int arrayNumber)
	if arrayNumber == 1
		return SAB_ActiveElementsOne
	else
		return SAB_ActiveElementsTwo
	endif
EndFunction

Function DebugPrintVacantSlotsInfo()
	Debug.Trace("vacant slots count: " + JArray.count(jKnownVacantSlots))
	
	Debug.Trace("vacant slots: " + JArray.asIntArray(jKnownVacantSlots))
EndFunction