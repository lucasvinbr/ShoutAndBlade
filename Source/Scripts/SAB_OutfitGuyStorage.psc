Scriptname SAB_OutfitGuyStorage extends ReferenceAlias  
{this script allows Emissi to remember the last type of ammo the player gave him}

Formlist Property SAB_OutfitGuyStorageList auto
int jItemAmountsArray

LeveledItem Property GearsetBeingEdited auto

Function SetupStorage(LeveledItem gearsetToEdit)
    GearsetBeingEdited = gearsetToEdit
    jItemAmountsArray = JValue.releaseAndRetain(jItemAmountsArray, jArray.object(), "ShoutAndBlade")

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
    SAB_OutfitGuyStorageList.AddForm(akBaseItem)
    GearsetBeingEdited.AddForm(akBaseItem, 1, aiItemCount)
    JArray.addInt(jItemAmountsArray, aiItemCount)
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