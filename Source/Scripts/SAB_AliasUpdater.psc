scriptname SAB_AliasUpdater extends Quest
{ updater for aliases the player can see, like nearby commanders }

; we need two arrays because of the 128 elements limit
; ...ok, we've expanded to 512
SAB_UpdatedReferenceAlias[] SAB_ActiveElementsOne
SAB_UpdatedReferenceAlias[] SAB_ActiveElementsTwo
SAB_UpdatedReferenceAlias[] SAB_ActiveElementsThree
SAB_UpdatedReferenceAlias[] SAB_ActiveElementsFour

int updatedAliasIndex = -1

; the "maximum" currently used index
int topFilledIndex = -1

; a jArray of ints, containing known "hole" indexes in the actives array that aren't being used
int jKnownVacantSlots

bool hasUpdatedAnElement = false

; we shouldn't register/remove aliases while this is true, 
; to prevent an index from being registered outside the ones we'll be looping through after the cleanup
bool editingIndexes = false

int Property numActives = 0 Auto Hidden

function Initialize()
	debug.Trace("alias updater: initialize!")
	SAB_ActiveElementsOne = new SAB_UpdatedReferenceAlias[128]
	SAB_ActiveElementsTwo = new SAB_UpdatedReferenceAlias[128]
	SAB_ActiveElementsThree = new SAB_UpdatedReferenceAlias[128]
	SAB_ActiveElementsFour = new SAB_UpdatedReferenceAlias[128]
	jKnownVacantSlots = jArray.object()
	JValue.retain(jKnownVacantSlots, "ShoutAndBlade")
endfunction



function RunUpdate(float curGameTime = 0.0, int updateIndexToUse = 0)
	; debug.Trace("alias updater: start loop!")

	hasUpdatedAnElement = false

	while !hasUpdatedAnElement && updatedAliasIndex >= 0

		SAB_UpdatedReferenceAlias aliasToUpdate = GetUpdatedAliasAtIndex(updatedAliasIndex)
		if aliasToUpdate != None
			hasUpdatedAnElement = aliasToUpdate.RunUpdate(curGameTime, updateIndexToUse)
		endif
		; if hasUpdatedAnElement
		; 	debug.Trace(GetName() + " - updated alias with index " + updatedAliasIndex)
		; endif

		updatedAliasIndex -= 1
	endwhile

	if updatedAliasIndex < 0
		updatedAliasIndex = topFilledIndex
	endif

	; debug.Trace("alias updater loop end")

endFunction


; returns the alias's index in the active aliases array, or -1 if we failed to find a vacant index
int Function RegisterAliasForUpdates(SAB_UpdatedReferenceAlias updatedScript, int currentIndex = -1)

	if currentIndex > -1
		debug.Trace(GetName() + " wanted to register " + updatedScript + ", but it already had an index")
		return -1
	endif

	while editingIndexes
		debug.Trace("(register) hold on, " + GetName() + " is editing indexes")
		Utility.Wait(0.05)
	endwhile

	editingIndexes = true
	int vacantIndex = topFilledIndex + 1

	if !jValue.empty(jKnownVacantSlots)
		if vacantIndex == 0
			; topFilledIndex is -1!
			; in this case, we aren't expecting any vacant slots,
			; so we empty the vacants list
			debug.Trace("alias updater " + GetName() + " is clearing invalid vacant slots")
			jArray.clear(jKnownVacantSlots)
			numActives = 0
			topFilledIndex = vacantIndex
		else
			; we know of a hole in the array, let's fill it
			vacantIndex = jArray.getInt(jKnownVacantSlots, 0)
			; debug.Trace("got vacant alias index from hole: " + vacantIndex)
			jArray.eraseInteger(jKnownVacantSlots, vacantIndex)
		endif
	else 
		if vacantIndex >= 512
			; there are no holes and all entries are filled!
			; abort
			debug.Trace("alias updater " + GetName() + " is full!")
			editingIndexes = false
			return -1
		endif
		; increment top index since there are no holes in the array
		topFilledIndex = vacantIndex
		; debug.Trace("aliasUpdater: topFilledIndex is now " + topFilledIndex)
	endif

	int indexInArray = vacantIndex % 128

	SAB_UpdatedReferenceAlias[] aliasArray = GetUpdatedAliasArrayAtIndex(vacantIndex)
	aliasArray[indexInArray] = updatedScript

	numActives += 1

	editingIndexes = false
	return vacantIndex
