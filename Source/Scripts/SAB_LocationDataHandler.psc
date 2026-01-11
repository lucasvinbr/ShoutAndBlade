scriptname SAB_LocationDataHandler extends Quest
{script for setting up and getting data for locations used by the mod.}

SAB_AliasUpdater Property Locations Auto
{ all locations useable by the mod, enabled and disabled. }

SAB_AliasUpdater Property EnabledLocations Auto
{ locations that are currently being used by the mod. Factions will browse this list when thinking about where to go }

FormList Property SAB_ObjectsToUseAsSpawnsList Auto
{ (Auto-fill) Formlist with objects like xmarkers, that should generally serve as "good enough" spawn points }

SAB_FactionDataHandler Property FactionDataHandler Auto

bool initialSetupDone = false
bool isBusyUpdatingLocationData = false
bool isBusyAddingNewLocsToBaseArray = false

bool shouldRecalculateDistances = false
bool shouldRebuildEnabledLocations = false
bool isReaddingAllLocations = false

int Property NextLocationIndex = 0 Auto Hidden
int Property NextEnabledLocationIndex = 0 Auto Hidden

; a jMap, mapped by location name, containing jMaps with some configurable data on locations
int Property jLocationsConfigMap Auto Hidden

; a jArray of forms (quests), that we should cast to SAB_LocationDataAddon
int jregisteredAddonsArray

Function Initialize()
    Locations.Initialize(false)
    EnabledLocations.Initialize(false)

    jLocationsConfigMap = jMap.object()
    JValue.retain(jLocationsConfigMap, "ShoutAndBlade")

    jregisteredAddonsArray = jArray.object()
    JValue.retain(jregisteredAddonsArray, "ShoutAndBlade")

    initialSetupDone = true
EndFunction


bool Function IsDoneSettingUp()
    return initialSetupDone
EndFunction


event OnInit()
    CalculateLocationDistances()
endevent


Function AddNewLocationsFromAddon(SAB_LocationDataAddon addon, int addonIndex)

    if addonIndex < 0
        ; register addon in an array, so that we can call for a re-add of locations
        int indexForAddon = GetNextIndexForLocationAddon()

        jArray.setForm(jregisteredAddonsArray, indexForAddon, addon)

        addon.SetIndexInRegisteredAddons(indexForAddon)
    endif

    while isBusyAddingNewLocsToBaseArray
        Debug.Trace("[SAB]  queued new addon location registration is waiting")
        Utility.Wait(0.1)
    endwhile

    isBusyAddingNewLocsToBaseArray = true

    SAB_LocationScript[] newLocations = addon.NewLocations
    int i = 0
    bool hasMadeChanges = false

    ; set up locations
    while i != -1 && i < newLocations.Length
        SAB_LocationScript newLoc = newLocations[i]
        if newLoc != None
            If GetLocationIndexById(newLoc.GetLocId()) == -1
                Locations.RegisterAliasForUpdates(newLoc)
                hasMadeChanges = true
                NextLocationIndex = Locations.GetTopIndex() + 1
                debug.Trace("SAB: added new location " + newLoc.GetLocName())
            EndIf

            i += 1
        endif
    endwhile

    isBusyAddingNewLocsToBaseArray = false

    If hasMadeChanges
        RebuildEnabledLocationsArray()
        CalculateLocationDistances()
    EndIf
    
EndFunction

Function ReaddLocationsFromAddons()

    if isReaddingAllLocations
        return
    endif

    isReaddingAllLocations = true

    Locations.UnregisterAllAliases()
    EnabledLocations.UnregisterAllAliases()

    int topIndex = GetNextIndexForLocationAddon()
    int i = 0

    while i < topIndex
        SAB_LocationDataAddon addonScript = jArray.getForm(jregisteredAddonsArray, i) as SAB_LocationDataAddon
        if addonScript != None
            Debug.Trace("[SAB] addon reload: readd " + addonScript)
            addonScript.ReaddLocations()
        else
            Debug.Trace("[SAB] addon reload: could not load addon quest form")
        endif

        i += 1
    endwhile

    isReaddingAllLocations = false
EndFunction

