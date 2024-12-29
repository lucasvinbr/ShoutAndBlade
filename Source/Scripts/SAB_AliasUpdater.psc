scriptname SAB_AliasUpdater extends Quest
{ updater for reference aliases, like commanders and locations. Can store a lot of them! }

; we need more arrays because of the 128 elements limit.
; each entry of this array is an object which has a SAB_UpdatedReferenceAlias array inside it
SAB_RefAliasContainer[] SAB_ActiveElementsContainers

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

Activator Property SAB_AliasContainerObject Auto
ObjectReference Property AliasContainerSpawnPoint Auto
GlobalVariable Property GameDaysPassed Auto Hidden
int Property updateTypeIndex = 0 Auto Hidden

bool autoUpdates = false

int numUpdatesRunning = 0
int updatesLimit = 8

; sets up the alias updater to make it work correctly, optionally telling it to update itself
function Initialize(bool autoRunUpdates = false)
	debug.Trace("alias updater: initialize! auto updates? " + autoRunUpdates)
	SAB_ActiveElementsContainers = new SAB_RefAliasContainer[128]
	jKnownVacantSlots = jArray.object()
	JValue.retain(jKnownVacantSlots, "ShoutAndBlade")

	if autoRunUpdates
		autoUpdates = true
		RegisterForSingleUpdate(1.0)
	endif
endfunction

Event OnUpdate()
	float daysPassed = 0.0
	if GameDaysPassed != None
		UpdateCurrentInstanceGlobal(GameDaysPassed)
		daysPassed = GameDaysPassed.GetValue()
	endif

	RunUpdate(daysPassed, updateTypeIndex)

	if autoUpdates
		RegisterForSingleUpdate(0.01)
	endif
EndEvent

function RunUpdate(float curGameTime = 0.0, int updateIndexToUse = 0)
	; debug.Trace("alias updater: start loop!")

	if numUpdatesRunning > updatesLimit
		return
	endif

	numUpdatesRunning += 1

	hasUpdatedAnElement = false

	while !hasUpdatedAnElement && updatedAliasIndex >= 0

		SAB_UpdatedReferenceAlias aliasToUpdate = GetUpdatedAliasAtIndex(updatedAliasIndex)

		; decrement before updating, 
		; to make sure the next update doesn't run on the same index if it's too fast
		updatedAliasIndex -= 1

		if aliasToUpdate != None
			hasUpdatedAnElement = aliasToUpdate.RunUpdate(curGameTime, updateIndexToUse)
		endif
		; if hasUpdatedAnElement
		; 	debug.Trace(GetName() + " - updated alias with index " + updatedAliasIndex)
		; endif
	endwhile

	if updatedAliasIndex < 0
		updatedAliasIndex = topFilledIndex
	endif

	numUpdatesRunning -= 1
	; debug.Trace("alias updater loop end")

endFunction


; returns the alias's index in the active aliases array, or -1 if we failed to find a vacant index.
; current index should be -1. 
; If it's something else, that means the alias already has an index, and shouldn't be registered again
; Returns the index in which the alias is registered, or -1 on failure
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
		if vacantIndex >= 128 * 128
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
				; debug.Trace("found hole at the top of an aliasupdater! decrementing topFilledIndex")
				jArray.eraseInteger(jKnownVacantSlots, topFilledIndex)
				topFilledIndex -= 1

				topHoleIndex = JArray.findInt(jKnownVacantSlots, topFilledIndex)

				if topFilledIndex >= 0
					topRef = GetUpdatedAliasAtIndex(topFilledIndex)
				endif
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

Function UnregisterAllAliases()
	While (topFilledIndex != -1)
		UnregisterAliasFromUpdates(topFilledIndex)
	EndWhile
EndFunction

int Function GetTopIndex()
	return topFilledIndex
EndFunction

; gets (creates, if necessary) one of the containers for arrays of aliases. 0 for elements one, 1 for elements two... 3 or anything else for elements four
SAB_RefAliasContainer Function GetOrCreateAliasContainerAtIndex(int arrayIndex)
	If SAB_ActiveElementsContainers[arrayIndex] == None
		SAB_RefAliasContainer newContainer = (AliasContainerSpawnPoint.PlaceAtMe(SAB_AliasContainerObject) as Form) as SAB_RefAliasContainer

		newContainer.Initialize()

		SAB_ActiveElementsContainers[arrayIndex] = newContainer
	EndIf

	return SAB_ActiveElementsContainers[arrayIndex]
EndFunction

; gets one of the arrays of aliases. 0 for elements one, 1 for elements two... 3 or anything else for elements four
SAB_UpdatedReferenceAlias[] Function GetAliasesArray(int arrayNumber)
	return GetOrCreateAliasContainerAtIndex(arrayNumber).GetElementsArray()
EndFunction

; picks the right alias to look at, considering the 128 element limit per array
SAB_UpdatedReferenceAlias Function GetUpdatedAliasAtIndex(int index)
	int indexInArray = index % 128
	int dividedIndex = index / 128

	return GetOrCreateAliasContainerAtIndex(dividedIndex).GetElementsArray()[indexInArray]
EndFunction

; picks the right array to look at, considering the 128 element limit per array
SAB_UpdatedReferenceAlias[] Function GetUpdatedAliasArrayAtIndex(int index)
	int dividedIndex = index / 128

	return GetOrCreateAliasContainerAtIndex(dividedIndex).GetElementsArray()
EndFunction

SAB_UpdatedReferenceAlias Function GetRandomFilledRefAlias()
	SAB_UpdatedReferenceAlias returnedRef = None
	If topFilledIndex == -1
		; no filled refs!
		return returnedRef
	EndIf

	if topFilledIndex < jArray.count(jKnownVacantSlots)
		; no filled refs! all slots that were filled are empty (this probably shouldn't happen)
		return returnedRef
	endif

	int pickedIndex = Utility.RandomInt(0, topFilledIndex)
	int attempts = 0
	While jArray.findInt(jKnownVacantSlots, pickedIndex) != -1
		attempts += 1
		If (attempts > 5)
			; topFilled index is guaranteed to be filled, I think
			return GetUpdatedAliasAtIndex(topFilledIndex)
		EndIf

		pickedIndex = Utility.RandomInt(0, topFilledIndex)
	EndWhile

	return GetUpdatedAliasAtIndex(pickedIndex)
EndFunction

Function DebugPrintVacantSlotsInfo()
	Debug.Trace("vacant slots count: " + JArray.count(jKnownVacantSlots))
	
	Debug.Trace("vacant slots: " + JArray.asIntArray(jKnownVacantSlots))
EndFunction