EndFunction

; nullifies the alias's index in the arrays and add the index to the "holes" jArray
Function UnregisterAliasFromUpdates(int aliasIndex)
	; debug.Trace("unregister alias " + aliasIndex)

	if aliasIndex < 0
		return
	endif

	while editingIndexes
		debug.Trace("(unregister) hold on, " + GetName() + " is editing indexes")
		Utility.Wait(0.05)
	endwhile

	editingIndexes = true

	int indexInArray = aliasIndex % 128

	SAB_UpdatedReferenceAlias[] aliasArray = GetUpdatedAliasArrayAtIndex(aliasIndex)
	aliasArray[indexInArray] = None

	; handle this new "hole" in the filled array:
	; if it's a hole in the top, we can just decrement the top
	if aliasIndex == topFilledIndex
		topFilledIndex -= 1
	else
		JArray.addInt(jKnownVacantSlots, aliasIndex)

		if topFilledIndex > -1
			; try and decrement topFilledIndex by finding holes at the top
			int topHoleIndex = JArray.findInt(jKnownVacantSlots, topFilledIndex)

			SAB_UpdatedReferenceAlias topRef = GetUpdatedAliasAtIndex(topFilledIndex)

			While topHoleIndex != -1 || (topFilledIndex >= 0 && !topRef)
				debug.Trace("found hole at the top of an aliasupdater! decrementing topFilledIndex")
				jArray.eraseInteger(jKnownVacantSlots, topFilledIndex)
				topFilledIndex -= 1

				topHoleIndex = JArray.findInt(jKnownVacantSlots, topFilledIndex)

				topRef = GetUpdatedAliasAtIndex(topFilledIndex)
			EndWhile

			if topFilledIndex == -1 && jArray.count(jKnownVacantSlots) > 0
				; there's an invalid hole in the vacant slots array! It should be empty if topFilled is -1
				jArray.clear(jKnownVacantSlots)
			endif

			
		endif
	endif
	
	editingIndexes = false
	numActives -= 1
EndFunction

int Function GetTopIndex()
	return topFilledIndex
EndFunction

; gets one of the arrays of aliases. 0 for elements one, 1 for elements two... 3 or anything else for elements four
SAB_UpdatedReferenceAlias[] Function GetAliasesArray(int arrayNumber)
	if arrayNumber == 0
		return SAB_ActiveElementsOne
	elseif arrayNumber == 1
		return SAB_ActiveElementsTwo
	elseif arrayNumber == 2
		return SAB_ActiveElementsThree
	else
		return SAB_ActiveElementsFour
	endif
EndFunction

; picks the right alias and array to look at, considering the 128 element limit per array
SAB_UpdatedReferenceAlias Function GetUpdatedAliasAtIndex(int index)
	int indexInArray = index % 128
	if index <= 127
		return SAB_ActiveElementsOne[indexInArray]
	elseif index <= 255
		return SAB_ActiveElementsTwo[indexInArray]
	elseif index <= 383
		return SAB_ActiveElementsThree[indexInArray]
	else
		return SAB_ActiveElementsFour[indexInArray]
	endif
EndFunction

; picks the right array to look at, considering the 128 element limit per array
SAB_UpdatedReferenceAlias[] Function GetUpdatedAliasArrayAtIndex(int index)
	if index <= 127
		return SAB_ActiveElementsOne
	elseif index <= 255
		return SAB_ActiveElementsTwo
	elseif index <= 383
		return SAB_ActiveElementsThree
	else
		return SAB_ActiveElementsFour
	endif
EndFunction

Function DebugPrintVacantSlotsInfo()
	Debug.Trace("vacant slots count: " + JArray.count(jKnownVacantSlots))
	
	Debug.Trace("vacant slots: " + JArray.asIntArray(jKnownVacantSlots))
EndFunction