; enables or disables the target location
Function SetLocationEnabled(SAB_LocationScript locScript, bool enable)

    while isBusyUpdatingLocationData
        Debug.Trace("[SAB]  queued location enable is waiting")
        Utility.Wait(0.1)
    endwhile

    int jLocDataMap = jMap.getObj(jLocationsConfigMap, locScript.ThisLocation.GetFormID())
    int locationOwnerFacIndex = -1

    if jLocDataMap != 0
        locationOwnerFacIndex = jMap.getInt(jLocDataMap, "OwnerFactionIndex", -1)
    endif

    SAB_FactionScript ownerFactionScript = None

    if locationOwnerFacIndex > -1 && locationOwnerFacIndex < FactionDataHandler.SAB_FactionQuests.Length 
        ownerFactionScript = FactionDataHandler.SAB_FactionQuests[locationOwnerFacIndex]
    endif

    if enable
        if !locScript.isEnabled
            locScript.Setup(ownerFactionScript)
        endif
    else
        if locScript.isEnabled
            locScript.DisableLocation()
        endif
    endif

    RebuildEnabledLocationsArray()
    CalculateLocationDistances()
    
EndFunction


Function RebuildEnabledLocationsArray()

    if isBusyUpdatingLocationData
        if !shouldRebuildEnabledLocations
            Debug.Trace("[SAB] rebuild enabled locations is  now scheduled")
        endif
        
        shouldRebuildEnabledLocations = true
        return
    endif

    isBusyUpdatingLocationData = true
    shouldRebuildEnabledLocations = false

    Debug.Trace("[SAB] rebuild enabled locations - start")

    int i = 0
    NextEnabledLocationIndex = 0
    EnabledLocations.UnregisterAllAliases()

    while i != -1 && i < NextLocationIndex
        SAB_LocationScript locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            if locScript.isEnabled
                EnabledLocations.RegisterAliasForUpdates(locScript)
            endif
        endif

        i += 1
    endwhile

    ; clear other enabled location entries
    NextEnabledLocationIndex = EnabledLocations.GetTopIndex()

    Debug.Trace("[SAB] rebuild enabled locations - end")

    isBusyUpdatingLocationData = false
    OnDoneUpdatingLocationData()

EndFunction


; updates each enabled location's cached references to their closest enabled locations.
; should be run again whenever a location is added/removed, to make sure the faction AIs know where it's better to go
Function CalculateLocationDistances()

    if isBusyUpdatingLocationData
        ; schedule a recalculation once the current updates are done
        if !shouldRebuildEnabledLocations
            Debug.Trace("[SAB] recalculate location distances is now scheduled")
        endif
        
        shouldRecalculateDistances = true
        return
    endif

    isBusyUpdatingLocationData = true
    shouldRecalculateDistances = false

    Debug.Trace("[SAB] recalculate location distances - start")

    int i = 0
    int j = 0
    int k = 0
    bool hasCreatedDistArrayEntry = false

    int jlocationDistancesMap = jIntMap.object()
    JValue.retain(jlocationDistancesMap, "ShoutAndBlade")

    ; fill the distances map with distances between each location
    while i < NextEnabledLocationIndex
        
        ; debug.Trace(EnabledLocations[i])
        SAB_LocationScript locScript = EnabledLocations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            ObjectReference baseRef = locScript.GetReference()
            ; debug.Trace(baseRef)
    
            while !baseRef
                ; during the new game initialization, some aliases may take longer to be properly filled
                Utility.Wait(0.15)
                baseRef = locScript.GetReference()
                ; debug.Trace(baseRef)
            endwhile
            
            baseRef = locScript.GetDistanceCheckReference()
    
            int jDistMapsFromI = jIntMap.object()
            JIntMap.setObj(jlocationDistancesMap, i, jDistMapsFromI)
    
            ; also prepare the "top 3 closest to cur loc" jArray
            int jDistancesArray = jArray.object()
            JValue.retain(jDistancesArray, "ShoutAndBlade")
    
            int jClosestIndexesArray = jArray.object()
            JValue.retain(jClosestIndexesArray, "ShoutAndBlade")
            
            j = 0
            while j < NextEnabledLocationIndex
                if i != j
                    ; check if we haven't already checked the distance between j and i
                    int jDistMapsFromJ = JIntMap.getObj(jlocationDistancesMap, j)
                    float distance = 0.0
    
                    if jDistMapsFromJ != 0
                        distance = JIntMap.getFlt(jDistMapsFromJ, i)
                    endif
    
                    if distance == 0.0
                        SAB_LocationScript otherLocScript = EnabledLocations.GetUpdatedAliasAtIndex(j) as SAB_LocationScript
                        if otherLocScript != None
                            distance = baseRef.GetDistance(otherLocScript.GetDistanceCheckReference())
                        endif
                    endif
    
                    if distance != 0.0
                        ; add distance and loc index to the sorted distances arrays
                        hasCreatedDistArrayEntry = false
                        k = jValue.count(jDistancesArray) - 1
                        while k >= 0
                            ; keep going until we find a stored distance that is smaller.
                            ; if we find it, store the new distance right after it
                            if jArray.getFlt(jDistancesArray, k) < distance
                                JArray.addFlt(jDistancesArray, distance, k + 1)
                                JArray.addInt(jClosestIndexesArray, j, k + 1)
                                hasCreatedDistArrayEntry = true
                                ; break
                                k = -1
                            endif
                            k -= 1
                        endwhile

                        ; if we couldn't find a smaller distance than the new one, it's the new smallest one!
                        if !hasCreatedDistArrayEntry
                            JArray.addFlt(jDistancesArray, distance, 0)
                            JArray.addInt(jClosestIndexesArray, j, 0)
                        endif


                        JIntMap.setFlt(jDistMapsFromI, j, distance)
                    endif
                    
                endif
                j += 1
                ;Utility.Wait(0.1)
            endwhile
    
            ; store the (limited to 3 elements) closest locations array in the location script
            int jTopClosestLocationsArray = jArray.subArray(jClosestIndexesArray, 0, 3)
            jValue.retain(jTopClosestLocationsArray, "ShoutAndBlade")
            locScript.jNearbyLocationsArray = jTopClosestLocationsArray
    
            jValue.release(jDistancesArray)
            jValue.zeroLifetime(jDistancesArray)
    
            jValue.release(jClosestIndexesArray)
            jValue.zeroLifetime(jClosestIndexesArray)
        endif
        
        i += 1
        ;Utility.Wait(0.1)
    endwhile

    jValue.release(jlocationDistancesMap)
    jValue.zeroLifetime(jlocationDistancesMap)

    Debug.Trace("[SAB] recalculate location distances - end")

    isBusyUpdatingLocationData = false

    OnDoneUpdatingLocationData()

