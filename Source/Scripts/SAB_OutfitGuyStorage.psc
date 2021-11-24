Scriptname SAB_OutfitGuyStorage extends ReferenceAlias  
{this script uses the inventory of the outfit customizer (outfit guy) to edit a unit's gear}

Formlist Property SAB_OutfitGuyStorageList auto

int jUnitDataBeingEdited

; jArray used for storing item counts of the items in SAB_OutfitGuyStorageList
int jItemAmountsArray

LeveledItem Property GearsetBeingEdited auto

Function SetupStorage(LeveledItem gearsetToEdit, int jUnitDataToEdit)
    jUnitDataBeingEdited = jUnitDataToEdit
    GearsetBeingEdited = gearsetToEdit
    jItemAmountsArray = JValue.releaseAndRetain(jItemAmountsArray, jArray.object(), "ShoutAndBlade")
    ; Debug.Trace("set up storage for unit: " + jUnitDataToEdit)
    ; empty the storage list and re-fill it with the gearset's current stuff
    SAB_OutfitGuyStorageList.Revert()

    int i = GearsetBeingEdited.GetNumForms()

    While (i > 0)
        i -= 1

        Form itemAtIndex = GearsetBeingEdited.GetNthForm(i)
        int itemAmount = GearsetBeingEdited.GetNthCount(i)

        if itemAmount > 0 && itemAtIndex != None
            SAB_OutfitGuyStorageList.AddForm(itemAtIndex)
            JArray.addInt(jItemAmountsArray, itemAmount)
        endif

    EndWhile

EndFunction

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    
    int itemIndexInStorage = SAB_OutfitGuyStorageList.Find(akBaseItem)

    if itemIndexInStorage < 0 ; not found in storage list
        SAB_OutfitGuyStorageList.AddForm(akBaseItem)
        GearsetBeingEdited.AddForm(akBaseItem, 1, aiItemCount)
        JArray.addInt(jItemAmountsArray, aiItemCount)
    else
        int previousStorageAmount = jArray.getInt(jItemAmountsArray, itemIndexInStorage)
        JArray.setInt(jItemAmountsArray, itemIndexInStorage, previousStorageAmount + aiItemCount)
        RebuildGearset()
    endif

    RebuildUnitGearData()
endEvent

Event OnItemRemoved(Form akBaseItem, Int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	int removedItemIndex = SAB_OutfitGuyStorageList.Find(akBaseItem)

    if removedItemIndex < 0
        return
    endif

    ; if the amount of removed items of this type equals the amount we've got stored, remove it from our list!
    int amountBeforeRemoving = JArray.getInt(jItemAmountsArray, removedItemIndex)

    if amountBeforeRemoving <= aiItemCount
        SAB_OutfitGuyStorageList.RemoveAddedForm(akBaseItem)
        JArray.eraseIndex(jItemAmountsArray, removedItemIndex)
    else
        JArray.setInt(jItemAmountsArray, removedItemIndex, amountBeforeRemoving - aiItemCount)
    endif

    RebuildGearset()
    RebuildUnitGearData()

endEvent

; runs whenever an item is removed from the list.
; removes all items and adds the remaining ones again
Function RebuildGearset()
    
    GearsetBeingEdited.Revert()

    int i = SAB_OutfitGuyStorageList.GetSize()

    While (i > 0)
        i -= 1

        Form itemAtIndex = SAB_OutfitGuyStorageList.GetAt(i)
        int itemAmount = jArray.getInt(jItemAmountsArray, i)

        if itemAmount > 0 && itemAtIndex != None
            GearsetBeingEdited.AddForm(itemAtIndex, 1, itemAmount)
        endif

    EndWhile

EndFunction

; rebuilds the unit's gear jArray using the data inside SAB_OutfitGuyStorageList and jItemAmountsArray
Function RebuildUnitGearData()

    int jUnitGearArray = jMap.getObj(jUnitDataBeingEdited, "jGearArray")

    ; create a new gear array if the unit didn't have one or it was invalid
    if jUnitGearArray == 0
        jUnitGearArray = jArray.object()
        jMap.setObj(jUnitDataBeingEdited, "jGearArray", jUnitGearArray)
    endif

    JArray.clear(jUnitGearArray)

    int i = SAB_OutfitGuyStorageList.GetSize()

    While (i > 0)
        i -= 1

        Form itemAtIndex = SAB_OutfitGuyStorageList.GetAt(i)
        int itemAmount = jArray.getInt(jItemAmountsArray, i)

        if itemAmount > 0 && itemAtIndex != None
            GearsetBeingEdited.AddForm(itemAtIndex, 1, itemAmount)
            int jNewGearEntry = jMap.object()
            jMap.setForm(jNewGearEntry, "itemForm", itemAtIndex)
            jMap.setInt(jNewGearEntry, "amount", itemAmount)

            JArray.addObj(jUnitGearArray, jNewGearEntry)
        endif

    EndWhile

    ;not sure if this is needed, but...
    jMap.setObj(jUnitDataBeingEdited, "jGearArray", jUnitGearArray)

EndFunction