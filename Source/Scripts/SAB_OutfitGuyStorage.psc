Scriptname SAB_OutfitGuyStorage extends ReferenceAlias  
{this script uses the inventory of the outfit customizer (outfit guy) to edit a unit's gear}


int jUnitDataBeingEdited

; jArray used for storing item counts of the Storage List
int jItemAmountsArray

; jArray used for storing item forms of the Storage List
int jItemFormsArray


LeveledItem Property GearsetBeingEdited auto

Function SetupStorage(LeveledItem gearsetToEdit, int jUnitDataToEdit)
    
    jUnitDataBeingEdited = jUnitDataToEdit
    GearsetBeingEdited = gearsetToEdit
    
    ; Debug.Trace("set up storage for unit: " + jUnitDataToEdit)
    ; empty the storage list and re-fill it with the gearset's current stuff
    jItemAmountsArray = JValue.releaseAndRetain(jItemAmountsArray, jArray.object(), "ShoutAndBlade")
    jItemFormsArray = JValue.releaseAndRetain(jItemFormsArray, jArray.object(), "ShoutAndBlade")

    ; debug.Trace("setup storage!")

    int i = GearsetBeingEdited.GetNumForms()

    While (i > 0)
        i -= 1

        Form itemAtIndex = GearsetBeingEdited.GetNthForm(i)
        int itemAmount = GearsetBeingEdited.GetNthCount(i)

        if itemAmount > 0 && itemAtIndex != None
            JArray.addForm(jItemFormsArray, itemAtIndex)
            JArray.addInt(jItemAmountsArray, itemAmount)

            ; debug.Trace("added " + itemAmount + " of item " + itemAtIndex)
        endif

    EndWhile

EndFunction

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    ; debug.Trace("added " + aiItemCount + " of item " + akBaseItem)
    int itemIndexInStorage = JArray.findForm(jItemFormsArray, akBaseItem)

    if itemIndexInStorage == -1 ; not found in storage list
        GearsetBeingEdited.AddForm(akBaseItem, 1, aiItemCount)
        JArray.addInt(jItemAmountsArray, aiItemCount)
        JArray.addForm(jItemFormsArray, akBaseItem)
    else
        int previousStorageAmount = jArray.getInt(jItemAmountsArray, itemIndexInStorage)
        JArray.setInt(jItemAmountsArray, itemIndexInStorage, previousStorageAmount + aiItemCount)
        ; debug.Trace("item amount is now " + (previousStorageAmount + aiItemCount))
        RebuildGearset()
    endif

    ; debug.Trace("item types count " + JValue.count(jItemAmountsArray))

    RebuildUnitGearData()
endEvent

Event OnItemRemoved(Form akBaseItem, Int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	; debug.Trace("removed " + aiItemCount + " of item " + akBaseItem)
    
    int removedItemIndex = JArray.findForm(jItemFormsArray, akBaseItem)

    ; debug.Trace("index " + removedItemIndex)

    if removedItemIndex < 0
        return
    endif

    ; if the amount of removed items of this type equals the amount we've got stored, remove it from our list!
    int amountBeforeRemoving = JArray.getInt(jItemAmountsArray, removedItemIndex)

    if amountBeforeRemoving <= aiItemCount
        JArray.eraseIndex(jItemFormsArray, removedItemIndex)
        JArray.eraseIndex(jItemAmountsArray, removedItemIndex)
    else
        JArray.setInt(jItemAmountsArray, removedItemIndex, amountBeforeRemoving - aiItemCount)
        ; debug.Trace("item amount is now " + (amountBeforeRemoving - aiItemCount))
    endif

    ; debug.Trace("item types count " + JValue.count(jItemAmountsArray))
    RebuildGearset()
    RebuildUnitGearData()

endEvent

; runs whenever an item is removed from the list.
; removes all items and adds the remaining ones again
Function RebuildGearset()

    ; debug.Trace("rebuild gearset leveledItem!")
    GearsetBeingEdited.Revert()

    int i = jArray.count(jItemFormsArray)

    While (i > 0)
        i -= 1

        Form itemAtIndex = jArray.getForm(jItemFormsArray, i)
        int itemAmount = jArray.getInt(jItemAmountsArray, i)

        if itemAmount > 0 && itemAtIndex != None
            GearsetBeingEdited.AddForm(itemAtIndex, 1, itemAmount)
            ; debug.Trace("gearset add: " + itemAtIndex + ", amount: " + itemAmount)
        endif

    EndWhile

EndFunction

; rebuilds the unit's gear jArray using the data inside SAB_OutfitGuyStorageList and jItemAmountsArray
Function RebuildUnitGearData()

    ; debug.Trace("rebuild gear data!")

    int jUnitGearArray = jMap.getObj(jUnitDataBeingEdited, "jGearArray")

    ; create a new gear array if the unit didn't have one or it was invalid
    if jUnitGearArray == 0
        jUnitGearArray = jArray.object()
        jMap.setObj(jUnitDataBeingEdited, "jGearArray", jUnitGearArray)
    endif

    JArray.clear(jUnitGearArray)

    int i = jArray.count(jItemFormsArray)

    While (i > 0)
        i -= 1

        Form itemAtIndex = jArray.getForm(jItemFormsArray, i)
        int itemAmount = jArray.getInt(jItemAmountsArray, i)

        if itemAmount > 0 && itemAtIndex != None
            GearsetBeingEdited.AddForm(itemAtIndex, 1, itemAmount)
            int jNewGearEntry = jMap.object()
            jMap.setForm(jNewGearEntry, "itemForm", itemAtIndex)
            jMap.setInt(jNewGearEntry, "amount", itemAmount)

            ; debug.Trace("gearArray add: " + itemAtIndex + ", amount: " + itemAmount)

            JArray.addObj(jUnitGearArray, jNewGearEntry)
        endif

    EndWhile

    ;not sure if this is needed, but...
    jMap.setObj(jUnitDataBeingEdited, "jGearArray", jUnitGearArray)

EndFunction