EndFunction

; checks if other update data requests were sent during this update and starts updating again if so
Function OnDoneUpdatingLocationData()
    if shouldRebuildEnabledLocations
        RebuildEnabledLocationsArray()
    endif

    if shouldRecalculateDistances
        CalculateLocationDistances()
    endif
EndFunction


; for each location, attempts to set up the configurable parts of their data using the data stored in jLocationsConfigMap
Function UpdateLocationsAccordingToJMap()
    int i = jMap.count(jLocationsConfigMap)
    bool hasChangedEnabledLocations = false

    While (i > 0)
        i -= 1
        
        string locId = jMap.getNthKey(jLocationsConfigMap, i)

        SAB_LocationScript locScript = GetLocationById(locId)

        if locScript != None
            int jLocDataMap = jMap.getObj(jLocationsConfigMap, locId)

            if jLocDataMap != 0
                bool enableLoc = jMap.getInt(jLocDataMap, "IsEnabled", 1) != 0

                if locScript.isEnabled != enableLoc
                    hasChangedEnabledLocations = true
                    SetLocationEnabled(locScript, enableLoc)
                endif

                if enableLoc
                    int ownerFacIndex = jMap.getInt(jLocDataMap, "OwnerFactionIndex", -1)

                    if ownerFacIndex > -1 
                        if ownerFacIndex < FactionDataHandler.SAB_FactionQuests.Length
                            if locScript.factionScript != FactionDataHandler.SAB_FactionQuests[ownerFacIndex]
                                locScript.BeTakenByFaction(FactionDataHandler.SAB_FactionQuests[ownerFacIndex], true)

                                locScript.SetOwnedUnits(jMap.getObj(jLocDataMap, "jStartingGarrison"))
                            endif
                        endif
                    else 
                        if locScript.factionScript != None
                            locScript.BecomeNeutral(true)
                        endif
                    endif
                endif

                locScript.GoldRewardMultiplier = jMap.getFlt(jLocDataMap, "GoldRewardMultiplier", 1.0)
                locScript.GarrisonSizeMultiplier = jMap.getFlt(jLocDataMap, "GarrisonSizeMultiplier", 1.0)
                locScript.OverrideDisplayName = jMap.getStr(jLocDataMap, "OverrideDisplayName")
                locScript.jStartingUnitsMap = jValue.releaseAndRetain(locScript.jStartingUnitsMap, jMap.getObj(jLocDataMap, "jStartingGarrison"), "ShoutAndBlade")

            endif
        endif
        
    EndWhile

    if hasChangedEnabledLocations
        RebuildEnabledLocationsArray()
        CalculateLocationDistances()
    endif
EndFunction


Function WriteCurrentLocOwnershipsToJmap()
    
    int i = 0

    while i < NextLocationIndex
        SAB_LocationScript locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            int jLocDataMap = JMap.getObj(jLocationsConfigMap, locScript.GetLocId())

            if jLocDataMap == 0
                jLocDataMap = jMap.object()
                jMap.setObj(jLocationsConfigMap, locScript.GetLocId(), jLocDataMap)
            endif
    
            jMap.setInt(jLocDataMap, "OwnerFactionIndex", FactionDataHandler.GetFactionIndex(locScript.factionScript))
        endif

        i += 1
    endwhile

EndFunction

Function WriteCurrentLocNamesToJmap()
    
    int i = 0

    while i < NextLocationIndex
        SAB_LocationScript locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            int jLocDataMap = JMap.getObj(jLocationsConfigMap, locScript.GetLocId())

            if jLocDataMap == 0
                jLocDataMap = jMap.object()
                jMap.setObj(jLocationsConfigMap, locScript.GetLocId(), jLocDataMap)
            endif
    
            jMap.setStr(jLocDataMap, "OverrideDisplayName", locScript.GetLocName())
        endif
        
        i += 1
    endwhile

EndFunction

Function WriteCurrentLocStartGarrsToJmap()
    
    int i = 0

    while i < NextLocationIndex
        SAB_LocationScript locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            int jLocDataMap = JMap.getObj(jLocationsConfigMap, locScript.GetLocId())

            if jLocDataMap == 0
                jLocDataMap = jMap.object()
                jMap.setObj(jLocationsConfigMap, locScript.GetLocId(), jLocDataMap)
            endif
    
            jMap.setObj(jLocDataMap, "jStartingGarrison", locScript.jStartingUnitsMap)
        endif
        

        i += 1
    endwhile

EndFunction

Function WriteCurrentLocGarrsToStartGarrsJmap()
    
    int i = 0

    while i < NextLocationIndex
        SAB_LocationScript locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None
            int jLocDataMap = JMap.getObj(jLocationsConfigMap, locScript.GetLocId())

            if jLocDataMap == 0
                jLocDataMap = jMap.object()
                jMap.setObj(jLocationsConfigMap, locScript.GetLocId(), jLocDataMap)
            endif
    
            jMap.setObj(jLocDataMap, "jStartingGarrison", locScript.jOwnedUnitsMap)
        endif
        

        i += 1
    endwhile

EndFunction

; creates a string array with location IDs accompanied by their names
string[] Function CreateStringArrayWithLocationIdentifiers(int page = 0)

    int jStringsArr = jArray.object()
    jValue.retain(jStringsArr, "ShoutAndBlade")

    SAB_UpdatedReferenceAlias[] refsInPage = Locations.GetUpdatedAliasArrayAtIndex(page * 128)
    int i = 0
    int endingIndex = NextLocationIndex
    if (page + 1) * 128 < endingIndex
        endingIndex = (page + 1) * 128
    endif

    while i < endingIndex
        SAB_LocationScript locScript = refsInPage[i] as SAB_LocationScript
        If locScript != None
            string locName = locScript.GetLocName()
            ; add loc's name to the jarray
            jArray.addStr(jStringsArr, ((i + 1) as string) + " - " + locName)
        EndIf

        i += 1
    endwhile

    ; create actual string array with the jarray's size
    ; fill string array with jarray's contents
    ; return string array
    string[] namesArray = Utility.CreateStringArray(jArray.count(jStringsArr))

    i = 0
    endingIndex = jArray.count(jStringsArr)

    while(i < endingIndex)
        namesArray[i] = jArray.getStr(jStringsArr, i)

        i += 1
    endwhile

    jValue.release(jStringsArr)
    jValue.zeroLifetime(jStringsArr)

    return namesArray
EndFunction

; creates a string array with only enabled location IDs accompanied by their names
string[] Function CreateStringArrayWithEnabledLocationIdentifiers(int page = 0)

    int jStringsArr = jArray.object()
    jValue.retain(jStringsArr, "ShoutAndBlade")

    SAB_UpdatedReferenceAlias[] refsInPage = EnabledLocations.GetUpdatedAliasArrayAtIndex(page * 128)
    int i = 0
    int endingIndex = NextLocationIndex
    if (page + 1) * 128 < endingIndex
        endingIndex = (page + 1) * 128
    endif

    while i < endingIndex
        SAB_LocationScript locScript = refsInPage[i] as SAB_LocationScript
        If locScript != None
            string locName = locScript.GetLocName()
            ; add loc's name to the jarray
            jArray.addStr(jStringsArr, ((i + 1) as string) + " - " + locName)
        EndIf

        i += 1
    endwhile

    ; create actual string array with the jarray's size
    ; fill string array with jarray's contents
    ; return string array
    string[] namesArray = Utility.CreateStringArray(jArray.count(jStringsArr))

    i = 0
    endingIndex = jArray.count(jStringsArr)

    while(i < endingIndex)
        namesArray[i] = jArray.getStr(jStringsArr, i)

        i += 1
    endwhile

    jValue.release(jStringsArr)
    jValue.zeroLifetime(jStringsArr)

    return namesArray
EndFunction


int Function GetEnabledLocationIndex(SAB_LocationScript targetLocScript)
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextEnabledLocationIndex
        locScript = EnabledLocations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript == targetLocScript
            return i
        endif
        i += 1
    endwhile

    return -1
EndFunction

; returns a jArray with the indexes of the locations that have the target faction as owner
int Function GetLocationIndexesOwnedByFaction(SAB_FactionScript factionScript)
    int i = 0
    int jReturnedArray = jArray.object()
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.factionScript == factionScript
            JArray.addInt(jReturnedArray, i)
        endif
        i += 1
    endwhile

    return jReturnedArray
EndFunction


; returns a random location from the enabled locations list
SAB_LocationScript Function GetRandomLocation()
    return EnabledLocations.GetRandomFilledRefAlias() as SAB_LocationScript
endfunction

; returns the location script at the target index of the Locations alias updater
SAB_LocationScript Function GetLocationByIndex(int index)
    if index < 0
        return None
    endif

    return Locations.GetUpdatedAliasAtIndex(index) as SAB_LocationScript
EndFunction

; returns the location script at the target index of the ENABLED Locations alias updater
SAB_LocationScript Function GetEnabledLocationByIndex(int index)
    if index < 0
        return None
    endif

    return EnabledLocations.GetUpdatedAliasAtIndex(index) as SAB_LocationScript
EndFunction

SAB_LocationScript Function GetLocationByName(string name)
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.GetLocName() == name
            return locScript
        endif
        i += 1
    endwhile

    return None
EndFunction

SAB_LocationScript Function GetLocationById(string Id)
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.GetLocId() == Id
            return locScript
        endif
        i += 1
    endwhile

    return None
EndFunction

; returns location's index in the Locations array. -1 if not found
int Function GetLocationIndexById(string Id)
    int i = 0
    SAB_LocationScript locScript = None

    while i < NextLocationIndex
        locScript = Locations.GetUpdatedAliasAtIndex(i) as SAB_LocationScript
        if locScript != None && locScript.GetLocId() == Id
            return i
        endif
        i += 1
    endwhile

    return -1
EndFunction


int Function GetNextIndexForLocationAddon()

    return jArray.count(jregisteredAddonsArray)

EndFunction

bool Function GetIsReaddingAllLocs()
    return isReaddingAllLocations
EndFunction

bool Function GetIsBusyEditingLocData()
    return isReaddingAllLocations || isBusyAddingNewLocsToBaseArray || isBusyUpdatingLocationData
EndFunction

; locationData jmap entries:

; int IsEnabled - 0 = disabled, anything else = enabled
; string OverrideDisplayName
; float GarrisonSizeMultiplier
; float GoldRewardMultiplier
; int OwnerFactionIndex - -1 for neutral

; a intMap. The keys for each entry are unit indexes
; int jStartingGarrison